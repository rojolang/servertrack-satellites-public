package main

import (
	"context"
	"crypto/tls"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"runtime"
	"sync"
	"sync/atomic"
	"syscall"
	"time"

	"github.com/gorilla/handlers"
	"github.com/gorilla/mux"
	"github.com/sirupsen/logrus"
)

// 🛰️ ServerTrack Satellites - Production Landing Page Deployment Service
// Turn-key solution for automated campaign deployment with Voluum integration

// API Request/Response Types with comprehensive validation
type CreateLanderRequest struct {
	CampaignID     string `json:"campaign_id" validate:"required,min=1,max=100"`
	LandingPageID  string `json:"landing_page_id" validate:"required,min=1,max=100"`
	Subdomain      string `json:"subdomain" validate:"required,min=1,max=100"`
	TrackingDomain string `json:"tracking_domain,omitempty"`
	RequestID      string `json:"request_id,omitempty"`
}

type CreateLanderResponse struct {
	Success   bool   `json:"success"`
	Message   string `json:"message"`
	Subdomain string `json:"subdomain,omitempty"`
	URL       string `json:"url,omitempty"`
	Error     string `json:"error,omitempty"`
	RequestID string `json:"request_id,omitempty"`
	Duration  string `json:"duration,omitempty"`
	Timestamp string `json:"timestamp"`
}

// Server Metrics for monitoring and observability
type ServerMetrics struct {
	RequestCount     int64         `json:"request_count"`
	ActiveRequests   int64         `json:"active_requests"`
	TotalDeployments int64         `json:"total_deployments"`
	FailedRequests   int64         `json:"failed_requests"`
	AverageLatency   time.Duration `json:"average_latency"`
}

// Global application state - properly initialized and thread-safe
var (
	// Application logger with structured logging
	logger *logrus.Logger
	
	// Application configuration loaded from environment
	config *ServerConfig
	
	// Thread-safe metrics tracking
	metrics ServerMetrics
	
	// Application lifecycle tracking
	startTime time.Time
	
	// Deployment processing infrastructure
	deployQueue chan CreateLanderRequest
	workers     sync.WaitGroup
	
	// Graceful shutdown coordination
	shutdownComplete chan struct{}
)

// init initializes the application with production-ready configuration
func init() {
	// Initialize application start time for uptime tracking
	startTime = time.Now()
	
	// Load configuration from environment variables
	config = LoadConfig()
	
	// Initialize structured logger with security-conscious configuration
	initializeLogger()
	
	// Initialize deployment processing infrastructure
	initializeDeploymentSystem()
	
	
	// Initialize graceful shutdown coordination
	shutdownComplete = make(chan struct{})
	
	logger.WithFields(logrus.Fields{
		"service":           "ServerTrack Satellites",
		"version":           "2.0.0",
		"worker_pool_size":  config.WorkerPoolSize,
		"queue_size":        config.DeploymentQueueSize,
		"base_domain":       config.BaseDomain,
	}).Info("🛰️ ServerTrack Satellites initialized successfully")
}

// initializeLogger sets up structured logging with security and performance optimizations
func initializeLogger() {
	logger = logrus.New()
	
	// Configure structured JSON logging for production
	logger.SetFormatter(&logrus.JSONFormatter{
		TimestampFormat: time.RFC3339Nano,
		PrettyPrint:     false, // Disable pretty print for performance
		FieldMap: logrus.FieldMap{
			logrus.FieldKeyTime:  "@timestamp",
			logrus.FieldKeyLevel: "level",
			logrus.FieldKeyMsg:   "message",
		},
	})
	
	// Set log level based on configuration
	level, err := logrus.ParseLevel(config.LogLevel)
	if err != nil {
		level = logrus.InfoLevel
		logger.WithField("invalid_level", config.LogLevel).Warn("Invalid log level, defaulting to info")
	}
	logger.SetLevel(level)
	
	// Log to stdout for container/systemd compatibility
	logger.SetOutput(os.Stdout)
}

// initializeDeploymentSystem sets up the worker pool and deployment queue
func initializeDeploymentSystem() {
	// Initialize deployment queue with configured size
	deployQueue = make(chan CreateLanderRequest, config.DeploymentQueueSize)
	
	// Start worker pool with configured size
	for i := 0; i < config.WorkerPoolSize; i++ {
		workers.Add(1)
		go deploymentWorker(i)
	}
	
	logger.WithFields(logrus.Fields{
		"worker_count": config.WorkerPoolSize,
		"queue_size":   config.DeploymentQueueSize,
	}).Info("🔧 Deployment system initialized")
}

// main is the entry point for the ServerTrack Satellites application
// It initializes the HTTP server with production-ready configuration and handles graceful shutdown
func main() {
	defer func() {
		// Final cleanup and shutdown signal
		close(shutdownComplete)
	}()

	// Log application startup with comprehensive context
	logger.WithFields(logrus.Fields{
		"service":     "ServerTrack Satellites",
		"version":     "2.0.0",
		"go_version":  runtime.Version(),
		"port":        config.Port,
		"host":        config.Host,
		"base_domain": config.BaseDomain,
		"log_level":   config.LogLevel,
	}).Info("🛰️ Starting ServerTrack Satellites - Production Landing Page Deployment Service")

	// Initialize HTTP router with security-hardened configuration
	router := initializeRouter()

	// Create production-ready HTTP server with comprehensive timeout and security settings
	server := &http.Server{
		Addr:           fmt.Sprintf("%s:%s", config.Host, config.Port),
		Handler:        router,
		ReadTimeout:    config.ReadTimeout,
		WriteTimeout:   config.WriteTimeout,
		IdleTimeout:    config.IdleTimeout,
		MaxHeaderBytes: int(config.MaxRequestSize),
		
		// Security: Disable HTTP/2 for increased security and simplicity
		TLSNextProto: make(map[string]func(*http.Server, *tls.Conn, http.Handler)),
	}

	// Set up graceful shutdown handling with proper signal management
	shutdown := make(chan os.Signal, 1)
	signal.Notify(shutdown, syscall.SIGINT, syscall.SIGTERM, syscall.SIGHUP)

	// Start the HTTP server in a separate goroutine
	serverErrors := make(chan error, 1)
	go func() {
		logger.WithFields(logrus.Fields{
			"address":        server.Addr,
			"read_timeout":   config.ReadTimeout,
			"write_timeout":  config.WriteTimeout,
			"idle_timeout":   config.IdleTimeout,
			"max_request_size": config.MaxRequestSize,
		}).Info("🌐 HTTP server starting")

		// Start listening for HTTP requests
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			serverErrors <- fmt.Errorf("server failed to start: %w", err)
		}
	}()

	// Log successful startup
	logger.WithFields(logrus.Fields{
		"endpoints": []string{
			fmt.Sprintf("GET  http://%s:%s/ - API documentation", config.Host, config.Port),
			fmt.Sprintf("GET  http://%s:%s/health - Health monitoring", config.Host, config.Port),
			fmt.Sprintf("GET  http://%s:%s/metrics - System metrics", config.Host, config.Port),
			fmt.Sprintf("POST http://%s:%s/api/v1/lander - Deploy satellite", config.Host, config.Port),
			fmt.Sprintf("GET  http://%s:%s/api/v1/landers - List deployments", config.Host, config.Port),
		},
	}).Info("🛰️ ServerTrack Satellites ready - All systems operational")

	// Block until shutdown signal received or server error occurs
	select {
	case err := <-serverErrors:
		logger.WithError(err).Fatal("💥 Server startup failed")
	case sig := <-shutdown:
		logger.WithField("signal", sig.String()).Info("🔄 Shutdown signal received, initiating graceful shutdown")
		
		// Perform graceful shutdown with timeout
		if err := gracefulShutdown(server); err != nil {
			logger.WithError(err).Error("💥 Graceful shutdown failed")
			os.Exit(1)
		}
	}

	logger.Info("✨ ServerTrack Satellites shutdown complete - Ready for next deployment")
}

// initializeRouter sets up the HTTP router with all routes, middleware, and security configurations
func initializeRouter() http.Handler {
	// Create router with strict slash handling for security
	router := mux.NewRouter().StrictSlash(true)

	// Apply security and operational middleware in correct order
	router.Use(securityHeadersMiddleware)  // Security headers first
	router.Use(requestIDMiddleware)        // Request tracking
	router.Use(requestSizeMiddleware)      // Request size limiting
	router.Use(errorHandlerMiddleware)     // Error handling
	router.Use(metricsMiddleware)          // Metrics collection
	router.Use(loggingMiddleware)          // Request logging

	// Define API routes with explicit HTTP methods for security
	router.HandleFunc("/", homeHandler).Methods("GET").Name("home")
	router.HandleFunc("/health", healthHandler).Methods("GET").Name("health")
	router.HandleFunc("/metrics", metricsHandler).Methods("GET").Name("metrics")
	
	// API v1 routes
	apiV1 := router.PathPrefix("/api/v1").Subrouter()
	apiV1.HandleFunc("/lander", createLanderHandler).Methods("POST").Name("create-lander")
	apiV1.HandleFunc("/landers", listLandersHandler).Methods("GET").Name("list-landers")
	apiV1.HandleFunc("/status/{requestId:[a-zA-Z0-9-]+}", getDeploymentStatus).Methods("GET").Name("deployment-status")

	// Add request logging for production monitoring
	loggedRouter := handlers.LoggingHandler(os.Stdout, router)
	
	// Add recovery middleware to prevent crashes
	recoveryHandler := handlers.RecoveryHandler(
		handlers.PrintRecoveryStack(true),
		handlers.RecoveryLogger(logger),
	)(loggedRouter)

	logger.Info("🔧 HTTP router initialized with security middleware and API endpoints")
	
	return recoveryHandler
}

// gracefulShutdown handles the graceful shutdown of the server and all background processes
func gracefulShutdown(server *http.Server) error {
	// Create shutdown context with timeout
	shutdownTimeout := 30 * time.Second
	ctx, cancel := context.WithTimeout(context.Background(), shutdownTimeout)
	defer cancel()

	logger.WithField("timeout", shutdownTimeout).Info("🔄 Beginning graceful shutdown sequence")

	// Stop accepting new requests
	if err := server.Shutdown(ctx); err != nil {
		return fmt.Errorf("server shutdown failed: %w", err)
	}
	logger.Info("🌐 HTTP server shutdown complete")

	// Close deployment queue to stop new work
	close(deployQueue)
	logger.Info("📤 Deployment queue closed")

	// Wait for all deployment workers to finish with timeout
	workersDone := make(chan struct{})
	go func() {
		workers.Wait()
		close(workersDone)
	}()

	select {
	case <-workersDone:
		logger.Info("👷 All deployment workers finished successfully")
	case <-ctx.Done():
		logger.Warn("⚠️ Deployment workers did not finish within timeout, forcing shutdown")
	}

	// Log final metrics before shutdown
	logger.WithFields(logrus.Fields{
		"total_requests":    atomic.LoadInt64(&metrics.RequestCount),
		"total_deployments": atomic.LoadInt64(&metrics.TotalDeployments),
		"failed_requests":   atomic.LoadInt64(&metrics.FailedRequests),
		"uptime":           time.Since(startTime).String(),
	}).Info("📊 Final metrics before shutdown")

	return nil
}

