package repository

import (
	"kubedeploy-eks/internal/user/model"

	"gorm.io/gorm"
)

type UserRepository interface {
	Create(user *model.User) error
	GetByID(id uint) (*model.User, error)
	GetByEmail(email string) (*model.User, error)
	GetByUsername(username string) (*model.User, error)
	Update(user *model.User) error
	Delete(id uint) error
	GetAll() ([]model.User, error)
}

type userRepository struct {
	db *gorm.DB
}

func NewUserRepository(db *gorm.DB) UserRepository {
	return &userRepository{db: db}
}

func (r *userRepository) Create(user *model.User) error {
	return r.db.Create(user).Error
}

func (r *userRepository) GetByID(id uint) (*model.User, error) {
	var user model.User
	err := r.db.First(&user, id).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) GetByEmail(email string) (*model.User, error) {
	var user model.User
	err := r.db.Where("email = ?", email).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) GetByUsername(username string) (*model.User, error) {
	var user model.User
	err := r.db.Where("username = ?", username).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) Update(user *model.User) error {
	return r.db.Save(user).Error
}

func (r *userRepository) Delete(id uint) error {
	return r.db.Delete(&model.User{}, id).Error
}

func (r *userRepository) GetAll() ([]model.User, error) {
	var users []model.User
	err := r.db.Find(&users).Error
	return users, err
}
