package utils

import (
	"fmt"
	"gorm.io/gorm"
	"io"
	"log"
	"os"
	"strings"
	"time"

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
