package controller

import (
	"net/http"
	"time"
	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
)

func CreateReservation(c echo.Context) error {
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
		ConcertCategoryId uuid.UUID `json:"concertCategoryId"`
	}
	if err := c.Bind(&reqBody); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid request body"})
	}

	var user models.User
	if err := db.Where("email = ?", email).First(&user).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "User not found"})
	}

	ticket := models.Ticket{
		ID:                uuid.New(),
		CreatedAt:         time.Now(),
		UpdatedAt:         time.Now(),
		UserId:            user.ID,
		ConcertCategoryId: reqBody.ConcertCategoryId,
	}

	if err := db.Create(&ticket).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to create ticket"})
	}

	// ticket creation working, but still need to update the number of sold tickets

	return c.JSON(http.StatusOK, ticket)
}

func CreateTicketListingReservation(c echo.Context) error {
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
		TicketListingId uuid.UUID `json:"ticketListingId"`
	}
	if err := c.Bind(&reqBody); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid request body"})
	}

	var user models.User
	if err := db.Where("email = ?", email).First(&user).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "User not found"})
	}

	var ticketListing models.TicketListing
	if err := db.Where("id = ?", reqBody.TicketListingId).First(&ticketListing).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Ticket listing not found"})
	}

	var ticket models.Ticket
	if err := db.Where("id = ?", ticketListing.TicketId).First(&ticket).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Ticket not found"})
	}

	tx := db.Begin()
	if tx.Error != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to start transaction"})
	}

	sale := models.Sale{
		ID:              uuid.New(),
		FinalPrice:      ticketListing.Price,
		TicketListingId: ticketListing.ID,
		BuyerId:         user.ID,
		SellerId:        ticket.UserId,
		CreatedAt:       time.Now(),
		UpdatedAt:       time.Now(),
	}

	if err := tx.Create(&sale).Error; err != nil {
		tx.Rollback()
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to create sale"})
	}

	ticketListing.Status = "sold"
	ticketListing.UpdatedAt = time.Now()

	if err := tx.Save(&ticketListing).Error; err != nil {
		tx.Rollback()
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to update ticket listing"})
	}

	ticket.UserId = user.ID
	ticket.UpdatedAt = time.Now()

	if err := tx.Save(&ticket).Error; err != nil {
		tx.Rollback()
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to update ticket"})
	}

	if err := tx.Commit().Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to commit transaction"})
	}

	return c.JSON(http.StatusOK, sale)
}
