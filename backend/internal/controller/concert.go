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

// @Summary		Récupère tous les concerts
// @Description	Récupère tous les concerts
// @ID				get-all-concerts
// @Tags			Concerts
// @Produce		json
// @Success		200	{array}	models.Concert
// @Router			/concerts [get]
func GetAllConcerts(c echo.Context) error {
	db := database.GetDB()
	var concerts []models.Concert
	db.Find(&concerts)
	return c.JSON(http.StatusOK, concerts)
}

// @Summary		Récupère un concert
// @Description	Récupère un concert par ID
// @ID				get-concert
// @Tags			Concerts
// @Produce		json
// @Param			id	path		string	true	"ID du concert"	format(uuid)
// @Success		200	{object}	models.Concert
// @Router			/concerts/{id} [get]
func GetConcert(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var concert models.Concert
	if err := db.Preload("Interests").
		Preload("Organization").
		Preload("ConcertCategories").
		Preload("ConcertCategories.Category").
		Preload("ConcertCategories.Tickets", "EXISTS (SELECT 1 FROM ticket_listings WHERE tickets.id = ticket_listings.ticket_id)").
		Preload("ConcertCategories.Tickets.TicketListing").
		Preload("ConcertCategories.Tickets.User").
		Where("id = ?", id).First(&concert).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return echo.NewHTTPError(http.StatusNotFound, "Concert not found")
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}
	return c.JSON(http.StatusOK, concert)
}

// @Summary		Créé un concert
// @Description	Créé un concert
// @ID				create-concert
// @Tags			Concerts
// @Produce		json
// @Success		201	{object}	models.Concert
// @Router			/concerts [post]
func CreateConcert(c echo.Context) error {
	db := database.GetDB()

	// Structure pour lier les champs et récupérer les InterestIDs
	var input struct {
		Name           string    `json:"name"`
		Description    string    `json:"description"`
		Location       string    `json:"location"`
		Date           time.Time `json:"date"`
		OrganizationID uuid.UUID `json:"OrganizationID"`
		InterestIDs    []int     `json:"InterestIDs"`
	}

	// Bind les données d'entrée à la structure
	if err := c.Bind(&input); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Failed to bind input: "+err.Error())
	}

	// Créer un nouvel objet Concert
	concert := &models.Concert{
		ID:             uuid.New(),
		Name:           input.Name,
		Description:    input.Description,
		Location:       input.Location,
		Date:           input.Date,
		OrganizationId: input.OrganizationID,
	}

	// Récupérer les objets Interest correspondant aux IDs
	var interests []models.Interest
	if len(input.InterestIDs) > 0 {
		if err := db.Where("id IN (?)", input.InterestIDs).Find(&interests).Error; err != nil {
			return echo.NewHTTPError(http.StatusInternalServerError, "Failed to find interests: "+err.Error())
		}
		concert.Interests = interests
	}

	// Créer le concert avec les associations
	if err := db.Create(&concert).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to create concert: "+err.Error())
	}
	return c.JSON(http.StatusOK, concert)
}

// @Summary		Modifie un concert
// @Description	Modifie un concert par ID
// @ID				update-concert
// @Tags			Concerts
// @Produce		json
// @Param			id	path		string	true	"ID du concert"	format(uuid)
// @Success		200	{object}	models.Concert
// @Router			/concerts/{id} [patch]
func UpdateConcert(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var concert models.Concert
	if err := db.Where("id = ?", id).First(&concert).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return echo.NewHTTPError(http.StatusNotFound, "Concert not found")
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}
	if err := c.Bind(&concert); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	}
	if err := db.Save(&concert).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}
	return c.JSON(http.StatusOK, concert)
}

// @Summary		Supprime un concert
// @Description	Supprime un concert par ID
// @ID				delete-concert
// @Tags			Concerts
// @Produce		json
// @Param			id	path	string	true	"ID du concert"	format(uuid)
// @Success		204
// @Router			/concerts/{id} [delete]
func DeleteConcert(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var concert models.Concert
	if err := db.Where("id = ?", id).Delete(&concert).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}
	return c.NoContent(http.StatusNoContent)
}
