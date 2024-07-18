package controller

import (
	"net/http"
	"time"
	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

// @Summary		Récupère tous les centres d'intérêts
// @Description	Récupère tous les centres d'intérêts
// @ID				get-all-interests
// @Tags			Interests
// @Produce		json
// @Success		200	{array}	models.Interest
// @Router			/interests [get]
func GetAllInterests(c echo.Context) error {
	db := database.GetDB()
	var interests []models.Interest
	db.Find(&interests)
	return c.JSON(http.StatusOK, interests)
}

// @Summary		Récupère un centre d'intérêt
// @Description	Récupère un centre d'intérêt par ID
// @ID				get-interest
// @Tags			Interests
// @Produce		json
// @Param			id	path		int	true	"ID du centre d'intérêt"
// @Success		200	{object}	models.Interest
// @Router			/interests/{id} [get]
func GetInterest(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var interest models.Interest
	db.First(&interest, id)
	return c.JSON(http.StatusOK, interest)
}

// @Summary		Créé un centre d'intérêt
// @Description	Créé un centre d'intérêt
// @ID				create-interest
// @Tags			Interests
// @Produce		json
// @Success		200	{array}	models.Interest
// @Router			/interests [post]
func CreateInterest(c echo.Context) error {
	db := database.GetDB()
	interest := new(models.Interest)
	if err := c.Bind(interest); err != nil {
		return err
	}
	db.Create(&interest)
	return c.JSON(http.StatusCreated, interest)
}

type InterestPatchInput struct {
	Name *string `json:"name"`
}

// @Summary		Modifie un centre d'intérêt
// @Description	Modifie un centre d'intérêt par ID
// @ID				update-interest
// @Tags			Interests
// @Produce		json
// @Param			id	path		int	true	"ID du centre d'intérêt"
// @Success		200	{object}	models.Interest
// @Router			/interests/{id} [patch]
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

// @Summary		Supprime un centre d'intérêt
// @Description	Supprime un centre d'intérêt par ID
// @ID				delete-interest
// @Tags			Interests
// @Produce		json
// @Param			id	path		int	true	"ID du centre d'intérêt"
// @Success		204
// @Router			/interests/{id} [delete]
func DeleteInterest(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var interest models.Interest
	db.First(&interest, id)
	db.Delete(&interest)
	return c.NoContent(http.StatusNoContent)
}

func GetUserInterests(c echo.Context) error {
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

	var userInterests []models.Interest
	if err := db.Model(&user).Association("Interests").Find(&userInterests); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}

	return c.JSON(http.StatusOK, userInterests)
}

func AddUserInterest(c echo.Context) error {
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

	interestID := c.Param("id")
	var interest models.Interest
	if err := db.First(&interest, interestID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return echo.NewHTTPError(http.StatusNotFound, "Interest not found")
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	if err := db.Model(&user).Association("Interests").Append(&interest); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}

	return c.JSON(http.StatusOK, interest)
}

func RemoveUserInterest(c echo.Context) error {
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

	interestID := c.Param("id")
	var interest models.Interest
	if err := db.First(&interest, interestID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return echo.NewHTTPError(http.StatusNotFound, "Interest not found")
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	if err := db.Model(&user).Association("Interests").Delete(&interest); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}

	return c.NoContent(http.StatusNoContent)
}
