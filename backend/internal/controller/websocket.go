package controller

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"github.com/labstack/echo/v4"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
}

type IncomingMessage struct {
	Content        string `json:"content"`
	AuthorId       string `json:"authorId"`
	ConversationId string `json:"conversationId"`
	Timestamp      string `json:"timestamp"`
}

func GetAllCategoriesForMessage(c echo.Context) error {
	db := database.GetDB()
	var categories []models.Category
	db.Find(&categories)
	return c.JSON(http.StatusOK, categories)
}

func SaveMessage(message models.Message) error {
	db := database.GetDB() // Assume GetDB() returns a *gorm.DB instance

	if err := db.Create(&message).Error; err != nil {
		return fmt.Errorf("could not save message: %v", err)
	}

	return nil
}

func CreateMessage(c echo.Context) error {
	db := database.GetDB()
	message := new(models.Message)
	if err := c.Bind(message); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	}
	db.Create(&message)
	return c.JSON(http.StatusCreated, message)
}

func WebSocketEndpoint(w http.ResponseWriter, r *http.Request) {
	upgrader.CheckOrigin = func(r *http.Request) bool { return true }

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		fmt.Fprintf(w, "%+v\n", err)
		return
	}

	for {
		_, p, err := conn.ReadMessage()
		if err != nil {
			fmt.Println(err)
			return
		}

		var incomingMessage IncomingMessage
		if err := json.Unmarshal(p, &incomingMessage); err != nil {
			fmt.Println("Error parsing message:", err)
			continue
		}

		// Convert incoming message to models.Message
		message := models.Message{
			ID:             uuid.New(),
			Content:        incomingMessage.Content,
			Readed:         false,
			AuthorId:       uuid.MustParse(incomingMessage.AuthorId),
			SentAt:         time.Now(),
			ConversationId: uuid.MustParse(incomingMessage.ConversationId),
			CreatedAt:      time.Now(),
			UpdatedAt:      time.Now(),
		}

		// Save the message to the database using SaveMessage function
		if err := SaveMessage(message); err != nil {
			fmt.Println("Error saving message:", err)
			continue
		}

		// Broadcast message to all connected clients
		if err := conn.WriteMessage(websocket.TextMessage, p); err != nil {
			fmt.Println(err)
			return
		}
	}
}
