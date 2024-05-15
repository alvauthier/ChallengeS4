package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ConcertCategory struct {
	gorm.Model
	ID         uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	ConcertId  uuid.UUID `gorm:"type:uuid;not null;uniqueIndex:idx_concert_category"`
	CategoryId int       `gorm:"not null;uniqueIndex:idx_concert_category"`
	NbTickets  int       `gorm:"not null;uniqueIndex:idx_concert_category"`
	Price      float64   `gorm:"not null;uniqueIndex:idx_concert_category"`
	Tickets    []Ticket
	Concert    Concert  `gorm:"foreignKey:ConcertId"`
	Category   Category `gorm:"foreignKey:CategoryId"`
}
