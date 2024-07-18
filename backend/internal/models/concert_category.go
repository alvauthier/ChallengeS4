package models

import (
	"time"

	"github.com/google/uuid"
)

type ConcertCategory struct {
	// gorm.Model
	ID               uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	ConcertId        uuid.UUID `gorm:"type:uuid;not null;index"`
	CategoryId       int       `gorm:"not null;index"`
	AvailableTickets int       `gorm:"not null"`
	SoldTickets      int
	Price            float64 `gorm:"not null"`
	Tickets          []Ticket
	// Tickets          []Ticket `gorm:"-"`
	Concert   Concert  `gorm:"foreignKey:ConcertId"`
	Category  Category `gorm:"foreignKey:CategoryId"`
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt *time.Time `gorm:"index"`
}
