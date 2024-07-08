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
			AvailableTickets int
			SoldTickets      int
			Price            float64
		}{
			1: {AvailableTickets: 200, SoldTickets: 0, Price: 70.0},
			3: {AvailableTickets: 170, SoldTickets: 0, Price: 100.0},
			4: {AvailableTickets: 120, SoldTickets: 0, Price: 170.0},
			5: {AvailableTickets: 80, SoldTickets: 0, Price: 250.0},
		}

		for categoryID, details := range categoryAssociations {
			concertCategory := models.ConcertCategory{
				ID:               uuid.New(),
				ConcertId:        concert.ID,
				CategoryId:       categoryID,
				AvailableTickets: details.AvailableTickets,
				SoldTickets:      details.SoldTickets,
				Price:            details.Price,
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
