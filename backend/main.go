package main

import (
	"fmt"
	"weezemaster/configuration"
	"weezemaster/controller"

	"github.com/labstack/echo/v4"
)

func main() {
	fmt.Println("Starting server...")
	router := echo.New()
	configuration.InitDB()

	router.GET("/hello", controller.GetHello)
	router.Start(":8080")

}
