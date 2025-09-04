package main

import (
	"kubedeploy-eks/internal/payment/handler"
	"kubedeploy-eks/internal/payment/model"
	"kubedeploy-eks/internal/payment/repository"
	"kubedeploy-eks/internal/payment/service"
	"kubedeploy-eks/pkg/config"
	"kubedeploy-eks/pkg/database"
	"log"
	"os"

	"github.com/gin-gonic/gin"
)

func main() {
	// Load configuration
	cfg := config.LoadConfig()

	// Connect to database (using same database for simplicity)
	db := database.NewConnection(cfg.DatabaseURL)

	// Auto migrate the schema
	if err := db.AutoMigrate(&model.Payment{}); err != nil {
		log.Fatal("Failed to migrate database:", err)
	}

	// Initialize repository, service, and handler
	paymentRepo := repository.NewPaymentRepository(db)
	userServiceAddr := getEnv("USER_SERVICE_GRPC", "localhost:9091")
	paymentService := service.NewPaymentService(paymentRepo, userServiceAddr) // gRPC connection to user service
	paymentHandler := handler.NewPaymentHandler(paymentService)

	// Initialize Gin router
	router := gin.Default()

	// Register routes
	paymentHandler.RegisterRoutes(router)

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "healthy"})
	})

	// Start server on a different port
	port := "8081"
	log.Printf("Starting payment service on port %s", port)
	if err := router.Run(":" + port); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
