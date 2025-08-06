package main

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	"github.com/gorilla/mux"
	"github.com/rs/cors"
	"github.com/sirupsen/logrus"
)

// 🚀 RojoLang API - Beautiful Lander Generation Service
// Keep It Freaking Simple Stupid (KIFSS) 

type CreateLanderRequest struct {
	CampaignID    string `json:"campaign_id" binding:"required"`
	LandingPageID string `json:"landing_page_id" binding:"required"`
	Subdomain     string `json:"subdomain" binding:"required"`
}

type CreateLanderResponse struct {
	Success   bool   `json:"success"`
	Message   string `json:"message"`
	Subdomain string `json:"subdomain,omitempty"`
	URL       string `json:"url,omitempty"`
	Error     string `json:"error,omitempty"`
}

var logger *logrus.Logger

func init() {
	// 🎨 Beautiful logging setup
	logger = logrus.New()
	logger.SetFormatter(&logrus.TextFormatter{
		FullTimestamp: true,
		ForceColors:   true,
	})
	logger.SetLevel(logrus.InfoLevel)
}

func main() {
	logger.Info("🚀 RojoLang API Starting Up...")
	logger.Info("🎯 Keep It Freaking Simple Stupid Mode: ACTIVATED")

	r := mux.NewRouter()
	
	// 🎨 Beautiful CORS setup
	c := cors.New(cors.Options{
		AllowedOrigins: []string{"*"},
		AllowedMethods: []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders: []string{"*"},
	})

	// 📍 Routes
	r.HandleFunc("/", homeHandler).Methods("GET")
	r.HandleFunc("/health", healthHandler).Methods("GET")
	r.HandleFunc("/api/v1/lander", createLanderHandler).Methods("POST")
	r.HandleFunc("/api/v1/landers", listLandersHandler).Methods("GET")

	// 🎯 Beautiful middleware
	r.Use(loggingMiddleware)

	handler := c.Handler(r)

	port := "8080"
	if p := os.Getenv("PORT"); p != "" {
		port = p
	}

	logger.Infof("🌐 Server starting on port %s", port)
	logger.Infof("🔗 Available endpoints:")
	logger.Infof("   GET  / - Welcome page")
	logger.Infof("   GET  /health - Health check")
	logger.Infof("   POST /api/v1/lander - Create new lander")
	logger.Infof("   GET  /api/v1/landers - List all landers")

	if err := http.ListenAndServe(":"+port, handler); err != nil {
		logger.Fatalf("💥 Server failed to start: %v", err)
	}
}

func homeHandler(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"service": "RojoLang Lander API",
		"version": "1.0.0",
		"status":  "🚀 Ready to create beautiful landers!",
		"endpoints": map[string]string{
			"POST /api/v1/lander":  "Create a new lander",
			"GET  /api/v1/landers": "List all landers",
			"GET  /health":         "Health check",
		},
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func healthHandler(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"status":    "healthy",
		"timestamp": time.Now().UTC(),
		"uptime":    "🟢 All systems go!",
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func createLanderHandler(w http.ResponseWriter, r *http.Request) {
	logger.Info("🎯 New lander creation request received")
	
	body, err := io.ReadAll(r.Body)
	if err != nil {
		logger.Errorf("💥 Failed to read request body: %v", err)
		sendErrorResponse(w, "Failed to read request body", http.StatusBadRequest)
		return
	}

	var req CreateLanderRequest
	if err := json.Unmarshal(body, &req); err != nil {
		logger.Errorf("💥 Failed to parse JSON: %v", err)
		sendErrorResponse(w, "Invalid JSON format", http.StatusBadRequest)
		return
	}

	// 🧹 Clean and validate inputs
	req.CampaignID = strings.TrimSpace(req.CampaignID)
	req.LandingPageID = strings.TrimSpace(req.LandingPageID)
	req.Subdomain = strings.TrimSpace(req.Subdomain)

	if req.CampaignID == "" || req.LandingPageID == "" || req.Subdomain == "" {
		logger.Error("💥 Missing required fields")
		sendErrorResponse(w, "campaign_id, landing_page_id, and subdomain are required", http.StatusBadRequest)
		return
	}

	logger.Infof("📊 Creating lander with:")
	logger.Infof("   🎯 Campaign ID: %s", req.CampaignID)
	logger.Infof("   📄 Landing Page ID: %s", req.LandingPageID)
	logger.Infof("   🌐 Subdomain: %s", req.Subdomain)

	// 🚀 Create the lander using our proven quick-deploy script
	if err := createLander(req); err != nil {
		logger.Errorf("💥 Failed to create lander: %v", err)
		sendErrorResponse(w, fmt.Sprintf("Failed to create lander: %v", err), http.StatusInternalServerError)
		return
	}

	fullDomain := req.Subdomain
	if !strings.Contains(req.Subdomain, ".") {
		fullDomain = req.Subdomain + ".puritysalt.com"
	}

	response := CreateLanderResponse{
		Success:   true,
		Message:   "🎉 Lander created successfully!",
		Subdomain: fullDomain,
		URL:       "https://" + fullDomain,
	}

	logger.Infof("✅ Lander created successfully: https://%s", fullDomain)
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func createLander(req CreateLanderRequest) error {
	// 🛠️ Use our proven quick-deploy script
	scriptPath := "/root/templates/quick-deploy.sh"
	
	fullDomain := req.Subdomain
	if !strings.Contains(req.Subdomain, ".") {
		fullDomain = req.Subdomain + ".puritysalt.com"
	}

	cmd := exec.Command("bash", scriptPath, fullDomain, req.CampaignID, req.LandingPageID)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	logger.Infof("🚀 Executing: bash %s %s %s %s", scriptPath, fullDomain, req.CampaignID, req.LandingPageID)
	
	return cmd.Run()
}

func listLandersHandler(w http.ResponseWriter, r *http.Request) {
	logger.Info("📋 Listing all landers")
	
	// 📂 Read nginx sites-available directory
	sitesDir := "/etc/nginx/sites-available"
	files, err := os.ReadDir(sitesDir)
	if err != nil {
		logger.Errorf("💥 Failed to read sites directory: %v", err)
		sendErrorResponse(w, "Failed to read landers", http.StatusInternalServerError)
		return
	}

	var landers []map[string]string
	for _, file := range files {
		if !file.IsDir() && strings.Contains(file.Name(), ".puritysalt.com") {
			landers = append(landers, map[string]string{
				"domain": file.Name(),
				"url":    "https://" + file.Name(),
				"status": "🟢 Active",
			})
		}
	}

	response := map[string]interface{}{
		"success": true,
		"count":   len(landers),
		"landers": landers,
	}

	logger.Infof("📊 Found %d active landers", len(landers))
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

func sendErrorResponse(w http.ResponseWriter, message string, statusCode int) {
	response := CreateLanderResponse{
		Success: false,
		Error:   message,
	}
	
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	json.NewEncoder(w).Encode(response)
}

func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		
		// 🎨 Beautiful request logging
		logger.Infof("🔄 %s %s from %s", r.Method, r.URL.Path, r.RemoteAddr)
		
		next.ServeHTTP(w, r)
		
		duration := time.Since(start)
		logger.Infof("✅ %s %s completed in %v", r.Method, r.URL.Path, duration)
	})
}