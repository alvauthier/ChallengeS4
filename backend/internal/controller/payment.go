package controller

import (
	"encoding/json"
	"io"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"weezemaster/internal/config"

	"github.com/labstack/echo/v4"
)

type CreatePaymentIntentRequest struct {
	Amount int64 `json:"amount"`
}

func CreatePaymentIntent(c echo.Context) error {
	req := new(CreatePaymentIntentRequest)
	if err := c.Bind(req); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "invalid request"})
	}

	urlStr := "https://api.stripe.com/v1/payment_intents"

	data := url.Values{}
	data.Set("amount", strconv.FormatInt(req.Amount, 10))
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
