package client

import (
	"context"
	"kubedeploy-eks/api/proto/user"
	"log"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

type UserClient struct {
	client user.UserServiceClient
}

func NewUserClient(serverAddr string) *UserClient {
	conn, err := grpc.NewClient(serverAddr, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatal("Failed to connect to user service:", err)
	}

	client := user.NewUserServiceClient(conn)
	return &UserClient{client: client}
}

func (c *UserClient) GetUser(ctx context.Context, userID uint) (*user.GetUserResponse, error) {
	return c.client.GetUser(ctx, &user.GetUserRequest{
		Id: uint32(userID),
	})
}

func (c *UserClient) GetUserByEmail(ctx context.Context, email string) (*user.GetUserResponse, error) {
	return c.client.GetUserByEmail(ctx, &user.GetUserByEmailRequest{
		Email: email,
	})
}
