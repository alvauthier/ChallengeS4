package main

import (
	"fmt"
	"weezemaster/internal/controller"
	"weezemaster/internal/database"
	"weezemaster/internal/middleware"

	_ "weezemaster/docs"

	"github.com/labstack/echo/v4"
	echoSwagger "github.com/swaggo/echo-swagger"
)

//	@title			Weezemaster API
//	@version		1.0
//	@description	This is the swagger documentation for the Weezemaster API.
//	@termsOfService	http://swagger.io/terms/

//	@contact.name	API Support
//	@contact.url	http://www.swagger.io/support
//	@contact.email	support@swagger.io

//	@license.name	Apache 2.0
//	@license.url	http://www.apache.org/licenses/LICENSE-2.0.html

//	@host		localhost:8080
//	@BasePath	/

func main() {
	fmt.Println("Starting server...")
	router := echo.New()
	database.InitDB()

	router.Use(func(next echo.HandlerFunc) echo.HandlerFunc {
		return func(c echo.Context) error {
			c.Response().Header().Set("Content-Type", "application/json; charset=utf-8")
			return next(c)
		}
	})

	authenticated := router.Group("")
	authenticated.Use(middleware.JWTMiddleware())

	router.POST("/register", controller.Register)
	router.POST("/login", controller.Login)
	router.GET("/users", controller.GetAllUsers)
	router.GET("/users/:id", controller.GetUser)
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

	router.GET("/concerts", controller.GetAllConcerts)
	router.GET("/concerts/:id", controller.GetConcert)
	authenticated.POST("/concerts", controller.CreateConcert)
	authenticated.PATCH("/concerts/:id", controller.UpdateConcert)
	authenticated.DELETE("/concerts/:id", controller.DeleteConcert)

	router.GET("/swagger/*", echoSwagger.WrapHandler)

	router.Start(":8080")

}
