# mac-bootstrap

Public launchers for the machine setup that lives in the **private**
[`jpslav/my_mac`](https://github.com/jpslav/my_mac) repo.

A private repo can't be fetched by `curl` on a blank machine — there's no
credential yet. These scripts are the smallest possible public step that gets a
new machine to "authenticated `gh`", then hand off to `my_mac` for everything
else.

## Entry points

New dev VM (UTM/VM for Claude Code + Node work) — runs `my_mac/install_dev_vm.sh`:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/jpslav/mac-bootstrap/main/dev_vm.sh)
```

Full personal Mac — runs `my_mac/install.sh`:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/jpslav/mac-bootstrap/main/full_mac.sh)
```

Both are idempotent and safe to re-run: each step checks current state first,
and once `~/.my_mac` exists you can just run `~/.my_mac/install_dev_vm.sh` (or
`install.sh`) directly and skip these entirely.

## What they do

1. Install Homebrew if missing (Homebrew's own installer is public, which is
   what makes this bootstrap possible at all), and put `brew` on `PATH`.
2. `brew install gh`.
3. `gh auth login`, if not already authenticated.
4. Fetch the chosen entry point from the private `my_mac` repo through the
   GitHub API and run it.

That's the whole scope. The two scripts are identical apart from which `my_mac`
entry point they target.

## Ground rules

- **Nothing secret ever goes in this repo.** It is public by design and is only
  a launcher — no keys, no tokens, no machine inventory. Anything that could
  matter belongs in the private `my_mac` repo (which has a secret-scanning
  pre-commit hook) or in a machine-local untracked file.
- The handoff downloads to a temp file and runs it rather than piping to `bash`.
  Piping would make the script text itself stdin, so the installer's interactive
  prompts (computer name, `gh auth login`) would read from the pipe instead of
  the terminal.
