package controller

import (
	"context"
	"fmt"
	"strings"
	"weezemaster/internal/config"

	"firebase.google.com/go/messaging"
)

func sanitizeTopicName(topic string) string {
	return strings.ReplaceAll(strings.ToLower(topic), " ", "_")
}

func SendFCMNotification(topic string, data map[string]string, notification map[string]string) error {
	fmt.Println("Sending FCM notification")
	fmt.Println("Topic reçu dans notification.go :", topic)
	client, err := config.FirebaseApp.Messaging(context.Background())
	if err != nil {
		return fmt.Errorf("error getting Messaging client: %v", err)
	}

	message := &messaging.Message{
		Topic: sanitizeTopicName(topic),
		Data:  data,
		Notification: &messaging.Notification{
			Title: notification["title"],
			Body:  notification["body"],
		},
	}

	response, err := client.Send(context.Background(), message)
	if err != nil {
		return fmt.Errorf("error sending FCM message: %v", err)
	}
	fmt.Printf("Successfully sent message: %s\n", response)
	return nil
}
