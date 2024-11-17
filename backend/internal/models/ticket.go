package models

import (
	"time"

	"github.com/google/uuid"
)

type Ticket struct {
	// gorm.Model
	ID                uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	CreatedAt         time.Time
	UpdatedAt         time.Time
	DeletedAt         *time.Time `gorm:"index"`
	UserId            uuid.UUID
	User              User `gorm:"foreignKey:UserId"`
	ConcertCategoryId uuid.UUID
	ConcertCategory   ConcertCategory `gorm:"foreignKey:ConcertCategoryId"`
	TicketListings     *[]TicketListing  `gorm:"foreignKey:TicketId"`
	MaxPrice         float64   `gorm:"not null"`
}
