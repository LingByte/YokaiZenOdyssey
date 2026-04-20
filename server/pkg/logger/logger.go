package logger

import (
	"github.com/natefinch/lumberjack"
	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
	"os"
)

type LogConfig struct {
	Level      string `yaml:"level"`
	Filename   string `yaml:"filename"`
	MaxSize    int    `yaml:"max_size"`
	MaxAge     int    `yaml:"max_age"`
	MaxBackups int    `yaml:"max_backups"`
}

var lg *zap.Logger

// Init 初始化lg
func Init(cfg *LogConfig) (err error) {
	writeSyncer := getLogWriter(cfg.Filename, cfg.MaxSize, cfg.MaxBackups, cfg.MaxAge)
	encoder := getEncoder()
	var l = new(zapcore.Level)
	err = l.UnmarshalText([]byte(cfg.Level))
	if err != nil {
		return
	}
	var core zapcore.Core
	consoleEncoder := zapcore.NewConsoleEncoder(zap.NewDevelopmentEncoderConfig())
	core = zapcore.NewTee(
		zapcore.NewCore(encoder, writeSyncer, l),
		zapcore.NewCore(consoleEncoder, zapcore.Lock(os.Stdout), zapcore.DebugLevel),
	)
	lg = zap.New(core, zap.AddCaller()) // zap.AddCaller() 添加调用栈信息
	zap.ReplaceGlobals(lg)              // 替换zap包全局的logger
	Info("init logger success")
	return
}

func getEncoder() zapcore.Encoder {
	encoderConfig := zap.NewProductionEncoderConfig()
	encoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder
	encoderConfig.TimeKey = "time"
	encoderConfig.EncodeLevel = zapcore.CapitalLevelEncoder
	encoderConfig.EncodeDuration = zapcore.SecondsDurationEncoder
	encoderConfig.EncodeCaller = zapcore.ShortCallerEncoder
	return zapcore.NewJSONEncoder(encoderConfig)
}

func getLogWriter(filename string, maxSize, maxBackup, maxAge int) zapcore.WriteSyncer {
	lumberJackLogger := &lumberjack.Logger{
		Filename:   filename,
		MaxSize:    maxSize,
		MaxBackups: maxBackup,
		MaxAge:     maxAge,
	}
	return zapcore.AddSync(lumberJackLogger)
}

// Info 通用 info 日志方法
func Info(msg string, fields ...zap.Field) {
	lg.Info(msg, fields...)
}

// Warn 通用 warn 日志方法
func Warn(msg string, fields ...zap.Field) {
	lg.Warn(msg, fields...)
}

// Error 通用 error 日志方法
func Error(msg string, fields ...zap.Field) {
	lg.Error(msg, fields...)
}

// Debug 通用 debug 日志方法
func Debug(msg string, fields ...zap.Field) {
	lg.Debug(msg, fields...)
}

// Fatal 通用 fatal 日志方法
func Fatal(msg string, fields ...zap.Field) {
	lg.Fatal(msg, fields...)
}

// Panic 通用 panic 日志方法
func Panic(msg string, fields ...zap.Field) {
	lg.Panic(msg, fields...)
}

// Sync 刷新缓冲区
func Sync() {
	_ = lg.Sync()
}
