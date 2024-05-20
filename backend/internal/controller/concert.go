package controller

import (
	"net/http"
	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

func GetAllConcerts(c echo.Context) error {
	db := database.GetDB()
	var concerts []models.Concert
	db.Find(&concerts)
	return c.JSON(http.StatusOK, concerts)
}

func GetConcert(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var concert models.Concert
	if err := db.Where("id = ?", id).First(&concert).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return echo.NewHTTPError(http.StatusNotFound, "Concert not found")
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}
	return c.JSON(http.StatusOK, concert)
}

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

func DeleteConcert(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var concert models.Concert
	if err := db.Where("id = ?", id).Delete(&concert).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}
	return c.NoContent(http.StatusNoContent)
}
