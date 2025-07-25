# Coolify MCP Server Debug and Setup Tools

This directory contains comprehensive tools to debug and set up the Coolify MCP server on your Synology NAS.

## Quick Start

1. **Set up environment variables:**
   ```bash
   ./setup-environment.sh
   ```

2. **Run comprehensive tests:**
   ```bash
   ./test-mcp-server.sh
   ```

3. **Debug container issues:**
   ```bash
   ./debug-synology.sh
   ```

## Files Overview

### Setup and Configuration
- `setup-environment.sh` - Interactive environment variable setup
- `claude-desktop-config.json` - Example Claude Desktop configuration
- `mcp-client-config.md` - Complete MCP client configuration guide

### Testing and Debugging
- `test-mcp-server.sh` - Comprehensive test suite for the MCP server
- `test-mcp-protocol.js` - Direct MCP protocol testing
- `debug-synology.sh` - System and container diagnostics
- `Dockerfile.debug` - Debug version of the Docker image
- `docker-compose.debug.yml` - Debug docker-compose configuration

### Documentation
- `TROUBLESHOOTING.md` - Complete troubleshooting guide
- `README.md` - This file

## Understanding MCP Server Behavior

**Important**: MCP servers are NOT web servers. They:
- Use stdio transport (not HTTP)
- Start when called by MCP clients
- Exit when clients disconnect
- Don't need to "stay running" like web servers

If your container "crashes" immediately, this is likely **normal behavior**.

## Typical Workflow

1. **First time setup:**
   ```bash
   ./setup-environment.sh  # Configure environment
   ./test-mcp-server.sh    # Verify everything works
   ```

2. **If having issues:**
   ```bash
   ./debug-synology.sh     # Diagnose the problem
   ```

3. **Configure MCP client:**
   - Copy `claude-desktop-config.json` to Claude Desktop config
   - Update with your actual Coolify URL and token
   - Restart Claude Desktop

4. **Test MCP integration:**
   - Open Claude Desktop
   - Look for Coolify tools in the interface
   - Try using a Coolify command

## Environment Variables Required

- `COOLIFY_BASE_URL` - Your Coolify instance URL
- `COOLIFY_ACCESS_TOKEN` - API token from Coolify
- `DEBUG` - (Optional) Set to "coolify:*" for debug output

## Common Issues

### "Container keeps crashing"
- **This is normal!** MCP servers exit when no client is connected
- Configure your MCP client properly instead

### "Can't connect to Coolify"
- Check your URL and token with `./setup-environment.sh`
- Verify network connectivity to your Coolify instance

### "Docker build fails"
- Check internet connectivity for npm install
- Verify Docker is working: `docker --version`

### "MCP client can't find server"
- Check Claude Desktop configuration
- Ensure Docker image is available
- Verify environment variables are set

## Getting Support

1. Run the diagnostic scripts and save output
2. Check `TROUBLESHOOTING.md` for detailed solutions
3. Review the GitHub repository issues
4. Provide diagnostic output when asking for help

## Files You Can Safely Delete

After setup is complete, you can delete:
- `setup-environment.sh` (after running once)
- `test-mcp-server.sh` (after successful tests)
- `debug-synology.sh` (keep for future debugging)
- `Dockerfile.debug` and `docker-compose.debug.yml` (unless debugging)

Keep these for reference:
- `mcp-client-config.md`
- `TROUBLESHOOTING.md`
- `claude-desktop-config.json`
