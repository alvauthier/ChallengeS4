package controller

import (
	"net/http"
	"time"
	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

//	@Summary		Récupère tous les centres d'intérêts
//	@Description	Récupère tous les centres d'intérêts
//	@ID				get-all-interests
//	@Tags			Interests
//	@Produce		json
//	@Success		200	{array}		models.Interest
//	@Failure		500	{object}	string
//	@Router			/interests [get]
//	@Security		Bearer
func GetAllInterests(c echo.Context) error {
	db := database.GetDB()
	var interests []models.Interest
	db.Find(&interests)

	var artists []models.Artist
	db.Preload("Interest").Find(&artists)

	// Créer une map pour stocker les intérêts des artistes
	artistInterests := make(map[int]struct{})
	for _, artist := range artists {
		if artist.Interest != nil {
			artistInterests[artist.Interest.ID] = struct{}{}
		}
	}

	// Filtrer les intérêts pour enlever ceux des artistes
	filteredInterests := []models.Interest{}
	for _, interest := range interests {
		if _, exists := artistInterests[interest.ID]; !exists {
			filteredInterests = append(filteredInterests, interest)
		}
	}

	return c.JSON(http.StatusOK, filteredInterests)
}

//	@Summary		Récupère un centre d'intérêt
//	@Description	Récupère un centre d'intérêt par ID
//	@ID				get-interest
//	@Tags			Interests
//	@Produce		json
//	@Param			id	path		int	true	"ID du centre d'intérêt"
//	@Success		200	{object}	models.Interest
//	@Failure		404	{object}	string
//	@Failure		500	{object}	string
//	@Router			/interests/{id} [get]
//	@Security		Bearer
func GetInterest(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var interest models.Interest
	db.First(&interest, id)
	return c.JSON(http.StatusOK, interest)
}

//	@Summary		Créé un centre d'intérêt
//	@Description	Créé un centre d'intérêt
//	@ID				create-interest
//	@Tags			Interests
//	@Produce		json
//	@Param			interest	body		models.Interest	true	"Centre d'intérêt à créer"
//	@Success		201			{array}		models.Interest
//	@Failure		400			{object}	string
//	@Failure		401			{object}	string
//	@Failure		500			{object}	string
//	@Router			/interests [post]
//	@Security		Bearer
func CreateInterest(c echo.Context) error {
	db := database.GetDB()
	interest := new(models.Interest)
	if err := c.Bind(interest); err != nil {
		return err
	}
	db.Create(&interest)
	return c.JSON(http.StatusCreated, interest)
}

type InterestPatchInput struct {
	Name *string `json:"name"`
}

//	@Summary		Modifie un centre d'intérêt
//	@Description	Modifie un centre d'intérêt par ID
//	@ID				update-interest
//	@Tags			Interests
//	@Produce		json
//	@Param			id			path		int					true	"ID du centre d'intérêt"
//	@Param			interest	body		InterestPatchInput	true	"Centre d'intérêt à modifier"
//	@Success		200			{object}	models.Interest
//	@Failure		400			{object}	string
//	@Failure		401			{object}	string
//	@Failure		404			{object}	string
//	@Failure		500			{object}	string
//	@Router			/interests/{id} [patch]
//	@Security		Bearer
func UpdateInterest(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var interest models.Interest
	if err := db.Where("id = ?", id).First(&interest).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return echo.NewHTTPError(http.StatusNotFound, "Interest not found")
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	patchInterest := new(InterestPatchInput)
	if err := c.Bind(patchInterest); err != nil {
		return echo.NewHTTPError(http.StatusBadRequest, err.Error())
	}

	if err := db.Model(&interest).Updates(patchInterest).Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	db.Model(&interest).UpdateColumn("updated_at", time.Now())

	return c.JSON(http.StatusOK, interest)
}

//	@Summary		Supprime un centre d'intérêt
//	@Description	Supprime un centre d'intérêt par ID
//	@ID				delete-interest
//	@Tags			Interests
//	@Produce		json
//	@Param			id	path	int	true	"ID du centre d'intérêt"
//	@Success		204
//	@Failure		401	{object}	string
//	@Failure		404	{object}	string
//	@Failure		500	{object}	string
//	@Router			/interests/{id} [delete]
//	@Security		Bearer
func DeleteInterest(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var interest models.Interest
	db.First(&interest, id)
	db.Delete(&interest)
	return c.NoContent(http.StatusNoContent)
}

//	@Summary		Récupère les centres d'intérêt de l'utilisateur
//	@Description	Récupère les centres d'intérêt de l'utilisateur
//	@ID				get-user-interests
//	@Tags			Interests
//	@Produce		json
//	@Success		200	{array}		models.Interest
//	@Failure		401	{object}	string
//	@Failure		500	{object}	string
//	@Router			/user/interests [get]
//	@Security		Bearer
func GetUserInterests(c echo.Context) error {
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

	var user models.User
	if err := db.Where("email = ?", email).First(&user).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "User not found"})
	}

	var userInterests []models.Interest
	if err := db.Model(&user).Association("Interests").Find(&userInterests); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}

	return c.JSON(http.StatusOK, userInterests)
}

//	@Summary		Ajoute un centre d'intérêt à l'utilisateur
//	@Description	Ajoute un centre d'intérêt à l'utilisateur
//	@ID				add-user-interest
//	@Tags			Interests
//	@Produce		json
//	@Param			id	path		int	true	"ID du centre d'intérêt"
//	@Success		200	{object}	models.Interest
//	@Failure		401	{object}	string
//	@Failure		404	{object}	string
//	@Failure		500	{object}	string
//	@Router			/user/interests/{id} [post]
//	@Security		Bearer
func AddUserInterest(c echo.Context) error {
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

	var user models.User
	if err := db.Where("email = ?", email).First(&user).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "User not found"})
	}

	interestID := c.Param("id")
	var interest models.Interest
	if err := db.First(&interest, interestID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return echo.NewHTTPError(http.StatusNotFound, "Interest not found")
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	if err := db.Model(&user).Association("Interests").Append(&interest); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}

	return c.JSON(http.StatusOK, interest)
}

//	@Summary		Supprime un centre d'intérêt de l'utilisateur
//	@Description	Supprime un centre d'intérêt de l'utilisateur
//	@ID				remove-user-interest
//	@Tags			Interests
//	@Produce		json
//	@Param			id	path	int	true	"ID du centre d'intérêt"
//	@Success		204
//	@Failure		401	{object}	string
//	@Failure		404	{object}	string
//	@Failure		500	{object}	string
//	@Router			/user/interests/{id} [delete]
//	@Security		Bearer
func RemoveUserInterest(c echo.Context) error {
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

	var user models.User
	if err := db.Where("email = ?", email).First(&user).Error; err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "User not found"})
	}

	interestID := c.Param("id")
	var interest models.Interest
	if err := db.First(&interest, interestID).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return echo.NewHTTPError(http.StatusNotFound, "Interest not found")
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	if err := db.Model(&user).Association("Interests").Delete(&interest); err != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": err.Error()})
	}

	return c.NoContent(http.StatusNoContent)
}
