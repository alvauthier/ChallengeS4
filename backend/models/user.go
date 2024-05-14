package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type User struct {
	gorm.Model
	ID             uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	Email          string    `gorm:"unique;not null"`
	Password       string    `gorm:"not null"`
	Firstname      string    `gorm:"not null"`
	Lastname       string    `gorm:"not null"`
	Role           string    `gorm:"not null"`
	LastConnexion  time.Time
	CreatedAt      time.Time
	UpdatedAt      time.Time
	Tickets        []Ticket `gorm:"foreignKey:UserId"`
	OrganizationId uuid.UUID
	Organization   *Organization  `gorm:"foreignKey:OrganizationId"`
	Interests      []Interest     `gorm:"many2many:user_interests;"`
	Conversations  []Conversation `gorm:"foreignKey:BuyerId"`
	Messages       []Message      `gorm:"foreignKey:AuthorId"`
	SalesAsBuyer   []Sale         `gorm:"foreignKey:BuyerId"`
	SalesAsSeller  []Sale         `gorm:"foreignKey:SellerId"`
}
