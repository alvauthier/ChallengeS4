package config

import (
	"bufio"
	"log"
	"os"
	"strings"

	"github.com/joho/godotenv"
)

var SecretKey []byte
var StripeSecretKey string
var ResendApiKey string
var ContactEmail string

var Config map[string]string

func LoadConfig(filePath string) error {
	Config = make(map[string]string)

	file, err := os.Open(filePath)
	if err != nil {
		return err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.TrimSpace(line) == "" || strings.HasPrefix(line, "#") {
			continue
		}
		parts := strings.SplitN(line, "=", 2)
		if len(parts) != 2 {
			continue
		}
		key := strings.TrimSpace(parts[0])
		value := strings.TrimSpace(parts[1])
		Config[key] = value
	}

	return scanner.Err()
}

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
