package controller

import (
	"bufio"
	"encoding/json"
	"net/http"
	"os"
	"strings"

	"github.com/labstack/echo/v4"
)

type LogEntry struct {
	Time         string `json:"time"`
	Level        string `json:"level,omitempty"`
	Prefix       string `json:"prefix,omitempty"`
	Message      string `json:"message,omitempty"`
	UserID       string `json:"user_id,omitempty"`
	Event        string `json:"event,omitempty"`
	ID           string `json:"id,omitempty"`
	RemoteIP     string `json:"remote_ip,omitempty"`
	Host         string `json:"host,omitempty"`
	Method       string `json:"method,omitempty"`
	URI          string `json:"uri,omitempty"`
	UserAgent    string `json:"user_agent,omitempty"`
	Status       int    `json:"status,omitempty"`
	Error        string `json:"error,omitempty"`
	Latency      int    `json:"latency,omitempty"`
	LatencyHuman string `json:"latency_human,omitempty"`
	BytesIn      int    `json:"bytes_in,omitempty"`
	BytesOut     int    `json:"bytes_out,omitempty"`
}

func GetLogs(c echo.Context) error {
	logFile, err := os.Open("../../cmd/weezemaster/temp/weezemaster.log")
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Impossible de lire le fichier de logs"})
	}
	defer logFile.Close()

	var logs []LogEntry
	scanner := bufio.NewScanner(logFile)

	eventType := c.QueryParam("event")

	for scanner.Scan() {
		line := scanner.Text()
		var entry LogEntry

		// Vérifier si la ligne est un log JSON structuré
		if err := json.Unmarshal([]byte(line), &entry); err == nil {
			entry.Error = extractErrorMessage(entry.Error)

			if eventType != "" && !strings.Contains(entry.Message, eventType) {
				continue
			}
			logs = append(logs, entry)
			continue
		}
	}

	return c.JSON(http.StatusOK, logs)
}

func extractErrorMessage(errorValue string) string {
	if strings.Contains(errorValue, "message=") {
		parts := strings.SplitN(errorValue, "message=", 2)
		return strings.Trim(parts[1], `" `)
	}
	return errorValue
}
