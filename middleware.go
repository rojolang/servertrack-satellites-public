package main

import (
	"context"
	"encoding/json"
	"net/http"
	"sync"
	"sync/atomic"
	"time"

	"github.com/google/uuid"
	"github.com/sirupsen/logrus"
)

// Rate limiter with beautiful concurrency
type RateLimiter struct {
	requests map[string][]time.Time
	mutex    sync.RWMutex
	limit    int
	window   time.Duration
}

func NewRateLimiter(limit int, window time.Duration) *RateLimiter {
	return &RateLimiter{
		requests: make(map[string][]time.Time),
		limit:    limit,
		window:   window,
	}
}

func (rl *RateLimiter) Allow(clientIP string) bool {
	rl.mutex.Lock()
	defer rl.mutex.Unlock()

	now := time.Now()
	requests := rl.requests[clientIP]

	// Clean old requests outside the window
	var validRequests []time.Time
	for _, reqTime := range requests {
		if now.Sub(reqTime) < rl.window {
			validRequests = append(validRequests, reqTime)
		}
	}

	if len(validRequests) >= rl.limit {
		return false
	}

	validRequests = append(validRequests, now)
	rl.requests[clientIP] = validRequests
	return true
}

var rateLimiter = NewRateLimiter(100, time.Minute) // 100 requests per minute

// 🎯 Request ID Middleware - Adds unique tracking to every request
func requestIDMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requestID := r.Header.Get("X-Request-ID")
		if requestID == "" {
			requestID = uuid.New().String()
		}
		
		w.Header().Set("X-Request-ID", requestID)
		ctx := context.WithValue(r.Context(), "request_id", requestID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

// 📊 Metrics Middleware - Tracks beautiful statistics 
func metricsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		atomic.AddInt64(&metrics.RequestCount, 1)
		atomic.AddInt64(&metrics.ActiveRequests, 1)

		defer func() {
			atomic.AddInt64(&metrics.ActiveRequests, -1)
			duration := time.Since(start)
			
			// Calculate rolling average latency (simplified)
			if metrics.AverageLatency == 0 {
				metrics.AverageLatency = duration
			} else {
				metrics.AverageLatency = (metrics.AverageLatency + duration) / 2
			}
		}()

		next.ServeHTTP(w, r)
	})
}

// 💥 Error Handler Middleware - Beautiful error handling
func errorHandlerMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				requestID := getRequestID(r)
				logger.WithFields(logrus.Fields{
					"request_id": requestID,
					"panic":      err,
					"path":       r.URL.Path,
					"method":     r.Method,
				}).Error("💥 Panic recovered")

				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusInternalServerError)
				response := map[string]interface{}{
					"success":    false,
					"error":      "Internal server error - satellite malfunction",
					"request_id": requestID,
					"message":    "🛰️ Our satellites detected an anomaly. Please try again.",
				}
				json.NewEncoder(w).Encode(response)
			}
		}()
		next.ServeHTTP(w, r)
	})
}

// 🔄 Enhanced Logging Middleware with beautiful insights
func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		requestID := getRequestID(r)

		logger.WithFields(logrus.Fields{
			"request_id":  requestID,
			"method":      r.Method,
			"path":        r.URL.Path,
			"remote_addr": r.RemoteAddr,
			"user_agent":  r.UserAgent(),
		}).Info("🔄 Satellite request received")

		// Wrap the ResponseWriter to capture status code
		wrapped := &responseWriter{ResponseWriter: w, statusCode: http.StatusOK}
		
		next.ServeHTTP(wrapped, r)

		duration := time.Since(start)
		logger.WithFields(logrus.Fields{
			"request_id":   requestID,
			"method":       r.Method,
			"path":         r.URL.Path,
			"status_code":  wrapped.statusCode,
			"duration_ms":  duration.Milliseconds(),
			"response_time": duration.String(),
		}).Info("✅ Satellite response transmitted")
	})
}

// 🚦 Rate Limiting Middleware - Beautiful traffic control
func rateLimitMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		clientIP := getClientIP(r)
		
		if !rateLimiter.Allow(clientIP) {
			logger.WithFields(logrus.Fields{
				"client_ip":  clientIP,
				"path":       r.URL.Path,
				"request_id": getRequestID(r),
			}).Warn("🚦 Rate limit exceeded")

			w.Header().Set("Content-Type", "application/json")
			w.WriteHeader(http.StatusTooManyRequests)
			response := map[string]interface{}{
				"success": false,
				"error":   "Rate limit exceeded",
				"message": "🛰️ Satellites are busy! Please try again in a moment.",
				"request_id": getRequestID(r),
			}
			json.NewEncoder(w).Encode(response)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// Response writer wrapper to capture status codes
type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}

// Helper functions
func getRequestID(r *http.Request) string {
	if id := r.Context().Value("request_id"); id != nil {
		return id.(string)
	}
	return "unknown"
}

func getClientIP(r *http.Request) string {
	// Check X-Forwarded-For header first
	if xff := r.Header.Get("X-Forwarded-For"); xff != "" {
		return xff
	}
	// Check X-Real-IP header
	if xri := r.Header.Get("X-Real-IP"); xri != "" {
		return xri
	}
	// Fall back to RemoteAddr
	return r.RemoteAddr
}