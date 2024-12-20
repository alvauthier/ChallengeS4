package main

import (
	"weezemaster/internal/database"
	"weezemaster/internal/fixtures"
)

func main() {
	database.InitDB()
	fixtures.LoadInterestFixtures()
	fixtures.LoadArtistFixtures()
	fixtures.LoadOrganizationFixtures()
	fixtures.LoadUserFixtures()
	fixtures.LoadUserInterestFixtures()
	fixtures.LoadConcertFixtures()
	fixtures.LoadCategoryFixtures()
	fixtures.LoadConcertCategoryFixtures()
	fixtures.LoadConcertInterestFixtures()
	fixtures.LoadTicketFixtures()
}
