package config

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)

var SecretKey []byte
var StripeSecretKey string

func init() {
	err := godotenv.Load("../../.env")
	if err != nil {
		log.Fatalf("Error loading .env file")
	}

	SecretKey = []byte(os.Getenv("SECRET_KEY"))
	if len(SecretKey) == 0 {
		log.Fatalf("Secret key is not set or empty")
	}
	StripeSecretKey = os.Getenv("STRIPE_SECRET_KEY")
	if StripeSecretKey == "" {
		log.Fatalf("Stripe secret key is not set or empty")
	}
}
