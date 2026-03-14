#!/usr/bin/env bash
# Root entry point — launches the platform-specific setup
cd "$(dirname "${BASH_SOURCE[0]}")/linux-macos" && bash setup.sh "$@"
