#!/bin/sh
set -e

# organize installer
# Usage: curl -fsSL https://raw.githubusercontent.com/thatjuan/organize/main/install.sh | sh

REPO="thatjuan/organize"
INSTALL_DIR="${INSTALL_DIR:-/usr/local/bin}"
BINARY_NAME="organize"

# Detect OS and architecture
detect_platform() {
    OS="$(uname -s)"
    ARCH="$(uname -m)"

    case "$OS" in
        Linux)
            case "$ARCH" in
                x86_64)
                    PLATFORM="linux-x86_64"
                    ;;
                aarch64|arm64)
                    PLATFORM="linux-aarch64"
                    ;;
                *)
                    echo "Error: Unsupported architecture: $ARCH"
                    exit 1
                    ;;
            esac
            ;;
        Darwin)
            case "$ARCH" in
                x86_64)
                    PLATFORM="darwin-x86_64"
                    ;;
                arm64)
                    PLATFORM="darwin-aarch64"
                    ;;
                *)
                    echo "Error: Unsupported architecture: $ARCH"
                    exit 1
                    ;;
            esac
            ;;
        *)
            echo "Error: Unsupported operating system: $OS"
            exit 1
            ;;
    esac

    echo "$PLATFORM"
}

# Get latest release version
get_latest_version() {
    curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | \
        grep '"tag_name":' | \
        sed -E 's/.*"([^"]+)".*/\1/'
}

main() {
    echo "Installing organize..."

    PLATFORM=$(detect_platform)
    VERSION=$(get_latest_version)

    if [ -z "$VERSION" ]; then
        echo "Error: Could not determine latest version"
        exit 1
    fi

    echo "Platform: $PLATFORM"
    echo "Version: $VERSION"

    DOWNLOAD_URL="https://github.com/$REPO/releases/download/$VERSION/organize-$PLATFORM.tar.gz"

    echo "Downloading from $DOWNLOAD_URL..."

    # Create temp directory
    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_DIR"' EXIT

    # Download and extract
    curl -fsSL "$DOWNLOAD_URL" | tar xzf - -C "$TMP_DIR"

    # Install binary
    if [ -w "$INSTALL_DIR" ]; then
        mv "$TMP_DIR/$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
    else
        echo "Installing to $INSTALL_DIR (requires sudo)..."
        sudo mv "$TMP_DIR/$BINARY_NAME" "$INSTALL_DIR/$BINARY_NAME"
    fi

    chmod +x "$INSTALL_DIR/$BINARY_NAME"

    echo ""
    echo "Successfully installed organize to $INSTALL_DIR/$BINARY_NAME"
    echo ""
    echo "Run 'organize --help' to get started"
}

main
