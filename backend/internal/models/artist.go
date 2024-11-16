package models

import (
	"time"

	"github.com/google/uuid"
)

type Artist struct {
	// gorm.Model
	ID         uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	Name       string    `gorm:"unique;not null"`
	CreatedAt  time.Time
	UpdatedAt  time.Time
	DeletedAt  *time.Time `gorm:"index"`
	InterestId int
	Interest   *Interest `gorm:"foreignKey:InterestId"`
	Concerts   []Concert `gorm:"foreignKey:ArtistId"`
}
