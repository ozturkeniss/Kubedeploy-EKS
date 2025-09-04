package main

import (
	"kubedeploy-eks/api/proto/user"
	"kubedeploy-eks/internal/user/grpc"
	"kubedeploy-eks/internal/user/handler"
	"kubedeploy-eks/internal/user/model"
	"kubedeploy-eks/internal/user/repository"
	"kubedeploy-eks/internal/user/service"
	"kubedeploy-eks/pkg/config"
	"kubedeploy-eks/pkg/database"
	"log"
	"net"

	"github.com/gin-gonic/gin"
	grpcServer "google.golang.org/grpc"
)

func main() {
	// Load configuration
	cfg := config.LoadConfig()

	// Connect to database
	db := database.NewConnection(cfg.DatabaseURL)

	// Auto migrate the schema
	if err := db.AutoMigrate(&model.User{}); err != nil {
		log.Fatal("Failed to migrate database:", err)
	}

	// Initialize repository, service, and handler
	userRepo := repository.NewUserRepository(db)
	userService := service.NewUserService(userRepo)
	userHandler := handler.NewUserHandler(userService)

	// Start gRPC server in a goroutine
	go func() {
		lis, err := net.Listen("tcp", ":9091")
		if err != nil {
			log.Fatal("Failed to listen on port 9091:", err)
		}

		grpcSrv := grpcServer.NewServer()
		userGRPCServer := grpc.NewUserGRPCServer(userService)
		user.RegisterUserServiceServer(grpcSrv, userGRPCServer)

		log.Println("Starting gRPC server on port 9091")
		if err := grpcSrv.Serve(lis); err != nil {
			log.Fatal("Failed to start gRPC server:", err)
		}
	}()

	// Initialize Gin router
	router := gin.Default()

	// Register routes
	userHandler.RegisterRoutes(router)

	// Health check endpoint
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "healthy"})
	})

	// Start HTTP server
	log.Printf("Starting HTTP server on port %s", cfg.Port)
	if err := router.Run(":" + cfg.Port); err != nil {
		log.Fatal("Failed to start HTTP server:", err)
	}
}
