package controller

import (
	"fmt"
	"net/http"
	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

// @Summary		Récupère une conversation
// @Description	Récupère une conversation par ID
// @ID				get-conversation
// @Tags			Conversations
// @Produce		json
// @Param			id	path		string	true	"ID de la conversation"	format(uuid)
// @Success		200	{object}	models.Conversation
// @Failure		401	{object}	string
// @Failure		404	{object}	string
// @Failure		500	{object}	string
// @Router			/conversations/{id} [get]
// @Security		Bearer
func GetConversation(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")

	authHeader := c.Request().Header.Get("Authorization")
	if authHeader == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": "Authorization header is missing"})
	}

	tokenString := authHeader
	if len(authHeader) > 7 && authHeader[:7] == "Bearer " {
		tokenString = authHeader[7:]
	}

	claims, err := verifyToken(tokenString)
	if err != nil {
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": "Invalid or expired token"})
	}

	email, ok := claims["email"].(string)
	if !ok {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Invalid token claims"})
	}

	var user models.User
	if err := db.Where("email = ?", email).First(&user).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "User not found"})
	}

	var conversation models.Conversation
	if err := db.Preload("Messages").Preload("TicketListing.Ticket.ConcertCategory.Category").Preload("TicketListing.Ticket.ConcertCategory.Concert").Preload("Seller").Preload("Buyer").Where("id = ?", id).First(&conversation).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return echo.NewHTTPError(http.StatusNotFound, "Conversation not found")
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	if user.ID != conversation.BuyerId && user.ID != conversation.SellerId {
		return echo.NewHTTPError(http.StatusUnauthorized, "User is not part of the conversation")
	}

	// return c.JSON(http.StatusOK, conversation)

	concert := conversation.TicketListing.Ticket.ConcertCategory.Concert

	response := map[string]interface{}{
		"ID":         conversation.ID,
		"Messages":   conversation.Messages,
		"BuyerId":    conversation.BuyerId,
		"BuyerName":  conversation.Buyer.Firstname + " " + conversation.Buyer.Lastname,
		"SellerId":   conversation.SellerId,
		"SellerName": conversation.Seller.Firstname + " " + conversation.Seller.Lastname,
		"Price":      conversation.Price,
		"Category":   conversation.TicketListing.Ticket.ConcertCategory.Category.Name,
		"Concert": map[string]interface{}{
			"ID":       concert.ID,
			"Name":     concert.Name,
			"Date":     concert.Date,
			"Location": concert.Location,
			"Image":    concert.Image,
		},
		"TicketListing": conversation.TicketListing,
	}

	return c.JSON(http.StatusOK, response)
}

// @Summary		Créé une conversation
// @Description	Créé une conversation
// @ID				create-conversation
// @Tags			Conversations
// @Accept			json
// @Produce		json
// @Param			conversation	body		object	true	"Conversation à créer"
// @Success		201				{object}	models.Conversation
// @Failure		400				{object}	string
// @Failure		401				{object}	string
// @Failure		500				{object}	string
// @Router			/conversations [post]
// @Security		Bearer
func CreateConversation(c echo.Context) error {
	db := database.GetDB()

	var input struct {
		BuyerId         uuid.UUID `json:"buyer_id"`
		SellerId        uuid.UUID `json:"seller_id"`
		TicketListingId uuid.UUID `json:"ticket_listing_id"`
	}

	if err := c.Bind(&input); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Failed to bind input: "+err.Error())
	}

	// Récupérer le ticketListing de la base de données
	var ticketListing models.TicketListing
	if err := db.Where("id = ?", input.TicketListingId).First(&ticketListing).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	// Récupérer le ticket de la base de données
	var ticket models.Ticket
	if err := db.Where("id = ?", ticketListing.TicketId).First(&ticket).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	var concertCategory models.ConcertCategory
	if err := db.Where("id = ?", ticket.ConcertCategoryId).First(&concertCategory).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	// Vérifier que le buyer_id n'est pas égal à l'user_id du ticket
	if input.BuyerId == ticket.UserId {
		return echo.NewHTTPError(http.StatusBadRequest, "Buyer cannot be the owner of the ticket")
	}

	// Vérifier que le seller_id n'est pas égal au buyer_id
	if input.SellerId == input.BuyerId {
		return echo.NewHTTPError(http.StatusBadRequest, "Seller cannot be the buyer")
	}

	conversation := &models.Conversation{
		ID:              uuid.New(),
		BuyerId:         input.BuyerId,
		SellerId:        input.SellerId,
		TicketListingId: input.TicketListingId,
		Price:           ticketListing.Price,
	}

	if err := db.Create(conversation).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to create conversation: "+err.Error())
	}

	return c.JSON(http.StatusOK, conversation)
}

type CheckConversationRequest struct {
	TicketListingID uuid.UUID `json:"ticket_listing_id"`
	BuyerID         uuid.UUID `json:"buyer_id"`
}

type CheckConversationResponse struct {
	ID              string           `json:"ID"`
	BuyerId         string           `json:"buyer_id"`
	SellerId        string           `json:"seller_id"`
	TicketListingId string           `json:"ticket_listing_id"`
	Messages        []models.Message `json:"messages"`
	Price           float64          `json:"price"`
}

// @Summary		Vérifie si une conversation existe
// @Description	Vérifie si une conversation existe
// @ID				check-conversation
// @Tags			Conversations
// @Accept			json
// @Produce		json
// @Param			ticket_listing_id	query	CheckConversationRequest	true	"Request"
// @Success		200				{object}	string "ID" "ID de la conversation"
// @Failure		400				{object}	string
// @Failure		500				{object}	string
// @Router			/conversations/check [get]
// @Security		Bearer
func CheckConversation(c echo.Context) error {
	fmt.Println("CheckConversation")
	var req CheckConversationRequest
	if err := c.Bind(&req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid request"})
	}

	db := database.GetDB()

	var conversation models.Conversation
	fmt.Println(req.TicketListingID)
	fmt.Println(req.BuyerID)
	if err := db.Where("ticket_listing_id = ? AND buyer_id = ?", req.TicketListingID, req.BuyerID).First(&conversation).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return c.JSON(http.StatusOK, map[string]string{"ID": ""})
		}
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Database error"})
	}

	return c.JSON(http.StatusOK, map[string]string{"ID": conversation.ID.String()})
}

// @Summary		Met à jour une conversation
// @Description	Met à jour une conversation
// @ID				update-conversation
// @Tags			Conversations
// @Accept			json
// @Produce		json
// @Param			id	path		string	true	"ID de la conversation"	format(uuid)
// @Param			conversation	body		float64	true	"Price"
// @Success		200				{object}	models.Conversation
// @Failure		400				{object}	string
// @Failure		401				{object}	string
// @Failure		404				{object}	string
// @Failure		500				{object}	string
// @Router			/conversations/{id} [patch]
// @Security		Bearer
func UpdateConversation(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")

	var input struct {
		Price float64 `json:"price"`
	}

	if err := c.Bind(&input); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Failed to bind input: "+err.Error())
	}

	var conversation models.Conversation
	if err := db.Where("id = ?", id).First(&conversation).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	conversation.Price = input.Price

	if err := db.Save(&conversation).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	return c.JSON(http.StatusOK, conversation)
}
