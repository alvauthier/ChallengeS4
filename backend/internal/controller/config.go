package controller

import (
	"fmt"
	"net/http"
	"os"
	"strings"
	"weezemaster/internal/config"

	"github.com/labstack/echo/v4"
)

func GetConfigValue(c echo.Context) error {
	key := c.Param("key")
	if key != "CONCERTS_MAX_USERS_BEFORE_QUEUE" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid configuration key"})
	}

	err := config.LoadConfig("../../cmd/weezemaster/config/weezemaster.config")
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to load configuration"})
	}

	value, exists := config.Config[key]
	if !exists {
		return c.JSON(http.StatusNotFound, map[string]string{"error": "Configuration key not found"})
	}

	return c.JSON(http.StatusOK, map[string]string{"value": value})
}

func UpdateConfigValue(c echo.Context) error {
	key := c.Param("key")
	if key != "CONCERTS_MAX_USERS_BEFORE_QUEUE" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid configuration key"})
	}

	var requestBody map[string]string
	if err := c.Bind(&requestBody); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"message": "Invalid request"})
	}

	value, exists := requestBody["value"]
	if !exists || value == "" {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Value is required"})
	}

	err := config.LoadConfig("../../cmd/weezemaster/config/weezemaster.config")
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to load configuration"})
	}

	config.Config[key] = value

	err = writeConfigToFile("../../cmd/weezemaster/config/weezemaster.config", config.Config)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to write configuration to file"})
	}

	return c.JSON(http.StatusOK, map[string]string{"message": "Configuration updated successfully"})
}

func writeConfigToFile(filePath string, config map[string]string) error {
	var sb strings.Builder
	for key, value := range config {
		sb.WriteString(fmt.Sprintf("%s=%s\n", key, value))
	}

	return os.WriteFile(filePath, []byte(sb.String()), 0644)
}
