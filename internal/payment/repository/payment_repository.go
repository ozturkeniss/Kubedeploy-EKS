package repository

import (
	"kubedeploy-eks/internal/payment/model"

	"gorm.io/gorm"
)

type PaymentRepository interface {
	Create(payment *model.Payment) error
	GetByID(id uint) (*model.Payment, error)
	GetByUserID(userID uint) ([]model.Payment, error)
	Update(payment *model.Payment) error
	Delete(id uint) error
	GetAll() ([]model.Payment, error)
}

type paymentRepository struct {
	db *gorm.DB
}

func NewPaymentRepository(db *gorm.DB) PaymentRepository {
	return &paymentRepository{db: db}
}

func (r *paymentRepository) Create(payment *model.Payment) error {
	return r.db.Create(payment).Error
}

func (r *paymentRepository) GetByID(id uint) (*model.Payment, error) {
	var payment model.Payment
	err := r.db.First(&payment, id).Error
	if err != nil {
		return nil, err
	}
	return &payment, nil
}

func (r *paymentRepository) GetByUserID(userID uint) ([]model.Payment, error) {
	var payments []model.Payment
	err := r.db.Where("user_id = ?", userID).Find(&payments).Error
	return payments, err
}

func (r *paymentRepository) Update(payment *model.Payment) error {
	return r.db.Save(payment).Error
}

func (r *paymentRepository) Delete(id uint) error {
	return r.db.Delete(&model.Payment{}, id).Error
}

func (r *paymentRepository) GetAll() ([]model.Payment, error) {
	var payments []model.Payment
	err := r.db.Find(&payments).Error
	return payments, err
}
