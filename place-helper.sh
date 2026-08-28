#!/bin/bash
#
# place_helper.sh
#
# Installs helper.vim for Vim and/or Neovim.
#
# The installer:
#   - Detects installed Vim-family editors.
#   - Creates the appropriate configuration directories.
#   - Copies helper.vim into the configuration directory.
#   - Adds a source directive to the editor's configuration.
#   - Avoids adding duplicate source directives.
#

set -e

# Determine the directory containing this installer.
script_dir="$(cd "$(dirname "$0")" && pwd)"

# The helper being installed.
helper_file="$script_dir/helper.vim"

# Make sure helper.vim exists.
if [ ! -f "$helper_file" ]; then
  echo "Error: helper.vim was not found." >&2
  echo "Expected: $helper_file" >&2
  exit 1
fi


#
# Install helper for Vim.
#
install_vim() {
  local config_dir="$HOME/.vim"
  local config_file="$HOME/.vimrc"
  local installed_file="$config_dir/helper.vim"
  local source_line="source $installed_file"

  echo "Installing helper for Vim..."

  # Create Vim's configuration directory.
  mkdir -p "$config_dir"

  # Install the helper.
  cp "$helper_file" "$installed_file"

  # Create .vimrc if it doesn't exist.
  touch "$config_file"

  # Add the source directive if it isn't already present.
  if ! grep -Fqx "$source_line" "$config_file"; then
    printf '\n%s\n' "$source_line" >> "$config_file"
  fi

  echo "  Installed: $installed_file"
  echo "  Configured: $config_file"
}


#
# Install helper for Neovim.
#
install_neovim() {
  local config_dir="$HOME/.config/nvim"
  local config_file="$config_dir/init.vim"
  local installed_file="$config_dir/helper.vim"
  local source_line="source $installed_file"

  echo "Installing helper for Neovim..."

  # Create Neovim's configuration directory.
  mkdir -p "$config_dir"

  # Install the helper.
  cp "$helper_file" "$installed_file"

  # Create init.vim if it doesn't exist.
  touch "$config_file"

  # Add the source directive if it isn't already present.
  if ! grep -Fqx "$source_line" "$config_file"; then
    printf '\n%s\n' "$source_line" >> "$config_file"
  fi

  echo "  Installed: $installed_file"
  echo "  Configured: $config_file"
}


#
# Detect installed editors.
#
vim_found=false
neovim_found=false

if command -v vim >/dev/null 2>&1; then
  vim_found=true
fi

if command -v nvim >/dev/null 2>&1; then
  neovim_found=true
fi


#
# Make sure at least one supported editor exists.
#
if ! $vim_found && ! $neovim_found; then
  echo "Error: No supported Vim-family editor was found." >&2
  echo "Checked for: vim and nvim" >&2
  exit 1
fi


#
# Install for every supported editor that is present.
#
if $vim_found; then
  install_vim
fi

if $neovim_found; then
  install_neovim
fi


echo
echo "Vim helper installation complete."
