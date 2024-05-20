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

func GetAllUsers(c echo.Context) error {
	db := database.GetDB()

	var users []models.User
	if err := db.Find(&users).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	return c.JSON(http.StatusOK, users)
}

func GetUser(c echo.Context) error {
	db := database.GetDB()

	id := c.Param("id")
	var user models.User
	if err := db.Where("id = ?", id).First(&user).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return echo.NewHTTPError(http.StatusNotFound, "User not found")
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	return c.JSON(http.StatusOK, user)
}

func CreateUser(c echo.Context) error {
	db := database.GetDB()

	user := new(models.User)
	if err := c.Bind(user); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	}

	user.ID = uuid.New()

	if err := db.Omit("organization_id", "last_connexion").Create(&user).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	return c.JSON(http.StatusCreated, user)
}

// UpdateUser PUT
// func UpdateUser(c echo.Context) error {
// 	db := database.GetDB()

// 	id := c.Param("id")
// 	var user models.User
// 	if err := db.Where("id = ?", id).First(&user).Error; err != nil {
// 		if err == gorm.ErrRecordNotFound {
// 			return echo.NewHTTPError(http.StatusNotFound, "User not found")
// 		}
// 		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
// 	}

// 	if err := c.Bind(&user); err != nil {
// 		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
// 	}

// 	if err := db.Omit("organization_id", "last_connexion").Save(&user).Error; err != nil {
// 		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
// 	}

// 	return c.JSON(http.StatusOK, user)
// }

type UserPatchInput struct {
	Firstname *string `json:"firstname"`
	Lastname  *string `json:"lastname"`
	Email     *string `json:"email"`
	Password  *string `json:"password"`
}

func UpdateUser(c echo.Context) error {
	db := database.GetDB()

	id := c.Param("id")
	var user models.User
	if err := db.Where("id = ?", id).First(&user).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return c.JSON(http.StatusNotFound, map[string]string{"message": "User not found"})
		}
		return c.JSON(http.StatusInternalServerError, map[string]string{"message": err.Error()})
	}

	patchUser := new(UserPatchInput)
	if err := c.Bind(patchUser); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"message": "Invalid request"})
	}

	if patchUser.Email != nil {
		var existingUser models.User
		if err := db.Where("email = ?", *patchUser.Email).First(&existingUser).Error; err != gorm.ErrRecordNotFound {
			return c.JSON(http.StatusUnprocessableEntity, map[string]string{"message": "Email already used"})
		}
	}

	if err := db.Model(&user).Updates(patchUser).Error; err != nil {
		return c.JSON(http.StatusUnprocessableEntity, map[string]string{"message": "Invalid fields"})
	}

	db.Model(&user).UpdateColumn("updated_at", time.Now())

	return c.JSON(http.StatusOK, user)
}

func DeleteUser(c echo.Context) error {
	db := database.GetDB()

	id := c.Param("id")
	var user models.User
	if err := db.Where("id = ?", id).Delete(&user).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	return c.NoContent(http.StatusNoContent)
}
