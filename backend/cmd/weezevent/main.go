package main

import (
	"fmt"
	"weezemaster/controller"
	"weezemaster/database"

	"github.com/labstack/echo/v4"
)

func main() {
	fmt.Println("Starting server...")
	router := echo.New()
	database.InitDB()
	database.Migrate()

	router.GET("/hello", controller.GetHello)
	router.Start(":8080")

}
