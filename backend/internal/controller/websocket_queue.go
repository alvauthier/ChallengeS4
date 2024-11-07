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

var queue = make(map[string][]*UserConnection)
var authorized = make(map[string][]*UserConnection)
var queueMutex = sync.Mutex{}
var maxUsers = 2 // Maximum d'utilisateurs autorisés par concert

type UserConnection struct {
	UserID string
	Conn   *websocket.Conn
}

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

	// Vérifie si l'utilisateur est déjà dans la liste des utilisateurs autorisés
	for _, uc := range authorized[concertID] {
		if uc.UserID == userID {
			message := Message{Status: "access_granted"}
			messageBytes, _ := json.Marshal(message)
			return conn.WriteMessage(websocket.TextMessage, messageBytes)
		}
	}

	// Calcul du nombre d'utilisateurs déjà autorisés
	currentInConcert := len(authorized[concertID])

	// Si la limite est atteinte, ajoute l'utilisateur en file d'attente
	if currentInConcert >= maxUsers {
		queue[concertID] = append(queue[concertID], &UserConnection{UserID: userID, Conn: conn})
		position := len(queue[concertID])

		message := Message{
			Status:   "in_queue",
			Position: position,
		}
		messageBytes, _ := json.Marshal(message)
		fmt.Printf("User %s ajouté à la file d'attente pour le concert %s à la position %d\n", userID, concertID, position)

		return conn.WriteMessage(websocket.TextMessage, messageBytes)
	}

	// Ajouter l'utilisateur aux utilisateurs autorisés
	authorized[concertID] = append(authorized[concertID], &UserConnection{UserID: userID, Conn: conn})
	message := Message{Status: "access_granted"}
	messageBytes, _ := json.Marshal(message)
	fmt.Printf("User %s accepté dans la salle pour le concert %s\n", userID, concertID)

	return conn.WriteMessage(websocket.TextMessage, messageBytes)
}

// removeUserFromQueue retire un utilisateur spécifique de la file d'attente lorsque sa connexion est fermée
// removeUserFromQueue retire un utilisateur spécifique de la file d'attente
func removeUserFromQueue(concertID, userID string) {
	queueMutex.Lock()
	defer queueMutex.Unlock()

	// Vérifie d'abord si l'utilisateur est dans la liste des utilisateurs autorisés
	if authorizedUsers, ok := authorized[concertID]; ok {
		for i, uc := range authorizedUsers {
			if uc.UserID == userID {
				// Retire l'utilisateur des utilisateurs autorisés
				authorized[concertID] = append(authorizedUsers[:i], authorizedUsers[i+1:]...)
				fmt.Printf("User %s a quitté la page concert pour le concert %s\n", userID, concertID)
				break
			}
		}
	}

	// Si la liste des utilisateurs autorisés est en dessous de la limite, on promeut le prochain en file d'attente
	if len(authorized[concertID]) < maxUsers {
		if queueUsers, ok := queue[concertID]; ok && len(queueUsers) > 0 {
			// Sélectionne le premier utilisateur en attente dans la file (index 0)
			nextUser := queueUsers[0]
			queue[concertID] = queueUsers[1:] // Retire l'utilisateur promu de la file

			// Ajoute l'utilisateur promu aux utilisateurs autorisés
			authorized[concertID] = append(authorized[concertID], nextUser)

			// Envoie une notification de type "access_granted" au nouvel utilisateur autorisé
			message := Message{Status: "access_granted"}
			messageBytes, _ := json.Marshal(message)
			if err := nextUser.Conn.WriteMessage(websocket.TextMessage, messageBytes); err != nil {
				fmt.Printf("Erreur d'écriture WebSocket : %v\n", err)
			}
			fmt.Printf("User %s promu pour entrer dans le concert %s\n", nextUser.UserID, concertID)
		}
	}

	// Gestion du décalage dans la file d'attente si un utilisateur en file d'attente quitte
	if queueUsers, ok := queue[concertID]; ok {
		for i, user := range queueUsers {
			if user.UserID == userID {
				// Retirer l'utilisateur de la file d'attente
				queue[concertID] = append(queueUsers[:i], queueUsers[i+1:]...)
				fmt.Printf("User %s a quitté la file d'attente pour le concert %s\n", userID, concertID)
				break
			}
		}

		// Mise à jour de la position de chaque utilisateur restant dans la file d'attente
		for index, user := range queue[concertID] {
			updatedMessage := Message{Status: "in_queue", Position: index + 1}
			updatedMessageBytes, _ := json.Marshal(updatedMessage)
			if err := user.Conn.WriteMessage(websocket.TextMessage, updatedMessageBytes); err != nil {
				fmt.Printf("Erreur lors de la mise à jour de la position pour l'utilisateur %s : %v\n", user.UserID, err)
			}
		}
	}
}
