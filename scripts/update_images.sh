#!/bin/bash
set -e  # Exit on any error

# Colors for better output (if terminal supports it)
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color
else
    GREEN=''
    YELLOW=''
    RED=''
    BLUE=''
    NC=''
fi

# Function to print formatted messages
print_header() {
    echo -e "${BLUE}================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Count non-empty lines in a newline-separated string. Guards the empty case,
# where `wc -l` on `echo ""` would report 1.
count_lines() {
    if [ -z "$1" ]; then
        echo 0
    else
        printf '%s\n' "$1" | wc -l | tr -d ' '
    fi
}

# Indent a multi-line string for nesting under a print_* heading.
print_indented() {
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        echo "  $line"
    done <<< "$1"
}

# Function to check if podman is available
check_dependencies() {
    print_info "Performing pre-flight checks..."

    if ! command -v podman &> /dev/null; then
        print_error "Podman is not installed or not in PATH"
        exit 1
    fi

    if ! podman info &> /dev/null; then
        print_error "Podman daemon is not running"
        exit 1
    fi

    print_success "Podman is ready"
}

# Function for safer image cleanup
cleanup_images() {
    # # podman images --format '{{.Tag}},{{.ID}}' | grep '<none>' | cut -d ',' -f 2 | xargs podman rmi
    print_header "🧹 IMAGE CLEANUP"

    # IMPORTANT: Do NOT use --filter dangling=true alone.
    #
    # After pulls/auto-update, the previous image often keeps its repository
    # name but loses the tag, e.g.:
    #   docker.io/library/postgres   <none>   9a0ce6be5dd4
    # Podman does NOT classify those as dangling (Names() is non-empty), so
    # dangling=true misses the bulk of reclaimable disk after updates.
    # Match Tag == <none> instead — same set as:
    #   podman images --format '{{.Tag}},{{.ID}}' | grep '<none>' | ...
    local untagged_images
    untagged_images=$(podman images --format '{{.Repository}}|{{.Tag}}|{{.ID}}|{{.Size}}' 2>/dev/null \
        | awk -F'|' '$2 == "<none>" { print }' || true)

    if [ -z "$untagged_images" ]; then
        print_success "No untagged images found - cleanup not needed"
        return 0
    fi

    local count
    count=$(printf '%s\n' "$untagged_images" | wc -l | tr -d ' ')
    print_info "Found $count untagged image(s) to remove"

    print_info "Images scheduled for removal:"
    while IFS='|' read -r repo tag id size; do
        [ -z "$id" ] && continue
        echo "  📦 ${repo}:${tag} ($size)"
        echo "     ID: $id"
    done <<< "$untagged_images"

    # Remove without --force so in-use images are left alone (podman rmi refuses).
    # Use <<< (not a pipe) so counters update in this shell, not a subshell.
    print_info "Removing untagged images..."
    local removed_count=0
    local failed_count=0

    while IFS='|' read -r repo tag id size; do
        [ -z "$id" ] && continue
        local repo_tag="${repo}:${tag}"
        if podman rmi "$id" &>/dev/null; then
            print_success "Removed: $repo_tag"
            removed_count=$((removed_count + 1))
        else
            print_warning "Failed to remove: $repo_tag (may be in use)"
            failed_count=$((failed_count + 1))
        fi
    done <<< "$untagged_images"

    if [ "$removed_count" -gt 0 ]; then
        print_success "Successfully removed $removed_count untagged image(s)"
    fi

    if [ "$failed_count" -gt 0 ]; then
        print_warning "$failed_count image(s) could not be removed (may be in use)"
    fi

    # Optional: Clean up unused volumes
    print_info "Cleaning up unused volumes..."
    local volume_output
    volume_output=$(podman volume prune --force 2>&1)
    if echo "$volume_output" | grep -q "Total reclaimed space:"; then
        print_success "Volumes cleaned up"
    else
        print_info "No unused volumes to clean"
    fi
}

# Function to check for available updates with better display
check_updates() {
    print_header "🔍 CHECKING FOR UPDATES"
    print_info "This may take a while as each container's image is checked against remote registries..."

    # Podman writes the reason a check failed (bad auth, registry rate limit,
    # DNS/network timeout) to stderr. Capture it to a file rather than
    # discarding it — those errors are the main thing worth seeing here.
    local stderr_file
    stderr_file=$(mktemp)

    local all_updates
    all_updates=$(podman auto-update --dry-run \
        --format "{{.Updated}}|{{.Unit}}|{{.Image}}|{{.Policy}}" 2>"$stderr_file" \
        | grep -v "^$" || true)

    local check_errors
    check_errors=$(cat "$stderr_file")
    rm -f "$stderr_file"

    # UPDATED is one of "pending", "false" or "failed". A container whose check
    # errored gets "failed", which matches neither of the other two — so it
    # needs an explicit branch, otherwise a container that has been failing its
    # check for weeks is indistinguishable from a healthy, up-to-date one.
    local pending_updates failed_updates
    pending_updates=$(printf '%s\n' "$all_updates" | grep "^pending|" || true)
    failed_updates=$(printf '%s\n' "$all_updates" | grep "^failed|" || true)

    local checked_count failed_count
    checked_count=$(count_lines "$all_updates")
    failed_count=$(count_lines "$failed_updates")

    if [ "$failed_count" -gt 0 ]; then
        print_error "$failed_count container(s) failed their update check:"
        while IFS='|' read -r status unit image policy; do
            [ -z "$unit" ] && continue
            echo "  ❌ $unit: $image ($policy)"
        done <<< "$failed_updates"
        echo
    fi

    if [ -n "$check_errors" ]; then
        print_warning "Podman reported while checking:"
        print_indented "$check_errors"
        echo
    fi

    if [ -z "$pending_updates" ]; then
        if [ "$checked_count" -eq 0 ]; then
            print_warning "No containers are configured for auto-update"
        elif [ "$failed_count" -gt 0 ]; then
            print_warning "No updates to apply, but the failures above need attention"
            print_info "Checked $checked_count container(s)"
        else
            print_success "All containers are up to date!"
            print_info "Checked $checked_count container(s)"
        fi
        return 1
    fi

    local update_count
    update_count=$(count_lines "$pending_updates")
    print_warning "Found $update_count of $checked_count container(s) with available updates:"
    echo
    while IFS='|' read -r status unit image policy; do
        [ -z "$unit" ] && continue
        echo "  🔄 $unit: $image ($policy)"
    done <<< "$pending_updates"
    echo
    return 0
}

# Function to perform updates
perform_updates() {
    print_header "⬆️  PERFORMING UPDATES"

    print_info "Starting container updates..."
    print_info "This may take several minutes as images are downloaded and containers are restarted..."
    local update_output=$(podman auto-update --format "{{.Unit}} -> {{.Updated}}" 2>&1)

    if [ -n "$update_output" ]; then
        echo "$update_output" | while read -r line; do
            if echo "$line" | grep -q "true"; then
                print_success "$line"
            elif echo "$line" | grep -q "false"; then
                print_info "$line"
            else
                echo "  $line"
            fi
        done
        print_success "Container updates completed"
    else
        print_info "No updates were performed"
    fi
}

# Main execution
print_header "🚀 PODMAN CONTAINER UPDATE SCRIPT"

# Pre-flight checks
check_dependencies

# Check for updates
if check_updates; then
    perform_updates
fi

cleanup_images

print_header "✅ UPDATE PROCESS COMPLETED"
print_success "Script finished successfully"
