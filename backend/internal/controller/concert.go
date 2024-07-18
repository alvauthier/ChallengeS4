package controller

import (
	"fmt"
	"net/http"
	"strconv"
	"time"
	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

// @Summary		Récupère tous les concerts
// @Description	Récupère tous les concerts
// @ID				get-all-concerts
// @Tags			Concerts
// @Produce		json
// @Success		200	{array}	models.Concert
// @Router			/concerts [get]
func GetAllConcerts(c echo.Context) error {
	db := database.GetDB()
	var concerts []models.Concert
	db.Find(&concerts)
	return c.JSON(http.StatusOK, concerts)
}

// @Summary		Récupère un concert
// @Description	Récupère un concert par ID
// @ID				get-concert
// @Tags			Concerts
// @Produce		json
// @Param			id	path		string	true	"ID du concert"	format(uuid)
// @Success		200	{object}	models.Concert
// @Router			/concerts/{id} [get]
func GetConcert(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var concert models.Concert
	if err := db.Preload("Interests").
		Preload("Organization").
		Preload("ConcertCategories").
		Preload("ConcertCategories.Category").
		Preload("ConcertCategories.Tickets", "EXISTS (SELECT 1 FROM ticket_listings WHERE tickets.id = ticket_listings.ticket_id)").
		Preload("ConcertCategories.Tickets.TicketListing").
		Preload("ConcertCategories.Tickets.User").
		Where("id = ?", id).First(&concert).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return echo.NewHTTPError(http.StatusNotFound, "Concert not found")
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}
	return c.JSON(http.StatusOK, concert)
}

type RequestPayloadConcert struct {
	Name          string `json:"name"`
	Image         string `json:"image"`
	Description   string `json:"description"`
	Location      string `json:"location"`
	Date          string `json:"date"`
	UserID        string `json:"userId"`
	InterestIDs   []int  `json:"InterestIDs"`
	CategoriesIDs []struct {
		ID     int     `json:"id"`
		Places int     `json:"places"`
		Price  float64 `json:"price"`
	} `json:"CategoriesIDs"`
}

// @Summary		Créé un concert
// @Description	Créé un concert
// @ID				create-concert
// @Tags			Concerts
// @Produce		json
// @Success		201	{object}	models.Concert
// @Router			/concerts [post]
func CreateConcert(c echo.Context) error {
	db := database.GetDB()

	var input RequestPayloadConcert

	if err := c.Bind(&input); err != nil {
		fmt.Println("3")
		return echo.NewHTTPError(http.StatusBadRequest, "Failed to bind input: "+err.Error())
	}

	date, _ := time.Parse("2006-01-02", input.Date)
	fmt.Println(date)

	user := &models.User{}
	if err := db.Where("id = ?", input.UserID).First(user).Error; err != nil {
		return echo.NewHTTPError(http.StatusNotFound, "User not found")
	}
	// Créer un nouvel objet Concert
	concert := models.Concert{
		ID:             uuid.New(),
		Name:           input.Name,
		Description:    input.Description,
		Location:       input.Location,
		Date:           date,
		OrganizationId: user.OrganizationId,
	}

	// Récupérer les objets Interest correspondant aux IDs
	var interests []models.Interest
	if len(input.InterestIDs) > 0 {
		if err := db.Where("id IN ?", input.InterestIDs).Find(&interests).Error; err != nil {
			return echo.NewHTTPError(http.StatusInternalServerError, "Failed to find interests: "+err.Error())
		}
		concert.Interests = interests
	}

	// Gérer les catégories
	var concertCategories []models.ConcertCategory
	for _, cat := range input.CategoriesIDs {
		category := models.ConcertCategory{
			ID:               uuid.New(), // Exemple pour le nom de la catégorie
			ConcertId:        concert.ID,
			CategoryId:       cat.ID,
			Price:            cat.Price,
			AvailableTickets: cat.Places,
		}
		concertCategories = append(concertCategories, category)
	}
	// Créer le concert avec les associations
	if err := db.Create(&concert).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to create concert: "+err.Error())
	}

	// Enregistrer les catégories associées au concert
	if err := db.Create(&concertCategories).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, "Failed to create concert categories: "+err.Error())
	}

	// Gérer l'image
	/*if input.Image != "" {
		// Assuming a function saveBase64Image exists to handle image saving
		imagePath, err := saveBase64Image(input.Image)
		if err != nil {
			return echo.NewHTTPError(http.StatusInternalServerError, "Failed to save image: "+err.Error())
		}
		// Enregistrer le chemin de l'image dans la base de données
		concert.image = imagePath
	}*/

	// Envoyer des notifications aux sujets correspondant aux centres d'intérêt
	/*for _, interest := range interests {
		data := map[string]string{
			"concert_id": concert.ID.String(),
			"name":       concert.Name,
		}
		notification := map[string]string{
			"title": "Nouveau concert susceptible de vous intéresser",
			"body":  fmt.Sprintf("Le concert \"%s\" vient d'être ajouté et pourrait vous plaire. Réservez vos places dès maintenant !", concert.Name),
		}

		fmt.Printf("Sending notification for interest %s\n", interest.Name)
		topic := sanitizeTopicName(interest.Name) // Utiliser le nom du centre d'intérêt comme sujet
		err := SendFCMNotification(topic, data, notification)
		if err != nil {
			fmt.Printf("Failed to send notification for interest %s: %v\n", interest.Name, err)
		}
	}*/
	fmt.Println("Concert created")
	return c.JSON(http.StatusOK, map[string]interface{}{
		"concert":    concert,
		"categories": concertCategories,
		"interests":  interests,
	})
}

// @Summary		Modifie un concert
// @Description	Modifie un concert par ID
// @ID				update-concert
// @Tags			Concerts
// @Produce		json
// @Param			id	path		string	true	"ID du concert"	format(uuid)
// @Success		200	{object}	models.Concert
// @Router			/concerts/{id} [patch]
func UpdateConcert(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var concert models.Concert
	if err := db.Where("id = ?", id).First(&concert).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return echo.NewHTTPError(http.StatusNotFound, "Concert not found")
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}
	if err := c.Bind(&concert); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	}
	if err := db.Save(&concert).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}
	return c.JSON(http.StatusOK, concert)
}

// @Summary		Supprime un concert
// @Description	Supprime un concert par ID
// @ID				delete-concert
// @Tags			Concerts
// @Produce		json
// @Param			id	path	string	true	"ID du concert"	format(uuid)
// @Success		204
// @Router			/concerts/{id} [delete]
func DeleteConcert(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var concert models.Concert
	if err := db.Where("id = ?", id).Delete(&concert).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}
	return c.NoContent(http.StatusNoContent)
}

func GetConcertByOrganizationID(c echo.Context) error {
	db := database.GetDB()

	organizationID, err := strconv.Atoi(c.Param("id"))
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid organization ID"})
	}

	var concerts []models.Concert
	if result := db.Where("organization_id = ?", organizationID).Find(&concerts); result.Error != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Error retrieving concerts"})
	}

	if len(concerts) == 0 {
		return c.JSON(http.StatusNotFound, map[string]string{"message": "No concerts found for this organization"})
	}

	return c.JSON(http.StatusOK, concerts)
}
