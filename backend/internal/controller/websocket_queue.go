package controller

import (
	"encoding/json"
	"fmt"
	"net/http"
	"sync"
	"time"

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

// Intervalle pour les pings en secondes
const pingInterval = 30 * time.Second

// HandleWebSocketQueue gère les connexions WebSocket pour la file d'attente des concerts
func HandleWebSocketQueue(c echo.Context) error {
	concertID := c.QueryParam("concertId")
	userID := c.QueryParam("userId")

	if concertID == "" || userID == "" {
		return echo.NewHTTPError(http.StatusBadRequest, "ConcertID et UserID requis")
	}

	conn, err := upgraderQueue.Upgrade(c.Response(), c.Request(), nil)
	if err != nil {
		return err
	}
	defer conn.Close()

	// Routine pour envoyer des pings périodiquement pour garder la connexion active
	ticker := time.NewTicker(pingInterval)
	defer ticker.Stop()
	go func() {
		for range ticker.C {
			if err := conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				fmt.Println("Erreur lors de l'envoi du ping :", err)
				break
			}
		}
	}()

	// Gérer l’entrée de l’utilisateur dans la file d’attente
	if err := handleQueue(userID, concertID, conn); err != nil {
		return err
	}

	// Écouter les messages WebSocket
	for {
		_, _, err := conn.ReadMessage()
		if err != nil {
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

	// Si l'utilisateur est déjà dans la salle, on lui envoie l'accès sans le retirer
	for _, id := range queue[concertID] {
		if id == userID {
			message := Message{Status: "access_granted"}
			messageBytes, _ := json.Marshal(message)
			return conn.WriteMessage(websocket.TextMessage, messageBytes)
		}
	}

	// Calcul du nombre d'utilisateurs déjà en salle
	currentInConcert := 0
	if len(queue[concertID]) >= maxUsers {
		currentInConcert = maxUsers
	} else {
		currentInConcert = len(queue[concertID])
	}

	// Si la limite est atteinte, ajouter l'utilisateur en file d'attente
	if len(queue[concertID]) >= maxUsers {
		queue[concertID] = append(queue[concertID], userID)
		position := len(queue[concertID]) - currentInConcert

		message := Message{
			Status:   "in_queue",
			Position: position,
		}
		messageBytes, _ := json.Marshal(message)
		fmt.Printf("User %s ajouté à la file d'attente pour le concert %s à la position %d\n", userID, concertID, position)

		return conn.WriteMessage(websocket.TextMessage, messageBytes)
	}

	// Ajouter l'utilisateur et lui accorder l'accès sans fermer sa connexion WebSocket
	queue[concertID] = append(queue[concertID], userID)
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
