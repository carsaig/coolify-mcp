#!/bin/bash

# Comprehensive test script for Coolify MCP Server
# This script tests the MCP server functionality step by step

set -e  # Exit on any error

echo "=== Coolify MCP Server Test Suite ==="
echo "This script will test the MCP server functionality comprehensively."
echo

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo "❌ .env file not found!"
    echo "Please run ./tmp/setup-environment.sh first to configure environment variables."
    exit 1
fi

# Load environment variables
source .env

if [ -z "$COOLIFY_BASE_URL" ] || [ -z "$COOLIFY_ACCESS_TOKEN" ]; then
    echo "❌ Environment variables not properly set!"
    echo "Please check your .env file."
    exit 1
fi

echo "✅ Environment variables loaded"
echo "COOLIFY_BASE_URL: $COOLIFY_BASE_URL"
echo "COOLIFY_ACCESS_TOKEN: ***${COOLIFY_ACCESS_TOKEN: -4}"
echo

# Test 1: Build the Docker image locally
echo "=== Test 1: Building Docker Image ==="
echo "Building the Coolify MCP server image..."

if docker build -t coolify-mcp:local . > build.log 2>&1; then
    echo "✅ Docker image built successfully"
else
    echo "❌ Docker build failed!"
    echo "Build log:"
    cat build.log
    exit 1
fi
echo

# Test 2: Test container startup
echo "=== Test 2: Container Startup Test ==="
echo "Testing if the container can start without errors..."

# Create a simple test that doesn't require stdio input
if timeout 10s docker run --rm \
    -e COOLIFY_BASE_URL="$COOLIFY_BASE_URL" \
    -e COOLIFY_ACCESS_TOKEN="$COOLIFY_ACCESS_TOKEN" \
    -e DEBUG="coolify:*" \
    coolify-mcp:local \
    node -e "
        console.log('Container startup test');
        console.log('Node version:', process.version);
        console.log('Environment check:');
        console.log('- COOLIFY_BASE_URL:', process.env.COOLIFY_BASE_URL ? 'SET' : 'NOT SET');
        console.log('- COOLIFY_ACCESS_TOKEN:', process.env.COOLIFY_ACCESS_TOKEN ? 'SET' : 'NOT SET');
        process.exit(0);
    " > startup.log 2>&1; then
    echo "✅ Container starts successfully"
    cat startup.log
else
    echo "❌ Container startup failed!"
    echo "Startup log:"
    cat startup.log
    exit 1
fi
echo

# Test 3: Test MCP server initialization
echo "=== Test 3: MCP Server Initialization ==="
echo "Testing MCP server initialization..."

# Create a test that tries to initialize the MCP server but exits quickly
if timeout 15s docker run --rm \
    -e COOLIFY_BASE_URL="$COOLIFY_BASE_URL" \
    -e COOLIFY_ACCESS_TOKEN="$COOLIFY_ACCESS_TOKEN" \
    -e DEBUG="coolify:*" \
    coolify-mcp:local \
    node -e "
        const { CoolifyMcpServer } = require('./dist/lib/mcp-server.js');
        const config = {
            baseUrl: process.env.COOLIFY_BASE_URL,
            accessToken: process.env.COOLIFY_ACCESS_TOKEN
        };
        console.log('Testing MCP server initialization...');
        try {
            const server = new CoolifyMcpServer(config);
            console.log('✅ MCP server created successfully');
            console.log('Server name:', server.name);
            console.log('Server version:', server.version);
            process.exit(0);
        } catch (error) {
            console.error('❌ MCP server initialization failed:', error.message);
            process.exit(1);
        }
    " > mcp_init.log 2>&1; then
    echo "✅ MCP server initializes successfully"
    cat mcp_init.log
else
    echo "❌ MCP server initialization failed!"
    echo "Initialization log:"
    cat mcp_init.log
    exit 1
fi
echo

# Test 4: Test Coolify API connectivity
echo "=== Test 4: Coolify API Connectivity ==="
echo "Testing connection to Coolify API..."

if timeout 20s docker run --rm \
    -e COOLIFY_BASE_URL="$COOLIFY_BASE_URL" \
    -e COOLIFY_ACCESS_TOKEN="$COOLIFY_ACCESS_TOKEN" \
    coolify-mcp:local \
    node -e "
        const { CoolifyClient } = require('./dist/lib/coolify-client.js');
        const config = {
            baseUrl: process.env.COOLIFY_BASE_URL,
            accessToken: process.env.COOLIFY_ACCESS_TOKEN
        };
        console.log('Testing Coolify API connectivity...');
        const client = new CoolifyClient(config);
        client.validateConnection()
            .then(() => {
                console.log('✅ Coolify API connection successful');
                return client.listServers();
            })
            .then(servers => {
                console.log('Available servers:', servers.length);
                process.exit(0);
            })
            .catch(error => {
                console.error('❌ Coolify API connection failed:', error.message);
                process.exit(1);
            });
    " > api_test.log 2>&1; then
    echo "✅ Coolify API connection successful"
    cat api_test.log
else
    echo "❌ Coolify API connection failed!"
    echo "API test log:"
    cat api_test.log
    exit 1
fi
echo

# Test 5: Test MCP protocol communication
echo "=== Test 5: MCP Protocol Communication ==="
echo "Testing MCP protocol initialization message..."

# Create MCP initialization message
mcp_init_message='{"jsonrpc": "2.0", "id": 1, "method": "initialize", "params": {"protocolVersion": "2024-11-05", "capabilities": {}, "clientInfo": {"name": "test", "version": "1.0.0"}}}'

if echo "$mcp_init_message" | timeout 30s docker run --rm -i \
    -e COOLIFY_BASE_URL="$COOLIFY_BASE_URL" \
    -e COOLIFY_ACCESS_TOKEN="$COOLIFY_ACCESS_TOKEN" \
    -e DEBUG="coolify:*" \
    coolify-mcp:local > mcp_protocol.log 2>&1; then
    echo "✅ MCP protocol communication successful"
    echo "Response:"
    cat mcp_protocol.log | head -20
else
    echo "❌ MCP protocol communication failed!"
    echo "Protocol test log:"
    cat mcp_protocol.log
    exit 1
fi
echo

# Cleanup
echo "=== Cleanup ==="
rm -f build.log startup.log mcp_init.log api_test.log mcp_protocol.log

echo "=== All Tests Passed! ==="
echo
echo "Your Coolify MCP server is working correctly. You can now:"
echo "1. Push the image to registry: docker tag coolify-mcp:local ghcr.io/carsaig/coolify-mcp:latest"
echo "2. Configure your MCP client (see tmp/mcp-client-config.md)"
echo "3. Use the server with Claude Desktop or other MCP clients"
echo
echo "Remember: MCP servers are designed to exit when no client is connected."
echo "This is normal behavior, not a crash!"
