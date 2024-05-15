package models

import (
	"gorm.io/gorm"
)

type Category struct {
	gorm.Model
	ID                int               `gorm:"unique;primaryKey"`
	Name              string            `gorm:"unique;not null"`
	ConcertCategories []ConcertCategory `gorm:"foreignKey:CategoryId"`
}
