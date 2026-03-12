#!/usr/bin/env bash
# Run this script to check resume data structure in the remote Railway database.
# Prerequisites: Railway CLI installed, logged in, project linked, and API deployed
# (lib/tasks/check_resume_data.rake must be in the deployed container).

set -e

cd "$(dirname "$0")/.."

echo "→ Checking Railway CLI..."
if ! command -v railway &>/dev/null; then
	echo "Railway CLI not found. Install with: brew install railway"
	exit 1
fi

echo "→ Checking Railway auth..."
if ! railway whoami &>/dev/null; then
	echo "Not logged in. Run: railway login"
	exit 1
fi

echo "→ Checking project link..."
if ! railway status &>/dev/null; then
	echo "Project not linked. Run: railway link"
	exit 1
fi

echo ""
echo "→ Checking resume data in remote database..."
echo "  (Using railway ssh - runs inside deployed container to reach postgres.railway.internal)"
railway ssh -- sh -c 'bundle exec rails runner - < /dev/stdin && cat /tmp/resume-check.txt' < scripts/check-resume-data.rb

echo ""
echo "✓ Done!"
