package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Conversation struct {
	gorm.Model
	ID            uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	CreatedAt     time.Time
	UpdatedAt     time.Time
	Messages      []Message
	Buyer         User
	TicketListing TicketListing
}
