package models

import (
	"time"

	"github.com/google/uuid"
)

// User représente un utilisateur
// swagger:model
type User struct {
	// gorm.Model
	// l'ID de l'utilisateur
	//
	// required: true
	// example: 123e4567-e89b-12d3-a456-426614174000
	ID uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	// l'email de l'utilisateur
	//
	// required: true
	// example: john@doe.com
	Email    string `gorm:"unique;not null" json:"email"`
	Password string `gorm:"not null" json:"-"`
	// le prénom de l'utilisateur
	//
	// required: true
	// example: John
	Firstname string `gorm:"not null"`
	// le nom de l'utilisateur
	//
	// required: true
	// example: Doe
	Lastname              string `gorm:"not null"`
	Role                  string `gorm:"not null;default:user"`
	Image                 string
	LastConnexion         time.Time
	CreatedAt             time.Time
	UpdatedAt             time.Time
	DeletedAt             *time.Time `gorm:"index"`
	Tickets               []Ticket   `gorm:"foreignKey:UserId"`
	OrganizationId        uuid.UUID
	Organization          *Organization  `gorm:"foreignKey:OrganizationId"`
	Interests             []Interest     `gorm:"many2many:user_interests;constraint:OnDelete:CASCADE;"`
	ConversationsAsBuyer  []Conversation `gorm:"foreignKey:BuyerId"`
	ConversationsAsSeller []Conversation `gorm:"foreignKey:SellerId"`
	Messages              []Message      `gorm:"foreignKey:AuthorId"`
	SalesAsBuyer          []Sale         `gorm:"foreignKey:BuyerId"`
	SalesAsSeller         []Sale         `gorm:"foreignKey:SellerId"`
	ResetCode             string         `json:"-"`
	ResetCodeExpiration   time.Time
}
