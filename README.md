# dotfiles

My macOS setup: zsh with Starship, Ghostty, Zed, Karabiner-Elements, and a
Brewfile with everything I install.

## New Mac

1. Install [Homebrew](https://brew.sh). It also installs the Xcode Command Line
   Tools, which provide `git`:

   ```shell
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

2. Clone the repo and run the installer:

   ```shell
   git clone https://github.com/vldryz/dotfiles.git ~/dotfiles
   ~/dotfiles/install.sh --check   # preview; changes nothing
   ~/dotfiles/install.sh
   ```

3. Open a new terminal tab.

`install.sh` installs whatever from the Brewfile is missing (it never upgrades),
links the configs into place, and is safe to re-run. A config that already
exists and differs from the repo is left alone and listed. Re-run with
`--adopt` to keep yours (it's copied into the repo) or `--overwrite` to use the
repo's (yours is moved to `~/.dotfiles-backup/`).

After adding an SSH key to GitHub, switch the remote so you can push:
`git -C ~/dotfiles remote set-url origin git@github.com:vldryz/dotfiles.git`

## Linux servers

Clone to `~/dotfiles`, then run `scripts/install-remote.sh` (Debian/Ubuntu,
uses apt).

## Keeping it current

- `upall` upgrades Homebrew packages, uv tools and Rust.
- Regenerate the Brewfile from what's installed:
  `brew bundle dump --file=- | grep -vE '^(#|npm )' > ~/dotfiles/Brewfile`
