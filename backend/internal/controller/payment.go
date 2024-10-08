package controller

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"weezemaster/internal/config"

	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"github.com/labstack/echo/v4"
	"github.com/shopspring/decimal"

	"gorm.io/gorm"
)

type CreatePaymentIntentRequest struct {
	ID string `json:"id"`
}

func GetAmountById(id string) (int64, error) {
	if id == "" {
		return 0, errors.New("UUID cannot be empty")
	}
	fmt.Println("ID: ", id)

	parts := strings.SplitN(id, "_", 2)
	if len(parts) != 2 {
		return 0, errors.New("invalid ID format")
	}

	prefix, idStr := parts[0], parts[1]

	db := database.GetDB()

	switch prefix {
	case "cc":
		var concertCategory models.ConcertCategory
		if err := db.Where("id = ?", idStr).First(&concertCategory).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				return 0, errors.New("no ConcertCategory found with the given UUID")
			}
			return 0, err
		}
		priceDecimal := decimal.NewFromFloat(concertCategory.Price)
		amountDecimal := priceDecimal.Mul(decimal.NewFromInt(100))
		amount := amountDecimal.IntPart()
		return amount, nil
	case "tl":
		var ticketListing models.TicketListing
		if err := db.Where("id = ?", idStr).First(&ticketListing).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				return 0, errors.New("no TicketListing found with the given UUID")
			}
			return 0, err
		}
		priceDecimal := decimal.NewFromFloat(ticketListing.Price)
		amountDecimal := priceDecimal.Mul(decimal.NewFromInt(100))
		amount := amountDecimal.IntPart()
		return amount, nil
	case "cv":
		var conversation models.Conversation
		if err := db.Where("id = ?", idStr).First(&conversation).Error; err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				return 0, errors.New("no Conversation found with the given UUID")
			}
			return 0, err
		}
		priceDecimal := decimal.NewFromFloat(conversation.Price)
		amountDecimal := priceDecimal.Mul(decimal.NewFromInt(100))
		amount := amountDecimal.IntPart()
		return amount, nil
	default:
		return 0, errors.New("unknown ID prefix")
	}
}

func CreatePaymentIntent(c echo.Context) error {
	req := new(CreatePaymentIntentRequest)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid request"})
	}

	amount, _ := GetAmountById(req.ID)

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
