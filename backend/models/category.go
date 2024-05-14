package models

import (
	"gorm.io/gorm"
)

type Category struct {
	gorm.Model
	ID   int    `gorm:"unique;primaryKey"`
	Name string `gorm:"unique;not null"`
	// Concerts []Concert `gorm:"many2many:concert_categories"`
	// ConcertCategories []ConcertCategory `gorm:"many2many:concert_categories"`
	ConcertCategories []ConcertCategory `gorm:"foreignKey:CategoryId"`
}
