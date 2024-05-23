package models

import (
	"time"
)

type Category struct {
	// gorm.Model
	ID                int               `gorm:"unique;primaryKey"`
	Name              string            `gorm:"unique;not null"`
	ConcertCategories []ConcertCategory `gorm:"foreignKey:CategoryId"`
	CreatedAt         time.Time
	UpdatedAt         time.Time
	DeletedAt         *time.Time `gorm:"index"`
}
