package controller

import (
	"bufio"
	"encoding/json"
	"net/http"
	"os"
	"sort"
	"strings"
	"time"

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

// @Summary		Récupérer les logs
// @Description	Récupérer les logs
// @ID				get-logs
// @Tags			Logs
// @Produce		json
// @Param			date	query	string	false	"Date des logs (format: 2006-01-02)"
// @Param			event	query	string	false	"Type d'événement à filtrer"
// @Success		200	{array}	LogEntry
// @Failure		400	"default"
// @Failure		500	"default"
// @Router			/logs [get]
// @Security		Bearer
func GetLogs(c echo.Context) error {
	dateParam := c.QueryParam("date")
	eventType := c.QueryParam("event")

	var date time.Time
	var err error
	if dateParam != "" {
		date, err = time.Parse("2006-01-02", dateParam)
		if err != nil {
			return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid date format"})
		}
	}

	logFile, err := os.Open("../../cmd/weezemaster/temp/weezemaster.log")
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Impossible de lire le fichier de logs"})
	}
	defer logFile.Close()

	var logs []LogEntry
	scanner := bufio.NewScanner(logFile)

	for scanner.Scan() {
		line := scanner.Text()
		var entry LogEntry

		// Vérifier si la ligne est un log JSON structuré
		if err := json.Unmarshal([]byte(line), &entry); err == nil {
			entry.Error = extractErrorMessage(entry.Error)

			if !date.IsZero() {
				logTime, err := time.Parse(time.RFC3339, entry.Time)
				if err != nil {
					continue
				}
				if logTime.Year() != date.Year() || logTime.YearDay() != date.YearDay() {
					continue
				}
			}

			if eventType != "" {
				if eventType == "errorEvent" {
					if entry.Error == "" {
						continue
					}
				} else {
					if !strings.Contains(entry.Message, eventType) {
						continue
					}
				}
			}

			logs = append(logs, entry)
		}
	}

	sort.Slice(logs, func(i, j int) bool {
		timeI, errI := time.Parse(time.RFC3339, logs[i].Time)
		timeJ, errJ := time.Parse(time.RFC3339, logs[j].Time)
		if errI != nil || errJ != nil {
			return false
		}
		return timeI.After(timeJ)
	})

	if len(logs) == 0 {
		return c.JSON(http.StatusOK, []LogEntry{})
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
