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

//	@Summary		Récupère tous les tickets
//	@Description	Récupère tous les tickets
//	@ID				get-all-tickets
//	@Tags			Tickets
//	@Produce		json
//	@Success		200	{array}		models.Ticket
//	@Failure		500	{object}	string
//	@Router			/tickets [get]
//	@Security		Bearer
func GetAllTickets(c echo.Context) error {
	db := database.GetDB()
	var tickets []models.Ticket
	db.Preload("User").Preload("ConcertCategory.Concert").Preload("ConcertCategory.Category").Find(&tickets)
	return c.JSON(http.StatusOK, tickets)
}

//	@Summary		Récupère un ticket
//	@Description	Récupère un ticket par ID
//	@ID				get-ticket
//	@Tags			Tickets
//	@Produce		json
//	@Param			id	path		string	true	"ID du ticket"	format(uuid)
//	@Success		200	{object}	models.Ticket
//	@Failure		404	{object}	string
//	@Failure		500	{object}	string
//	@Router			/tickets/{id} [get]
//	@Security		Bearer
func GetTicket(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var ticket models.Ticket
	if err := db.Preload("User").Preload("ConcertCategory").Preload("TicketListing").Where("id = ?", id).First(&ticket).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return echo.NewHTTPError(http.StatusNotFound, "Ticket not found")
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}
	return c.JSON(http.StatusOK, ticket)
}

//	@Summary		Créé un ticket
//	@Description	Créé un ticket
//	@ID				create-ticket
//	@Tags			Tickets
//	@Produce		json
//	@Param			ticket	body		models.Ticket	true	"Ticket à créer"
//	@Success		201		{object}	models.Ticket
//	@Failure		400		{object}	string
//	@Failure		500		{object}	string
//	@Router			/tickets [post]
//	@Security		Bearer
func CreateTicket(c echo.Context) error {
	db := database.GetDB()
	ticket := new(models.Ticket)
	if err := c.Bind(ticket); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	}
	db.Create(&ticket)
	return c.JSON(http.StatusCreated, ticket)
}

type TicketPatchInput struct {
	UserId            *string `json:"user_id"`
	ConcertCategoryId *string `json:"concert_category_id"`
	TicketListings    *[]models.TicketListing
}

//	@Summary		Modifie un ticket
//	@Description	Modifie un ticket par ID
//	@ID				update-ticket
//	@Tags			Tickets
//	@Produce		json
//	@Param			id		path		string				true	"ID du ticket"	format(uuid)
//	@Param			ticket	body		TicketPatchInput	true	"Champs à modifier"
//	@Success		200		{object}	models.Ticket
//	@Failure		400		{object}	string
//	@Failure		404		{object}	string
//	@Failure		500		{object}	string
//	@Router			/tickets/{id} [patch]
//	@Security		Bearer
func UpdateTicket(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var ticket models.Ticket
	if err := db.Where("id = ?", id).First(&ticket).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return c.JSON(http.StatusNotFound, map[string]string{"message": "Ticket not found"})
		}
		return c.JSON(http.StatusInternalServerError, map[string]string{"message": err.Error()})
	}

	input := new(TicketPatchInput)
	if err := c.Bind(input); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"message": err.Error()})
	}

	if input.UserId != nil {
		userID, err := uuid.Parse(*input.UserId)
		if err != nil {
			return c.JSON(http.StatusBadRequest, map[string]string{"message": "Invalid user ID"})
		}
		ticket.UserId = userID
	}
	if input.ConcertCategoryId != nil {
		concertCategoryID, err := uuid.Parse(*input.ConcertCategoryId)
		if err != nil {
			return c.JSON(http.StatusBadRequest, map[string]string{"message": "Invalid concert category ID"})
		}
		ticket.ConcertCategoryId = concertCategoryID
	}
	if input.TicketListings != nil {
		ticket.TicketListings = nil
	}

	ticket.UpdatedAt = time.Now()
	db.Save(&ticket)
	return c.JSON(http.StatusOK, ticket)
}

//	@Summary		Supprime un ticket
//	@Description	Supprime un ticket par ID
//	@ID				delete-ticket
//	@Tags			Tickets
//	@Produce		json
//	@Param			id	path		string	true	"ID du ticket"	format(uuid)
//	@Success		204	{object}	models.Ticket
//	@Failure		404	{object}	string
//	@Failure		500	{object}	string
//	@Router			/tickets/{id} [delete]
//	@Security		Bearer
func DeleteTicket(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var ticket models.Ticket
	if err := db.Where("id = ?", id).First(&ticket).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return c.JSON(http.StatusNotFound, map[string]string{"message": "Ticket not found"})
		}
		return c.JSON(http.StatusInternalServerError, map[string]string{"message": err.Error()})
	}
	db.Delete(&ticket)
	return c.JSON(http.StatusOK, ticket)
}

//	@Summary		Récupère les tickets d'un utilisateur
//	@Description	Récupère les tickets d'un utilisateur
//	@ID				get-user-tickets
//	@Tags			Tickets
//	@Produce		json
//	@Success		200	{array}		models.Ticket
//	@Failure		401	{object}	string
//	@Failure		500	{object}	string
//	@Router			/tickets/mytickets [get]
//	@Security		Bearer
func GetUserTickets(c echo.Context) error {
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

	var user models.User
	if err := db.Where("email = ?", email).First(&user).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "User not found"})
	}

	var userTickets []models.Ticket
	if err := db.Preload("ConcertCategory").
		Preload("ConcertCategory.Concert").
		Preload("ConcertCategory.Category").
		Preload("TicketListings").
		Where("user_id = ?", user.ID).Find(&userTickets).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}

	return c.JSON(http.StatusOK, userTickets)
}
