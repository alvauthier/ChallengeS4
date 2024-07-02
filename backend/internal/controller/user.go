package controller

import (
	"net/http"
	"time"
	"weezemaster/internal/config"
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
// @Param			id	path		string	true	"ID de l'utilisateur"	format(uuid)
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
// @Router			/register [post]
func Register(c echo.Context) error {
	db := database.GetDB()

	user := new(models.User)
	if err := c.Bind(user); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	}

	user.ID = uuid.New()

	hashedPassword, err := HashPassword(user.Password)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}
	user.Password = hashedPassword

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

// @Summary		Se connecter
// @Description	Se connecter avec un email et un mot de passe
// @ID				login
// @Tags			Users
// @Produce		json
// @Param			email		query		string	true	"Email de l'utilisateur"
// @Param			password	query		string	true	"Mot de passe de l'utilisateur"
// @Success		200	{object}	models.User
// @Router			/login [post]
func Login(c echo.Context) error {
	db := database.GetDB()

	var requestBody map[string]string
	if err := c.Bind(&requestBody); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"message": "Invalid request"})
	}

	email := requestBody["email"]
	password := requestBody["password"]

	var user models.User
	if err := db.Where("email = ?", email).First(&user).Error; err != nil {
		return c.JSON(http.StatusUnauthorized, map[string]string{"message": "Invalid credentials"})
	}

	err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password))
	if err != nil {
		return c.JSON(http.StatusUnauthorized, map[string]string{"message": "Invalid credentials"})
	}

	accessToken, err := createAccessToken(user.Email, user.Role)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"message": err.Error()})
	}

	refreshToken, err := createRefreshToken(user.Email, user.Role)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"message": err.Error()})
	}
	return c.JSON(http.StatusOK, map[string]string{
		"access_token":  accessToken,
		"refresh_token": refreshToken,
	})
}

// @Summary		Modifie un utilisateur
// @Description	Modifie un utilisateur par ID
// @ID				update-user
// @Tags			Users
// @Produce		json
// @Param			id	path		string	true	"ID de l'utilisateur"	format(uuid)
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

	if patchUser.Password != nil {
		hashedPassword, err := HashPassword(*patchUser.Password)
		if err != nil {
			return c.JSON(http.StatusInternalServerError, map[string]string{"message": err.Error()})
		}
		patchUser.Password = &hashedPassword
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
// @Param			id	path	string	true	"ID de l'utilisateur"	format(uuid)
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

func generateJTI() string {
	return fmt.Sprintf("%d", time.Now().UnixNano())
}

func createAccessToken(email, role string) (string, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256,
		jwt.MapClaims{
			"email": email,
			"role":  role,
			"exp":   time.Now().Add(time.Minute * 1).Unix(),
			"iat":   time.Now().Unix(),
			"jti":   generateJTI(),
		})

	tokenString, err := token.SignedString(config.SecretKey)
	if err != nil {
		return "", err
	}

	fmt.Println(tokenString)
	return tokenString, nil
}

func createRefreshToken(email, role string) (string, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256,
		jwt.MapClaims{
			"email": email,
			"role":  role,
			"exp":   time.Now().Add(time.Hour * 24 * 30).Unix(),
			// "exp": time.Now().Add(time.Minute * 2).Unix(), // 2 minutes pour les tests
			"iat": time.Now().Unix(),
			"jti": generateJTI(),
		})

	tokenString, err := token.SignedString(config.SecretKey)
	if err != nil {
		return "", err
	}

	return tokenString, nil
}

func verifyToken(tokenString string) (jwt.MapClaims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &jwt.MapClaims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return config.SecretKey, nil
	})

	if err != nil {
		return nil, err
	}

	if !token.Valid {
		return nil, fmt.Errorf("invalid token")
	}

	claims, ok := token.Claims.(*jwt.MapClaims)
	if !ok {
		return nil, fmt.Errorf("invalid token claims")
	}

	return *claims, nil
}

func RefreshAccessToken(c echo.Context) error {
	var requestBody map[string]string
	if err := c.Bind(&requestBody); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"message": "Invalid request"})
	}

	refreshToken := requestBody["refresh_token"]

	// Vérifie le refresh token
	claims, err := verifyToken(refreshToken)
	fmt.Println("REFRESH TOKEN FUNCTION")
	fmt.Println(claims)
	fmt.Println(err)
	if err != nil {
		return c.JSON(http.StatusUnauthorized, map[string]string{"message": "Invalid refresh token"})
	}

	// Extrait l'email et le rôle à partir des claims du refresh token
	email, emailOk := claims["email"].(string)
	role, roleOk := claims["role"].(string)
	if !emailOk || !roleOk {
		return c.JSON(http.StatusInternalServerError, map[string]string{"message": "Invalid token claims"})
	}

	// Génère un nouvel access token
	accessToken, err := createAccessToken(email, role)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"message": err.Error()})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"access_token": accessToken,
	})
}
