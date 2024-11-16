package controller

import (
	"encoding/json"
	"fmt"
	"net/http"
	"sync"

	"github.com/gorilla/websocket"
	"github.com/labstack/echo/v4"
)

var upgraderCommunity = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

var artistRooms = make(map[string][]*websocket.Conn) // Map des rooms avec les connexions des utilisateurs
var artistMutex = sync.Mutex{}                       // Mutex pour protéger l'accès concurrent à la map

// CommunityMessagePayload définit la structure des messages échangés via WebSocket
type CommunityMessagePayload struct {
	ArtistID string `json:"artist_id,omitempty"`
	Sender   string `json:"sender,omitempty"`
	Content  string `json:"content,omitempty"`
}

// HandleWebSocketCommunity gère les connexions WebSocket pour les rooms d'artistes
func HandleWebSocketCommunity(c echo.Context) error {
	conn, err := upgraderCommunity.Upgrade(c.Response(), c.Request(), nil)
	if err != nil {
		return err
	}
	defer conn.Close()

	artistID := c.QueryParam("artistId")
	if artistID == "" {
		return echo.NewHTTPError(http.StatusBadRequest, "ArtistID requis")
	}

	// Ajouter la connexion à la room de l'artiste
	artistMutex.Lock()
	artistRooms[artistID] = append(artistRooms[artistID], conn)
	artistMutex.Unlock()

	for {
		// Lire les messages suivants
		_, message, err := conn.ReadMessage()
		if err != nil {
			// Supprimer la connexion si elle est fermée
			removeArtistConnection(artistID, conn)
			break
		}

		var msgPayload CommunityMessagePayload
		if err := json.Unmarshal(message, &msgPayload); err != nil {
			fmt.Println("Erreur de parsing du message: ", err)
			continue
		}

		// Diffuser le message aux autres connexions dans la même room
		broadcastArtistMessage(artistID, message)
	}

	return nil
}

// Diffuse le message à toutes les connexions de la room
func broadcastArtistMessage(artistID string, message []byte) {
	artistMutex.Lock()
	defer artistMutex.Unlock()

	conns := artistRooms[artistID]
	for _, conn := range conns {
		if err := conn.WriteMessage(websocket.TextMessage, message); err != nil {
			fmt.Println("Erreur lors de l'écriture du message: ", err)
		}
	}
}

// Supprime une connexion de la room
func removeArtistConnection(artistID string, conn *websocket.Conn) {
	artistMutex.Lock()
	defer artistMutex.Unlock()

	conns := artistRooms[artistID]
	for i, c := range conns {
		if c == conn {
			artistRooms[artistID] = append(conns[:i], conns[i+1:]...)
			break
		}
	}
}
