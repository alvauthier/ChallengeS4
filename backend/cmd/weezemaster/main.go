package main

import (
	"fmt"
	"log"
	"weezemaster/internal/config"
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
	// erro := godotenv.Load("../../.env")
	// if erro != nil {
	// 	log.Fatalf("Error loading .env file")
	// }

	// env := os.Getenv("ENVIRONMENT")

	fmt.Println("Starting server...")
	router := echo.New()
	database.InitDB()

	err := config.InitFirebase()
	if err != nil {
		log.Fatalf("Failed to initialize Firebase: %v", err)
	}

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
	router.POST("/forgot-password", controller.EmailForgotPassword)
	router.POST("/reset-password", controller.ResetPassword)
	authenticated.GET("/users", controller.GetAllUsers, middleware.CheckRole("admin"))
	authenticated.GET("/users/:id", controller.GetUser, middleware.CheckRole("user", "admin"))
	authenticated.PATCH("/users/:id", controller.UpdateUser, middleware.CheckRole("admin"))
	authenticated.DELETE("/users/:id", controller.DeleteUser, middleware.CheckRole("admin"))

	authenticated.GET("/interests", controller.GetAllInterests, middleware.CheckRole("user", "organizer", "admin"))
	authenticated.GET("/interests/:id", controller.GetInterest, middleware.CheckRole("admin"))
	authenticated.POST("/interests", controller.CreateInterest, middleware.CheckRole("admin"))
	authenticated.PATCH("/interests/:id", controller.UpdateInterest, middleware.CheckRole("admin"))
	authenticated.DELETE("/interests/:id", controller.DeleteInterest, middleware.CheckRole("admin"))

	authenticated.GET("/categories", controller.GetAllCategories, middleware.CheckRole("user", "organizer", "admin"))
	authenticated.GET("/categories/:id", controller.GetCategory, middleware.CheckRole("admin"))
	authenticated.POST("/categories", controller.CreateCategory, middleware.CheckRole("admin"))
	authenticated.PATCH("/categories/:id", controller.UpdateCategory, middleware.CheckRole("admin"))
	authenticated.DELETE("/categories/:id", controller.DeleteCategory, middleware.CheckRole("admin"))

	router.POST("/registerorganizer", controller.RegisterOrganizer)

	authenticated.GET("/tickets", controller.GetAllTickets, middleware.CheckRole("admin"))
	authenticated.GET("/tickets/:id", controller.GetTicket, middleware.CheckRole("admin"))
	authenticated.POST("/tickets", controller.CreateTicket, middleware.CheckRole("admin"))
	authenticated.PATCH("/tickets/:id", controller.UpdateTicket, middleware.CheckRole("admin"))
	authenticated.DELETE("/tickets/:id", controller.DeleteTicket, middleware.CheckRole("admin"))
	authenticated.GET("/tickets/mytickets", controller.GetUserTickets, middleware.CheckRole("user"))

	authenticated.GET("/ticketlisting", controller.GetAllTicketListings, middleware.CheckRole("admin"))
	authenticated.GET("/ticketlisting/:id", controller.GetTicketListings, middleware.CheckRole("admin"))
	authenticated.POST("/ticketlisting", controller.CreateTicketListings, middleware.CheckRole("user"))
	authenticated.PATCH("/ticketlisting/:id", controller.UpdateTicketListing, middleware.CheckRole("user", "admin"))
	authenticated.DELETE("/ticketlisting/:id", controller.DeleteTicketListing, middleware.CheckRole("user"))
	authenticated.GET("/ticketlisting/concert/:id", controller.GetTicketListingByConcertId, middleware.CheckRole("user", "organizer", "admin"))

	router.GET("/concerts", controller.GetAllConcerts)
	router.GET("/concerts/:id", controller.GetConcert)
	authenticated.POST("/concerts", controller.CreateConcert, middleware.CheckRole("organizer", "admin"))
	authenticated.PATCH("/concerts/:id", controller.UpdateConcert, middleware.CheckRole("organizer", "admin"))
	authenticated.DELETE("/concerts/:id", controller.DeleteConcert, middleware.CheckRole("organizer", "admin"))
	authenticated.GET("/organization/concerts", controller.GetConcertByOrganizationID, middleware.CheckRole("organizer", "admin"))

	authenticated.GET("/user/interests", controller.GetUserInterests, middleware.CheckRole("user, organizer, admin"))
	authenticated.POST("/user/interests/:id", controller.AddUserInterest, middleware.CheckRole("user, organizer, admin"))
	authenticated.DELETE("/user/interests/:id", controller.RemoveUserInterest, middleware.CheckRole("user, organizer, admin"))

	authenticated.POST("/reservation", controller.CreateReservation, middleware.CheckRole("user"))
	authenticated.POST("/ticket_listing_reservation/:ticketListingId", controller.CreateTicketListingReservation, middleware.CheckRole("user"))
	authenticated.POST("/ticket_listing_reservation_conversation/:conversationId", controller.CreateTicketListingReservationFromConversation, middleware.CheckRole("user"))

	authenticated.POST("/create-payment-intent", controller.CreatePaymentIntent, middleware.CheckRole("user"))

	router.GET("/swagger/*", echoSwagger.WrapHandler)

	authenticated.GET("/conversations/:id", controller.GetConversation, middleware.CheckRole("user", "organizer", "admin"))
	authenticated.POST("/conversations", controller.CreateConversation, middleware.CheckRole("user", "organizer", "admin"))
	authenticated.PATCH("/conversations/:id", controller.UpdateConversation, middleware.CheckRole("user", "organizer", "admin"))

	authenticated.POST("/messages", controller.PostMessage, middleware.CheckRole("user", "organizer", "admin"))

	authenticated.POST("/conversations/check", controller.CheckConversation, middleware.CheckRole("user", "organizer", "admin"))
	router.GET("/ws", controller.HandleWebSocket)

	router.Start(":8080")
}
