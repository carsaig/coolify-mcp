#!/usr/bin/env node

// Simple MCP protocol test script
// This script tests the MCP server by sending protocol messages

const { spawn } = require('child_process');
const path = require('path');

console.log('=== MCP Protocol Test ===');

// Check if we have the required environment variables
if (!process.env.COOLIFY_BASE_URL || !process.env.COOLIFY_ACCESS_TOKEN) {
    console.error('❌ Environment variables not set!');
    console.error('Please set COOLIFY_BASE_URL and COOLIFY_ACCESS_TOKEN');
    process.exit(1);
}

console.log('Environment:');
console.log('- COOLIFY_BASE_URL:', process.env.COOLIFY_BASE_URL);
console.log('- COOLIFY_ACCESS_TOKEN:', '***' + process.env.COOLIFY_ACCESS_TOKEN.slice(-4));
console.log();

// Test messages
const testMessages = [
    {
        name: 'Initialize',
        message: {
            jsonrpc: '2.0',
            id: 1,
            method: 'initialize',
            params: {
                protocolVersion: '2024-11-05',
                capabilities: {},
                clientInfo: {
                    name: 'test-client',
                    version: '1.0.0'
                }
            }
        }
    },
    {
        name: 'List Tools',
        message: {
            jsonrpc: '2.0',
            id: 2,
            method: 'tools/list',
            params: {}
        }
    }
];

async function testMCPServer() {
    console.log('Starting MCP server...');
    
    // Start the MCP server process
    const serverProcess = spawn('node', ['dist/index.js'], {
        env: {
            ...process.env,
            DEBUG: 'coolify:*'
        },
        stdio: ['pipe', 'pipe', 'pipe']
    });

    let responseBuffer = '';
    let messageCount = 0;
    
    // Handle server output
    serverProcess.stdout.on('data', (data) => {
        const output = data.toString();
        responseBuffer += output;
        
        // Look for JSON-RPC responses
        const lines = responseBuffer.split('\n');
        for (const line of lines) {
            if (line.trim() && line.includes('"jsonrpc"')) {
                try {
                    const response = JSON.parse(line.trim());
                    console.log(`✅ Received response for message ${response.id}:`);
                    console.log(JSON.stringify(response, null, 2));
                    console.log();
                    
                    messageCount++;
                    if (messageCount >= testMessages.length) {
                        console.log('✅ All test messages completed successfully!');
                        serverProcess.kill();
                        process.exit(0);
                    }
                } catch (e) {
                    // Not a JSON response, might be debug output
                    console.log('Debug output:', line.trim());
                }
            }
        }
    });

    // Handle server errors
    serverProcess.stderr.on('data', (data) => {
        const error = data.toString();
        if (error.includes('Fatal error:')) {
            console.error('❌ Server fatal error:', error);
            process.exit(1);
        } else {
            console.log('Server debug:', error.trim());
        }
    });

    // Handle server exit
    serverProcess.on('exit', (code) => {
        if (code !== 0) {
            console.error(`❌ Server exited with code ${code}`);
            process.exit(1);
        }
    });

    // Wait a moment for server to start
    await new Promise(resolve => setTimeout(resolve, 2000));

    // Send test messages
    for (const test of testMessages) {
        console.log(`Sending ${test.name} message...`);
        const messageStr = JSON.stringify(test.message) + '\n';
        serverProcess.stdin.write(messageStr);
        
        // Wait between messages
        await new Promise(resolve => setTimeout(resolve, 1000));
    }

    // Timeout after 30 seconds
    setTimeout(() => {
        console.error('❌ Test timeout - server not responding');
        serverProcess.kill();
        process.exit(1);
    }, 30000);
}

// Check if dist/index.js exists
const serverPath = path.join(process.cwd(), 'dist', 'index.js');
const fs = require('fs');

if (!fs.existsSync(serverPath)) {
    console.error('❌ Server not built! Please run: npm run build');
    process.exit(1);
}

console.log('✅ Server found at:', serverPath);
console.log();

// Run the test
testMCPServer().catch(error => {
    console.error('❌ Test failed:', error);
    process.exit(1);
});
