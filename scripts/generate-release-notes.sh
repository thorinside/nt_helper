#!/bin/bash

# Script to generate release notes for a given tag
# Usage: ./scripts/generate-release-notes.sh v1.61.0 [previous-tag]

set -e

CURRENT_TAG=${1:-$(git describe --tags --abbrev=0)}
PREVIOUS_TAG=${2:-$(git tag --sort=-version:refname | grep -v "$CURRENT_TAG" | head -1)}

if [ -z "$CURRENT_TAG" ]; then
    echo "Error: No tag specified and no tags found"
    exit 1
fi

if [ -z "$PREVIOUS_TAG" ]; then
    echo "Warning: No previous tag found, using initial commit"
    PREVIOUS_TAG=$(git rev-list --max-parents=0 HEAD)
fi

echo "Generating release notes for $CURRENT_TAG (comparing with $PREVIOUS_TAG)"
echo "=================================================================="

# Create release notes
{
    echo "## 🚀 What's New in $CURRENT_TAG"
    echo ""
    
    # Features (feat:, add:, new:)
    FEATURES=$(git log --pretty=format:"- %s" ${PREVIOUS_TAG}..${CURRENT_TAG} --grep="feat:" --grep="add:" --grep="new:" --grep="feature:" -i)
    if [ ! -z "$FEATURES" ]; then
        echo "### ✨ Features"
        echo "$FEATURES"
        echo ""
    fi
    
    # Improvements (improve:, enhance:, update:)  
    IMPROVEMENTS=$(git log --pretty=format:"- %s" ${PREVIOUS_TAG}..${CURRENT_TAG} --grep="improve:" --grep="enhance:" --grep="update:" --grep="refactor:" -i)
    if [ ! -z "$IMPROVEMENTS" ]; then
        echo "### 🔧 Improvements"
        echo "$IMPROVEMENTS"
        echo ""
    fi
    
    # Bug fixes (fix:, bug:)
    FIXES=$(git log --pretty=format:"- %s" ${PREVIOUS_TAG}..${CURRENT_TAG} --grep="fix:" --grep="bug:" -i)
    if [ ! -z "$FIXES" ]; then
        echo "### 🐛 Bug Fixes"
        echo "$FIXES"
        echo ""
    fi
    
    # Documentation (docs:, doc:)
    DOCS=$(git log --pretty=format:"- %s" ${PREVIOUS_TAG}..${CURRENT_TAG} --grep="docs:" --grep="doc:" -i)
    if [ ! -z "$DOCS" ]; then
        echo "### 📚 Documentation"
        echo "$DOCS"
        echo ""
    fi
    
    # Pull requests merged
    PRS=$(git log --pretty=format:"- %s" ${PREVIOUS_TAG}..${CURRENT_TAG} --grep="#[0-9]" | head -10)
    if [ ! -z "$PRS" ]; then
        echo "### 📋 Pull Requests"
        echo "$PRS"
        echo ""
    fi
    
    # Other changes (excluding the categorized ones)
    OTHER=$(git log --pretty=format:"- %s" ${PREVIOUS_TAG}..${CURRENT_TAG} --invert-grep --grep="feat:" --grep="add:" --grep="new:" --grep="feature:" --grep="improve:" --grep="enhance:" --grep="update:" --grep="refactor:" --grep="fix:" --grep="bug:" --grep="docs:" --grep="doc:" -i)
    if [ ! -z "$OTHER" ]; then
        echo "### 🔄 Other Changes"
        echo "$OTHER"
        echo ""
    fi
    
    echo "---"
    echo "**Full Changelog**: https://github.com/thorinside/nt_helper/compare/${PREVIOUS_TAG}...${CURRENT_TAG}"
    
} | tee "release-notes-${CURRENT_TAG}.md"

echo ""
echo "Release notes generated and saved to: release-notes-${CURRENT_TAG}.md"