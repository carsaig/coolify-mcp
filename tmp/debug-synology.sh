#!/bin/bash

# Debug script for Coolify MCP server on Synology NAS
# Run this script on your Synology system to diagnose issues

echo "=== Coolify MCP Server Debug Script ==="
echo "Timestamp: $(date)"
echo

# Check Docker version and status
echo "=== Docker Information ==="
docker --version
docker info | grep -E "(Server Version|Storage Driver|Logging Driver|Cgroup Driver)"
echo

# Check if container exists and its status
echo "=== Container Status ==="
if docker ps -a | grep -q coolify-mcp; then
    echo "Container 'coolify-mcp' found:"
    docker ps -a | grep coolify-mcp
    echo
    
    # Get container details
    echo "=== Container Details ==="
    docker inspect coolify-mcp | jq -r '.[] | {
        State: .State,
        Config: {
            Image: .Config.Image,
            Env: .Config.Env,
            Cmd: .Config.Cmd
        },
        NetworkSettings: .NetworkSettings.Networks
    }'
    echo
    
    # Get container logs
    echo "=== Container Logs (last 50 lines) ==="
    docker logs --tail 50 --timestamps coolify-mcp
    echo
    
    # Check if container is running
    if docker ps | grep -q coolify-mcp; then
        echo "Container is currently running"
        
        # Try to execute a command inside the container
        echo "=== Container Health Check ==="
        docker exec coolify-mcp node -e "console.log('Container is responsive')" 2>/dev/null || echo "Container not responsive to exec commands"
    else
        echo "Container is not running"
        
        # Try to start it and capture immediate output
        echo "=== Attempting to start container ==="
        docker start coolify-mcp
        sleep 5
        docker logs --tail 20 coolify-mcp
    fi
else
    echo "Container 'coolify-mcp' not found"
    echo "Available containers:"
    docker ps -a
fi

echo
echo "=== Docker Images ==="
docker images | grep -E "(coolify|mcp)"

echo
echo "=== Network Information ==="
docker network ls
if docker network ls | grep -q mcp-net; then
    echo "mcp-net network details:"
    docker network inspect mcp-net
fi

echo
echo "=== System Resources ==="
echo "Memory usage:"
free -h
echo "Disk usage:"
df -h | grep -E "(/$|/volume)"

echo
echo "=== Environment Variables Check ==="
echo "COOLIFY_BASE_URL: ${COOLIFY_BASE_URL:-'NOT SET'}"
echo "COOLIFY_ACCESS_TOKEN: ${COOLIFY_ACCESS_TOKEN:+'SET (length: ' + ${#COOLIFY_ACCESS_TOKEN} + ')'}"
echo "DEBUG: ${DEBUG:-'NOT SET'}"

echo
echo "=== Recommendations ==="
echo "1. Check the container logs above for specific error messages"
echo "2. Verify your COOLIFY_BASE_URL and COOLIFY_ACCESS_TOKEN are correct"
echo "3. Ensure your Coolify instance is accessible from this network"
echo "4. Try running the debug version: docker-compose -f docker-compose.debug.yml up"

echo
echo "=== Debug script completed ==="
