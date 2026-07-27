#!/usr/bin/env bash

# Public bootstrap shim for a NEW DEV VM (UTM/VM used for Claude Code + Node).
#
# Usage on a blank macOS VM:
#   bash <(curl -fsSL https://raw.githubusercontent.com/jpslav/mac-bootstrap/main/dev_vm.sh)
#
# The real installer lives in the PRIVATE jpslav/my_mac repo, which can't be
# fetched without an authenticated gh - so this script does the bare minimum to
# get there (Homebrew, gh, a GitHub login) and hands off. Everything else,
# including all machine configuration, stays in my_mac.
#
# Nothing secret belongs in this repo: it is public by design and is only a
# launcher. See full_mac.sh for the full personal-Mac entry point.

set -e

PROFILE_SCRIPT="install_dev_vm.sh"
MY_MAC_REPO="jpslav/my_mac"

if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # The installer doesn't touch this shell's PATH, so derive it ourselves.
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$candidate" ]; then
      eval "$("$candidate" shellenv)"
      break
    fi
  done
fi

if ! command -v brew &>/dev/null; then
  echo "ERROR: Homebrew still isn't on PATH; can't continue." >&2
  exit 1
fi

if ! command -v gh &>/dev/null; then
  echo "Installing gh..."
  brew install gh
fi

if ! gh auth status &>/dev/null; then
  echo
  echo "Log in to GitHub - $MY_MAC_REPO is private, so this is how we read it."
  echo "Pick SSH as the git protocol, and keep the admin:public_key scope if"
  echo "offered: the installer registers this machine's SSH key for you."
  echo
  gh auth login
fi

echo "Fetching $PROFILE_SCRIPT from $MY_MAC_REPO..."
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
# Downloaded to a file and then run - deliberately NOT piped to bash. Piping
# would make the script text itself this shell's stdin, so the installer's
# interactive prompts (computer name, gh login) would read from the pipe
# instead of the terminal.
gh api "repos/$MY_MAC_REPO/contents/$PROFILE_SCRIPT" \
  -H "Accept: application/vnd.github.raw" > "$tmp"

echo "Handing off to $MY_MAC_REPO/$PROFILE_SCRIPT"
echo
bash "$tmp"
