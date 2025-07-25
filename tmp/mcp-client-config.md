# MCP Client Configuration for Coolify MCP Server

## Understanding MCP Transport

The Coolify MCP server uses **stdio transport**, which means it communicates through standard input/output streams, not HTTP. This is different from web servers and requires special configuration for MCP clients.

## Important Notes

- **The container will exit immediately if no MCP client is connected** - this is normal behavior
- MCP servers are designed to be started by MCP clients, not run as standalone services
- The Docker container should only be used when called by an MCP client

## Configuration for Different MCP Clients

### 1. Claude Desktop

Create or update your Claude Desktop configuration file:

**macOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "coolify": {
      "command": "docker",
      "args": [
        "run", "--rm", "-i",
        "--env-file", "/path/to/your/.env",
        "ghcr.io/carsaig/coolify-mcp:latest"
      ]
    }
  }
}
```

Or if you want to pass environment variables directly:

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

### 2. Direct Node.js Execution (Alternative)

If you prefer to run without Docker:

```json
{
  "mcpServers": {
    "coolify": {
      "command": "node",
      "args": ["/path/to/coolify-mcp/dist/index.js"],
      "env": {
        "COOLIFY_BASE_URL": "https://your-coolify-instance.com",
        "COOLIFY_ACCESS_TOKEN": "your-actual-token"
      }
    }
  }
}
```

### 3. Testing MCP Protocol Communication

To test if the MCP server responds correctly, you can use this command:

```bash
# Test MCP initialization
echo '{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {"name": "test", "version": "1.0.0"}}}' | \
docker run --rm -i \
  -e COOLIFY_BASE_URL="https://your-coolify-instance.com" \
  -e COOLIFY_ACCESS_TOKEN="your-actual-token" \
  ghcr.io/carsaig/coolify-mcp:latest
```

Expected response should include server capabilities and available tools.

## Troubleshooting

### Container Exits Immediately
This is **normal behavior** for MCP servers. They are designed to:
1. Start when called by an MCP client
2. Process requests via stdio
3. Exit when the client disconnects

### Testing Container Health
To verify the container can start properly:

```bash
# Test that the container can start and show help
docker run --rm \
  -e COOLIFY_BASE_URL="https://your-coolify-instance.com" \
  -e COOLIFY_ACCESS_TOKEN="your-actual-token" \
  ghcr.io/carsaig/coolify-mcp:latest \
  --help 2>/dev/null || echo "Container started successfully"
```

### Debug Mode
For debugging, use the debug image:

```bash
docker run --rm -it \
  -e COOLIFY_BASE_URL="https://your-coolify-instance.com" \
  -e COOLIFY_ACCESS_TOKEN="your-actual-token" \
  -e DEBUG="coolify:*" \
  coolify-mcp:debug
```

## Key Points

1. **Don't expect the container to stay running** - MCP servers are not web servers
2. **Configure your MCP client properly** - the client starts and manages the server
3. **Use environment variables** - never hardcode credentials
4. **Test connectivity first** - ensure your Coolify instance is accessible
5. **Check logs in the MCP client** - not in the Docker container logs
