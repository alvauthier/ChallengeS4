package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Ticket struct {
	gorm.Model
	ID                uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	CreatedAt         time.Time
	UpdatedAt         time.Time
	UserId            uuid.UUID
	User              User `gorm:"foreignKey:UserId"`
	ConcertCategoryId uuid.UUID
	ConcertCategory   ConcertCategory `gorm:"foreignKey:ConcertCategoryId"`
	TicketListing     *TicketListing  `gorm:"foreignKey:TicketId"`
}
