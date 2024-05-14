package main

import (
	"weezemaster/internal/database"
)

func main() {
	database.InitDB()
	database.Migrate()
}
