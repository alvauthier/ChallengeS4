package models

import (
	"time"

	"github.com/google/uuid"
)

type ConcertCategory struct {
	// gorm.Model
	ID               uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	ConcertId        uuid.UUID `gorm:"type:uuid;not null;uniqueIndex:idx_concert_category"`
	CategoryId       int       `gorm:"not null;uniqueIndex:idx_concert_category"`
	AvailableTickets int       `gorm:"not null;uniqueIndex:idx_concert_category"`
	SoldTickets      int       `gorm:"uniqueIndex:idx_concert_category"`
	Price            float64   `gorm:"not null;uniqueIndex:idx_concert_category"`
	Tickets          []Ticket  `gorm:"-"`
	Concert          Concert   `gorm:"foreignKey:ConcertId" json:"-"`
	Category         Category  `gorm:"foreignKey:CategoryId" json:"-"`
	CreatedAt        time.Time
	UpdatedAt        time.Time
	DeletedAt        *time.Time `gorm:"index"`
}
