package controller

import (
	"crypto/rand"
	"net/http"
	"time"
	"weezemaster/internal/config"
	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"fmt"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"github.com/resend/resend-go/v2"
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

    userIdFromToken, ok := claims["id"].(string)
    userRole, ok := claims["role"].(string)

    if !ok {
        return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Invalid token claims"})
    }

    id := c.Param("id")

	if userRole != "admin" && userIdFromToken != id {
		return echo.NewHTTPError(http.StatusForbidden, "You are not allowed to access this resource")
	}

	var user models.User
	if err := db.Preload("ConversationsAsBuyer").Preload("ConversationsAsBuyer.Buyer").Preload("ConversationsAsBuyer.Seller").Preload("ConversationsAsSeller").Preload("ConversationsAsSeller.Buyer").Preload("ConversationsAsSeller.Seller").Where("id = ?", id).First(&user).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return echo.NewHTTPError(http.StatusNotFound, "User not found")
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	return c.JSON(http.StatusOK, user)
}

type RegisterRequest struct {
	Email     string `json:"email"`
	Password  string `json:"password"`
	Firstname string `json:"firstname"`
	Lastname  string `json:"lastname"`
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

	req := new(RegisterRequest)
	if err := c.Bind(req); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	}

	user := &models.User{
		ID:        uuid.New(),
		Email:     req.Email,
		Firstname: req.Firstname,
		Lastname:  req.Lastname,
		Role:      "user",
	}

	hashedPassword, err := HashPassword(req.Password)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}
	user.Password = hashedPassword

	if err := db.Omit("organization_id", "last_connexion").Create(&user).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	user.Password = ""
	return c.JSON(http.StatusCreated, user)
}

type UserPatchInput struct {
	Firstname *string `json:"firstname"`
	Lastname  *string `json:"lastname"`
	Email     *string `json:"email"`
	Password  *string `json:"password"`
}

type RequestPayload struct {
	OrganizationName        string `json:"organization"`
	OrganizationDescription string `json:"orgadescri"`
	UserEmail               string `json:"email"`
	UserPassword            string `json:"password"`
	UserFirstname           string `json:"firstname"`
	UserLastname            string `json:"lastname"`
}

func RegisterOrganizer(c echo.Context) error {
	db := database.GetDB()

	var payload RequestPayload

	if err := c.Bind(&payload); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	}

	org := models.Organization{
		ID:          uuid.New(),
		Name:        payload.OrganizationName,
		Description: payload.OrganizationDescription,
	}

	if err := db.Create(&org).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	user := models.User{
		ID:             uuid.New(),
		Email:          payload.UserEmail,
		Password:       payload.UserPassword,
		Firstname:      payload.UserFirstname,
		Lastname:       payload.UserLastname,
		Role:           "organizer",
		OrganizationId: org.ID,
	}

	hashedPassword, err := HashPassword(user.Password)
	if err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}
	user.Password = hashedPassword

	if err := db.Omit("last_connexion").Create(&user).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	return c.JSON(http.StatusCreated, map[string]interface{}{
		"organization": org,
		"user":         user,
	})
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

	accessToken, err := createAccessToken(user.ID, user.Email, user.Role)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"message": err.Error()})
	}

	refreshToken, err := createRefreshToken(user.ID, user.Email, user.Role)
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

	if patchUser.Email != nil && *patchUser.Email != user.Email {
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

func createAccessToken(id uuid.UUID, email, role string) (string, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256,
		jwt.MapClaims{
			"id":    id.String(),
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

	// fmt.Println(tokenString)
	return tokenString, nil
}

func createRefreshToken(id uuid.UUID, email, role string) (string, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256,
		jwt.MapClaims{
			"id":    id.String(),
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
	if err != nil {
		return c.JSON(http.StatusUnauthorized, map[string]string{"message": "Invalid refresh token"})
	}

	// Extrait l'id, l'email et le rôle à partir des claims du refresh token
	idStr, idOk := claims["id"].(string)
	if !idOk {
		return c.JSON(http.StatusInternalServerError, map[string]string{"message": "Invalid token claims"})
	}

	id, err := uuid.Parse(idStr)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"message": "Invalid user ID format"})
	}
	email, emailOk := claims["email"].(string)
	role, roleOk := claims["role"].(string)
	if !idOk || !emailOk || !roleOk {
		return c.JSON(http.StatusInternalServerError, map[string]string{"message": "Invalid token claims"})
	}

	// Génère un nouvel access token
	accessToken, err := createAccessToken(id, email, role)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"message": err.Error()})
	}

	return c.JSON(http.StatusOK, map[string]string{
		"access_token": accessToken,
	})
}

const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

func generateResetCode(nb int) string {
	b := make([]byte, nb)
	_, err := rand.Read(b)
	if err != nil {
		return ""
	}

	for i := 0; i < len(b); i++ {
		b[i] = charset[b[i]%byte(len(charset))]
	}

	return string(b)
}

type ForgotPasswordRequest struct {
	Email string `json:"email"`
}

func EmailForgotPassword(c echo.Context) error {
	req := new(ForgotPasswordRequest)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"message": "Invalid request"})
	}

	email := req.Email

	if email == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"message": "Invalid email"})
	}

	db := database.GetDB()

	var user models.User
	if err := db.Where("email = ?", email).First(&user).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return c.JSON(http.StatusOK, map[string]string{"message": "Ok"})
		}
		return c.JSON(http.StatusInternalServerError, map[string]string{"message": err.Error()})
	}

	resetCode := generateResetCode(10)
	user.ResetCode = resetCode
	user.ResetCodeExpiration = time.Now().Add(time.Minute * 15)

	if err := db.Model(&user).Updates(user).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"message": err.Error()})
	}

	client := resend.NewClient(config.ResendApiKey)

	params := &resend.SendEmailRequest{
		From: config.ContactEmail,
		To:   []string{email},
		Html: `<!DOCTYPE html>
<html lang="fr">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Réinitialisation de mot de passe</title>
    <style>
      body {
        font-family: Arial, sans-serif;
        background-color: #f4f4f4;
        margin: 0;
        padding: 0;
      }
      .email-container {
        max-width: 600px;
        margin: 0 auto;
        background-color: #ffffff;
        padding: 20px;
        border-radius: 8px;
        box-shadow: 0 0 10px rgba(0, 0, 0, 0.1);
      }
      h1 {
        text-align: center;
      }
      h2 {
        color: #333333;
      }
      p {
        font-size: 16px;
        color: #555555;
        line-height: 1.5;
      }
    </style>
  </head>
  <body>
    <h1>Weezemaster</h1>
    <div class="email-container">
      <h2>Réinitialisation de mot de passe</h2>
      <p>Bonjour,</p>
      <p>Vous pouvez réinitialiser votre mot de passe à l'aide du code suivant : <strong>` + resetCode + `</strong>. </p>
	  <p>Ce code est valable pendant 15 minutes.</p>
      <p>À bientôt sur <strong>Weezemaster</strong>. </p>
      <p>Si vous n'avez pas demandé cette réinitialisation, veuillez ignorer cet email.</p>
    </div>
  </body>
</html>`,
		Subject: "Weezemaster - Mot de passe oublié",
	}

	_, err := client.Emails.Send(params)
	if err != nil {
		fmt.Println(err.Error())
	}

	return c.JSON(http.StatusOK, map[string]string{"message": "Ok"})
}

func ResetPassword(c echo.Context) error {
	var requestBody map[string]string
	if err := c.Bind(&requestBody); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"message": "Invalid request"})
	}

	resetCode := requestBody["reset_code"]
	newPassword := requestBody["new_password"]

	if resetCode == "" || newPassword == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"message": "Invalid request"})
	}

	db := database.GetDB()

	var user models.User
	if err := db.Where("reset_code = ?", resetCode).First(&user).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return c.JSON(http.StatusNotFound, map[string]string{"message": "User not found"})
		}
		return c.JSON(http.StatusInternalServerError, map[string]string{"message": err.Error()})
	}

	// if user.ResetCode != resetCode {
	// 	return c.JSON(http.StatusUnauthorized, map[string]string{"message": "Invalid reset code"})
	// }

	if user.ResetCodeExpiration.Before(time.Now()) {
		return c.JSON(http.StatusUnauthorized, map[string]string{"message": "Reset code expired"})
	}

	hashedPassword, err := HashPassword(newPassword)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"message": err.Error()})
	}

	user.Password = hashedPassword
	user.ResetCode = ""
	user.ResetCodeExpiration = time.Time{}

	if err := db.Model(&user).Select("Password", "ResetCode", "ResetCodeExpiration").Updates(user).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"message": "Error updating user"})
	}

	return c.JSON(http.StatusOK, map[string]string{"message": "Password updated successfully"})
}
