#!/bin/sh
set -eu

REPO="${PHANTASM_INSTALL_REPO:-indefiniteloop/phantasm-dist}"
INSTALL_DIR="${PHANTASM_INSTALL_DIR:-$HOME/.local/bin}"
VERSION=""

usage() {
  cat <<'EOF'
Install Phantasm from GitHub Releases.

Usage:
  install.sh [--version <version>] [--install-dir <dir>] [--repo <owner/repo>]

Options:
  --version      Release version to install. Accepts 0.1.0 or v0.1.0.
  --install-dir  Destination directory for the phantasm and phm binaries.
  --repo         GitHub repository slug. Defaults to PHANTASM_INSTALL_REPO or indefiniteloop/phantasm-dist.
  --help         Show this help text.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --version)
      VERSION="${2:-}"
      shift 2
      ;;
    --install-dir)
      INSTALL_DIR="${2:-}"
      shift 2
      ;;
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Required command not found: $1" >&2
    exit 1
  fi
}

need_cmd curl
need_cmd tar
need_cmd uname
need_cmd mktemp

if command -v sha256sum >/dev/null 2>&1; then
  SHA256_BIN="sha256sum"
elif command -v shasum >/dev/null 2>&1; then
  SHA256_BIN="shasum -a 256"
else
  echo "Need sha256sum or shasum for checksum verification." >&2
  exit 1
fi

os_name="$(uname -s)"
arch_name="$(uname -m)"

case "$os_name" in
  Linux) platform="linux" ;;
  Darwin) platform="macos" ;;
  *)
    echo "Unsupported operating system: $os_name" >&2
    exit 1
    ;;
esac

case "$arch_name" in
  x86_64|amd64) arch="x86_64" ;;
  arm64|aarch64) arch="aarch64" ;;
  *)
    echo "Unsupported architecture: $arch_name" >&2
    exit 1
    ;;
esac

if [ -z "$VERSION" ]; then
  VERSION="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" | sed -n 's/.*"tag_name":[[:space:]]*"\([^"]*\)".*/\1/p' | head -n 1)"
  if [ -z "$VERSION" ]; then
    echo "Could not resolve the latest release for $REPO." >&2
    exit 1
  fi
fi

VERSION="${VERSION#v}"
TAG="v$VERSION"
ARCHIVE_BASENAME="phantasm-${VERSION}-${platform}-${arch}"
ARCHIVE_NAME="${ARCHIVE_BASENAME}.tar.gz"
CHECKSUM_NAME="phantasm-${VERSION}-SHA256SUMS.txt"
BASE_URL="https://github.com/$REPO/releases/download/$TAG"

tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/phantasm-install.XXXXXX")"
trap 'rm -rf "$tmpdir"' EXIT INT TERM

echo "Downloading $ARCHIVE_NAME from $REPO..."
curl -fsSL "$BASE_URL/$ARCHIVE_NAME" -o "$tmpdir/$ARCHIVE_NAME"
curl -fsSL "$BASE_URL/$CHECKSUM_NAME" -o "$tmpdir/$CHECKSUM_NAME"

expected_checksum="$(sed -n "s/^\([0-9a-fA-F]\{64\}\)[[:space:]]\+$ARCHIVE_NAME$/\1/p" "$tmpdir/$CHECKSUM_NAME" | head -n 1)"
if [ -z "$expected_checksum" ]; then
  echo "Checksum entry for $ARCHIVE_NAME was not found in $CHECKSUM_NAME." >&2
  exit 1
fi

actual_checksum="$(sh -c "$SHA256_BIN \"$tmpdir/$ARCHIVE_NAME\"" | awk '{print $1}')"
if [ "$expected_checksum" != "$actual_checksum" ]; then
  echo "Checksum verification failed for $ARCHIVE_NAME." >&2
  exit 1
fi

mkdir -p "$INSTALL_DIR"
tar -C "$tmpdir" -xzf "$tmpdir/$ARCHIVE_NAME"
install -m 0755 "$tmpdir/phantasm" "$INSTALL_DIR/phantasm"
if [ -f "$tmpdir/phm" ]; then
  install -m 0755 "$tmpdir/phm" "$INSTALL_DIR/phm"
else
  cp "$INSTALL_DIR/phantasm" "$INSTALL_DIR/phm"
fi

echo "Installed phantasm to $INSTALL_DIR/phantasm"
echo "Installed phm alias to $INSTALL_DIR/phm"
"$INSTALL_DIR/phantasm" --version

case ":$PATH:" in
  *":$INSTALL_DIR:"*)
    ;;
  *)
    echo
    echo "Add this directory to your PATH if needed:"
    echo "  export PATH=\"$INSTALL_DIR:\$PATH\""
    ;;
esac

echo
echo "Next step:"
echo "  cd /path/to/your/project && phm bootstrap"
