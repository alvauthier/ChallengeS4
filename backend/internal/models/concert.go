package models

import (
	"time"

	"github.com/google/uuid"
)

type Concert struct {
	// gorm.Model
	ID                uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	Name              string    `gorm:"not null"`
	Description       string    `gorm:"not null"`
	Location          string    `gorm:"not null"`
	Date              time.Time `gorm:"not null"`
	Image             string
	CreatedAt         time.Time
	UpdatedAt         time.Time
	DeletedAt         *time.Time        `gorm:"index"`
	OrganizationId    uuid.UUID         `gorm:"not null"`
	Organization      *Organization     `gorm:"not null;foreignKey:OrganizationId"`
	Interests         []Interest        `gorm:"many2many:concert_interests;"`
	ConcertCategories []ConcertCategory `gorm:"foreignKey:ConcertId"`
}
