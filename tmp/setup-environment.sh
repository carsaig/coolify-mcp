#!/bin/bash

# Environment setup script for Coolify MCP Server on Synology NAS
# This script helps configure the environment variables and test connectivity

echo "=== Coolify MCP Server Environment Setup ==="
echo "This script will help you configure the environment for the Coolify MCP server."
echo

# Function to prompt for input with validation
prompt_for_input() {
    local prompt="$1"
    local var_name="$2"
    local validation_func="$3"
    local value=""
    
    while true; do
        echo -n "$prompt: "
        read -r value
        
        if [ -n "$validation_func" ] && ! $validation_func "$value"; then
            echo "Invalid input. Please try again."
            continue
        fi
        
        if [ -n "$value" ]; then
            eval "$var_name='$value'"
            break
        else
            echo "This field is required. Please enter a value."
        fi
    done
}

# Validation functions
validate_url() {
    local url="$1"
    if [[ "$url" =~ ^https?:// ]]; then
        return 0
    else
        echo "URL must start with http:// or https://"
        return 1
    fi
}

validate_token() {
    local token="$1"
    if [ ${#token} -ge 10 ]; then
        return 0
    else
        echo "Token seems too short. Please verify it's correct."
        return 1
    fi
}

# Check if .env file already exists
if [ -f ".env" ]; then
    echo "Found existing .env file:"
    cat .env
    echo
    echo -n "Do you want to update it? (y/N): "
    read -r update_env
    if [[ ! "$update_env" =~ ^[Yy]$ ]]; then
        echo "Using existing .env file."
        source .env
        SKIP_ENV_SETUP=true
    fi
fi

if [ "$SKIP_ENV_SETUP" != "true" ]; then
    echo "=== Environment Variable Configuration ==="
    echo
    
    # Get Coolify base URL
    prompt_for_input "Enter your Coolify instance URL (e.g., https://coolify.yourdomain.com)" COOLIFY_BASE_URL validate_url
    
    # Get Coolify access token
    prompt_for_input "Enter your Coolify API access token" COOLIFY_ACCESS_TOKEN validate_token
    
    # Ask about debug logging
    echo -n "Enable debug logging? (y/N): "
    read -r enable_debug
    if [[ "$enable_debug" =~ ^[Yy]$ ]]; then
        DEBUG="coolify:*"
    else
        DEBUG=""
    fi
    
    # Create .env file
    echo "=== Creating .env file ==="
    cat > .env << EOF
# Coolify MCP Server Environment Variables
COOLIFY_BASE_URL=$COOLIFY_BASE_URL
COOLIFY_ACCESS_TOKEN=$COOLIFY_ACCESS_TOKEN
DEBUG=$DEBUG
NODE_ENV=production
EOF
    
    echo "Environment file created successfully!"
    echo
fi

# Test connectivity
echo "=== Testing Coolify API Connectivity ==="
echo "Testing connection to: $COOLIFY_BASE_URL"

# Test basic connectivity
if command -v curl >/dev/null 2>&1; then
    echo "Testing basic connectivity..."
    if curl -s --connect-timeout 10 "$COOLIFY_BASE_URL" >/dev/null; then
        echo "✅ Basic connectivity to Coolify instance successful"
    else
        echo "❌ Cannot reach Coolify instance at $COOLIFY_BASE_URL"
        echo "Please check:"
        echo "  - URL is correct"
        echo "  - Coolify instance is running"
        echo "  - Network connectivity from this machine"
    fi
    
    echo "Testing API endpoint..."
    api_response=$(curl -s -w "%{http_code}" -H "Authorization: Bearer $COOLIFY_ACCESS_TOKEN" \
                   -H "Content-Type: application/json" \
                   "$COOLIFY_BASE_URL/api/v1/servers" -o /tmp/api_test.json)
    
    if [ "$api_response" = "200" ]; then
        echo "✅ API authentication successful"
        echo "Available servers:"
        cat /tmp/api_test.json | head -c 200
        echo "..."
    else
        echo "❌ API authentication failed (HTTP $api_response)"
        echo "Please check:"
        echo "  - API token is correct"
        echo "  - Token has proper permissions"
        echo "  - API endpoint is accessible"
        if [ -f /tmp/api_test.json ]; then
            echo "Response:"
            cat /tmp/api_test.json
        fi
    fi
    
    rm -f /tmp/api_test.json
else
    echo "⚠️  curl not available, skipping connectivity test"
fi

echo
echo "=== Environment Setup Complete ==="
echo "Your .env file is ready. You can now:"
echo "1. Build the Docker image: docker build -t coolify-mcp:local ."
echo "2. Run with docker-compose: docker-compose up -d"
echo "3. Check logs: docker logs coolify-mcp"
echo
echo "Environment variables:"
echo "COOLIFY_BASE_URL=$COOLIFY_BASE_URL"
echo "COOLIFY_ACCESS_TOKEN=***${COOLIFY_ACCESS_TOKEN: -4}"
echo "DEBUG=$DEBUG"
