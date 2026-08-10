#!/usr/bin/env bash

# Public bootstrap shim for a NEW DEV VM (UTM/VM used for Claude Code + Node).
#
# Usage on a blank macOS VM:
#   bash <(curl -fsSL https://raw.githubusercontent.com/jpslav/mac-bootstrap/main/dev_vm.sh)
#
# The real installer lives in the PRIVATE jpslav/my_mac repo, which can't be
# fetched without an authenticated gh - so this script does the bare minimum to
# get there (Homebrew, gh, a GitHub login, and the clone itself) and then runs
# the installer from disk. Everything else, including all machine configuration,
# stays in my_mac.
#
# Nothing secret belongs in this repo: it is public by design and is only a
# launcher. See full_mac.sh for the full personal-Mac entry point.

set -e

ENTRY_POINT="install_dev_vm.sh"
MY_MAC_REPO="jpslav/my_mac"
MY_MAC_DIR="$HOME/.my_mac"

# Homebrew 6.0 made "ask mode" the default, so every install that pulls in a
# dependency stops and waits for a y/n. HOMEBREW_NO_ASK turns that back off (the
# name is backwards: setting it *disables* asking). Exported so my_mac's
# installer inherits it too.
export HOMEBREW_NO_ASK=1
export HOMEBREW_NO_ENV_HINTS=1
export HOMEBREW_NO_INSTALL_CLEANUP=1

# Look for brew ON DISK before installing it. `command -v brew` on its own is not
# enough: a terminal session opened before Homebrew was installed has a PATH that
# predates /etc/paths.d/homebrew, so brew is present but invisible - and this
# script would then reinstall it, sudo prompt and all, on every re-run.
find_brew() {
  local candidate
  command -v brew &>/dev/null && return 0
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$candidate" ]; then
      eval "$("$candidate" shellenv)"
      return 0
    fi
  done
  return 1
}

if ! find_brew; then
  # Take a sudo ticket BEFORE handing off to Homebrew's installer. Under
  # NONINTERACTIVE it probes with `sudo -n -l mkdir`, which by design never
  # prompts - so on a blank machine that has not yet cached a ticket the probe
  # fails and it aborts with "Need sudo access on macOS (e.g. the user X needs
  # to be an Administrator)!". That message is misleading: an Administrator who
  # simply hasn't typed a password yet fails in exactly the same way.
  echo "Homebrew needs sudo - enter your macOS password (just this once):"
  if ! sudo -v; then
    echo >&2
    echo "ERROR: $(whoami) cannot use sudo, so Homebrew can't be installed." >&2
    echo "Make this account an Administrator (System Settings > Users & Groups)" >&2
    echo "and run this script again." >&2
    exit 1
  fi

  echo "Installing Homebrew..."
  # NONINTERACTIVE=1 skips the "Press RETURN to continue" gate. The password was
  # taken above; my_mac's bootstrap picks up a keepalive loop shortly after, so
  # that one prompt covers the whole install.
  NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  find_brew || true
fi

if ! command -v brew &>/dev/null; then
  echo "ERROR: Homebrew still isn't on PATH; can't continue." >&2
  exit 1
fi

if ! command -v gh &>/dev/null; then
  echo "Installing gh..."
  brew install gh
fi

# Normally Apple's command line tools (installed alongside Homebrew) provide git.
if ! command -v git &>/dev/null; then
  echo "Installing git..."
  brew install git
fi

if ! gh auth status &>/dev/null; then
  echo
  echo "Log in to GitHub - $MY_MAC_REPO is private, so this is how we read it."
  echo "Pick SSH as the git protocol, and keep the admin:public_key scope if"
  echo "offered: the installer registers this machine's SSH key for you."
  echo
  gh auth login
fi

# Cloned over HTTPS using gh's credentials: this machine has no SSH key on the
# GitHub account yet - registering one is the installer's job. my_mac switches
# origin over to SSH once that key is in place.
if [ -d "$MY_MAC_DIR/.git" ]; then
  echo "Updating existing $MY_MAC_DIR checkout..."
  git -C "$MY_MAC_DIR" pull --ff-only ||
    echo "WARNING: couldn't fast-forward $MY_MAC_DIR - continuing with what's on disk"
else
  echo "Cloning $MY_MAC_REPO to $MY_MAC_DIR..."
  gh auth setup-git
  git clone "https://github.com/$MY_MAC_REPO.git" "$MY_MAC_DIR"
fi

# An earlier version of this script fetched the entry point into a temp file and
# ran that, leaving the installer to clone the repo itself. When the fetch came
# back empty the installer carried on regardless and died against a directory
# that had never been created. Now everything runs from the clone, and a missing
# clone stops here with something you can act on.
if [ ! -x "$MY_MAC_DIR/$ENTRY_POINT" ]; then
  echo "ERROR: $MY_MAC_DIR/$ENTRY_POINT is missing after the clone." >&2
  echo "Check the clone above, or clone by hand:" >&2
  echo "  git clone https://github.com/$MY_MAC_REPO.git $MY_MAC_DIR" >&2
  exit 1
fi

echo "Handing off to $MY_MAC_DIR/$ENTRY_POINT"
echo
exec "$MY_MAC_DIR/$ENTRY_POINT"
