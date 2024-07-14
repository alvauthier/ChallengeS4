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
	router.POST("/refresh", controller.RefreshAccessToken)
	authenticated.GET("/users", controller.GetAllUsers, middleware.CheckRole("admin"))
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

	router.POST("/registerorganizer", controller.RegisterOrganizer)

	// WIP : routes for tickets and ticketlistings

	// router.GET("/tickets", controller.GetAllTickets)
	// router.GET("/tickets/:id", controller.GetTicket)
	// router.POST("/tickets", controller.CreateTicket)
	// // router.PATCH("/tickets/:id", controller.UpdateTicket)
	// router.DELETE("/tickets/:id", controller.DeleteTicket)

	// router.GET("/ticketlisting", controller.GetAllTicketListings)
	// router.GET("/ticketlisting/:id", controller.GetTicketListings)
	// router.POST("/ticketlisting", controller.CreateTicketListings)
	// router.PATCH("/ticketlisting/:id", controller.UpdateTicketListing)
	// router.DELETE("/ticketlisting/:id", controller.DeleteTicketListing)
	// router.GET("/ticketlisting/concert/:id", controller.GetTicketListingByConcertId)

	router.GET("/concerts", controller.GetAllConcerts)
	router.GET("/concerts/:id", controller.GetConcert)
	// authenticated.GET("/concerts/:id", controller.GetConcert, middleware.CheckRole("user")) // pour tester les rôles
	authenticated.POST("/concerts", controller.CreateConcert, middleware.CheckRole("organizer", "admin"))
	authenticated.PATCH("/concerts/:id", controller.UpdateConcert)
	authenticated.DELETE("/concerts/:id", controller.DeleteConcert)

	authenticated.POST("/reservation", controller.CreateReservation, middleware.CheckRole("user"))

	authenticated.POST("/create-payment-intent", controller.CreatePaymentIntent, middleware.CheckRole("user"))

	router.GET("/swagger/*", echoSwagger.WrapHandler)

	router.Start(":8080")

}
