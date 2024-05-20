package controller

import (
	"net/http"
	"time"
	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

func GetAllInterests(c echo.Context) error {
	db := database.GetDB()
	var interests []models.Interest
	db.Find(&interests)
	return c.JSON(http.StatusOK, interests)
}

func GetInterest(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var interest models.Interest
	db.First(&interest, id)
	return c.JSON(http.StatusOK, interest)
}

func CreateInterest(c echo.Context) error {
	db := database.GetDB()
	interest := new(models.Interest)
	if err := c.Bind(interest); err != nil {
		return err
	}
	db.Create(&interest)
	return c.JSON(http.StatusCreated, interest)
}

// update PUT
// func UpdateInterest(c echo.Context) error {
// 	db := database.GetDB()
// 	id := c.Param("id")
// 	interest := new(models.Interest)
// 	db.First(&interest, id)
// 	if err := c.Bind(interest); err != nil {
// 		return err
// 	}
// 	db.Save(&interest)
// 	return c.JSON(http.StatusOK, interest)
// }

type InterestPatchInput struct {
	Name *string `json:"name"`
}

func UpdateInterest(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var interest models.Interest
	if err := db.Where("id = ?", id).First(&interest).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return echo.NewHTTPError(http.StatusNotFound, "Interest not found")
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	patchInterest := new(InterestPatchInput)
	if err := c.Bind(patchInterest); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	}

	if err := db.Model(&interest).Updates(patchInterest).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	db.Model(&interest).UpdateColumn("updated_at", time.Now())

	return c.JSON(http.StatusOK, interest)
}

func DeleteInterest(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var interest models.Interest
	db.First(&interest, id)
	db.Delete(&interest)
	return c.NoContent(http.StatusNoContent)
}
