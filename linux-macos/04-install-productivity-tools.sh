#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/shared.sh"

assert_not_root

# Run platform-specific installs
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	echo "⏭️  No productivity tools for Linux..."
elif [[ "$OSTYPE" == "darwin"* ]]; then
	source "$SCRIPT_DIR/macos/04-install-productivity-tools.sh"
fi
