package main

import (
	"os"
	"strconv"
	"time"
)

// ServerConfig holds all configuration for the ServerTrack Satellites API
// This configuration is loaded from environment variables with secure defaults
type ServerConfig struct {
	// Server Configuration
	Port         string        `json:"port"`
	Host         string        `json:"host"`
	ReadTimeout  time.Duration `json:"read_timeout"`
	WriteTimeout time.Duration `json:"write_timeout"`
	IdleTimeout  time.Duration `json:"idle_timeout"`
	
	// Security Configuration
	MaxRequestSize int64 `json:"max_request_size"`
	
	// Deployment Configuration
	DeploymentQueueSize int    `json:"deployment_queue_size"`
	WorkerPoolSize      int    `json:"worker_pool_size"`
	ScriptPath          string `json:"script_path"`
	SitesDirectory      string `json:"sites_directory"`
	
	// Domain Configuration
	BaseDomain string `json:"base_domain"`
	
	// Logging Configuration
	LogLevel  string `json:"log_level"`
	LogFormat string `json:"log_format"`
}

// LoadConfig loads configuration from environment variables with secure defaults
func LoadConfig() *ServerConfig {
	config := &ServerConfig{
		// Server defaults - production ready
		Port:         getEnvOrDefault("PORT", "8080"),
		Host:         getEnvOrDefault("HOST", "0.0.0.0"),
		ReadTimeout:  getDurationEnvOrDefault("READ_TIMEOUT", 30*time.Second),
		WriteTimeout: getDurationEnvOrDefault("WRITE_TIMEOUT", 30*time.Second),
		IdleTimeout:  getDurationEnvOrDefault("IDLE_TIMEOUT", 120*time.Second),
		
		// Security defaults - hardened configuration
		MaxRequestSize: getInt64EnvOrDefault("MAX_REQUEST_SIZE", 1<<20), // 1MB
		
		// Deployment defaults - optimized for performance
		DeploymentQueueSize: getIntEnvOrDefault("DEPLOYMENT_QUEUE_SIZE", 100),
		WorkerPoolSize:      getIntEnvOrDefault("WORKER_POOL_SIZE", 4),
		ScriptPath:          getEnvOrDefault("DEPLOYMENT_SCRIPT", "/root/templates/quick-deploy.sh"),
		SitesDirectory:      getEnvOrDefault("SITES_DIRECTORY", "/etc/nginx/sites-available"),
		
		// Domain configuration - customizable per deployment
		BaseDomain: getEnvOrDefault("BASE_DOMAIN", "puritysalt.com"),
		
		// Logging defaults - structured production logging
		LogLevel:  getEnvOrDefault("LOG_LEVEL", "info"),
		LogFormat: getEnvOrDefault("LOG_FORMAT", "json"),
	}
	
	return config
}

// Helper functions for environment variable parsing with type safety
func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getIntEnvOrDefault(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		if parsed, err := strconv.Atoi(value); err == nil {
			return parsed
		}
	}
	return defaultValue
}

func getInt64EnvOrDefault(key string, defaultValue int64) int64 {
	if value := os.Getenv(key); value != "" {
		if parsed, err := strconv.ParseInt(value, 10, 64); err == nil {
			return parsed
		}
	}
	return defaultValue
}

func getDurationEnvOrDefault(key string, defaultValue time.Duration) time.Duration {
	if value := os.Getenv(key); value != "" {
		if parsed, err := time.ParseDuration(value); err == nil {
			return parsed
		}
	}
	return defaultValue
}