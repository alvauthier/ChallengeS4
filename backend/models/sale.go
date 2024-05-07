package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Sale struct {
	gorm.Model
	ID         uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	FinalPrice float64   `gorm:"not null"`
	TicketSold TicketListing
	Buyer      User
	Seller     User
	CreatedAt  time.Time
	UpdatedAt  time.Time
}
