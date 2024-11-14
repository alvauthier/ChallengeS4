package models

import (
	"time"

	"github.com/google/uuid"
)

type Organization struct {
	// gorm.Model
	ID          uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	Name        string    `gorm:"unique;not null"`
	Description string    `gorm:"not null"`
	Image       string
	CreatedAt   time.Time
	UpdatedAt   time.Time
	DeletedAt   *time.Time `gorm:"index"`
	Users       []User     `gorm:"foreignKey:OrganizationId"`
	Concerts    []Concert  `gorm:"foreignKey:OrganizationId"`
}
