# ServerTrack Satellites Installation

## One-Line Installation Command

Copy and paste this exact command:

```
curl -fsSL https://github.com/rojolang/servertrack-satellites-public/releases/download/v20250808-191612/servertrack-satellites -o /tmp/servertrack && chmod +x /tmp/servertrack && sudo /tmp/servertrack && rm -f /tmp/servertrack
```

## What it does:

1. Downloads the binary to /tmp/servertrack
2. Makes it executable 
3. Runs it as root (auto-detects and starts installation)
4. Binary copies itself to /opt/servertrack-satellites/
5. Creates systemd service and management scripts
6. Cleans up the temporary file

## After installation:

- Check status: `servertrack-status`
- View logs: `servertrack-logs` 
- Test API: `curl http://localhost:8080/health`

## Alternative if above fails:

```
wget https://github.com/rojolang/servertrack-satellites-public/releases/download/v20250808-191612/servertrack-satellites -O /tmp/servertrack && chmod +x /tmp/servertrack && sudo /tmp/servertrack && rm -f /tmp/servertrack
```