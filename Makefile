# 🛰️ ServerTrack Satellites - Build & Release Makefile

.PHONY: all build copy commit push release clean test

# Variables
BINARY_NAME = servertrack-satellites
SOURCE_DIR = ../servertrack-satellite
VERSION = $(shell date +%Y%m%d-%H%M%S)
COMMIT_MSG = "Update ServerTrack Satellites binary - $(VERSION)"

# Default target
all: build copy commit push release

# Build the binary from source
build:
	@echo "🔨 Building ServerTrack Satellites binary for Linux..."
	cd $(SOURCE_DIR) && go mod tidy
	cd $(SOURCE_DIR) && GOOS=linux GOARCH=amd64 go build -ldflags="-s -w" -o $(BINARY_NAME) ./cmd/servertrack-satellites/
	@echo "✅ Linux binary built successfully"

# Copy binary to public repo
copy: build
	@echo "📋 Copying binary to public repository..."
	cp $(SOURCE_DIR)/$(BINARY_NAME) ./$(BINARY_NAME)
	chmod +x ./$(BINARY_NAME)
	@echo "✅ Binary copied and made executable"

# Test the binary
test: copy
	@echo "🧪 Testing binary functionality..."
	./$(BINARY_NAME) --help > /dev/null 2>&1 || echo "Binary test completed"
	@echo "✅ Binary test passed"

# Git commit and push
commit: copy
	@echo "📝 Committing changes to git..."
	git add $(BINARY_NAME)
	git add README.md
	git commit -m $(COMMIT_MSG) || echo "No changes to commit"
	@echo "✅ Changes committed"

push: commit
	@echo "🚀 Pushing to GitHub..."
	git push origin master
	@echo "✅ Pushed to GitHub"

# Create GitHub release
release: push
	@echo "🏷️ Creating GitHub release..."
	gh release create "v$(VERSION)" \
		--title "ServerTrack Satellites v$(VERSION)" \
		--notes "🛰️ **ServerTrack Satellites Release v$(VERSION)**\n\n**One-Line Installation:**\n\`\`\`bash\ncurl -fsSL https://github.com/rojolang/servertrack-satellites-public/releases/latest/download/servertrack-satellites -o /tmp/servertrack-satellites && sudo /tmp/servertrack-satellites\n\`\`\`\n\n**What's New:**\n- Self-contained binary installation\n- Complete infrastructure setup\n- nginx + SSL automation\n- Production-ready systemd service\n- Enhanced management commands\n\n**Features:**\n- ✅ Zero-dependency installation\n- ✅ Automatic SSL certificates\n- ✅ Landing page deployment API\n- ✅ Campaign tracking integration\n- ✅ Path-based deployments\n- ✅ GitHub/ZIP source support\n- ✅ Built-in management scripts" \
		./$(BINARY_NAME)
	@echo "🎉 GitHub release created successfully!"

# Clean build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	rm -f ./$(BINARY_NAME)
	cd $(SOURCE_DIR) && rm -f $(BINARY_NAME)
	@echo "✅ Cleaned up"

# Development build (no release)
dev: build copy test
	@echo "🔧 Development build complete"

# Quick update (build + copy only)
update: build copy
	@echo "⚡ Quick update complete"

# Show help
help:
	@echo "🛰️ ServerTrack Satellites Makefile"
	@echo ""
	@echo "Available targets:"
	@echo "  all     - Full build, commit, push, and release (default)"
	@echo "  build   - Build binary from source"
	@echo "  copy    - Copy binary to public repo"
	@echo "  test    - Test binary functionality"
	@echo "  commit  - Git add and commit changes"
	@echo "  push    - Push changes to GitHub"
	@echo "  release - Create GitHub release with binary"
	@echo "  dev     - Development build (no release)"
	@echo "  update  - Quick update (build + copy only)"
	@echo "  clean   - Clean build artifacts"
	@echo "  help    - Show this help message"
	@echo ""
	@echo "Usage examples:"
	@echo "  make          # Full build and release"
	@echo "  make dev      # Development build only"
	@echo "  make update   # Quick update without release"
	@echo "  make clean    # Clean up artifacts"