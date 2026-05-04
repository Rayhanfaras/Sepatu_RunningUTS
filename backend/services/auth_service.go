package services

import (
	"context"
	"errors"
	"os"
	"strconv"
	"time"

	"github.com/Rayhanfaras/Sepatu_RunningUTS/config"
	"github.com/Rayhanfaras/Sepatu_RunningUTS/models"
	"github.com/Rayhanfaras/Sepatu_RunningUTS/repositories"
	"github.com/golang-jwt/jwt/v5"
	"gorm.io/gorm"
)

type AuthService struct {
	userRepo *repositories.UserRepository
}

func NewAuthService() *AuthService {
	return &AuthService{
		userRepo: repositories.NewUserRepository(),
	}
}

func (s *AuthService) VerifyFirebaseToken(firebaseToken string) (string, *models.User, error) {

	// 1. VERIFY FIREBASE TOKEN
	token, err := config.FirebaseAuth.VerifyIDToken(context.Background(), firebaseToken)
	if err != nil {
		return "", nil, errors.New("firebase token tidak valid atau kadaluarsa")
	}

	// 2. CHECK EMAIL VERIFIED
	emailVerified, _ := token.Claims["email_verified"].(bool)
	if !emailVerified {
		return "", nil, errors.New("EMAIL_NOT_VERIFIED")
	}

	// 3. EXTRACT DATA
	uid := token.UID
	email, _ := token.Claims["email"].(string)
	name, _ := token.Claims["name"].(string)

	// 4. CARI USER BY FIREBASE UID
	user, err := s.userRepo.FindByFirebaseUID(uid)

	if errors.Is(err, gorm.ErrRecordNotFound) {

		// 🔥 5. CEK BY EMAIL (INI FIX UTAMA)
		existingUser, errEmail := s.userRepo.FindByEmail(email)

		if errEmail == nil {
			// USER SUDAH ADA → UPDATE LINK KE FIREBASE UID
			now := time.Now().Unix()

			existingUser.FirebaseUID = uid
			existingUser.LastLoginAt = &now
			existingUser.EmailVerified = true

			_ = s.userRepo.Update(existingUser)

			user = existingUser

		} else {
			// USER BENAR-BENAR BARU → CREATE
			now := time.Now().Unix()

			newUser := &models.User{
				FirebaseUID:   uid,
				Email:         email,
				Name:          name,
				Role:          "user",
				EmailVerified: true,
				LastLoginAt:   &now,
			}

			if err := s.userRepo.Create(newUser); err != nil {
				return "", nil, err
			}

			user = newUser
		}

	} else if err != nil {
		return "", nil, errors.New("error mengambil data user")
	} else {
		// USER SUDAH ADA BY FIREBASE UID → UPDATE LOGIN
		now := time.Now().Unix()

		user.LastLoginAt = &now
		user.EmailVerified = true

		_ = s.userRepo.Update(user)
	}

	// 6. GENERATE JWT BACKEND
	jwtToken, err := s.generateJWT(user)
	if err != nil {
		return "", nil, errors.New("gagal membuat token")
	}

	return jwtToken, user, nil
}

func (s *AuthService) generateJWT(user *models.User) (string, error) {

	expireHours, _ := strconv.Atoi(os.Getenv("JWT_EXPIRE_HOURS"))
	if expireHours == 0 {
		expireHours = 24
	}

	claims := jwt.MapClaims{
		"sub":            user.ID,
		"firebase_uid":   user.FirebaseUID,
		"email":          user.Email,
		"name":           user.Name,
		"role":           user.Role,
		"email_verified": user.EmailVerified,
		"iat":            time.Now().Unix(),
		"exp":            time.Now().Add(time.Hour * time.Duration(expireHours)).Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	return token.SignedString([]byte(os.Getenv("JWT_SECRET")))
}
