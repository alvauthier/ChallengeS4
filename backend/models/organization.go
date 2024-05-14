package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Organization struct {
	gorm.Model
	ID          uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	Name        string    `gorm:"unique;not null"`
	Description string    `gorm:"not null"`
	CreatedAt   time.Time
	UpdatedAt   time.Time
	Users       []User    `gorm:"foreignKey:OrganizationId"`
	Concerts    []Concert `gorm:"foreignKey:OrganizationId"`
}
