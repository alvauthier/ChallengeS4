package fixtures

import (
	"log"
	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"time"

	"github.com/google/uuid"
)

func LoadTicketFixtures() {
	db := database.GetDB()

	userEmail := "user@user.fr"
	var user models.User
	db.Where("email = ?", userEmail).First(&user)

	if user.ID == uuid.Nil {
		log.Println("User not found")
		return
	}

	concertName := "Eras Tour"
	categoryName := "Catégorie 4"
	var concertCategory models.ConcertCategory
	db.Joins("JOIN concerts ON concert_categories.concert_id = concerts.id").
		Joins("JOIN categories ON concert_categories.category_id = categories.id").
		Where("concerts.name = ? AND categories.name = ?", concertName, categoryName).
		First(&concertCategory)

	if concertCategory.ID == uuid.Nil {
		log.Println("Concert category not found")
		return
	}

	ticket := models.Ticket{
		ID:                uuid.New(),
		CreatedAt:         time.Now(),
		UpdatedAt:         time.Now(),
		UserId:            user.ID,
		ConcertCategoryId: concertCategory.ID,
	}

	result := db.Create(&ticket)
	if result.Error != nil {
		log.Println("Error creating ticket:", result.Error)
	}
}
