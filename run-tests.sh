#!/bin/bash
# Run all ERT tests for org-stb

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Running org-stb test suite..."
echo "=============================="

emacs -batch \
  -l ert \
  -l "$SCRIPT_DIR/org-stb.el" \
  -l "$SCRIPT_DIR/org-stb-test.el" \
  -f ert-run-tests-batch-and-exit

echo ""
echo "=============================="
echo "All tests completed!"
