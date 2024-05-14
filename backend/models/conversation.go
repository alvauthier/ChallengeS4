package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Conversation struct {
	gorm.Model
	ID              uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	CreatedAt       time.Time
	UpdatedAt       time.Time
	Messages        []Message `gorm:"foreignKey:ConversationId"`
	BuyerId         uuid.UUID
	Buyer           User `gorm:"foreignKey:BuyerId"`
	TicketListingId uuid.UUID
	TicketListing   TicketListing `gorm:"foreignKey:TicketListingId"`
}
