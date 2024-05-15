package fixtures

import (
	"log"
	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"github.com/google/uuid"
)

func LoadUserFixtures() {
	db := database.GetDB()

	users := []models.User{
		{
			ID:        uuid.New(),
			Email:     "user@user.fr",
			Password:  "test",
			Firstname: "John",
			Lastname:  "Doe",
			Role:      "user",
		},
		{
			ID:        uuid.New(),
			Email:     "admin@user.fr",
			Password:  "test",
			Firstname: "Steve",
			Lastname:  "Jobs",
			Role:      "admin",
		},
	}

	for _, user := range users {
		result := db.Omit("organization_id", "last_connexion").Create(&user)
		if result.Error != nil {
			log.Println("Error creating user:", result.Error)
			return
		}
	}
}
