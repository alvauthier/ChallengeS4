package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Sale struct {
	gorm.Model
	ID              uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	FinalPrice      float64   `gorm:"not null"`
	TicketListingId uuid.UUID
	TicketSold      TicketListing `gorm:"foreignKey:TicketListingId"`
	BuyerId         uuid.UUID
	SellerId        uuid.UUID
	Buyer           User `gorm:"foreignKey:BuyerId"`
	Seller          User `gorm:"foreignKey:SellerId"`
	CreatedAt       time.Time
	UpdatedAt       time.Time
}
