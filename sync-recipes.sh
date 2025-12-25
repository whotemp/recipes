#!/bin/bash

# Load environment variables from .env file
if [ -f .env ]; then
    set -a
    source .env
    set +a
else
    echo "❌ Error: .env file not found"
    echo "Create a .env file with: ICLOUD_SOURCE=\"/path/to/your/icloud/folder\""
    exit 1
fi

# Configuration
LOCAL_REPO="$(cd "$(dirname "$0")" && pwd)"

echo "🔄 Starting recipe sync from iCloud to local git repo..."

# Step 1: Delete all markdown files in the local repo (except this script and preserved files)
echo "🗑️  Removing existing markdown files..."

# Build find command with exclusions
FIND_CMD="find \"$LOCAL_REPO\" -type f -name \"*.md\""

# Exclude this script
FIND_CMD="$FIND_CMD ! -name \"$(basename "$0")\""

# Exclude preserved files if PRESERVE_FILES is set
if [ -n "$PRESERVE_FILES" ]; then
    # Convert comma-separated list to array
    IFS=',' read -ra FILES <<< "$PRESERVE_FILES"
    for file in "${FILES[@]}"; do
        # Trim whitespace
        file=$(echo "$file" | xargs)
        FIND_CMD="$FIND_CMD ! -name \"$file\""
        echo "  Preserving: $file"
    done
fi

FIND_CMD="$FIND_CMD -delete"

# Execute the find command
eval $FIND_CMD

# Step 2: Copy markdown files from iCloud
echo "📋 Copying markdown files from iCloud..."
if [ -d "$ICLOUD_SOURCE" ]; then
    # Copy all .md files, preserving directory structure
    rsync -av --include="*/" --include="*.md" --exclude="*" "$ICLOUD_SOURCE/" "$LOCAL_REPO/"
    echo "✅ Sync complete!"
    
    # Show what was copied
    echo ""
    echo "📊 Files in repository:"
    find "$LOCAL_REPO" -type f -name "*.md" | wc -l | xargs echo "Total markdown files:"
else
    echo "❌ Error: iCloud source directory not found at: $ICLOUD_SOURCE"
    exit 1
fi

# Step 3: Git commit
echo ""
echo "📝 Committing changes to git..."
git add .
if git diff --staged --quiet; then
    echo "ℹ️  No changes to commit"
else
    git commit -m "Sync recipes from iCloud - $(date '+%Y-%m-%d %H:%M')"
    echo "✅ Changes committed!"
    echo ""
    echo "💡 To push changes, run: git push"
fi
