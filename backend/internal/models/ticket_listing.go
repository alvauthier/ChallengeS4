package models

import (
	"time"

	"github.com/google/uuid"
)

type TicketListing struct {
	// gorm.Model
	// ID            uuid.UUID       `gorm:"unique;type:uuid;primaryKey;default:uuid_generate_v4()" json:"id"`
	// Price         float64         `gorm:"not null" json:"price"`
	// Status        string          `gorm:"not null" json:"status"`
	// CreatedAt     time.Time       `json:"createdAt"`
	// UpdatedAt     time.Time       `json:"updatedAt"`
	// DeletedAt     *time.Time      `gorm:"index"`
	// TicketId      uuid.UUID       `gorm:"not null" json:"ticketId"`
	ID            uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	Price         float64   `gorm:"not null"`
	Status        string    `gorm:"not null"`
	CreatedAt     time.Time
	UpdatedAt     time.Time
	DeletedAt     *time.Time      `gorm:"index"`
	TicketId      uuid.UUID       `gorm:"not null;uniqueIndex"`
	Ticket        Ticket          `gorm:"foreignKey:TicketId" json:"-"`
	Conversations *[]Conversation `gorm:"foreignKey:TicketListingId"`
	Sale          *Sale           `gorm:"foreignKey:TicketListingId"`
}
