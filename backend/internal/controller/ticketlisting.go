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

func GetAllTicketListings(c echo.Context) error {
	db := database.GetDB()
	var ticketListing []models.TicketListing
	db.Preload("Ticket.ConcertCategory").Find(&ticketListing)
	return c.JSON(http.StatusOK, ticketListing)
}

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

	ticketListing := models.TicketListing{
		ID:        uuid.New(),
		Price:     reqBody.Price,
		Status:    "available",
		TicketId:  reqBody.TicketId,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	if res := db.Create(&ticketListing); res.Error != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Internal server error"})
	}
	return c.JSON(http.StatusCreated, ticketListing)
}

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
