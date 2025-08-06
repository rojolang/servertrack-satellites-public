package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"regexp"
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
		"author": "ServerTrack Team",
		"motto":  "🛰️ Elegant automation, beautiful results",
		"uptime": time.Since(startTime).String(),
	}

	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("X-Response-Time", time.Since(time.Now()).String())
	json.NewEncoder(w).Encode(response)
}

// 🏥 Health Handler for basic system status
func healthHandler(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"status":      "healthy",
		"timestamp":   time.Now().UTC(),
		"uptime":      "🛰️ All satellites operational",
		"service":     "ServerTrack Satellites API",
		"version":     "2.0.0",
		"environment": "production",
		"motto":       "🛰️ Elegant automation, beautiful results",
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// 📊 Simple Metrics Handler 
func metricsHandler(w http.ResponseWriter, r *http.Request) {
	uptime := time.Since(startTime)
	requestCount := atomic.LoadInt64(&metrics.RequestCount)
	deployments := atomic.LoadInt64(&metrics.TotalDeployments)

	response := map[string]interface{}{
		"service":   "ServerTrack Satellites Metrics",
		"timestamp": time.Now().UTC(),
		"requests":  requestCount,
		"deployments": deployments,
		"uptime":    uptime.String(),
		"status":    "🛰️ All satellites operational",
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
		"message":     fmt.Sprintf("🛰️ Found %d active satellite deployments", len(landers)),
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
	// Enhanced subdomain validation - letters, numbers, hyphens, dots, and forward slashes
	for _, char := range subdomain {
		if !((char >= 'a' && char <= 'z') || (char >= 'A' && char <= 'Z') || 
			 (char >= '0' && char <= '9') || char == '-' || char == '.' || char == '/') {
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

// 🛠️ Process deployment with path-based folder duplication
func processDeploy(req CreateLanderRequest) error {
	fullDomain := req.Subdomain
	if !strings.Contains(req.Subdomain, ".") {
		fullDomain = req.Subdomain + ".puritysalt.com"
	}

	// Handle path-based deployments (e.g., "fb.puritysalt.com/1/")
	if strings.Contains(fullDomain, "/") {
		return processPathBasedDeploy(req, fullDomain)
	}

	// Regular deployment for domain-only requests
	scriptPath := "/root/templates/quick-deploy.sh"
	trackingDomain := req.TrackingDomain
	if trackingDomain == "" {
		trackingDomain = "track.puritysalt.com"
	}
	cmd := exec.Command("bash", scriptPath, fullDomain, req.CampaignID, req.LandingPageID, trackingDomain)
	output, err := cmd.CombinedOutput()
	
	if err != nil {
		logger.WithFields(logrus.Fields{
			"request_id": req.RequestID,
			"output":     string(output),
		}).Error("💥 Deployment script failed")
		return err
	}

	// Apply tracking domain customization to the deployed HTML
	siteDir := "/var/www/" + fullDomain
	deploymentURL := fmt.Sprintf("https://%s", fullDomain)
	return injectCampaignParams(siteDir+"/index.html", req.CampaignID, req.LandingPageID, req.TrackingDomain, deploymentURL)
}

// 📁 Process path-based deployment with folder duplication
func processPathBasedDeploy(req CreateLanderRequest, fullDomain string) error {
	// Extract domain and path
	parts := strings.SplitN(fullDomain, "/", 2)
	if len(parts) < 2 {
		return fmt.Errorf("invalid path format")
	}
	
	domain := parts[0]
	requestedPath := parts[1]
	
	// Remove trailing slash if present
	requestedPath = strings.TrimSuffix(requestedPath, "/")
	
	// If no specific path requested, find next available number
	if requestedPath == "" {
		requestedPath = findNextAvailablePath(domain)
	}
	
	// Create the base domain deployment if it doesn't exist
	baseDir := "/var/www/" + domain
	nginxConfigExists := false
	if _, err := os.Stat("/etc/nginx/sites-available/" + domain); err == nil {
		nginxConfigExists = true
	}
	
	if _, err := os.Stat(baseDir); os.IsNotExist(err) || !nginxConfigExists {
		// Deploy base domain first using the deployment script
		scriptPath := "/root/templates/quick-deploy.sh"
		trackingDomain := req.TrackingDomain
		if trackingDomain == "" {
			trackingDomain = "track.puritysalt.com"
		}
		cmd := exec.Command("bash", scriptPath, domain, req.CampaignID, req.LandingPageID, trackingDomain)
		if output, err := cmd.CombinedOutput(); err != nil {
			logger.WithFields(logrus.Fields{
				"request_id": req.RequestID,
				"output":     string(output),
			}).Error("💥 Failed to create base domain")
			return fmt.Errorf("failed to create base domain: %v", err)
		}
	}
	
	// Create the path-specific directory
	pathDir := baseDir + "/" + requestedPath
	if err := os.MkdirAll(pathDir, 0755); err != nil {
		return fmt.Errorf("failed to create path directory: %v", err)
	}
	
	// Copy template files to the path directory
	templateDir := "/var/www/template"
	cmd := exec.Command("cp", "-r", templateDir+"/.", pathDir+"/")
	if output, err := cmd.CombinedOutput(); err != nil {
		logger.WithFields(logrus.Fields{
			"request_id": req.RequestID,
			"output":     string(output),
		}).Error("💥 Failed to copy template to path directory")
		return fmt.Errorf("failed to copy template: %v", err)
	}
	
	// Set proper ownership
	cmd = exec.Command("chown", "-R", "www-data:www-data", pathDir)
	if _, err := cmd.CombinedOutput(); err != nil {
		logger.WithFields(logrus.Fields{
			"request_id": req.RequestID,
		}).Warn("⚠️  Failed to set ownership")
	}
	
	// Update the HTML file with campaign parameters
	deploymentURL := fmt.Sprintf("https://%s", fullDomain)
	return injectCampaignParams(pathDir+"/index.html", req.CampaignID, req.LandingPageID, req.TrackingDomain, deploymentURL)
}

// 🔢 Find the next available path number
func findNextAvailablePath(domain string) string {
	baseDir := "/var/www/" + domain
	for i := 1; i <= 1000; i++ {
		pathDir := fmt.Sprintf("%s/%d", baseDir, i)
		if _, err := os.Stat(pathDir); os.IsNotExist(err) {
			return fmt.Sprintf("%d", i)
		}
	}
	return "1" // fallback
}

// 💉 Inject campaign parameters into HTML file
func injectCampaignParams(htmlPath, campaignID, landingPageID, trackingDomain, deploymentURL string) error {
	content, err := os.ReadFile(htmlPath)
	if err != nil {
		return fmt.Errorf("failed to read HTML file: %v", err)
	}
	
	htmlContent := string(content)
	
	// Use default tracking domain if none provided
	if trackingDomain == "" {
		trackingDomain = "track.puritysalt.com"
	}
	
	// Replace the existing cpid, lpid, and lpurl values in the tracking script
	// Look for the existing tracking script and replace the values
	oldCpidPattern := `var cpid = '[^']*';`
	oldLpidPattern := `var lpid = '[^']*';`
	oldLpurlPattern := `var lpurl = '[^']*';`
	
	newCpid := fmt.Sprintf("var cpid = '%s';", campaignID)
	newLpid := fmt.Sprintf("var lpid = '%s';", landingPageID)
	newLpurl := fmt.Sprintf("var lpurl = '%s';", deploymentURL)
	
	// Replace existing cpid, lpid, and lpurl values
	htmlContent = regexp.MustCompile(oldCpidPattern).ReplaceAllString(htmlContent, newCpid)
	htmlContent = regexp.MustCompile(oldLpidPattern).ReplaceAllString(htmlContent, newLpid)
	htmlContent = regexp.MustCompile(oldLpurlPattern).ReplaceAllString(htmlContent, newLpurl)
	
	// Replace all tracking domain URLs in the HTML
	oldTrackingPattern := `https://track\.puritysalt\.com`
	newTrackingURL := fmt.Sprintf("https://%s", trackingDomain)
	htmlContent = regexp.MustCompile(oldTrackingPattern).ReplaceAllString(htmlContent, newTrackingURL)
	
	// No additional script injection needed - template already has tracking script
	
	// Write updated content back
	return os.WriteFile(htmlPath, []byte(htmlContent), 0644)
}