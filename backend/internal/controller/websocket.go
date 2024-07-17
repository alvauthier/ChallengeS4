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

// Global variables to hold clients and broadcast channel
var clients = make(map[*websocket.Conn]bool) // connected clients
var broadcast = make(chan models.Message)    // broadcast channel

func handleMessages() {
	for {
		// grab the next message from the broadcast channel
		message := <-broadcast
		// send it out to every client that is currently connected
		for client := range clients {
			err := client.WriteJSON(message)
			if err != nil {
				fmt.Printf("Error sending message to client: %v\n", err)
				client.Close()
				delete(clients, client)
			} else {
				fmt.Printf("Message sent to client: %v\n", message)
			}
		}
	}
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
	fmt.Printf("Message saved to database: %v\n", message)
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
	defer conn.Close()
	clients[conn] = true
	fmt.Println("New client connected")

	for {
		_, p, err := conn.ReadMessage()
		if err != nil {
			fmt.Println("Error reading message:", err)
			delete(clients, conn)
			break
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

		// Send the newly received message to the broadcast channel
		broadcast <- message
		fmt.Printf("Broadcasting message: %v\n", message)
	}
}

func Init() {
	go handleMessages()
}
