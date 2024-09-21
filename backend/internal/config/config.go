package config

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)

var SecretKey []byte
var StripeSecretKey string
var ResendApiKey string
var ContactEmail string

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
	ResendApiKey = os.Getenv("RESEND_API_KEY")
	if ResendApiKey == "" {
		log.Fatalf("Resend API key is not set or empty")
	}
	ContactEmail = os.Getenv("CONTACT_EMAIL")
	if ContactEmail == "" {
		log.Fatalf("Contact email from your domain is not set or empty")
	}
}
