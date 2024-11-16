package fixtures

import (
	"log"
	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"github.com/google/uuid"
)

func LoadArtistFixtures() {
	db := database.GetDB()

	interestName := "Taylor Swift"

	var interest models.Interest
	db.Where("name = ?", interestName).First(&interest)
	if interest.ID == 0 {
		log.Println("Interest not found")
		return
	}

	artists := []models.Artist{
		{
			ID:         uuid.New(),
			Name:       "Taylor Swift",
			Interest:   &interest,
			InterestId: interest.ID,
		},
	}

	for _, artist := range artists {
		result := db.Create(&artist)
		if result.Error != nil {
			log.Println("Error creating artist:", result.Error)
			return
		}
	}
}
