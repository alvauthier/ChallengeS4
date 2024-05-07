package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ConcertCategory struct {
	gorm.Model
	ID        uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	NbTickets int       `gorm:"not null"`
	Price     float64   `gorm:"not null"`
	Tickets   []Ticket
	Concert   Concert
	Category  Category
}
