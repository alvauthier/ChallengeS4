package controller

import (
	"net/http"
	"time"
	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"fmt"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

// @Summary		Récupère tous les utilisateurs
// @Description	Récupère tous les utilisateurs
// @ID				get-all-users
// @Tags			Users
// @Produce		json
// @Success		200	{array}	models.User
// @Router			/users [get]
func GetAllUsers(c echo.Context) error {
	db := database.GetDB()

	var users []models.User
	if err := db.Find(&users).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	return c.JSON(http.StatusOK, users)
}

// @Summary		Récupère un utilisateur
// @Description	Récupère un utilisateur par ID
// @ID				get-user
// @Tags			Users
// @Produce		json
// @Param			id	path		string	true	"ID de l'utilisateur"
// @Success		200	{object}	models.User
// @Router			/users/{id} [get]
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

// @Summary		Créé un utilisateur
// @Description	Créé un utilisateur
// @ID				create-user
// @Tags			Users
// @Produce		json
// @Success		201	{object}	models.User
// @Router			/users [post]
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

type UserPatchInput struct {
	Firstname *string `json:"firstname"`
	Lastname  *string `json:"lastname"`
	Email     *string `json:"email"`
	Password  *string `json:"password"`
}

// @Summary		Modifie un utilisateur
// @Description	Modifie un utilisateur par ID
// @ID				update-user
// @Tags			Users
// @Produce		json
// @Param			id	path		string	true	"ID de l'utilisateur"
// @Success		200	{object}	models.User
// @Router			/users/{id} [patch]
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

// @Summary		Supprime un utilisateur
// @Description	Supprime un utilisateur par ID
// @ID				delete-user
// @Tags			Users
// @Produce		json
// @Param			id	path	string	true	"ID de l'utilisateur"
// @Success		204
// @Router			/users/{id} [delete]
func DeleteUser(c echo.Context) error {
	db := database.GetDB()

	id := c.Param("id")
	var user models.User
	if err := db.Where("id = ?", id).Delete(&user).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	return c.NoContent(http.StatusNoContent)
}

func HashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), 14)
	return string(bytes), err
}

func CheckPasswordHash(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

var secretKey = []byte("secret-key")

func createToken(username string) (string, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256,
		jwt.MapClaims{
			"username": username,
			"exp":      time.Now().Add(time.Hour * 24).Unix(),
		})

	tokenString, err := token.SignedString(secretKey)
	if err != nil {
		return "", err
	}

	return tokenString, nil
}

func verifyToken(tokenString string) error {
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		return secretKey, nil
	})

	if err != nil {
		return err
	}

	if !token.Valid {
		return fmt.Errorf("invalid token")
	}

	return nil
}
