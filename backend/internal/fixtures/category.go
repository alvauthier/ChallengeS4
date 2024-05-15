package fixtures

import (
	"log"
	"weezemaster/internal/database"
	"weezemaster/internal/models"
)

func LoadCategoryFixtures() {
	db := database.GetDB()

	categories := []models.Category{
		{
			Name: "Fosse",
		},
		{
			Name: "Catégorie 1",
		},
		{
			Name: "Catégorie 2",
		},
		{
			Name: "Catégorie 3",
		},
		{
			Name: "Catégorie 4",
		},
		{
			Name: "Carré or",
		},
	}

	for _, category := range categories {
		result := db.Create(&category)
		if result.Error != nil {
			log.Println("Error creating category:", result.Error)
			return
		}
	}
}
