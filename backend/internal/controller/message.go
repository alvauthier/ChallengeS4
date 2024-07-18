package controller

import (
	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"net/http"
	"weezemaster/internal/database"
	"weezemaster/internal/models"
)

// PostMessage @Summary		Créer un message
// @Description	Créer un message
// @ID				post-message
// @Tags			Messages
// @Produce		json
// @Param			message	body		models.Message	true	"Message"
// @Success		201	{object}	models.Message
// @Router			/messages [post]
// PostMessage @Summary		Créer un message
// @Description	Créer un message
// @ID				post-message
// @Tags			Messages
// @Produce		json
// @Param			message	body		models.Message	true	"Message"
// @Success		201	{object}	models.Message
// @Router			/messages [post]
func PostMessage(c echo.Context) error {
	db := database.GetDB()
	var newMessage models.Message

	var input struct {
		Content        string `json:"content"`
		ConversationId string `json:"conversation_id"`
	}

	if err := c.Bind(&input); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Failed to bind input: "+err.Error())
	}

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

	newMessage.ID = uuid.New()
	newMessage.AuthorId = user.ID
	newMessage.Content = input.Content

	conversationId, err := uuid.Parse(input.ConversationId)
	if err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, "Invalid conversation ID: "+err.Error())
	}

	newMessage.ConversationId = conversationId

	if err := db.Create(&newMessage).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	return c.JSON(http.StatusCreated, newMessage)
}
