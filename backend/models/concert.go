package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Concert struct {
	gorm.Model
	ID           uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	Name         string    `gorm:"not null"`
	Description  string    `gorm:"not null"`
	Localisation string    `gorm:"not null"`
	Date         time.Time `gorm:"not null"`
	CreatedAt    time.Time
	UpdatedAt    time.Time
	// Categories     []Category `gorm:"many2many:concert_categories"`
	OrganizationId uuid.UUID
	Organisation   Organization `gorm:"foreignKey:OrganizationId"`
	Interests      []Interest   `gorm:"many2many:concert_interests;"`
	// ConcertCategories []ConcertCategory `gorm:"many2many:concert_categories"`
	ConcertCategories []ConcertCategory `gorm:"foreignKey:ConcertId"`
}
