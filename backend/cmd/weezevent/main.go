package main

import (
	"fmt"
	"weezemaster/internal/controller"
	"weezemaster/internal/database"

	"github.com/labstack/echo/v4"
)

func main() {
	fmt.Println("Starting server...")
	router := echo.New()
	database.InitDB()
	// database.Migrate()

	router.GET("/hello", controller.GetHello)

	router.GET("/users", controller.GetAllUsers)
	router.GET("/users/:id", controller.GetUser)
	router.POST("/users", controller.CreateUser)
	router.PATCH("/users/:id", controller.UpdateUser)
	router.DELETE("/users/:id", controller.DeleteUser)

	router.GET("/interests", controller.GetAllInterests)
	router.GET("/interests/:id", controller.GetInterest)
	router.POST("/interests", controller.CreateInterest)
	router.PATCH("/interests/:id", controller.UpdateInterest)
	router.DELETE("/interests/:id", controller.DeleteInterest)

	router.GET("/categories", controller.GetAllCategories)
	router.GET("/categories/:id", controller.GetCategory)
	router.POST("/categories", controller.CreateCategory)
	router.PATCH("/categories/:id", controller.UpdateCategory)
	router.DELETE("/categories/:id", controller.DeleteCategory)

	router.Start(":8080")

}
