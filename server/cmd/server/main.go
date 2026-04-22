package main

import (
	"flag"
	"fmt"
	"github.com/LingByte/YokaiZenOdyssey/internal/handlers"
	"github.com/LingByte/YokaiZenOdyssey/internal/models"
	"github.com/LingByte/YokaiZenOdyssey/pkg/logger"
	"github.com/LingByte/YokaiZenOdyssey/pkg/middleware"
	"github.com/gin-gonic/gin"
	"go.uber.org/zap"
	"gorm.io/gorm"
	"log"
	"os"

	"github.com/LingByte/YokaiZenOdyssey/pkg/config"
	"github.com/LingByte/YokaiZenOdyssey/pkg/utils"
)

type YokaiZenOdysseyApp struct {
	db *gorm.DB
}

func NewYokaiZenOdysseyApp(db *gorm.DB) *YokaiZenOdysseyApp {
	return &YokaiZenOdysseyApp{
		db: db,
	}
}

func (app *YokaiZenOdysseyApp) RegisterRoutes(r *gin.Engine) {
	// 创建用户处理器
	userHandler := handlers.NewUserHandler(app.db)
	
	// 注册用户路由
	userHandler.RegisterRoutes(r)

	// 创建存档处理器
	saveHandler := handlers.NewSaveHandler(app.db)
	
	// 注册存档路由
	saveHandler.RegisterRoutes(r)
}

func main() {
	mode := flag.String("mode", "development", "running environment (development, test, production)")
	flag.Parse()
	cfg, err := config.Load(*mode)
	if err != nil {
		log.Fatalf("load config: %v", err)
	}

	db, err := utils.InitDatabase(os.Stdout, cfg.Database.Type, cfg.Database.DSN)
	if err != nil {
		log.Fatalf("init database: %v", err)
	}

	err = logger.Init(&cfg.Log)
	if err != nil {
		panic(err)
	}

	err = utils.MakeMigrates(db, []any{&models.User{}, &models.SaveGame{}})
	if err != nil {
		logger.Error("migration failed: ", zap.Error(err))
	} else {
		logger.Info("migration success", zap.String("database", cfg.Database.Type))
	}

	// 执行种子用户数据初始化
	err = utils.SeedUsers(db)
	if err != nil {
		logger.Error("seed users failed: ", zap.Error(err))
	} else {
		logger.Info("seed users success")
	}

	app := NewYokaiZenOdysseyApp(db)
	gin.SetMode(gin.DebugMode)
	r := gin.Default()

	// Cors Handle Middleware
	r.Use(middleware.CorsMiddleware())

	// Logger Handle Middleware
	r.Use(middleware.LoggerMiddleware(zap.L()))

	// RateLimit Middleware
	r.Use(middleware.RateLimiterMiddleware())

	app.RegisterRoutes(r)

	logger.Info(fmt.Sprintf("%s (%s) starting on port %d\n", cfg.Project.Name, cfg.Mode, cfg.Port))
	if err := r.Run(fmt.Sprintf(":%d", cfg.Port)); err != nil {
		logger.Error("server run failed", zap.Error(err))
	}
}
