package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type TicketListing struct {
	gorm.Model
	ID            uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	Price         float64   `gorm:"not null"`
	Status        string    `gorm:"not null"`
	CreatedAt     time.Time
	UpdatedAt     time.Time
	TicketId      uuid.UUID
	Ticket        Ticket          `gorm:"foreignKey:TicketId"`
	Conversations *[]Conversation `gorm:"foreignKey:TicketListingId"`
	Sale          *Sale           `gorm:"foreignKey:TicketListingId"`
}
