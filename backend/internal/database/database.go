package database

import (
	"fmt"
	"log"
	"os"
	_ "weezemaster/internal/config"
	"weezemaster/internal/models"

	"github.com/joho/godotenv"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

var db *gorm.DB

func InitDB() {
	wd, _ := os.Getwd()
	log.Printf("Current working directory: %s", wd)
	err := godotenv.Load("../../.env")
	if err != nil {
		log.Fatalf("Error loading .env file: %v", err)
	}
	host := os.Getenv("POSTGRES_HOST")
	port := os.Getenv("POSTGRES_PORT")
	user := os.Getenv("POSTGRES_USER")
	dbname := os.Getenv("POSTGRES_DB")
	password := os.Getenv("POSTGRES_PASSWORD")

	dsn := fmt.Sprintf("host=%s user=%s password=%s dbname=%s port=%s sslmode=disable TimeZone=Europe/Paris", host, user, password, dbname, port)

	db, err = gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("Error connecting to the database: %v", err)
	}
}

func GetDB() *gorm.DB {
	return db
}

func Migrate() {
	err := db.AutoMigrate(
		&models.ConcertCategory{},
		&models.User{},
		&models.Organization{},
		&models.Concert{},
		&models.Category{},
		&models.Interest{},
		&models.Ticket{},
		&models.TicketListing{},
		&models.Sale{},
		&models.Conversation{},
		&models.Message{},
	)
	if err != nil {
		log.Fatalf("Error migrating database schema: %v", err)
	}
}
