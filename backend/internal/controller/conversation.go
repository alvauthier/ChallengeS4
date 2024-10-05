package controller

import (
	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
	"net/http"
	"weezemaster/internal/database"
	"weezemaster/internal/models"
)

// GetConversation @Summary		Récupère une conversation
// @Description	Récupère une conversation par ID
// @ID				get-conversation
// @Tags			Conversations
// @Produce		json
// @Param			id	path		string	true	"ID de la conversation"	format(uuid)
// @Success		200	{object}	models.Conversation
// @Router			/conversations/{id} [get]
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
	if err := db.Preload("Messages").Preload("TicketListing.Ticket.ConcertCategory.Concert").Preload("TicketListing.Ticket.ConcertCategory.Category").Preload("Buyer").Preload("Buyer").Preload("Seller").Where("id = ?", id).First(&conversation).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return echo.NewHTTPError(http.StatusNotFound, "Conversation not found")
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	if user.ID != conversation.BuyerId && user.ID != conversation.SellerId {
		return echo.NewHTTPError(http.StatusUnauthorized, "User is not part of the conversation")
	}

	return c.JSON(http.StatusOK, conversation)
}

// CreateConversation @Summary		Créé une conversation
// @Description	Créé une conversation
// @ID				create-conversation
// @Tags			Conversations
// @Accept		json
// @Produce		json
// @Param			conversation	body		object	true	"Conversation à créer"
// @Success		200	{object}	models.Conversation
// @Router			/conversations [post]
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
		Price:           concertCategory.Price,
	}

	if err := db.Create(conversation).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to create conversation: "+err.Error())
	}

	return c.JSON(http.StatusOK, conversation)
}
