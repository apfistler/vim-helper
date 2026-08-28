#!/bin/bash
#
# place-helper.sh
#
# Installs Vim Editing Helpers for Vim and/or Neovim.
#
# The installer:
#   - Detects installed Vim-family editors.
#   - Creates the appropriate configuration directories.
#   - Creates the plugin directory when needed.
#   - Copies the helper files into the appropriate location.
#   - Adds source directives to the editor configuration.
#   - Avoids adding duplicate source directives.
#

set -e

#
# Determine the directory containing this installer.
#
script_dir="$(cd "$(dirname "$0")" && pwd)"

#
# Helper directory.
#
helper_dir="$script_dir/helper"

#
# Make sure the helper directory exists.
#
if [ ! -d "$helper_dir" ]; then
  echo "Error: helper directory was not found." >&2
  echo "Expected: $helper_dir" >&2
  exit 1
fi


#
# Install helpers for Vim.
#
install_vim() {
  local config_dir="$HOME/.vim"
  local plugin_dir="$config_dir/plugin"
  local config_file="$HOME/.vimrc"

  echo "Installing Vim helpers..."

  #
  # Create Vim configuration/plugin directories.
  #
  mkdir -p "$plugin_dir"

  #
  # Install helper files.
  #
  cp "$helper_dir"/*.vim "$plugin_dir/"

  #
  # Vim automatically loads files from ~/.vim/plugin/,
  # so no source directive is normally required.
  #

  echo "  Installed to: $plugin_dir"
}


#
# Install helpers for Neovim.
#
install_neovim() {
  local config_dir="$HOME/.config/nvim"
  local plugin_dir="$config_dir/plugin"

  echo "Installing Neovim helpers..."

  #
  # Create Neovim configuration/plugin directories.
  #
  mkdir -p "$plugin_dir"

  #
  # Install helper files.
  #
  cp "$helper_dir"/*.vim "$plugin_dir/"

  #
  # Neovim automatically loads files from the plugin
  # directory, so no source directive is normally required.
  #

  echo "  Installed to: $plugin_dir"
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
