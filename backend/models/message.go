package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Message struct {
	gorm.Model
	ID           uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	Content      string    `gorm:"not null"`
	Readed       bool      `gorm:"not null"`
	Author       User
	SentAt       time.Time
	Conversation Conversation
}
