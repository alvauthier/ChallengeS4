package controller

import (
	"net/http"
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
	if err := db.Preload("Interests").Preload("Organization").Preload("ConcertCategories").Preload("ConcertCategories.Category").Where("id = ?", id).First(&concert).Error; err != nil {
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
	concert := new(models.Concert)
	if err := c.Bind(concert); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	}

	concert.ID = uuid.New()

	if err := db.Create(&concert).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
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
