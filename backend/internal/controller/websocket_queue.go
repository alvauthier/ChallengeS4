package controller

import (
	"encoding/json"
	"fmt"
	"net/http"
	"sync"

	"github.com/gorilla/websocket"
	"github.com/labstack/echo/v4"
)

var upgraderQueue = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

var queue = make(map[string][]string) // File d'attente par concert (concertID -> liste d'utilisateurs)
var queueMutex = sync.Mutex{}
var maxUsers = 1 // Maximum d'utilisateurs autorisés par concert

// Message struct pour formater les messages WebSocket en JSON
type Message struct {
	Status   string `json:"status"`
	Position int    `json:"position,omitempty"` // Position optionnelle pour la file d'attente
}

// HandleWebSocketQueue gère les connexions WebSocket pour la file d'attente des concerts
func HandleWebSocketQueue(c echo.Context) error {
	concertID := c.QueryParam("concertId")
	userID := c.QueryParam("userId")

	// Vérification des paramètres requis
	if concertID == "" || userID == "" {
		return echo.NewHTTPError(http.StatusBadRequest, "ConcertID et UserID requis")
	}

	// Établir la connexion WebSocket
	conn, err := upgraderQueue.Upgrade(c.Response(), c.Request(), nil)
	if err != nil {
		return err
	}
	defer conn.Close()

	// Gérer l'entrée de l'utilisateur dans la file d'attente
	if err := handleQueue(userID, concertID, conn); err != nil {
		return err
	}

	// Écouter les messages WebSocket (si nécessaire pour d'autres actions)
	for {
		_, _, err := conn.ReadMessage()
		if err != nil {
			// Si la connexion est fermée, retirer l'utilisateur de la file d'attente
			removeUserFromQueue(concertID, userID)
			break
		}
	}

	return nil
}

// handleQueue ajoute un utilisateur à la file d'attente ou l'accepte dans la salle si possible
func handleQueue(userID, concertID string, conn *websocket.Conn) error {
	queueMutex.Lock()
	defer queueMutex.Unlock()

	// Vérifier le nombre d'utilisateurs déjà présents dans la salle pour ce concert
	if len(queue[concertID]) >= maxUsers {
		// Ajouter l'utilisateur à la file d'attente
		queue[concertID] = append(queue[concertID], userID)
		position := len(queue[concertID])

		// Message JSON indiquant la position en file d'attente
		message := Message{
			Status:   "in_queue",
			Position: position,
		}
		messageBytes, _ := json.Marshal(message)
		fmt.Printf("User %s ajouté à la file d'attente pour le concert %s à la position %d\n", userID, concertID, position)

		return conn.WriteMessage(websocket.TextMessage, messageBytes)
	}

	// Si l'utilisateur peut entrer dans la salle, envoyer un message d'acceptation
	message := Message{Status: "access_granted"}
	messageBytes, _ := json.Marshal(message)
	fmt.Printf("User %s accepté dans la salle pour le concert %s\n", userID, concertID)

	return conn.WriteMessage(websocket.TextMessage, messageBytes)
}

// removeUserFromQueue retire un utilisateur spécifique de la file d'attente lorsque sa connexion est fermée
func removeUserFromQueue(concertID, userID string) {
	queueMutex.Lock()
	defer queueMutex.Unlock()

	if queueUsers, ok := queue[concertID]; ok {
		for i, id := range queueUsers {
			if id == userID {
				queue[concertID] = append(queueUsers[:i], queueUsers[i+1:]...)
				fmt.Printf("User %s retiré de la file d'attente pour le concert %s\n", userID, concertID)
				break
			}
		}
	}
}