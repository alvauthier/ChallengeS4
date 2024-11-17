package fixtures

import (
	"log"
	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"github.com/google/uuid"
)

func LoadConcertInterestFixtures() {
	db := database.GetDB()

	concertName := "Eras Tour"

	var concert models.Concert

	db.Where("name = ?", concertName).First(&concert)

	if concert.ID != uuid.Nil {
		var interests []models.Interest
		db.Where("id IN (?)", []int{1, 11}).Find(&interests)

		if len(interests) == 0 {
			log.Println("Interests not found")
			return
		}

		db.Model(&concert).Association("Interests").Append(&interests)
	} else {
		log.Println("Concert not found")
	}
}
