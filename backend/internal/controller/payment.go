package controller

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"weezemaster/internal/config"

	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"github.com/labstack/echo/v4"

	"gorm.io/gorm"
)

type CreatePaymentIntentRequest struct {
	ConcertCategoryId string `json:"concertCategoryId"`
}

func GetAmountByConcertCategoryId(concertCategoryId string) (int64, error) {
	if concertCategoryId == "" {
		return 0, errors.New("UUID cannot be empty")
	}

	db := database.GetDB()
	var concertCategory models.ConcertCategory
	if err := db.Where("id = ?", concertCategoryId).First(&concertCategory).Error; err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return 0, errors.New("no ConcertCategory found with the given UUID")
		}
		return 0, err
	}
	amount := int64(concertCategory.Price * 100)
	return amount, nil
}

func CreatePaymentIntent(c echo.Context) error {
	req := new(CreatePaymentIntentRequest)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid request"})
	}

	amount, _ := GetAmountByConcertCategoryId(req.ConcertCategoryId)

	urlStr := "https://api.stripe.com/v1/payment_intents"

	data := url.Values{}
	data.Set("amount", strconv.FormatInt(amount, 10))
	data.Set("currency", "eur")
	data.Set("payment_method_types[]", "card")

	request, err := http.NewRequestWithContext(c.Request().Context(), "POST", urlStr, strings.NewReader(data.Encode()))
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}

	request.Header.Set("Authorization", "Bearer "+config.StripeSecretKey)
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	client := &http.Client{}
	response, err := client.Do(request)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}
	defer response.Body.Close()

	body, err := io.ReadAll(response.Body)
	if err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}

	return c.JSON(http.StatusOK, json.RawMessage(body))
}
