package fixtures

import (
	"log"
	"time"
	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"github.com/google/uuid"
)

func LoadConcertFixtures() {
	db := database.GetDB()

	organizationName := "Weezevent"
	artistName := "Taylor Swift"

	var organization models.Organization

	db.Where("name = ?", organizationName).First(&organization)

	if organization.ID == uuid.Nil {
		log.Println("Organization not found")
		return
	}

	var artist models.Artist
	db.Where("name = ?", artistName).First(&artist)
	if artist.ID == uuid.Nil {
		log.Println("Artist not found")
		return
	}

	if organization.ID != uuid.Nil {
		concert := models.Concert{
			ID:             uuid.New(),
			Name:           "Eras Tour - Taylor Swift",
			Description:    "The Eras Tour is the fifth concert tour by American singer-songwriter Taylor Swift, in support of her ninth studio album, Eras.",
			Date:           time.Now().AddDate(0, 1, 0),
			Location:       "Paris La Défense Arena",
			Organization:   &organization,
			OrganizationId: organization.ID,
			Artist:         &artist,
			ArtistId:       artist.ID,
		}
		result := db.Create(&concert)
		if result.Error != nil {
			log.Println("Error creating concert:", result.Error)
			return
		}
	} else {
		log.Println("Organization not found")
	}
}
