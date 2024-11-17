package controller

import (
	"net/http"
	"time"
	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

//	@Summary		Récupère toutes les catégories
//	@Description	Récupère toutes les catégories
//	@ID				get-all-categories
//	@Tags			Categories
//	@Produce		json
//	@Success		200	{array}		models.Category
//	@Failure		500	{object}	string
//	@Router			/categories [get]
//	@Security		Bearer
func GetAllCategories(c echo.Context) error {
	db := database.GetDB()
	var categories []models.Category
	db.Find(&categories)
	return c.JSON(http.StatusOK, categories)
}

//	@Summary		Récupère une catégorie
//	@Description	Récupère une catégorie par ID
//	@ID				get-category
//	@Tags			Categories
//	@Produce		json
//	@Param			id	path		int	true	"ID de la catégorie"
//	@Success		200	{object}	models.Category
//	@Failure		404	{object}	string
//	@Failure		500	{object}	string
//	@Router			/categories/{id} [get]
//	@Security		Bearer
func GetCategory(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var category models.Category
	db.First(&category, id)
	return c.JSON(http.StatusOK, category)
}

//	@Summary		Créé une catégorie
//	@Description	Créé une catégorie
//	@ID				create-category
//	@Tags			Categories
//	@Produce		json
//	@Success		200	{array}		models.Category
//	@Failure		400	{object}	string
//	@Failure		500	{object}	string
//	@Router			/categories [post]
//	@Security		Bearer
func CreateCategory(c echo.Context) error {
	db := database.GetDB()
	category := new(models.Category)
	if err := c.Bind(category); err != nil {
		return err
	}
	db.Create(&category)
	return c.JSON(http.StatusCreated, category)
}

type CategoryPatchInput struct {
	Name *string `json:"name"`
}

//	@Summary		Modifie une catégorie
//	@Description	Modifie une catégorie par ID
//	@ID				update-category
//	@Tags			Categories
//	@Produce		json
//	@Param			id		path		int					true	"ID de la catégorie"
//	@Param			name	body		CategoryPatchInput	true	"Nom de la catégorie"
//	@Success		200		{object}	models.Category
//	@Failure		400		{object}	string
//	@Failure		404		{object}	string
//	@Failure		422		{object}	string
//	@Failure		500		{object}	string
//	@Router			/categories/{id} [patch]
//	@Security		Bearer
func UpdateCategory(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var category models.Category
	if err := db.Where("id = ?", id).First(&category).Error; err != nil {
		if err == gorm.ErrRecordNotFound {
			return c.JSON(http.StatusNotFound, map[string]string{"message": "Category not found"})
		}
		return c.JSON(http.StatusInternalServerError, map[string]string{"message": err.Error()})
	}

	patchCategory := new(CategoryPatchInput)
	if err := c.Bind(patchCategory); err != nil {
		return c.JSON(http.StatusBadRequest, map[string]string{"message": "Invalid request"})
	}

	if patchCategory.Name != nil {
		var existingCategory models.Category
		if err := db.Where("name = ?", *patchCategory.Name).First(&existingCategory).Error; err != gorm.ErrRecordNotFound {
			return c.JSON(http.StatusUnprocessableEntity, map[string]string{"message": "Category name already used"})
		}
	}

	tx := db.Begin()
	if err := tx.Model(&category).Updates(patchCategory).Error; err != nil {
		tx.Rollback()
		return c.JSON(http.StatusUnprocessableEntity, map[string]string{"message": "Invalid fields"})
	}

	tx.Model(&category).UpdateColumn("updated_at", time.Now())
	tx.Commit()

	return c.JSON(http.StatusOK, category)
}

//	@Summary		Supprime une catégorie
//	@Description	Supprime une catégorie par ID
//	@ID				delete-category
//	@Tags			Categories
//	@Produce		json
//	@Param			id	path	int	true	"ID de la catégorie"
//	@Success		204
//	@Failure		404	{object}	string
//	@Failure		500	{object}	string
//	@Router			/categories/{id} [delete]
//	@Security		Bearer
func DeleteCategory(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var category models.Category
	db.First(&category, id)
	db.Delete(&category)
	return c.NoContent(http.StatusNoContent)
}
