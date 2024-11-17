package controller

import (
	"encoding/json"
	"fmt"
	"net/http"
	"sync"
	"time"
	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

var rooms = make(map[string][]*websocket.Conn) // Map des rooms avec les connexions des utilisateurs
var mutex = sync.Mutex{}                       // Mutex pour protéger l'accès concurrent à la map

// MessagePayload définit la structure des messages échangés via WebSocket
type MessagePayload struct {
	ConversationID string `json:"conversation_id,omitempty"`
	SenderID       string `json:"sender_id,omitempty"`
	ReceiverID     string `json:"receiver_id,omitempty"`
	Content        string `json:"content,omitempty"`
}

type PriceUpdatePayload struct {
	ConversationID string  `json:"conversation_id,omitempty"`
	NewPrice       float64 `json:"new_price,omitempty"`
}

// HandleWebSocket gère les connexions WebSocket pour toutes les conversations
// @Summary Gérer les connexions WebSocket pour le chat
// @Description Gère les connexions WebSocket pour le chat entre les utilisateurs
// @ID handle-websocket-chat
// @Tags WebSockets
// @Accept json
// @Success 101 {string} string "Switching Protocols"
// @Router /ws-chat [get]
func HandleWebSocketChat(c echo.Context) error {
	conn, err := upgrader.Upgrade(c.Response(), c.Request(), nil)
	if err != nil {
		return err
	}
	defer conn.Close()
	var conversationID string
	var authorID uuid.UUID
	// Lire le premier message pour initialiser la conversation
	_, message, err := conn.ReadMessage()
	if err != nil {
		fmt.Println("Erreur lors de la lecture du premier message: ", err)
		return err
	}
	fmt.Println("Premier message reçu: ", string(message))
	var payload MessagePayload
	if err := json.Unmarshal(message, &payload); err != nil {
		fmt.Println("Erreur de parsing du message initial: ", err)
		return err
	}
	fmt.Println("Payload initial: ", payload)
	// Vérifier si une conversation existe déjà
	if payload.ConversationID != "" {
		conversationUUID, err := uuid.Parse(payload.ConversationID)
		if err != nil {
			fmt.Println("Format de conversation ID invalide: ", err)
			return err
		}
		var conversation models.Conversation
		err = database.GetDB().Where("id = ?", conversationUUID).First(&conversation).Error
		if err != nil {
			if err == gorm.ErrRecordNotFound {
				// La conversation n'existe pas, créer une nouvelle conversation
				conversationID = createNewConversation(payload.SenderID, payload.ReceiverID)
			} else {
				fmt.Println("Erreur lors de la récupération de la conversation: ", err)
				return err
			}
		} else {
			conversationID = conversation.ID.String()
		}
	} else {
		// Si conversationID n'est pas fourni, créer une nouvelle conversation
		conversationID = createNewConversation(payload.SenderID, payload.ReceiverID)
	}
	// Assigner l'authorID
	authorID, err = uuid.Parse(payload.SenderID)
	if err != nil {
		fmt.Println("Format de sender ID invalide: ", err)
		return err
	}
	// Ajouter la connexion à la room de la conversation
	mutex.Lock()
	rooms[conversationID] = append(rooms[conversationID], conn)
	mutex.Unlock()
	fmt.Println("Connexion ajoutée à la room: ", conversationID)
	// Informer le client de l'ID de la conversation (si une nouvelle conversation a été créée)
	responsePayload := MessagePayload{
		ConversationID: conversationID,
	}
	if payload.ConversationID == "" {
		responsePayload.SenderID = payload.SenderID
		responsePayload.ReceiverID = payload.ReceiverID
	}
	responseMessage, _ := json.Marshal(responsePayload)
	conn.WriteMessage(websocket.TextMessage, responseMessage)
	fmt.Println("Message de réponse envoyé: ", string(responseMessage))
	for {
		// Lire les messages suivants
		_, message, err := conn.ReadMessage()
		if err != nil {
			// Supprimer la connexion si elle est fermée
			removeConnection(conversationID, conn)
			break
		}
		fmt.Println("Message reçu: ", string(message))
		var msgPayload MessagePayload
		if err := json.Unmarshal(message, &msgPayload); err != nil {
			fmt.Println("Erreur de parsing du message: ", err)
			continue
		}
		fmt.Println("Payload du message: ", msgPayload)

		// Vérifier si le message est une mise à jour de prix
		if msgPayload.Content == "" {
			var priceUpdatePayload PriceUpdatePayload
			if err := json.Unmarshal(message, &priceUpdatePayload); err != nil {
				fmt.Println("Erreur de parsing du message de mise à jour de prix: ", err)
				continue
			}
			fmt.Println("Mise à jour de prix reçue: ", priceUpdatePayload)
			// Diffuser la mise à jour du prix aux autres connexions dans la même room
			broadcastMessage(conversationID, message)
			continue
		}

		// Sauvegarder le message dans la base de données
		if err := saveMessageToDatabase(conversationID, msgPayload.Content, authorID); err != nil {
			// Gérer l'erreur de sauvegarde
			fmt.Println("Erreur lors de la sauvegarde du message: ", err)
			continue
		}

		// Diffuser le message aux autres connexions dans la même room
		broadcastMessage(conversationID, message)
	}
	return nil
}

// Fonction pour créer une nouvelle conversation
func createNewConversation(senderID string, receiverID string) string {
	db := database.GetDB()
	senderUUID, err := uuid.Parse(senderID)
	if err != nil {
		fmt.Println("Format de sender ID invalide: ", err)
		return ""
	}
	receiverUUID, err := uuid.Parse(receiverID)
	if err != nil {
		fmt.Println("Format de receiver ID invalide: ", err)
		return ""
	}
	newConversation := models.Conversation{
		ID:        uuid.New(),
		BuyerId:   senderUUID,   // Selon la logique de votre application
		SellerId:  receiverUUID, // Selon la logique de votre application
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}
	if err := db.Create(&newConversation).Error; err != nil {
		fmt.Println("Erreur lors de la création de la conversation: ", err)
		return ""
	}
	fmt.Println("Nouvelle conversation créée: ", newConversation.ID.String())
	return newConversation.ID.String()
}

// Diffuse le message à toutes les connexions de la room
func broadcastMessage(conversationID string, message []byte) {
	mutex.Lock()
	defer mutex.Unlock()
	conns := rooms[conversationID]
	for _, conn := range conns {
		if err := conn.WriteMessage(websocket.TextMessage, message); err != nil {
			fmt.Println("Erreur lors de l'écriture du message: ", err)
		}
	}
	fmt.Println("Message diffusé dans la room: ", conversationID)
}

// Supprime une connexion de la room
func removeConnection(conversationID string, conn *websocket.Conn) {
	mutex.Lock()
	defer mutex.Unlock()
	conns := rooms[conversationID]
	for i, c := range conns {
		if c == conn {
			rooms[conversationID] = append(conns[:i], conns[i+1:]...)
			break
		}
	}
	fmt.Println("Connexion supprimée de la room: ", conversationID)
}

// Sauvegarder le message dans la base de données
func saveMessageToDatabase(conversationID string, message string, authorID uuid.UUID) error {
	db := database.GetDB()
	conversationUUID, err := uuid.Parse(conversationID)
	if err != nil {
		return err
	}
	var conversation models.Conversation
	err = db.Where("id = ?", conversationUUID).First(&conversation).Error
	if err != nil {
		if err == gorm.ErrRecordNotFound {
			// La conversation n'existe pas, ne pas la créer ici
			return gorm.ErrRecordNotFound
		} else {
			return err
		}
	}
	// Créer un nouveau message
	newMessage := models.Message{
		ID:             uuid.New(),
		ConversationId: conversation.ID,
		Content:        message,
		Readed:         false,      // Indiquer que le message n'a pas été lu au départ
		AuthorId:       authorID,   // ID de l'auteur
		SentAt:         time.Now(), // Heure d'envoi du message
		CreatedAt:      time.Now(), // Heure de création
		UpdatedAt:      time.Now(), // Heure de mise à jour
	}
	// Sauvegarder le message dans la base
	if err := db.Create(&newMessage).Error; err != nil {
		return err
	}
	fmt.Println("Message sauvegardé dans la base de données: ", newMessage.ID.String())
	return nil
}
