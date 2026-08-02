package config

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/LingByte/YokaiZenOdyssey/pkg/logger"
	"github.com/LingByte/YokaiZenOdyssey/pkg/utils"
)

var GlobalConfig *Config

type Config struct {
	Mode     string           `yaml:"mode"`
	Port     int              `yaml:"port"`
	Database DatabaseConfig   `yaml:"database"`
	Project  ProjectConfig    `yaml:"project"`
	Log      logger.LogConfig `yaml:"log"`
}

type DatabaseConfig struct {
	Type string `yaml:"type"`
	DSN  string `yaml:"dsn"`
}

type ProjectConfig struct {
	Name string     `yaml:"name"`
	Team TeamConfig `yaml:"team"`
}

type TeamConfig struct {
	Name    string   `yaml:"name"`
	Org     string   `yaml:"org"`
	Members []string `yaml:"members"`
}

func Load(mode string) (*Config, error) {
	path, _, err := resolveConfigPath(mode)
	if err != nil {
		return nil, err
	}

	var cfg Config
	if err := utils.LoadYAMLFile(path, &cfg); err != nil {
		return nil, fmt.Errorf("load config file %s: %w", path, err)
	}
	applyDefaults(&cfg, mode)
	if err := validate(&cfg); err != nil {
		return nil, err
	}
	GlobalConfig = &cfg
	return GlobalConfig, nil
}

func resolveConfigPath(mode string) (string, []string, error) {
	var candidates []string

	if mode != "" {
		candidates = []string{
			filepath.Join("config", fmt.Sprintf("application-%s.yaml", mode)),
			filepath.Join("config", fmt.Sprintf("application-%s.yml", mode)),
			fmt.Sprintf("application-%s.yaml", mode),
			fmt.Sprintf("application-%s.yml", mode),
		}
	} else {
		candidates = []string{
			filepath.Join("config", "application.yaml"),
			filepath.Join("config", "application.yml"),
			"application.yaml",
			"application.yml",
		}
	}

	tried := make([]string, 0, len(candidates))
	for _, p := range candidates {
		tried = append(tried, p)
		if _, err := os.Stat(p); err == nil {
			return p, tried, nil
		}
	}

	return "", tried, fmt.Errorf("config file not found for mode %s", mode)
}

func applyDefaults(cfg *Config, mode string) {
	if cfg.Mode == "" {
		if mode != "" {
			cfg.Mode = mode
		} else {
			cfg.Mode = "development"
		}
	}
	if cfg.Port == 0 {
		cfg.Port = 8080
	}
	if cfg.Database.Type == "" {
		cfg.Database.Type = "sqlite"
	}
	if cfg.Database.DSN == "" && strings.EqualFold(cfg.Database.Type, "sqlite") {
		cfg.Database.DSN = "yok.db"
	}
}

func validate(cfg *Config) error {
	if cfg.Mode == "" {
		return fmt.Errorf("config.mode is required")
	}
	if cfg.Port <= 0 {
		return fmt.Errorf("config.port must be > 0")
	}
	if cfg.Database.Type == "" {
		return fmt.Errorf("config.database.type is required")
	}
	if cfg.Database.DSN == "" {
		return fmt.Errorf("config.database.dsn is required")
	}
	if cfg.Project.Name == "" {
		return fmt.Errorf("config.project.name is required")
	}
	if cfg.Project.Team.Name == "" {
		return fmt.Errorf("config.project.team.name is required")
	}
	return nil
}
