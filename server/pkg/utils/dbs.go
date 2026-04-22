package utils

import (
	"fmt"
	"gorm.io/gorm"
	"io"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"

	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm/logger"
)

const (
	ENVDBDriver = "DB_DRIVER"
	ENVDSN      = "DB_DSN"
)

func InitDatabase(logWrite io.Writer, driver, dsn string) (*gorm.DB, error) {
	if driver == "" {
		driver = strings.TrimSpace(os.Getenv(ENVDBDriver))
	}
	if dsn == "" {
		dsn = strings.TrimSpace(os.Getenv(ENVDSN))
	}
	if driver == "" {
		return nil, fmt.Errorf("db driver is empty")
	}
	if dsn == "" {
		return nil, fmt.Errorf("db dsn is empty")
	}

	var newLogger logger.Interface
	if logWrite == nil {
		logWrite = os.Stdout
	}

	newLogger = logger.New(
		log.New(logWrite, "\r\n", log.LstdFlags), // io writer
		logger.Config{
			SlowThreshold:             time.Second, // Slow SQL threshold
			LogLevel:                  logger.Warn, // Log level
			IgnoreRecordNotFoundError: true,        // Ignore ErrRecordNotFound error for logger
			Colorful:                  false,       // Disable color
		},
	)

	cfg := &gorm.Config{
		Logger:                 newLogger,
		SkipDefaultTransaction: true,
	}
	return createDatabaseInstance(cfg, driver, dsn)
}

func MakeMigrates(db *gorm.DB, insts []any) error {
	for _, v := range insts {
		if err := db.AutoMigrate(v); err != nil {
			return err
		}
	}
	return nil
}

// SeedDatabase 执行 migrations 文件夹下的 SQL 种子数据文件
func SeedDatabase(db *gorm.DB, migrationsPath string) error {
	// 查找所有 .sql 文件
	files, err := filepath.Glob(filepath.Join(migrationsPath, "*.sql"))
	if err != nil {
		return fmt.Errorf("failed to find SQL files: %w", err)
	}

	if len(files) == 0 {
		log.Println("No SQL seed files found in migrations folder")
		return nil
	}

	// 按文件名排序执行
	for _, file := range files {
		log.Printf("Executing seed file: %s", file)
		
		// 读取 SQL 文件内容
		sqlContent, err := os.ReadFile(file)
		if err != nil {
			return fmt.Errorf("failed to read seed file %s: %w", file, err)
		}

		// 分割 SQL 语句（按分号分隔）
		sqlStatements := strings.Split(string(sqlContent), ";")
		
		for _, stmt := range sqlStatements {
			stmt = strings.TrimSpace(stmt)
			if stmt == "" || strings.HasPrefix(stmt, "--") {
				continue
			}

			// 执行 SQL 语句
			if err := db.Exec(stmt).Error; err != nil {
				// 如果是重复插入错误，可以忽略（种子数据可能已存在）
				if strings.Contains(err.Error(), "UNIQUE constraint") || 
				   strings.Contains(err.Error(), "duplicate") {
					log.Printf("Skipping duplicate data in %s: %v", file, err)
					continue
				}
				return fmt.Errorf("failed to execute SQL statement from %s: %w", file, err)
			}
		}
		
		log.Printf("Successfully executed seed file: %s", file)
	}

	return nil
}

// SeedUsers 程序化种子用户数据（使用 bcrypt 加密密码）
func SeedUsers(db *gorm.DB) error {
	type User struct {
		ID        uint      `gorm:"primaryKey"`
		Username  string    `gorm:"uniqueIndex;size:50;not null"`
		Password  string    `gorm:"size:255;not null"`
		Email     string    `gorm:"uniqueIndex;size:100"`
		Nickname  string    `gorm:"size:50"`
		Avatar    string    `gorm:"size:255"`
		Status    int       `gorm:"default:1"`
		CreatedAt time.Time
		UpdatedAt time.Time
	}

	// 检查用户是否已存在
	var count int64
	db.Model(&User{}).Count(&count)
	if count > 0 {
		log.Println("Users already exist, skipping seed")
		return nil
	}

	// 生成密码哈希
	adminPassword, err := bcrypt.GenerateFromPassword([]byte("admin123"), bcrypt.DefaultCost)
	if err != nil {
		return fmt.Errorf("failed to hash admin password: %w", err)
	}

	userPassword, err := bcrypt.GenerateFromPassword([]byte("user123"), bcrypt.DefaultCost)
	if err != nil {
		return fmt.Errorf("failed to hash user password: %w", err)
	}

	// 创建用户
	users := []User{
		{
			Username: "admin",
			Password: string(adminPassword),
			Email:    "admin@example.com",
			Nickname: "管理员",
			Status:   1,
		},
		{
			Username: "testuser",
			Password: string(userPassword),
			Email:    "user@example.com",
			Nickname: "测试用户",
			Status:   1,
		},
	}

	for _, user := range users {
		if err := db.Create(&user).Error; err != nil {
			return fmt.Errorf("failed to create user %s: %w", user.Username, err)
		}
		log.Printf("Created user: %s (password: %s)", user.Username, 
			map[string]string{"admin": "admin123", "testuser": "user123"}[user.Username])
	}

	log.Println("Seed users completed successfully")
	return nil
}
