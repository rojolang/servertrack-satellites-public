# 🛰️ ServerTrack Satellites Binary

The `servertrack-satellites` binary is not included in this repository due to size constraints.

## Download Binary

The binary will be automatically downloaded when you run the installer:

```bash
curl -fsSL https://raw.githubusercontent.com/rojolang/servertrack-satellites/main/public-install.sh | sudo bash
```

## Manual Binary Download

If you need to download the binary manually:

```bash
# Download from releases (when available)
curl -fsSL https://github.com/rojolang/servertrack-satellites/releases/latest/download/servertrack-satellites -o servertrack-satellites
chmod +x servertrack-satellites
```

## Build from Source

To build the binary from source code:

```bash
# This would require the Go source code
go build -o servertrack-satellites .
```

---

**Note: The binary is approximately 5.4MB and contains the complete ServerTrack Satellites API server.**