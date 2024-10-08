package models

import (
	"time"
)

type Interest struct {
	// gorm.Model
	ID        int       `gorm:"unique;primaryKey"`
	Name      string    `gorm:"unique;not null"`
	Users     []User    `gorm:"many2many:user_interests;constraint:OnDelete:CASCADE;"`
	Concerts  []Concert `gorm:"many2many:concert_interests;"`
	CreatedAt time.Time
	UpdatedAt time.Time
	DeletedAt *time.Time `gorm:"index"`
}
