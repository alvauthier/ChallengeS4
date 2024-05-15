package fixtures

import (
	"log"
	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"github.com/google/uuid"
)

func LoadConcertCategoryFixtures() {
	db := database.GetDB()

	concertName := "Eras Tour - Taylor Swift"

	var concert models.Concert

	db.Where("name = ?", concertName).First(&concert)

	if concert.ID != uuid.Nil {
		categoryAssociations := map[int]struct {
			NbTickets int
			Price     float64
		}{
			1: {NbTickets: 200, Price: 70.0},
			3: {NbTickets: 170, Price: 100.0},
			4: {NbTickets: 120, Price: 170.0},
			5: {NbTickets: 80, Price: 250.0},
		}

		for categoryID, details := range categoryAssociations {
			concertCategory := models.ConcertCategory{
				ID:         uuid.New(),
				ConcertId:  concert.ID,
				CategoryId: categoryID,
				NbTickets:  details.NbTickets,
				Price:      details.Price,
			}
			result := db.Create(&concertCategory)
			if result.Error != nil {
				log.Println("Error creating concert category:", result.Error)
				return
			}
		}
	} else {
		log.Println("Concert not found")
	}
}
