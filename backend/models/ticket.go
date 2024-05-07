package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Ticket struct {
	gorm.Model
	ID              uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	CreatedAt       time.Time
	UpdatedAt       time.Time
	Owner           User
	ConcertCategory ConcertCategory
	TicketListing   *TicketListing
}
