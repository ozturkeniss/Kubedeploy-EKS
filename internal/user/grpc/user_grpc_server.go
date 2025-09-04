package grpc

import (
	"context"
	"kubedeploy-eks/api/proto/user"
	"kubedeploy-eks/internal/user/service"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

type UserGRPCServer struct {
	user.UnimplementedUserServiceServer
	userService service.UserService
}

func NewUserGRPCServer(userService service.UserService) *UserGRPCServer {
	return &UserGRPCServer{
		userService: userService,
	}
}

func (s *UserGRPCServer) GetUser(ctx context.Context, req *user.GetUserRequest) (*user.GetUserResponse, error) {
	userResp, err := s.userService.GetUserByID(uint(req.Id))
	if err != nil {
		return nil, status.Errorf(codes.NotFound, "user not found: %v", err)
	}

	return &user.GetUserResponse{
		Id:        uint32(userResp.ID),
		Username:  userResp.Username,
		Email:     userResp.Email,
		CreatedAt: userResp.CreatedAt.String(),
		UpdatedAt: userResp.UpdatedAt.String(),
	}, nil
}

func (s *UserGRPCServer) GetUserByEmail(ctx context.Context, req *user.GetUserByEmailRequest) (*user.GetUserResponse, error) {
	userResp, err := s.userService.GetUserByEmail(req.Email)
	if err != nil {
		return nil, status.Errorf(codes.NotFound, "user not found: %v", err)
	}

	return &user.GetUserResponse{
		Id:        uint32(userResp.ID),
		Username:  userResp.Username,
		Email:     userResp.Email,
		CreatedAt: userResp.CreatedAt.String(),
		UpdatedAt: userResp.UpdatedAt.String(),
	}, nil
}
