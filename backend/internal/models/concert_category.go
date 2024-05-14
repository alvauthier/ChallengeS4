package models

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type ConcertCategory struct {
	gorm.Model
	ID         uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	ConcertId  uuid.UUID `gorm:"type:uuid;not null"`
	CategoryId int       `gorm:"not null"`
	NbTickets  int       `gorm:"not null"`
	Price      float64   `gorm:"not null"`
	Tickets    []Ticket
	Concert    Concert  `gorm:"foreignKey:ConcertId"`
	Category   Category `gorm:"foreignKey:CategoryId"`
}
