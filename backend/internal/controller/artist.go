package controller

import (
	"net/http"
	"time"
	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"github.com/google/uuid"
	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

// @Summary		Récupère tous les artistes
// @Description	Récupère tous les artistes
// @ID				get-all-artists
// @Tags			Artists
// @Produce		json
// @Success		200	{array}	models.Artist
// @Router			/artists [get]
func GetAllArtists(c echo.Context) error {
	db := database.GetDB()
	var artists []models.Artist
	db.Find(&artists)
	return c.JSON(http.StatusOK, artists)
}

// @Summary		Récupère un artiste
// @Description	Récupère un artiste par ID
// @ID				get-artist
// @Tags			Artists
// @Produce		json
// @Param			id	path		int	true	"ID de l'artiste"
// @Success		200	{object}	models.Artist
// @Router			/artists/{id} [get]
func GetArtist(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var artist models.Artist
	if err := db.Preload("Concerts").Where("id = ?", id).First(&artist).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return echo.NewHTTPError(http.StatusNotFound, "Artist not found")
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}
	return c.JSON(http.StatusOK, artist)
}

// @Summary		Créé un artiste
// @Description	Créé un artiste
// @ID				create-artist
// @Tags			Artists
// @Produce		json
// @Success		200	{array}	models.Artist
// @Router			/artists [post]
func CreateArtist(c echo.Context) error {
	db := database.GetDB()
	artist := new(models.Artist)
	if err := c.Bind(artist); err != nil {
		return err
	}

	artist.ID = uuid.New()

	// Start transaction
	tx := db.Begin()
	if tx.Error != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, tx.Error.Error())
	}

	// Create interest
	interest := models.Interest{Name: artist.Name}
	if err := tx.Create(&interest).Error; err != nil {
		tx.Rollback()
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	// Set interest ID to artist
	artist.InterestId = interest.ID

	// Create artist
	if err := tx.Create(&artist).Error; err != nil {
		tx.Rollback()
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	// Commit transaction
	if err := tx.Commit().Error; err != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	return c.JSON(http.StatusCreated, artist)
}

type ArtistPatchInput struct {
	Name string `json:"name"`
}

// @Summary		Met à jour un artiste
// @Description	Met à jour un artiste par ID
// @ID				update-artist
// @Tags			Artists
// @Produce		json
// @Param			id	path		int	true	"ID de l'artiste"
// @Success		200	{object}	models.Artist
// @Router			/artists/{id} [patch]
func UpdateArtist(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var artist models.Artist
	if err := db.Where("id = ?", id).First(&artist).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return echo.NewHTTPError(http.StatusNotFound, "Artist not found")
		}
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}
	artistPatch := new(ArtistPatchInput)
	if err := c.Bind(artistPatch); err != nil {
		return err
	}

	// Start transaction
	tx := db.Begin()
	if tx.Error != nil {
		return echo.NewHTTPError(http.StatusInternalServerError, tx.Error.Error())
	}

	// Update artist name
	artist.Name = artistPatch.Name
	artist.UpdatedAt = time.Now()
	if err := tx.Save(&artist).Error; err != nil {
		tx.Rollback()
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	// Update associated interest name
	var interest models.Interest
	if err := tx.Where("id = ?", artist.InterestId).First(&interest).Error; err != nil {
		tx.Rollback()
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}
	interest.Name = artistPatch.Name
	if err := tx.Save(&interest).Error; err != nil {
		tx.Rollback()
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	// Commit transaction
	if err := tx.Commit().Error; err != nil {
		tx.Rollback()
		return echo.NewHTTPError(http.StatusInternalServerError, err.Error())
	}

	return c.JSON(http.StatusOK, artist)
}

// @Summary		Supprime un artiste
// @Description	Supprime un artiste par ID
// @ID				delete-artist
// @Tags			Artists
// @Produce		json
// @Param			id	path		int	true	"ID de l'artiste"
// @Success		200	{object}	models.Artist
// @Router			/artists/{id} [delete]
func DeleteArtist(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	artistID, err := uuid.Parse(id)
	if err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"error": "Invalid artist ID"})
	}

	// Start a new transaction
	tx := db.Begin()
	if tx.Error != nil {
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to start transaction"})
	}

	// Find the artist
	var artist models.Artist
	if err := tx.Where("id = ?", artistID).First(&artist).Error; err != nil {
		tx.Rollback()
		return c.JSON(http.StatusNotFound, map[string]string{"error": "Artist not found"})
	}

	// Delete the artist
	if err := tx.Delete(&artist).Error; err != nil {
		tx.Rollback()
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to delete artist"})
	}

	// Delete the associated interest
	if err := tx.Delete(&models.Interest{}, artist.InterestId).Error; err != nil {
		tx.Rollback()
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to delete associated interest"})
	}

	// Commit the transaction
	if err := tx.Commit().Error; err != nil {
		tx.Rollback()
		return c.JSON(http.StatusInternalServerError, map[string]string{"error": "Failed to commit transaction"})
	}

	return c.NoContent(http.StatusNoContent)
}
