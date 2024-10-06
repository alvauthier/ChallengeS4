package models

import (
	"time"

	"github.com/google/uuid"
)

type Conversation struct {
	// gorm.Model
	ID              uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	CreatedAt       time.Time
	UpdatedAt       time.Time
	DeletedAt       *time.Time `gorm:"index"`
	Messages        []Message  `gorm:"foreignKey:ConversationId"`
	BuyerId         uuid.UUID
	Buyer           User `gorm:"foreignKey:BuyerId"`
	SellerId        uuid.UUID
	Seller          User `gorm:"foreignKey:SellerId"`
	TicketListingId uuid.UUID
	TicketListing   TicketListing `gorm:"foreignKey:TicketListingId"`
	Price           float64       `gorm:"not null"`
}
