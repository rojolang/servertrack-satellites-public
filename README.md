# 🛰️ ServerTrack Satellites - Elegant Campaign Automation

## Overview  
Sophisticated satellite-based REST API for deploying beautiful landing page campaigns with seamless Voluum tracking integration. Engineered for elegance, built for performance, designed for scale.

## 🛰️ Satellite Features
- 🎨 **Beautiful RESTful API** with intelligent satellite deployment management
- 🌟 **Sophisticated logging** with real-time satellite insights and emoji indicators
- ⚡ **Automated nginx configuration** with intelligent proxy routing and load balancing
- 🔐 **SSL certificate automation** for secure, professional satellite deployments  
- 📊 **Seamless Voluum tracking** with parameter injection and click handling
- 🛡️ **Facebook ad compliance** with stealth tracking and clean URLs
- 🚀 **One-liner deployment** for instant satellite server setup
- 💎 **Production-ready systemd service** with graceful restarts and monitoring

## 🔧 API Endpoints

### POST /api/v1/lander
Deploy a new satellite landing page with tracking configuration.

**Request Body:**
```json
{
  "campaign_id": "5480898d-f573-4d75-aec5-a3a389fe7d71",
  "landing_page_id": "4e0167ae-5839-4d9b-bc9e-bd1ed4a0ca0e",
  "subdomain": "test"
}
```

**Response:**
```json
{
  "success": true,
  "message": "🛰️ Satellite deployed successfully! Your beautiful lander is live and tracking.",
  "subdomain": "test.puritysalt.com", 
  "url": "https://test.puritysalt.com"
}
```

### GET /api/v1/landers
List all active satellite deployments.

**Response:**
```json
{
  "success": true,
  "count": 2,
  "landers": [
    {
      "domain": "test.puritysalt.com",
      "url": "https://test.puritysalt.com",
      "status": "🟢 Active"
    }
  ]
}
```

### GET /health
Satellite system health check endpoint.

## 🚀 Quick Start

1. **Install dependencies:**
```bash
go mod tidy
```

2. **Run the API:**
```bash
go run main.go
```

3. **Test the API:**
```bash
curl -X POST http://localhost:8080/api/v1/lander \
  -H "Content-Type: application/json" \
  -d '{
    "campaign_id": "your-campaign-id",
    "landing_page_id": "your-landing-page-id", 
    "subdomain": "test"
  }'
```

## 🎨 Beautiful Features

### Logging
Every request is beautifully logged with:
- 🔄 Request start
- ✅ Request completion with timing
- 🎯 Campaign details
- 💥 Error details with context

### Error Handling
Comprehensive error handling with:
- Validation of required fields
- JSON parsing errors
- System command failures
- Beautiful error responses

### CORS Support
Full CORS support for web applications.

## 🛠️ Requirements

- Ubuntu 24.04 LTS
- Go 1.21+
- nginx with SSL support
- Existing quick-deploy template at `/root/templates/quick-deploy.sh`

## 🌐 Production Deployment

The API automatically:
1. Creates nginx configurations
2. Sets up SSL certificates
3. Configures Voluum tracking
4. Deploys lander files
5. Tests configuration

## 📊 Monitoring

Check logs for beautiful real-time monitoring:
```bash
tail -f /var/log/rojolang-api.log
```

## 🚀 One-Liner Installation

Install ServerTrack Satellites on any Ubuntu 24.04 server with this beautiful one-liner:

```bash
curl -fsSL https://raw.githubusercontent.com/rojolang/servertrack-satellites/main/install.sh | bash
```

Or manually:

```bash
git clone https://github.com/rojolang/servertrack-satellites.git
cd servertrack-satellites
chmod +x install.sh
./install.sh
```

## ⚡ New Enhanced Features (v2.0.0)

### 🎨 Beautiful Logging & Monitoring
- **JSON structured logging** with request tracing
- **Real-time metrics** endpoint with system performance data  
- **Request ID tracking** for complete request lifecycle visibility
- **Beautiful emoji indicators** for instant status recognition

### 🚀 Concurrency & Performance  
- **Worker pool architecture** with configurable concurrent deployments
- **Buffered deployment queue** for handling traffic spikes elegantly
- **Graceful shutdown handling** with proper resource cleanup
- **Memory and CPU monitoring** with automatic optimization

### 🛡️ Enhanced Security & Middleware
- **Rate limiting** with intelligent IP-based throttling
- **Request validation** with comprehensive input sanitization  
- **Error recovery** with panic handling and graceful degradation
- **CORS security** with proper header management

### 📊 Advanced Monitoring
- **GET /metrics** - Real-time system performance metrics
- **GET /health** - Comprehensive health monitoring with system stats
- **GET /api/v1/status/{id}** - Deployment status tracking
- **Beautiful response times** and latency tracking

### 💎 Professional Grade Features
- **Deployment queuing** for handling multiple simultaneous requests
- **Request/response timing** with microsecond precision
- **System resource monitoring** (memory, CPU, goroutines)
- **Production-ready logging** with structured JSON output

## 📈 Performance Metrics

- **Concurrent Workers**: 2x CPU cores for optimal throughput
- **Queue Capacity**: 100 simultaneous deployments  
- **Request Timeout**: 30 seconds with graceful handling
- **Memory Optimized**: Automatic garbage collection monitoring
- **Zero Downtime**: Graceful shutdown with request completion

---

**🛰️ Built with elegant automation - ServerTrack Satellites Team**