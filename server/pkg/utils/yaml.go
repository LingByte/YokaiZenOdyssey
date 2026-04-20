package utils

import (
	"fmt"
	"os"

	"gopkg.in/yaml.v3"
)

func UnmarshalYAML(data []byte, out any) error {
	if out == nil {
		return fmt.Errorf("out must not be nil")
	}
	if err := yaml.Unmarshal(data, out); err != nil {
		return fmt.Errorf("yaml unmarshal: %w", err)
	}
	return nil
}

func UnmarshalYAMLString(s string, out any) error {
	return UnmarshalYAML([]byte(s), out)
}

func LoadYAMLFile(path string, out any) error {
	b, err := os.ReadFile(path)
	if err != nil {
		return fmt.Errorf("read yaml file %s: %w", path, err)
	}
	return UnmarshalYAML(b, out)
}
