package fixtures

import (
	"log"
	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"github.com/google/uuid"
)

func LoadOrganizationFixtures() {
	db := database.GetDB()

	organizations := []models.Organization{
		{
			ID:          uuid.New(),
			Name:        "Weezevent",
			Description: "Weezevent is a ticketing platform that allows you to create, manage and promote your events and ticketing solutions.",
		},
	}

	for _, organization := range organizations {
		result := db.Create(&organization)
		if result.Error != nil {
			log.Println("Error creating organization:", result.Error)
			return
		}
	}

	user := models.User{
		ID:             uuid.New(),
		Email:          "orga@user.fr",
		Password:       "test",
		Firstname:      "Liam",
		Lastname:       "Neeson",
		Role:           "organizer",
		OrganizationId: organizations[0].ID,
	}
	result := db.Omit("last_connexion").Create(&user)
	if result.Error != nil {
		log.Println("Error creating user:", result.Error)
		return
	}
}
