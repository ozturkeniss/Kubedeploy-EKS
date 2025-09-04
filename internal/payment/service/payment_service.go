package service

import (
	"context"
	"errors"
	"kubedeploy-eks/internal/payment/client"
	"kubedeploy-eks/internal/payment/model"
	"kubedeploy-eks/internal/payment/repository"

	"gorm.io/gorm"
)

type PaymentService interface {
	CreatePayment(req *model.CreatePaymentRequest) (*model.PaymentResponse, error)
	GetPaymentByID(id uint) (*model.PaymentResponse, error)
	GetUserPayments(userID uint) ([]model.PaymentResponse, error)
	GetAllPayments() ([]model.PaymentResponse, error)
}

type paymentService struct {
	repo       repository.PaymentRepository
	userClient *client.UserClient
}

func NewPaymentService(repo repository.PaymentRepository, userServiceAddr string) PaymentService {
	userClient := client.NewUserClient(userServiceAddr)

	return &paymentService{
		repo:       repo,
		userClient: userClient,
	}
}

func (s *paymentService) CreatePayment(req *model.CreatePaymentRequest) (*model.PaymentResponse, error) {
	// Validate user exists via gRPC
	_, err := s.userClient.GetUser(context.Background(), req.UserID)
	if err != nil {
		return nil, errors.New("user not found")
	}

	payment := &model.Payment{
		UserID:      req.UserID,
		Amount:      req.Amount,
		Currency:    req.Currency,
		Description: req.Description,
		Status:      "pending",
	}

	if err := s.repo.Create(payment); err != nil {
		return nil, err
	}

	return s.paymentToResponse(payment), nil
}

func (s *paymentService) GetPaymentByID(id uint) (*model.PaymentResponse, error) {
	payment, err := s.repo.GetByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("payment not found")
		}
		return nil, err
	}

	return s.paymentToResponse(payment), nil
}

func (s *paymentService) GetUserPayments(userID uint) ([]model.PaymentResponse, error) {
	// Validate user exists via gRPC
	_, err := s.userClient.GetUser(context.Background(), userID)
	if err != nil {
		return nil, errors.New("user not found")
	}

	payments, err := s.repo.GetByUserID(userID)
	if err != nil {
		return nil, err
	}

	var responses []model.PaymentResponse
	for _, payment := range payments {
		responses = append(responses, *s.paymentToResponse(&payment))
	}

	return responses, nil
}

func (s *paymentService) GetAllPayments() ([]model.PaymentResponse, error) {
	payments, err := s.repo.GetAll()
	if err != nil {
		return nil, err
	}

	var responses []model.PaymentResponse
	for _, payment := range payments {
		responses = append(responses, *s.paymentToResponse(&payment))
	}

	return responses, nil
}

func (s *paymentService) paymentToResponse(payment *model.Payment) *model.PaymentResponse {
	return &model.PaymentResponse{
		ID:          payment.ID,
		UserID:      payment.UserID,
		Amount:      payment.Amount,
		Currency:    payment.Currency,
		Description: payment.Description,
		Status:      payment.Status,
		CreatedAt:   payment.CreatedAt,
		UpdatedAt:   payment.UpdatedAt,
	}
}
