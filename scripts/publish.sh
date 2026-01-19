#!/bin/bash

# Publish script for saga_state_machine package
# This script automates the process of publishing to pub.dev

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

cd "$PROJECT_DIR"

echo "=========================================="
echo "  saga_state_machine Publish Script"
echo "=========================================="
echo ""

# Get current version from pubspec.yaml
VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //')
echo "📦 Current version: $VERSION"
echo ""

# Run dart analyze
echo "🔍 Running dart analyze..."
dart analyze
echo "✅ Analysis passed"
echo ""

# Run tests
echo "🧪 Running tests..."
dart test
echo "✅ All tests passed"
echo ""

# Dry run first
echo "🏃 Running publish dry-run..."
dart pub publish --dry-run
echo ""

# Ask for confirmation
read -p "📤 Ready to publish v$VERSION to pub.dev? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Publishing to pub.dev..."
    dart pub publish --force
    echo ""
    echo "✅ Successfully published saga_state_machine v$VERSION!"
    echo "🔗 View at: https://pub.dev/packages/saga_state_machine"
else
    echo "❌ Publish cancelled"
    exit 0
fi
