package controller

import (
	"net/http"
	"time"
	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

// @Summary		Get all ticket listings
// @Description	Get all ticket listings
// @Tags			Ticket listing
// @Accept			json
// @Produce		json
// @Success		200	{array}		models.TicketListing
// @Failure		500	{object}	map[string]string
// @Router			/ticketlistings [get]
// @Security		Bearer
func GetAllTicketListings(c echo.Context) error {
	db := database.GetDB()
	var ticketListing []models.TicketListing
	db.Preload("Ticket.ConcertCategory").Find(&ticketListing)
	return c.JSON(http.StatusOK, ticketListing)
}

// @Summary		Get ticket listing by ID
// @Description	Get ticket listing by ID
// @Tags			Ticket listing
// @Accept			json
// @Produce		json
// @Param			id	path		string	true	"TicketListing ID"
// @Success		200	{object}	models.TicketListing
// @Failure		404	{object}	map[string]string
// @Failure		500	{object}	map[string]string
// @Router			/ticketlistings/{id} [get]
// @Security		Bearer
func GetTicketListings(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var ticketListing models.TicketListing
	if err := db.Where("id = ?", id).First(&ticketListing).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return echo.NewHTTPError(http.StatusNotFound, "TicketListing not found")
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}
	return c.JSON(http.StatusOK, ticketListing)
}

// @Summary		Get ticket listing by concert ID
// @Description	Get ticket listing by concert ID
// @Tags			Ticket listing
// @Accept			json
// @Produce		json
// @Param			id	path		string	true	"Concert ID"
// @Success		200	{array}		models.TicketListing
// @Failure		500	{object}	map[string]string
// @Router			/ticketlistings/concert/{id} [get]
// @Security		Bearer
func GetTicketListingByConcertId(c echo.Context) error {
	db := database.GetDB()
	concertId := c.Param("id")
	var ticketListings []models.TicketListing
	if err := db.Preload("Ticket").Preload("Ticket.User").Joins("JOIN tickets ON tickets.id = ticket_listings.ticket_id").
		Joins("JOIN concert_categories ON concert_categories.id = tickets.concert_category_id").
		Where("concert_categories.concert_id = ?", concertId).
		Find(&ticketListings).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Internal server error"})
	}
	return c.JSON(http.StatusOK, ticketListings)
}

// @Summary		Create ticket listings
// @Description	Create ticket listings
// @Tags			Ticket listing
// @Accept			json
// @Produce		json
// @Param			ticketId	body		string	true	"Ticket ID"
// @Param			price		body		float64	true	"Price"
// @Success		201			{object}	models.TicketListing
// @Failure		400			{object}	map[string]string
// @Failure		401			{object}	map[string]string
// @Failure		500			{object}	map[string]string
// @Router			/ticketlistings [post]
// @Security		Bearer
func CreateTicketListings(c echo.Context) error {
	db := database.GetDB()

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

	var reqBody struct {
		TicketId uuid.UUID `json:"ticketId"`
		Price    float64   `json:"price"`
	}
	if err := c.Bind(&reqBody); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid request body"})
	}

	var user models.User
	if err := db.Where("email = ?", email).First(&user).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "User not found"})
	}

	var ticket models.Ticket
	if err := db.Where("id = ? AND user_id = ?", reqBody.TicketId, user.ID).First(&ticket).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Ticket not found or does not belong to the user"})
	}

	var concertCategory models.ConcertCategory
	if err := db.Where("id = ?", ticket.ConcertCategoryId).First(&concertCategory).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Concert category not found"})
	}

	if reqBody.Price > concertCategory.Price {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Price exceeds the original ticket price"})
	}

	var existingListing models.TicketListing
	if err := db.Where("ticket_id = ? AND status = ?", reqBody.TicketId, "available").First(&existingListing).Error; err == nil {
		return c.JSON(http.StatusConflict, map[string]string{"error": "Ticket listing already exists with status available"})
	}

	newListing := models.TicketListing{
		ID:        uuid.New(),
		Price:     reqBody.Price,
		Status:    "available",
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
		TicketId:  reqBody.TicketId,
	}

	if err := db.Create(&newListing).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to create ticket listing"})
	}

	return c.JSON(http.StatusOK, newListing)
}

// @Summary		Update ticket listing
// @Description	Update ticket listing
// @Tags			Ticket listing
// @Accept			json
// @Produce		json
// @Param			id		path		string	true	"TicketListing ID"
// @Param			price	body		float64	false	"Price"
// @Param			status	body		string	false	"Status"
// @Success		200		{object}	models.TicketListing
// @Failure		400		{object}	map[string]string
// @Failure		404		{object}	map[string]string
// @Failure		500		{object}	map[string]string
// @Router			/ticketlistings/{id} [patch]
// @Security		Bearer
func UpdateTicketListing(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var ticketListing models.TicketListing

	if res := db.Where("id = ?", id).First(&ticketListing); res.Error != nil {
		if res.Error == gorm.ErrRecordNotFound {
			return c.JSON(http.StatusNotFound, map[string]string{"error": "TicketListing not found"})
		}
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Internal server error"})
	}

	input := new(models.TicketListing)
	if err := c.Bind(input); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid payload"})
	}

	if input.Price != 0 {
		ticketListing.Price = input.Price
	}
	if input.Status != "" {
		ticketListing.Status = input.Status
	}

	ticketListing.UpdatedAt = time.Now()

	if res := db.Save(&ticketListing); res.Error != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Internal server error"})
	}

	return c.JSON(http.StatusOK, ticketListing)
}

// @Summary		Delete ticket listing
// @Description	Delete ticket listing
// @Tags			Ticket listing
// @Accept			json
// @Produce		json
// @Param			id	path	string	true	"TicketListing ID"
// @Success		204
// @Failure		404	{object}	map[string]string
// @Failure		500	{object}	map[string]string
// @Router			/ticketlistings/{id} [delete]
// @Security		Bearer
func DeleteTicketListing(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")

	ticketListingID, err := uuid.Parse(id)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid ID format"})
	}

	var ticketListing models.TicketListing
	if res := db.Where("id = ?", ticketListingID).First(&ticketListing); res.Error != nil {
		if res.Error == gorm.ErrRecordNotFound {
			return c.JSON(http.StatusNotFound, map[string]string{"error": "TicketListing not found"})
		}
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Internal server error"})
	}

	if res := db.Delete(&ticketListing); res.Error != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Internal server error"})
	}

	return c.NoContent(http.StatusNoContent)
}
