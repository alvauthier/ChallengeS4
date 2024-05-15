package fixtures

import (
	"log"
	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"github.com/google/uuid"
)

func LoadUserInterestFixtures() {
	db := database.GetDB()

	userEmail := "user@user.fr"

	var user models.User

	db.Where("email = ?", userEmail).First(&user)

	if user.ID != uuid.Nil {
		var interests []models.Interest
		db.Where("id IN (?)", []int{1, 2, 11}).Find(&interests)

		if len(interests) == 0 {
			log.Println("Interests not found")
			return
		}

		db.Model(&user).Association("Interests").Append(&interests)
	} else {
		log.Println("User not found")
	}
}
