//go:build !mysql && !pg

package utils

import (
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func createDatabaseInstance(cfg *gorm.Config, driver, dsn string) (*gorm.DB, error) {
	if dsn == "" {
		dsn = "file::memory:"
	}
	return gorm.Open(sqlite.Open(dsn), cfg)
}
