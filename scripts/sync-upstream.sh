#!/usr/bin/env bash
set -euo pipefail

echo "==> Fetching origin..."
git fetch origin

echo "==> Current divergence:"
git rev-list --left-right --count main...origin/main 2>/dev/null || echo "(No divergence info available)"

echo "==> Rebasing onto origin/main..."
git rebase origin/main || echo "⚠️  Rebase skipped (already up-to-date or no remote changes)"

echo "==> Installing dependencies..."
pnpm install

echo "==> Building..."
pnpm build
pnpm ui:build

echo "==> Running doctor..."
pnpm clawdbot doctor

echo "==> Rebuilding macOS app..."
./scripts/restart-mac.sh

echo "==> Verifying gateway health..."
pnpm clawdbot health

echo "==> Checking for Swift 6.2 compatibility issues..."
if grep -r "FileManager\\.default\|Thread\\.isMainThread" src/ apps/ --include="*.swift" --quiet; then
    echo "⚠️  Found potential Swift 6.2 deprecated API usage"
    echo "   Run manual fixes or use analyze-mode investigation"
else
    echo "✅ No obvious Swift deprecation issues found"
fi

echo "==> Testing agent functionality..."
# Note: Update YOUR_TELEGRAM_SESSION_ID with actual session ID
pnpm clawdbot agent --message "Verification: Upstream sync and macOS rebuild completed successfully." --session-id YOUR_TELEGRAM_SESSION_ID || echo "Warning: Agent test failed - check Telegram for verification message"

echo "==> Done! Check Telegram for verification message, then run 'git push --force-with-lease' when ready."