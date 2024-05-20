package controller

import (
	"net/http"
	"time"
	"weezemaster/internal/database"
	"weezemaster/internal/models"

	"github.com/labstack/echo/v4"
	"gorm.io/gorm"
)

func GetAllCategories(c echo.Context) error {
	db := database.GetDB()
	var categories []models.Category
	db.Find(&categories)
	return c.JSON(http.StatusOK, categories)
}

func GetCategory(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var category models.Category
	db.First(&category, id)
	return c.JSON(http.StatusOK, category)
}

func CreateCategory(c echo.Context) error {
	db := database.GetDB()
	category := new(models.Category)
	if err := c.Bind(category); err != nil {
		return err
	}
	db.Create(&category)
	return c.JSON(http.StatusCreated, category)
}

// update PUT
// func UpdateCategory(c echo.Context) error {
// 	db := database.GetDB()
// 	id := c.Param("id")
// 	category := new(models.Category)
// 	db.First(&category, id)
// 	if err := c.Bind(category); err != nil {
// 		return err
// 	}
// 	db.Save(&category)
// 	return c.JSON(http.StatusOK, category)
// }

type CategoryPatchInput struct {
	Name *string `json:"name"`
}

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

func DeleteCategory(c echo.Context) error {
	db := database.GetDB()
	id := c.Param("id")
	var category models.Category
	db.First(&category, id)
	db.Delete(&category)
	return c.NoContent(http.StatusNoContent)
}
