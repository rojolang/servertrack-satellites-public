# 🚀 RojoLang API - Beautiful Lander Generation Service

## Overview
Simple, beautiful REST API for generating landing page campaigns with Voluum tracking integration. Built with the **Keep It Freaking Simple Stupid (KIFSS)** philosophy.

## 🎯 Features
- ✅ RESTful API for lander creation
- ✅ Beautiful logging with emojis
- ✅ Automatic nginx configuration
- ✅ SSL certificate automation
- ✅ Voluum tracking integration
- ✅ Facebook ad compliance

## 🔧 API Endpoints

### POST /api/v1/lander
Create a new landing page with tracking configuration.

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
  "message": "🎉 Lander created successfully!",
  "subdomain": "test.puritysalt.com",
  "url": "https://test.puritysalt.com"
}
```

### GET /api/v1/landers
List all active landers.

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
Health check endpoint.

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

---

**Built with ❤️ using the KIFSS philosophy - Keep It Freaking Simple Stupid**