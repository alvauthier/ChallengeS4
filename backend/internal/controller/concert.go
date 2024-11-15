package controller

import (
    "encoding/json"
    "fmt"
    "io"
    "net/http"
    "os"
    "path/filepath"
    "strings"
    "time"
    "weezemaster/internal/database"
    "weezemaster/internal/models"

    "github.com/golang-jwt/jwt/v5"
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
	db.Preload("Interests").Find(&concerts)
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
	authHeader := c.Request().Header.Get("Authorization")
	var userID uuid.UUID

	if authHeader != "" {
		tokenString := authHeader
		if len(authHeader) > 7 && authHeader[:7] == "Bearer " {
			tokenString = authHeader[7:]
		}

		claims, err := verifyToken(tokenString)
		if err == nil {
			userIdFromToken, ok := claims["id"].(string)
			if ok {
				userID, _ = uuid.Parse(userIdFromToken)
			}
		}
	}

	var concert models.Concert
	if err := db.
	Preload("Interests").
	Preload("Organization").
    Preload("ConcertCategories").
    Preload("ConcertCategories.Category").
    Preload("ConcertCategories.Tickets", "EXISTS (SELECT 1 FROM ticket_listings WHERE tickets.id = ticket_listings.ticket_id)").
    Preload("ConcertCategories.Tickets.User").
	Preload("ConcertCategories.Tickets.TicketListings",
	func(db *gorm.DB) *gorm.DB {
    	if userID != uuid.Nil {
    		return db.Joins("JOIN tickets ON tickets.id = ticket_listings.ticket_id").
    			Where("ticket_listings.status = ? AND tickets.user_id != ?", "available", userID)
    	}
    	return db.Where("ticket_listings.status = ?", "available")
    }).Where("id = ?", c.Param("id")).First(&concert).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return c.JSON(http.StatusNotFound, map[string]string{"message": "Concert not found"})
		}
		return c.JSON(http.StatusInternalServerError, map[string]string{"message": err.Error()})
	}

	return c.JSON(http.StatusOK, concert)
}

type RequestPayloadConcert struct {
	Name          string `json:"name"`
	Image         string `json:"image"`
	Description   string `json:"description"`
	Location      string `json:"location"`
	Date          string `json:"date"`
	InterestIDs   []int  `json:"InterestIDs"`
	CategoriesIDs []struct {
		ID     int     `json:"id"`
		Places int     `json:"places"`
		Price  float64 `json:"price"`
	} `json:"CategoriesIDs"`
}

type Category struct {
    ID     int     `json:"id"`
    Places int     `json:"places"`
    Price  float64 `json:"price"`
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

    // Extraire les champs du form-data
    name := c.FormValue("name")
    description := c.FormValue("description")
    location := c.FormValue("location")
    dateStr := c.FormValue("date")
    interestIDs := c.FormValue("InterestIDs")
    categoriesIDs := c.FormValue("CategoriesIDs")

    date, _ := time.Parse("2006-01-02 15:04", dateStr)

    token, ok := c.Get("user").(*jwt.Token)
    if !ok {
        return echo.NewHTTPError(http.StatusUnauthorized, "Invalid token")
    }

    claims, ok := token.Claims.(*jwt.MapClaims)
    if !ok || !token.Valid {
        return echo.NewHTTPError(http.StatusUnauthorized, "Invalid token claims")
    }

    userId, ok := (*claims)["id"].(string)
    if !ok {
        return echo.NewHTTPError(http.StatusForbidden, "User ID not found in token")
    }

    user := &models.User{}
    if err := db.Where("id = ?", userId).First(user).Error; err != nil {
        return echo.NewHTTPError(http.StatusNotFound, "User not found")
    }

    // Récupérer le fichier image depuis le form-data
    file, err := c.FormFile("image")
    if err != nil {
        return echo.NewHTTPError(http.StatusBadRequest, "Image file is required")
    }

    // Ouvrir le fichier
    src, err := file.Open()
    if err != nil {
        return echo.NewHTTPError(http.StatusInternalServerError, "Failed to open image file: "+err.Error())
    }
    defer src.Close()

    // Vérifier l'extension du fichier
    fileExtension := strings.ToLower(filepath.Ext(file.Filename))
    if fileExtension != ".jpg" && fileExtension != ".jpeg" && fileExtension != ".png" {
        return echo.NewHTTPError(http.StatusBadRequest, "Invalid file extension")
    }

    // Générer un UUID pour le nom du fichier
    fileUUID := uuid.New().String()
    fileName := fileUUID + fileExtension
    filePath := filepath.Join("uploads", "concerts", fileName)

    // Créer le dossier uploads/concerts s'il n'existe pas
    if err := os.MkdirAll(filepath.Dir(filePath), os.ModePerm); err != nil {
        return echo.NewHTTPError(http.StatusInternalServerError, "Failed to create directory: "+err.Error())
    }

    // Créer le fichier de destination
    dst, err := os.Create(filePath)
    if err != nil {
        return echo.NewHTTPError(http.StatusInternalServerError, "Failed to create destination file: "+err.Error())
    }
    defer dst.Close()

    // Copier les données de l'image dans le fichier de destination
    if _, err := io.Copy(dst, src); err != nil {
        return echo.NewHTTPError(http.StatusInternalServerError, "Failed to save image: "+err.Error())
    }

    // Créer un nouvel objet Concert
    concert := models.Concert{
        ID:             uuid.New(),
        Name:           name,
        Description:    description,
        Location:       location,
        Date:           date,
        Image:          fileName,
        OrganizationId: user.OrganizationId,
    }

    // Récupérer les objets Interest correspondant aux IDs
    var interests []models.Interest
    if len(interestIDs) > 0 {
        if err := db.Where("id IN ?", strings.Split(interestIDs, ",")).Find(&interests).Error; err != nil {
            return echo.NewHTTPError(http.StatusInternalServerError, "Failed to find interests: "+err.Error())
        }
        concert.Interests = interests
    }

    var categories []Category
    if err := json.Unmarshal([]byte(categoriesIDs), &categories); err != nil {
        return echo.NewHTTPError(http.StatusBadRequest, "Failed to parse categories: "+err.Error())
    }

	// Gérer les catégories
	var concertCategories []models.ConcertCategory
    for _, cat := range categories {
        category := models.ConcertCategory{
            ID:               uuid.New(),
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

    // Envoyer des notifications aux sujets correspondant aux centres d'intérêt
    for _, interest := range interests {
        data := map[string]string{
            "concert_id": concert.ID.String(),
            "name":       concert.Name,
        }
        notification := map[string]string{
            "title": "Nouveau concert susceptible de vous intéresser",
            "body":  fmt.Sprintf("Le concert \"%s\" vient d'être ajouté et pourrait vous plaire. Réservez vos places dès maintenant !", concert.Name),
        }

        fmt.Printf("Sending notification for interest %s\n", interest.Name)
        topic := sanitizeTopicName(interest.Name)
        err := SendFCMNotification(topic, data, notification)
        if err != nil {
            fmt.Printf("Failed to send notification for interest %s: %v\n", interest.Name, err)
        }
    }

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

    name := c.FormValue("name")
    location := c.FormValue("location")
    dateStr := c.FormValue("date")

    date, _ := time.Parse("2006-01-02 15:04", dateStr)

    // Vérifier si une nouvelle image est fournie
    file, err := c.FormFile("image")
    if err == nil {
        // Supprimer l'ancienne image si elle existe
        if concert.Image != "" {
            oldImagePath := filepath.Join("uploads", "concerts", concert.Image)
            if err := os.Remove(oldImagePath); err != nil {
                return c.JSON(http.StatusInternalServerError, map[string]string{"message": "Failed to delete old image: " + err.Error()})
            }
        }

        // Ouvrir le fichier
        src, err := file.Open()
        if err != nil {
            return c.JSON(http.StatusInternalServerError, map[string]string{"message": "Failed to open image file: " + err.Error()})
        }
        defer src.Close()

        // Vérifier l'extension du fichier
        fileExtension := strings.ToLower(filepath.Ext(file.Filename))
        if fileExtension != ".jpg" && fileExtension != ".jpeg" && fileExtension != ".png" {
            return c.JSON(http.StatusBadRequest, map[string]string{"message": "Invalid file extension"})
        }

        // Générer un UUID pour le nom du fichier
        fileUUID := uuid.New().String()
        fileName := fileUUID + fileExtension
        filePath := filepath.Join("uploads", "users", fileName)

        // Créer le dossier uploads/concerts s'il n'existe pas
        if err := os.MkdirAll(filepath.Dir(filePath), os.ModePerm); err != nil {
            return c.JSON(http.StatusInternalServerError, map[string]string{"message": "Failed to create directory: " + err.Error()})
        }

        // Créer le fichier de destination
        dst, err := os.Create(filePath)
        if err != nil {
            return c.JSON(http.StatusInternalServerError, map[string]string{"message": "Failed to create destination file: " + err.Error()})
        }
        defer dst.Close()

        // Copier les données de l'image dans le fichier de destination
        if _, err := io.Copy(dst, src); err != nil {
            return c.JSON(http.StatusInternalServerError, map[string]string{"message": "Failed to save image: " + err.Error()})
        }

        concert.Image = fileName
    }

    concert.Name = name
    concert.Location = location
    concert.Date = date

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
	fmt.Println('a')
	db := database.GetDB()
	authHeader := c.Request().Header.Get("Authorization")
	if authHeader == "" {
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": "Authorization header is missing"})
	}

	tokenString := authHeader
	if len(authHeader) > 7 && authHeader[:7] == "Bearer " {
		tokenString = authHeader[7:]
	}

	claims, err := verifyToken(tokenString)
	if err != nil {
		return c.JSON(http.StatusUnauthorized, map[string]string{"error": "Invalid or expired token"})
	}

	email, ok := claims["email"].(string)
	if !ok {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Invalid token claims"})
	}
	user := &models.User{}
	if err := db.Where("email = ?", email).First(user).Error; err != nil {
		return echo.NewHTTPError(http.StatusNotFound, "User not found")
	}
	fmt.Println(user.OrganizationId)
	var concerts []models.Concert
	if result := db.Where("organization_id = ?", user.OrganizationId).Find(&concerts); result.Error != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Error retrieving concerts"})
	}

	if len(concerts) == 0 {
		return c.JSON(http.StatusNotFound, map[string]string{"message": "No concerts found for this organization"})
	}

	return c.JSON(http.StatusOK, concerts)
}
