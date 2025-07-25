#!/usr/bin/env node

// Debug script to test Coolify MCP server in Docker
console.log('=== Coolify MCP Server Debug ===');
console.log('Node version:', process.version);
console.log('Platform:', process.platform);
console.log('Architecture:', process.arch);
console.log('Working directory:', process.cwd());

// Check environment variables
console.log('\n=== Environment Variables ===');
console.log('COOLIFY_BASE_URL:', process.env.COOLIFY_BASE_URL || 'NOT SET');
console.log('COOLIFY_ACCESS_TOKEN:', process.env.COOLIFY_ACCESS_TOKEN ? 'SET (length: ' + process.env.COOLIFY_ACCESS_TOKEN.length + ')' : 'NOT SET');
console.log('DEBUG:', process.env.DEBUG || 'NOT SET');

// Check if required files exist
const fs = require('fs');
const path = require('path');

console.log('\n=== File System Check ===');
const requiredFiles = [
    'dist/index.js',
    'dist/lib/mcp-server.js',
    'dist/lib/coolify-client.js',
    'package.json'
];

requiredFiles.forEach(file => {
    const exists = fs.existsSync(path.join(process.cwd(), file));
    console.log(`${file}: ${exists ? 'EXISTS' : 'MISSING'}`);
});

// Test basic connectivity
console.log('\n=== Connectivity Test ===');
if (process.env.COOLIFY_BASE_URL && process.env.COOLIFY_ACCESS_TOKEN) {
    const baseUrl = process.env.COOLIFY_BASE_URL;
    console.log('Testing connection to:', baseUrl);
    
    // Simple fetch test
    fetch(`${baseUrl}/api/v1/servers`, {
        headers: {
            'Authorization': `Bearer ${process.env.COOLIFY_ACCESS_TOKEN}`,
            'Content-Type': 'application/json'
        }
    })
    .then(response => {
        console.log('HTTP Status:', response.status);
        console.log('Response OK:', response.ok);
        return response.text();
    })
    .then(text => {
        console.log('Response preview:', text.substring(0, 200));
        console.log('\n=== Starting MCP Server ===');
        
        // Now try to start the actual MCP server
        try {
            require('./dist/index.js');
        } catch (error) {
            console.error('Failed to start MCP server:', error);
            process.exit(1);
        }
    })
    .catch(error => {
        console.error('Connection test failed:', error.message);
        console.log('\n=== Attempting to start MCP server anyway ===');
        
        try {
            require('./dist/index.js');
        } catch (serverError) {
            console.error('Failed to start MCP server:', serverError);
            process.exit(1);
        }
    });
} else {
    console.log('Environment variables not set, cannot test connectivity');
    console.log('Attempting to start MCP server anyway...');
    
    try {
        require('./dist/index.js');
    } catch (error) {
        console.error('Failed to start MCP server:', error);
        process.exit(1);
    }
}
