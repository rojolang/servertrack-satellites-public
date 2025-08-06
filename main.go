package main

import (
	"context"
	"net/http"
	"os"
	"os/signal"
	"runtime"
	"sync"
	"syscall"
	"time"

	"github.com/gorilla/handlers"
	"github.com/gorilla/mux"
	"github.com/rs/cors"
	"github.com/sirupsen/logrus"
)

// 🛰️ ServerTrack Satellites - Beautiful Lander Generation Service
// Elegantly crafted for effortless campaign creation 

type CreateLanderRequest struct {
	CampaignID    string `json:"campaign_id" binding:"required"`
	LandingPageID string `json:"landing_page_id" binding:"required"`
	Subdomain     string `json:"subdomain" binding:"required"`
	RequestID     string `json:"request_id,omitempty"`
}

type CreateLanderResponse struct {
	Success   bool   `json:"success"`
	Message   string `json:"message"`
	Subdomain string `json:"subdomain,omitempty"`
	URL       string `json:"url,omitempty"`
	Error     string `json:"error,omitempty"`
	RequestID string `json:"request_id,omitempty"`
	Duration  string `json:"duration,omitempty"`
}

type ServerMetrics struct {
	RequestCount    int64 `json:"request_count"`
	ActiveRequests  int64 `json:"active_requests"`
	TotalDeployments int64 `json:"total_deployments"`
	SuccessRate     float64 `json:"success_rate"`
	AverageLatency  time.Duration `json:"average_latency"`
	Uptime         time.Duration `json:"uptime"`
}

var (
	logger      *logrus.Logger
	metrics     ServerMetrics
	startTime   time.Time
	deployQueue = make(chan CreateLanderRequest, 100) // Buffered channel for deployment queue
	workers     sync.WaitGroup
)

func init() {
	// 🎨 Beautiful enhanced logging setup
	logger = logrus.New()
	logger.SetFormatter(&logrus.JSONFormatter{
		TimestampFormat: time.RFC3339,
		PrettyPrint:     true,
		FieldMap: logrus.FieldMap{
			logrus.FieldKeyTime:  "timestamp",
			logrus.FieldKeyLevel: "level",
			logrus.FieldKeyMsg:   "message",
		},
	})
	logger.SetLevel(logrus.InfoLevel)
	startTime = time.Now()
	
	// Initialize worker pool for concurrent deployments
	workerCount := runtime.NumCPU() * 2 // 2x CPU cores for optimal performance
	for i := 0; i < workerCount; i++ {
		workers.Add(1)
		go deploymentWorker(i)
	}
}

func main() {
	logger.WithFields(logrus.Fields{
		"service": "ServerTrack Satellites",
		"version": "2.0.0",
		"workers": runtime.NumCPU() * 2,
	}).Info("🛰️ Initializing Beautiful Campaign Engine...")
	
	logger.Info("✨ Elegant automation ready for deployment")

	r := mux.NewRouter()
	
	// 🎨 Beautiful CORS setup with enhanced security
	c := cors.New(cors.Options{
		AllowedOrigins:   []string{"*"},
		AllowedMethods:   []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders:   []string{"*"},
		ExposedHeaders:   []string{"X-Request-ID", "X-Response-Time"},
		AllowCredentials: true,
		MaxAge:          300,
	})

	// 📍 Enhanced Routes with middleware
	r.HandleFunc("/", homeHandler).Methods("GET")
	r.HandleFunc("/health", healthHandler).Methods("GET")
	r.HandleFunc("/metrics", metricsHandler).Methods("GET")
	r.HandleFunc("/api/v1/lander", createLanderHandler).Methods("POST")
	r.HandleFunc("/api/v1/landers", listLandersHandler).Methods("GET")
	r.HandleFunc("/api/v1/status/{requestId}", getDeploymentStatus).Methods("GET")

	// 🎯 Beautiful middleware stack
	r.Use(requestIDMiddleware)
	r.Use(metricsMiddleware)  
	r.Use(errorHandlerMiddleware)
	r.Use(loggingMiddleware)
	r.Use(rateLimitMiddleware)

	// 📝 Request logging middleware from Gorilla
	loggedRouter := handlers.LoggingHandler(os.Stdout, r)
	handler := c.Handler(loggedRouter)

	port := "8080"
	if p := os.Getenv("PORT"); p != "" {
		port = p
	}

	// 🚀 Enhanced server with graceful shutdown
	server := &http.Server{
		Addr:           ":" + port,
		Handler:        handler,
		ReadTimeout:    30 * time.Second,
		WriteTimeout:   30 * time.Second,
		IdleTimeout:    60 * time.Second,
		MaxHeaderBytes: 1 << 20, // 1 MB
	}

	logger.WithFields(logrus.Fields{
		"port": port,
		"endpoints": []string{
			"GET  / - Welcome page",
			"GET  /health - Satellite health check", 
			"GET  /metrics - System metrics",
			"POST /api/v1/lander - Deploy new satellite",
			"GET  /api/v1/landers - List all satellites",
			"GET  /api/v1/status/{id} - Check deployment status",
		},
	}).Info("🌐 ServerTrack Satellites launching...")

	// Graceful shutdown handling
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	go func() {
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			logger.Fatalf("💥 Server failed to start: %v", err)
		}
	}()

	logger.Info("🛰️ All satellites operational! Server ready for beautiful campaigns.")

	<-quit
	logger.Info("🔄 Graceful shutdown initiated...")

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	// Close deployment queue and wait for workers to finish
	close(deployQueue)
	workers.Wait()

	if err := server.Shutdown(ctx); err != nil {
		logger.Errorf("💥 Server forced to shutdown: %v", err)
	}

	logger.Info("✨ ServerTrack Satellites shutdown complete. Beautiful campaigns await!")
}

