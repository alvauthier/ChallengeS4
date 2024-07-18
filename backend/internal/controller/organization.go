package controller

import (
	"net/http"
	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"github.com/labstack/echo/v4"
)

func GetAllOrganizations(c echo.Context) error {
	db := database.GetDB()
	var organizations []models.Organization
	if err := db.Find(&organizations).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}
	return c.JSON(http.StatusOK, organizations)
}
