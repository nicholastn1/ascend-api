#!/usr/bin/env bash
# Run this script to seed the remote Railway database with AI prompts.
# Prerequisites: Railway CLI installed, logged in, and project linked.

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
echo "→ Seeding database with prompts from db/prompts/*.md..."
echo "  (Using railway ssh - runs inside deployed container to reach postgres.railway.internal)"
railway ssh -- bundle exec rails db:seed

echo ""
echo "✓ Done! Prompts have been loaded into the remote database."
