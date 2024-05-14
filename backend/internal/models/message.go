package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Message struct {
	gorm.Model
	ID             uuid.UUID `gorm:"unique;type:uuid;primaryKey"`
	Content        string    `gorm:"not null"`
	Readed         bool      `gorm:"not null"`
	AuthorId       uuid.UUID
	Author         User `gorm:"foreignKey:AuthorId"`
	SentAt         time.Time
	ConversationId uuid.UUID
	Conversation   Conversation `gorm:"foreignKey:ConversationId"`
}
