# Coolify MCP Server Troubleshooting Guide

## Quick Diagnosis

If your Coolify MCP server container is "crashing", first understand that **this is likely normal behavior**. MCP servers are designed to:

1. Start when called by an MCP client
2. Process requests via stdio (standard input/output)
3. Exit when the client disconnects

**A container that exits immediately is NOT necessarily broken!**

## Step-by-Step Troubleshooting

### 1. Run the Debug Script

```bash
# On your Synology NAS, run:
./tmp/debug-synology.sh
```

This will show you:
- Container status and logs
- Docker configuration
- Network settings
- System resources

### 2. Check Environment Variables

```bash
# Run the environment setup:
./tmp/setup-environment.sh
```

Ensure you have:
- `COOLIFY_BASE_URL` - Your Coolify instance URL
- `COOLIFY_ACCESS_TOKEN` - Valid API token from Coolify

### 3. Test the Server Functionality

```bash
# Run comprehensive tests:
./tmp/test-mcp-server.sh
```

This will test:
- Docker image building
- Container startup
- MCP server initialization
- Coolify API connectivity
- MCP protocol communication

### 4. Test MCP Protocol Directly

```bash
# Test MCP protocol communication:
echo '{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {"name": "test", "version": "1.0.0"}}}' | \
docker run --rm -i \
  -e COOLIFY_BASE_URL="https://your-coolify-instance.com" \
  -e COOLIFY_ACCESS_TOKEN="your-actual-token" \
  ghcr.io/carsaig/coolify-mcp:latest
```

Expected: JSON response with server capabilities.

## Common Issues and Solutions

### Issue: "Container keeps crashing"

**Likely Cause**: This is normal MCP server behavior.

**Solution**: 
- MCP servers exit when no client is connected
- Configure your MCP client (Claude Desktop) properly
- Don't run the container with `docker-compose up -d` expecting it to stay running

### Issue: "COOLIFY_ACCESS_TOKEN environment variable is required"

**Cause**: Environment variables not set or not passed to container.

**Solution**:
```bash
# Create .env file:
./tmp/setup-environment.sh

# Or set directly:
export COOLIFY_BASE_URL="https://your-coolify-instance.com"
export COOLIFY_ACCESS_TOKEN="your-actual-token"
```

### Issue: "Failed to connect to Coolify server"

**Cause**: Network connectivity or wrong URL/token.

**Solutions**:
1. Verify Coolify instance is accessible:
   ```bash
   curl -I https://your-coolify-instance.com
   ```

2. Test API endpoint:
   ```bash
   curl -H "Authorization: Bearer your-token" \
        https://your-coolify-instance.com/api/v1/servers
   ```

3. Check firewall/network settings on Synology

### Issue: "Docker build fails"

**Cause**: Missing dependencies or network issues.

**Solutions**:
1. Check Docker context: `docker context ls`
2. Ensure internet connectivity for npm install
3. Try building with debug: `docker build --progress=plain -t coolify-mcp:test .`

### Issue: "MCP client can't connect"

**Cause**: Wrong client configuration.

**Solution**: Use the correct Claude Desktop config:
```json
{
  "mcpServers": {
    "coolify": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "-e", "COOLIFY_BASE_URL=https://your-coolify-instance.com",
        "-e", "COOLIFY_ACCESS_TOKEN=your-actual-token",
        "ghcr.io/carsaig/coolify-mcp:latest"
      ]
    }
  }
}
```

## Debug Mode

For detailed debugging, use the debug image:

```bash
# Build debug image:
docker build -f tmp/Dockerfile.debug -t coolify-mcp:debug .

# Run with debug output:
docker run --rm -it \
  -e COOLIFY_BASE_URL="https://your-coolify-instance.com" \
  -e COOLIFY_ACCESS_TOKEN="your-actual-token" \
  -e DEBUG="coolify:*" \
  coolify-mcp:debug
```

## Getting Help

If you're still having issues:

1. Run all diagnostic scripts and save the output
2. Check the GitHub repository issues
3. Provide the following information:
   - Synology model and DSM version
   - Docker version (`docker --version`)
   - Output from `./tmp/debug-synology.sh`
   - Output from `./tmp/test-mcp-server.sh`
   - Your MCP client configuration (with tokens redacted)

## Remember

- **Container exits are normal** for MCP servers
- **Test connectivity first** before blaming the container
- **Use the debug scripts** - they're designed to find the real issues
- **MCP servers are not web servers** - they don't need ports or persistent running
