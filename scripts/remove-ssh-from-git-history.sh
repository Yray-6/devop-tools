#!/bin/bash

# Script to remove SSH keys from git history
# WARNING: This rewrites git history and requires force push

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
CYAN="\033[36m"
BOLD="\033[1m"
RESET="\033[0m"

echo -e "${BOLD}${RED}========================================${RESET}"
echo -e "${BOLD}${RED}    Remove SSH Keys from Git History    ${RESET}"
echo -e "${BOLD}${RED}========================================${RESET}"
echo ""

echo -e "${YELLOW}⚠️  WARNING: This script will rewrite git history!${RESET}"
echo -e "${YELLOW}This operation cannot be undone!${RESET}"
echo ""
echo -e "${BOLD}Before proceeding:${RESET}"
echo -e "1. Make sure you have a backup of your repository"
echo -e "2. Coordinate with team members (they'll need to re-clone)"
echo -e "3. All branches will be affected"
echo ""

read -p "Are you sure you want to continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo -e "${BLUE}Operation cancelled${RESET}"
    exit 0
fi

cd "$PROJECT_ROOT" || exit 1

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Not a git repository${RESET}"
    exit 1
fi

echo ""
echo -e "${BLUE}🔍 Checking for SSH keys in git history...${RESET}"

# List of files to remove from history
FILES_TO_REMOVE=(
    ".ssh/id_rsa"
    ".ssh/id_rsa.pub"
    "id_rsa"
    "id_rsa.pub"
    "storage/.ssh/id_rsa"
    "storage/.ssh/id_rsa.pub"
)

# Check which files exist in history
FOUND_FILES=()
for file in "${FILES_TO_REMOVE[@]}"; do
    if git log --all --full-history -- "$file" > /dev/null 2>&1; then
        FOUND_FILES+=("$file")
        echo -e "${YELLOW}  Found: $file${RESET}"
    fi
done

if [ ${#FOUND_FILES[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ No SSH keys found in git history${RESET}"
    exit 0
fi

echo ""
echo -e "${BOLD}Files to remove from history:${RESET}"
for file in "${FOUND_FILES[@]}"; do
    echo -e "  - ${CYAN}$file${RESET}"
done

echo ""
read -p "Proceed with removal? (yes/no): " CONFIRM2
if [ "$CONFIRM2" != "yes" ]; then
    echo -e "${BLUE}Operation cancelled${RESET}"
    exit 0
fi

# Check for unstaged changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo ""
    echo -e "${YELLOW}⚠️  You have unstaged changes in your repository${RESET}"
    echo -e "${YELLOW}Git filter-branch requires a clean working directory${RESET}"
    echo ""
    echo -e "${BOLD}Choose an action:${RESET}"
    echo -e "  1) Stash changes (recommended - can restore later)"
    echo -e "  2) Commit changes"
    echo -e "  3) Discard changes (⚠️  WARNING: This will lose uncommitted work)"
    echo -e "  4) Cancel and exit"
    echo ""
    read -p "Enter choice (1-4): " CHANGE_CHOICE
    
    case "$CHANGE_CHOICE" in
        1)
            echo -e "${BLUE}📦 Stashing changes...${RESET}"
            git stash push -m "Auto-stash before removing SSH keys from history"
            STASHED=1
            echo -e "${GREEN}✅ Changes stashed${RESET}"
            ;;
        2)
            echo -e "${BLUE}📝 Committing changes...${RESET}"
            git add -A
            git commit -m "Commit changes before removing SSH keys from history"
            echo -e "${GREEN}✅ Changes committed${RESET}"
            ;;
        3)
            echo -e "${RED}🗑️  Discarding changes...${RESET}"
            read -p "Are you sure? This cannot be undone! (yes/no): " DISCARD_CONFIRM
            if [ "$DISCARD_CONFIRM" = "yes" ]; then
                git reset --hard HEAD
                git clean -fd
                echo -e "${GREEN}✅ Changes discarded${RESET}"
            else
                echo -e "${BLUE}Operation cancelled${RESET}"
                exit 0
            fi
            ;;
        4)
            echo -e "${BLUE}Operation cancelled${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Operation cancelled.${RESET}"
            exit 1
            ;;
    esac
    echo ""
fi

echo ""
echo -e "${BLUE}🗑️  Removing SSH keys from git history...${RESET}"
echo -e "${YELLOW}This may take a while depending on repository size...${RESET}"
echo ""

# Method 1: Using git filter-repo (recommended, but may not be installed)
if command -v git-filter-repo > /dev/null 2>&1; then
    echo -e "${GREEN}Using git-filter-repo (recommended method)...${RESET}"
    
    # Build paths argument
    PATHS_ARG=""
    for file in "${FOUND_FILES[@]}"; do
        PATHS_ARG="$PATHS_ARG --path $file"
    done
    
    # Remove all files in one command
    echo -e "${BLUE}Removing files from all branches...${RESET}"
    git filter-repo $PATHS_ARG --invert-paths --force
    
    if [ $? -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ SSH keys removed from git history using git-filter-repo${RESET}"
    else
        echo -e "${RED}❌ Error: Failed to remove files from history${RESET}"
        exit 1
    fi
    
# Method 2: Using git filter-branch (built-in, but slower)
else
    echo -e "${YELLOW}Using git filter-branch (slower method)...${RESET}"
    echo -e "${YELLOW}Note: Consider installing git-filter-repo for better performance:${RESET}"
    echo -e "${CYAN}  pip install git-filter-repo${RESET}"
    echo ""
    
    # Build filter command for all files
    FILTER_CMD="git rm --cached --ignore-unmatch"
    for file in "${FOUND_FILES[@]}"; do
        FILTER_CMD="$FILTER_CMD '$file'"
    done
    
    # Suppress git filter-branch warning
    export FILTER_BRANCH_SQUELCH_WARNING=1
    
    # Use filter-branch to remove files from all branches
    echo -e "${BLUE}Rewriting git history (this may take a while)...${RESET}"
    git filter-branch --force --index-filter "$FILTER_CMD" \
        --prune-empty --tag-name-filter cat -- --all 2>&1 | grep -v "Ref 'refs/heads/.*' unchanged" || true
    
    if [ ${PIPESTATUS[0]} -eq 0 ]; then
        echo ""
        echo -e "${GREEN}✅ SSH keys removed from git history using git filter-branch${RESET}"
        
        # Clean up refs
        echo ""
        echo -e "${BLUE}🧹 Cleaning up refs...${RESET}"
        rm -rf .git/refs/original/ 2>/dev/null || true
        git reflog expire --expire=now --all 2>/dev/null || true
        git gc --prune=now --aggressive 2>/dev/null || true
        
        echo -e "${GREEN}✅ Cleanup completed${RESET}"
    else
        echo -e "${RED}❌ Error: Failed to remove files from history${RESET}"
        exit 1
    fi
fi

# Restore stashed changes if any
if [ "$STASHED" = "1" ]; then
    echo ""
    echo -e "${BLUE}📦 Restoring stashed changes...${RESET}"
    git stash pop 2>/dev/null || {
        echo -e "${YELLOW}⚠️  Could not auto-restore stash. You can restore manually with:${RESET}"
        echo -e "${CYAN}  git stash pop${RESET}"
    }
    echo ""
fi

echo ""
echo -e "${BOLD}${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "${BOLD}✅ SSH keys have been removed from git history!${RESET}"
echo ""
echo -e "${BOLD}📋 Next Steps:${RESET}"
echo ""
echo -e "1. ${BOLD}Verify the removal:${RESET}"
echo -e "   ${CYAN}git log --all --full-history -- .ssh/id_rsa${RESET}"
echo ""
echo -e "2. ${BOLD}Force push to remote (WARNING: This rewrites remote history):${RESET}"
echo -e "   ${CYAN}git push origin --force --all${RESET}"
echo -e "   ${CYAN}git push origin --force --tags${RESET}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT:${RESET}"
echo -e "  - All team members must re-clone the repository"
echo -e "  - Existing clones will have conflicts"
echo -e "  - Make sure everyone is aware of this change"
echo ""
echo -e "3. ${BOLD}Clean up local repository (optional):${RESET}"
echo -e "   ${CYAN}rm -rf .git/refs/original/${RESET}"
echo -e "   ${CYAN}git reflog expire --expire=now --all${RESET}"
echo -e "   ${CYAN}git gc --prune=now --aggressive${RESET}"
echo ""

