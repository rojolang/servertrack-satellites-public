package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"runtime"
	"strings"
	"sync/atomic"
	"time"

	"github.com/gorilla/mux"
	"github.com/sirupsen/logrus"
)

// 🏠 Enhanced Home Handler with beautiful system info
func homeHandler(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"service":     "ServerTrack Satellites API",
		"version":     "2.0.0",
		"status":      "🛰️ All satellites operational and ready for deployment",
		"description": "Beautiful, effortless landing page generation with Voluum integration",
		"features": []string{
			"🎨 Elegant RESTful API with intelligent satellite deployment management",
			"🌟 Sophisticated logging with real-time satellite insights",
			"⚡ Automated nginx configuration with intelligent proxy routing",
			"🔐 SSL certificate automation for secure deployments",
			"📊 Seamless Voluum tracking with parameter injection",
			"🛡️ Facebook ad compliance with stealth tracking",
			"🚀 Concurrent deployment processing",
			"💎 Production-ready with graceful shutdown",
		},
		"endpoints": map[string]interface{}{
			"GET  /": map[string]string{
				"description": "Welcome page with API documentation",
				"returns":     "Service information and available endpoints",
			},
			"GET  /health": map[string]string{
				"description": "Comprehensive satellite system health check",
				"returns":     "Service status, uptime, and system metrics",
			},
			"GET  /metrics": map[string]string{
				"description": "Real-time system performance metrics",
				"returns":     "Request counts, latency, and deployment statistics",
			},
			"POST /api/v1/lander": map[string]string{
				"description": "Deploy a new satellite landing page campaign",
				"parameters":  "campaign_id, landing_page_id, subdomain",
				"returns":     "Deployment status, URL, and tracking information",
			},
			"GET  /api/v1/landers": map[string]string{
				"description": "List all active satellite deployments",
				"returns":     "Array of active landers with status and metrics",
			},
			"GET  /api/v1/status/{id}": map[string]string{
				"description": "Check deployment status by request ID",
				"parameters":  "request_id",
				"returns":     "Deployment progress and completion status",
			},
		},
		"system": map[string]interface{}{
			"go_version":     runtime.Version(),
			"architecture":   runtime.GOARCH,
			"operating_system": runtime.GOOS,
			"cpu_cores":      runtime.NumCPU(),
			"goroutines":     runtime.NumGoroutine(),
			"worker_pool":    runtime.NumCPU() * 2,
		},
		"author": "ServerTrack Team",
		"motto":  "🛰️ Elegant automation, beautiful results",
		"uptime": time.Since(startTime).String(),
	}

	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("X-Response-Time", time.Since(time.Now()).String())
	json.NewEncoder(w).Encode(response)
}

// 🏥 Enhanced Health Handler with comprehensive system monitoring
func healthHandler(w http.ResponseWriter, r *http.Request) {
	var memStats runtime.MemStats
	runtime.ReadMemStats(&memStats)

	response := map[string]interface{}{
		"status":      "healthy",
		"timestamp":   time.Now().UTC(),
		"uptime":      "🛰️ All satellites operational",
		"service":     "ServerTrack Satellites API",
		"version":     "2.0.0",
		"environment": "production",
		"system": map[string]interface{}{
			"memory": map[string]interface{}{
				"allocated_mb": memStats.Alloc / 1024 / 1024,
				"total_mb":     memStats.TotalAlloc / 1024 / 1024,
				"sys_mb":       memStats.Sys / 1024 / 1024,
				"gc_cycles":    memStats.NumGC,
			},
			"runtime": map[string]interface{}{
				"goroutines": runtime.NumGoroutine(),
				"cpu_cores":  runtime.NumCPU(),
				"go_version": runtime.Version(),
			},
			"performance": map[string]interface{}{
				"request_count":    atomic.LoadInt64(&metrics.RequestCount),
				"active_requests":  atomic.LoadInt64(&metrics.ActiveRequests),
				"total_deployments": atomic.LoadInt64(&metrics.TotalDeployments),
				"average_latency":  metrics.AverageLatency.String(),
				"uptime":          time.Since(startTime).String(),
			},
		},
		"motto": "🛰️ Elegant automation, beautiful results",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// 📊 Beautiful Metrics Handler for real-time insights
func metricsHandler(w http.ResponseWriter, r *http.Request) {
	var memStats runtime.MemStats
	runtime.ReadMemStats(&memStats)

	uptime := time.Since(startTime)
	requestCount := atomic.LoadInt64(&metrics.RequestCount)
	deployments := atomic.LoadInt64(&metrics.TotalDeployments)

	successRate := float64(100)
	if requestCount > 0 {
		successRate = (float64(deployments) / float64(requestCount)) * 100
	}

	response := map[string]interface{}{
		"service": "ServerTrack Satellites Metrics",
		"timestamp": time.Now().UTC(),
		"metrics": map[string]interface{}{
			"requests": map[string]interface{}{
				"total":          requestCount,
				"active":         atomic.LoadInt64(&metrics.ActiveRequests),
				"per_second":     float64(requestCount) / uptime.Seconds(),
				"per_minute":     float64(requestCount) / uptime.Minutes(),
			},
			"deployments": map[string]interface{}{
				"total":        deployments,
				"success_rate": fmt.Sprintf("%.2f%%", successRate),
				"per_hour":     float64(deployments) / uptime.Hours(),
			},
			"performance": map[string]interface{}{
				"average_latency": metrics.AverageLatency.String(),
				"uptime":          uptime.String(),
				"uptime_seconds":  uptime.Seconds(),
			},
			"system": map[string]interface{}{
				"memory_usage_mb": memStats.Alloc / 1024 / 1024,
				"goroutines":      runtime.NumGoroutine(),
				"cpu_cores":       runtime.NumCPU(),
				"worker_pool":     runtime.NumCPU() * 2,
			},
		},
		"status": "🛰️ All satellites reporting nominal performance",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// 🚀 Enhanced Lander Creation Handler with beautiful concurrency
func createLanderHandler(w http.ResponseWriter, r *http.Request) {
	start := time.Now()
	requestID := getRequestID(r)
	
	logger.WithFields(logrus.Fields{
		"request_id": requestID,
		"endpoint":   "/api/v1/lander",
	}).Info("🎯 New satellite deployment request received")

	body, err := io.ReadAll(r.Body)
	if err != nil {
		logger.WithFields(logrus.Fields{
			"request_id": requestID,
			"error":      err,
		}).Error("💥 Failed to read request body")
		sendErrorResponse(w, requestID, "Failed to read request body", http.StatusBadRequest)
		return
	}

	var req CreateLanderRequest
	if err := json.Unmarshal(body, &req); err != nil {
		logger.WithFields(logrus.Fields{
			"request_id": requestID,
			"error":      err,
		}).Error("💥 Failed to parse JSON")
		sendErrorResponse(w, requestID, "Invalid JSON format", http.StatusBadRequest)
		return
	}

	// Add request ID for tracking
	req.RequestID = requestID

	// 🧹 Enhanced input validation
	if err := validateLanderRequest(req); err != nil {
		logger.WithFields(logrus.Fields{
			"request_id": requestID,
			"error":      err,
		}).Error("💥 Validation failed")
		sendErrorResponse(w, requestID, err.Error(), http.StatusBadRequest)
		return
	}

	logger.WithFields(logrus.Fields{
		"request_id":     requestID,
		"campaign_id":    req.CampaignID,
		"landing_page_id": req.LandingPageID,
		"subdomain":      req.Subdomain,
	}).Info("📊 Deploying satellite with configuration")

	// 🚀 Queue deployment for concurrent processing
	select {
	case deployQueue <- req:
		logger.WithFields(logrus.Fields{
			"request_id": requestID,
			"queue_size": len(deployQueue),
		}).Info("📤 Deployment queued successfully")
	default:
		logger.WithFields(logrus.Fields{
			"request_id": requestID,
		}).Error("📤 Deployment queue full")
		sendErrorResponse(w, requestID, "Server busy - deployment queue full", http.StatusServiceUnavailable)
		return
	}

	fullDomain := req.Subdomain
	if !strings.Contains(req.Subdomain, ".") {
		fullDomain = req.Subdomain + ".puritysalt.com"
	}

	atomic.AddInt64(&metrics.TotalDeployments, 1)
	duration := time.Since(start)

	response := CreateLanderResponse{
		Success:   true,
		Message:   "🛰️ Satellite deployment initiated! Your beautiful lander is being deployed.",
		Subdomain: fullDomain,
		URL:       "https://" + fullDomain,
		RequestID: requestID,
		Duration:  duration.String(),
	}

	logger.WithFields(logrus.Fields{
		"request_id": requestID,
		"domain":     fullDomain,
		"duration":   duration.String(),
	}).Info("✅ Satellite deployment queued successfully")

	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("X-Response-Time", duration.String())
	json.NewEncoder(w).Encode(response)
}

// 📋 Enhanced Landers List Handler with beautiful metrics
func listLandersHandler(w http.ResponseWriter, r *http.Request) {
	requestID := getRequestID(r)
	
	logger.WithFields(logrus.Fields{
		"request_id": requestID,
	}).Info("📋 Listing all satellite deployments")

	// 📂 Read nginx sites-available directory
	sitesDir := "/etc/nginx/sites-available"
	files, err := os.ReadDir(sitesDir)
	if err != nil {
		logger.WithFields(logrus.Fields{
			"request_id": requestID,
			"error":      err,
		}).Error("💥 Failed to read sites directory")
		sendErrorResponse(w, requestID, "Failed to read satellite deployments", http.StatusInternalServerError)
		return
	}

	var landers []map[string]interface{}
	for _, file := range files {
		if !file.IsDir() && strings.Contains(file.Name(), ".puritysalt.com") {
			info, _ := file.Info()
			landers = append(landers, map[string]interface{}{
				"domain":      file.Name(),
				"url":         "https://" + file.Name(),
				"status":      "🟢 Active",
				"deployed":    info.ModTime().Format(time.RFC3339),
				"uptime":      time.Since(info.ModTime()).String(),
			})
		}
	}

	response := map[string]interface{}{
		"success":     true,
		"request_id":  requestID,
		"total_count": len(landers),
		"satellites":  landers,
		"system": map[string]interface{}{
			"total_deployments": atomic.LoadInt64(&metrics.TotalDeployments),
			"active_requests":   atomic.LoadInt64(&metrics.ActiveRequests),
		},
		"message": fmt.Sprintf("🛰️ Found %d active satellite deployments", len(landers)),
	}

	logger.WithFields(logrus.Fields{
		"request_id": requestID,
		"count":      len(landers),
	}).Info("📊 Satellite deployments listed successfully")

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// 🔍 Deployment Status Handler for request tracking
func getDeploymentStatus(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	requestID := vars["requestId"]
	currentRequestID := getRequestID(r)

	logger.WithFields(logrus.Fields{
		"request_id":        currentRequestID,
		"deployment_id":     requestID,
	}).Info("🔍 Checking deployment status")

	// For now, return a simple status - in production this would query a database
	response := map[string]interface{}{
		"success":       true,
		"request_id":    currentRequestID,
		"deployment_id": requestID,
		"status":        "completed",
		"message":       "🛰️ Satellite deployment completed successfully",
		"checked_at":    time.Now().UTC(),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// 🧹 Enhanced validation function
func validateLanderRequest(req CreateLanderRequest) error {
	if strings.TrimSpace(req.CampaignID) == "" {
		return fmt.Errorf("campaign_id is required and cannot be empty")
	}
	if strings.TrimSpace(req.LandingPageID) == "" {
		return fmt.Errorf("landing_page_id is required and cannot be empty")
	}
	if strings.TrimSpace(req.Subdomain) == "" {
		return fmt.Errorf("subdomain is required and cannot be empty")
	}
	if len(req.Subdomain) > 50 {
		return fmt.Errorf("subdomain too long (max 50 characters)")
	}
	if !isValidSubdomain(req.Subdomain) {
		return fmt.Errorf("invalid subdomain format")
	}
	return nil
}

func isValidSubdomain(subdomain string) bool {
	// Basic subdomain validation - letters, numbers, and hyphens
	for _, char := range subdomain {
		if !((char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') || 
			 (char >= '0' && char <= '9') || char == '-' || char == '.') {
			return false
		}
	}
	return true
}

// 💥 Enhanced error response function
func sendErrorResponse(w http.ResponseWriter, requestID, message string, statusCode int) {
	response := CreateLanderResponse{
		Success:   false,
		Error:     message,
		RequestID: requestID,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(response)
}

// 👷 Deployment Worker - Beautiful concurrent processing
func deploymentWorker(workerID int) {
	defer workers.Done()
	
	logger.WithFields(logrus.Fields{
		"worker_id": workerID,
	}).Info("👷 Deployment worker started")

	for req := range deployQueue {
		start := time.Now()
		
		logger.WithFields(logrus.Fields{
			"worker_id":     workerID,
			"request_id":    req.RequestID,
			"campaign_id":   req.CampaignID,
			"subdomain":     req.Subdomain,
		}).Info("🔧 Processing deployment")

		err := processDeploy(req)
		duration := time.Since(start)

		if err != nil {
			logger.WithFields(logrus.Fields{
				"worker_id":  workerID,
				"request_id": req.RequestID,
				"error":      err,
				"duration":   duration.String(),
			}).Error("💥 Deployment failed")
		} else {
			logger.WithFields(logrus.Fields{
				"worker_id":  workerID,
				"request_id": req.RequestID,
				"duration":   duration.String(),
			}).Info("✅ Deployment completed successfully")
		}
	}

	logger.WithFields(logrus.Fields{
		"worker_id": workerID,
	}).Info("👷 Deployment worker shutting down")
}

// 🛠️ Process deployment using our proven quick-deploy script
func processDeploy(req CreateLanderRequest) error {
	scriptPath := "/root/templates/quick-deploy.sh"
	
	fullDomain := req.Subdomain
	if !strings.Contains(req.Subdomain, ".") {
		fullDomain = req.Subdomain + ".puritysalt.com"
	}

	cmd := exec.Command("bash", scriptPath, fullDomain, req.CampaignID, req.LandingPageID)
	output, err := cmd.CombinedOutput()
	
	if err != nil {
		logger.WithFields(logrus.Fields{
			"request_id": req.RequestID,
			"output":     string(output),
		}).Error("💥 Deployment script failed")
		return err
	}

	return nil
}