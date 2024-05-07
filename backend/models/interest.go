package models

import (
	"gorm.io/gorm"
)

type Interest struct {
	gorm.Model
	ID       int       `gorm:"unique;primaryKey"`
	Name     string    `gorm:"unique;not null"`
	Users    []User    `gorm:"many2many:user_interests;"`
	Concerts []Concert `gorm:"many2many:concert_interests;"`
}
