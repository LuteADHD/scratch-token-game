#!/bin/bash

# SCRATCH Token Gaming Platform Deployment Script
# This script handles the complete deployment process

set -e

echo "🎰 SCRATCH Token Gaming Platform Deployment"
echo "==========================================="

# Configuration
NETWORK=${1:-devnet}
PROJECT_NAME="scratch-token-game"

echo "📋 Deployment Configuration:"
echo "   Network: $NETWORK"
echo "   Project: $PROJECT_NAME"
echo ""

# Check prerequisites
echo "🔍 Checking prerequisites..."

if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed"
    exit 1
fi

if ! command -v cargo &> /dev/null; then
    echo "❌ Rust/Cargo is not installed"
    exit 1
fi

if ! command -v solana &> /dev/null; then
    echo "❌ Solana CLI is not installed"
    exit 1
fi

if ! command -v anchor &> /dev/null; then
    echo "❌ Anchor CLI is not installed"
    exit 1
fi

echo "✅ All prerequisites found"

# Set Solana network
echo "🌐 Setting Solana network to $NETWORK..."
solana config set --url $NETWORK

# Check wallet balance
echo "💰 Checking wallet balance..."
BALANCE=$(solana balance --lamports | head -1)
if [ "$BALANCE" -lt 1000000000 ]; then
    echo "⚠️  Low SOL balance. You may need more SOL for deployment."
    if [ "$NETWORK" == "devnet" ]; then
        echo "🎁 Requesting devnet airdrop..."
        solana airdrop 2
    fi
fi

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Build smart contracts
echo "🔨 Building smart contracts..."
cd smart-contracts
anchor build

# Run tests
echo "🧪 Running tests..."
anchor test --skip-deploy

# Deploy smart contracts
echo "🚀 Deploying smart contracts to $NETWORK..."
anchor deploy --provider.cluster $NETWORK

# Update frontend configuration
echo "⚙️  Updating frontend configuration..."
cd ../frontend
PROGRAM_ID=$(anchor keys list | grep "scratch_game" | awk '{print $2}')
echo "Program ID: $PROGRAM_ID"

# Create config file
cat > js/config.js << EOF
// Auto-generated configuration
const CONFIG = {
    network: '$NETWORK',
    programId: '$PROGRAM_ID',
    rpcUrl: '$(solana config get | grep "RPC URL" | awk '{print $3}')',
    commitment: 'confirmed'
};

if (typeof module !== 'undefined' && module.exports) {
    module.exports = CONFIG;
}
EOF

# Build frontend
echo "🎨 Building frontend..."
cd ..
npm run build:frontend

# Deploy to hosting (if configured)
if [ -n "$VERCEL_TOKEN" ]; then
    echo "🌐 Deploying to Vercel..."
    npx vercel --prod --token $VERCEL_TOKEN
elif [ -n "$NETLIFY_TOKEN" ]; then
    echo "🌐 Deploying to Netlify..."
    npx netlify deploy --prod --auth $NETLIFY_TOKEN
else
    echo "📁 Frontend built successfully. Deploy manually to your hosting provider."
fi

echo ""
echo "🎉 Deployment completed successfully!"
echo "=================================="
echo "   Network: $NETWORK"
echo "   Program ID: $PROGRAM_ID"
echo "   RPC URL: $(solana config get | grep "RPC URL" | awk '{print $3}')"
echo ""
echo "📝 Next steps:"
echo "   1. Update pump.fun token configuration"
echo "   2. Initialize prize pools"
echo "   3. Test all game mechanics"
echo "   4. Launch marketing campaign"
echo ""
echo "⚠️  Remember to:"
echo "   - Backup your keypairs"
echo "   - Monitor smart contract accounts"
echo "   - Set up monitoring and alerts"
echo ""
echo "🔗 Useful commands:"
echo "   solana program show $PROGRAM_ID"
echo "   solana account <token_account>"
echo "   anchor idl fetch $PROGRAM_ID"
echo ""
echo "Good luck with your SCRATCH token launch! 🚀"
