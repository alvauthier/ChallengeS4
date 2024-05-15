package fixtures

import (
	"log"
	"weezemaster/internal/database"
	"weezemaster/internal/models"
)

func LoadInterestFixtures() {
	db := database.GetDB()

	interests := []models.Interest{
		{
			Name: "Taylor Swift",
		},
		{
			Name: "Ed Sheeran",
		},
		{
			Name: "Werenoi",
		},
		{
			Name: "Mickeal Jackson",
		},
		{
			Name: "Queen",
		},
		{
			Name: "The Beatles",
		},
		{
			Name: "The Rolling Stones",
		},
		{
			Name: "Elton John",
		},
		{
			Name: "David Bowie",
		},
		{
			Name: "Rock",
		},
		{
			Name: "Pop",
		},
		{
			Name: "Metal",
		},
		{
			Name: "Jazz",
		},
		{
			Name: "Rap",
		},
	}

	for _, interest := range interests {
		result := db.Create(&interest)
		if result.Error != nil {
			log.Println("Error creating interest:", result.Error)
			return
		}
	}
}
