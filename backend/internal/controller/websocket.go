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
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
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

	// Vérifier si la conversation existe
	var conversation models.Conversation
	if err := db.First(&conversation, "id = ?", message.ConversationId).Error; err != nil {
		return fmt.Errorf("could not save message: conversation does not exist")
	}

	if err := db.Create(&message).Error; err != nil {
		return fmt.Errorf("could not save message: %v", err)
	}
	fmt.Printf("Message saved to database: %v\n", message)
	return nil
}

func WebSocketEndpoint(c echo.Context) error {
	upgrader.CheckOrigin = func(r *http.Request) bool { return true }

	conn, err := upgrader.Upgrade(c.Response(), c.Request(), nil)
	if err != nil {
		fmt.Fprintf(c.Response(), "%+v\n", err)
		return err
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

		authorId, err := uuid.Parse(incomingMessage.AuthorId)
		if err != nil {
			fmt.Println("Invalid AuthorId UUID:", err)
			continue
		}

		conversationId, err := uuid.Parse(incomingMessage.ConversationId)
		if err != nil {
			fmt.Println("Invalid ConversationId UUID:", err)
			continue
		}

		// Convert incoming message to models.Message
		message := models.Message{
			ID:             uuid.New(),
			Content:        incomingMessage.Content,
			Readed:         false,
			AuthorId:       authorId,
			SentAt:         time.Now(),
			ConversationId: conversationId,
			CreatedAt:      time.Now(),
			UpdatedAt:      time.Now(),
		}

		// Log the message before saving
		fmt.Printf("Saving message: %+v\n", message)

		// Save the message to the database using SaveMessage function
		if err := SaveMessage(message); err != nil {
			fmt.Println("Error saving message:", err)
			continue
		}

		// Send the newly received message to the broadcast channel
		broadcast <- message
		fmt.Printf("Broadcasting message: %v\n", message)
	}

	return nil
}

func Init() {
	go handleMessages()
}
