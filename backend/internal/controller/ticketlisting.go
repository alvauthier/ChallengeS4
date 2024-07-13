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
	db.Find(&ticketListing)
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
	ticketListing := new(models.TicketListing)
	if err := c.Bind(ticketListing); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid payload"})
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
