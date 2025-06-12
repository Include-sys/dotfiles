#!/usr/bin/env bash
# Bootstrap your shell + terminal tooling in a single go.
set -euo pipefail

# -------- helpers ------------------------------------------------------------
msg()  { printf '\033[1;32m%-6s\033[0m %s\n' '-->' "$*"; }
err()  { printf '\033[1;31m%-6s\033[0m %s\n' 'ERR' "$*" >&2; }
die()  { err "$*"; exit 1; }

need() { command -v "$1" &>/dev/null; }

# Detect package manager ------------------------------------------------------
if   need apt-get; then PM="apt-get" ; INSTALL="sudo apt-get install -y"
elif need dnf    ; then PM="dnf"     ; INSTALL="sudo dnf install -y"
elif need pacman ; then PM="pacman"  ; INSTALL="sudo pacman -Syu --noconfirm"
elif need brew   ; then PM="brew"    ; INSTALL="brew install"
else die "No supported package manager found (apt, dnf, pacman, brew)"; fi

# Packages --------------------------------------------------------------------
pkgs_common=(git curl zsh tmux)
pkgs_fonts_linux=(fonts-powerline fonts-firacode)
pkgs_ruby=(ruby-full build-essential)

install_pkgs() {
  msg "Installing ${*}"
  $INSTALL "$@" >/dev/null
}

# ---------- zsh --------------------------------------------------------------
install_zsh() {
  need zsh && msg "zsh already installed" && return
  install_pkgs "${pkgs_common[@]}"
}

install_ohmyzsh() {
  [[ -d $HOME/.oh-my-zsh ]] && msg "Oh My Zsh already present" && return
  msg "Installing Oh My Zsh"
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_powerlevel10k() {
  local dest="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  [[ -d $dest ]] && msg "Powerlevel10k already present" && return
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$dest"
}

# ---------- fonts ------------------------------------------------------------
install_fonts() {
  local font='MesloLGS NF'
  if fc-list | grep -qi "$font"; then msg "NerdFont already installed"; return; fi

  msg "Installing Meslo Nerd Font"
  tmp=$(mktemp -d)
  curl -fsSL \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Meslo.zip \
    -o "$tmp/meslo.zip"
  unzip -q "$tmp/meslo.zip" -d "$tmp"
  mkdir -p "$HOME/.local/share/fonts"
  mv "$tmp"/*.ttf "$HOME/.local/share/fonts/"
  fc-cache -f                               # refresh font cache
  rm -rf "$tmp"
}

# ---------- tmux & TPM -------------------------------------------------------
install_tmux() {
  need tmux || install_pkgs tmux
  local tpm="$HOME/.tmux/plugins/tpm"
  [[ -d $tpm ]] && msg "TPM already present" && return
  git clone https://github.com/tmux-plugins/tpm "$tpm"
}

# ---------- colorls ----------------------------------------------------------
install_colorls() {
  need ruby || install_pkgs "${pkgs_ruby[@]}"
  gem install --user-install colorls
}

# ---------- symlink dotfiles -------------------------------------------------
backup_and_link() {
  local src=$1 dst=$2
  [[ -e $dst && ! -L $dst ]] && mv "$dst" "${dst}.bak.$(date +%s)"
  ln -sf "$src" "$dst"
}

#link_dotfiles() {
#  msg "Linking dotfiles"
#  local repo_root script_dir
#  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
#  repo_root="$(cd "$script_dir" && pwd)"

#  shopt -s dotglob
#  for f in "$repo_root/dotfiles/"*; do
#    dst="$HOME/$(basename "$f")"
#    [[ -d $f && $(basename "$f") == ".config" ]] && {
#      mkdir -p "$HOME/.config"
#      rsync -a --delete "$f/" "$HOME/.config/$(basename "$f")/"
#    } || backup_and_link "$f" "$dst"
#  done
#  shopt -u dotglob
#}


patch_zshrc() {
  local repo_root=$1
  local rc="$HOME/.zshrc"
  local start="# >>> dotfiles include START >>>"
  local end="# <<< dotfiles include END   <<<"

  # make sure the file exists
  [[ -f $rc ]] || touch "$rc"

  if grep -qF "$start" "$rc"; then
    msg ".zshrc already includes dotfiles block"
    return
  fi

  msg "Patching .zshrc to source repo’s config"
  {
    printf "\n%s\n" "$start"
    echo "export DOTFILES_DIR=\"$repo_root\""
    echo '[ -f "$DOTFILES_DIR/dotfiles/.zshrc" ] && source "$DOTFILES_DIR/dotfiles/.zshrc"'
    printf "%s\n" "$end"
  } >> "$rc"
}

link_other_dotfiles() {
  local repo_root=$1
  msg "Linking dotfiles (except .zshrc)"
  shopt -s dotglob
  for f in "$repo_root/dotfiles/"*; do
    [[ $(basename "$f") == ".zshrc" ]] && continue   # skip
    dst="$HOME/$(basename "$f")"
    # recurse .config exactly as before
    if [[ -d $f && $(basename "$f") == ".config" ]]; then
      mkdir -p "$HOME/.config"
      rsync -a --delete "$f/" "$HOME/.config/$(basename "$f")/"
    else
      backup_and_link "$f" "$dst"
    fi
  done
  shopt -u dotglob
}

# ---------------------- run all ---------------------------------------------
main() {
  install_zsh
  install_ohmyzsh
  install_powerlevel10k
  install_fonts
  install_tmux
  install_colorls
  link_dotfiles

  # repo root = folder containing this script
  local repo_root; repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

  patch_zshrc "$repo_root"         # <-- new behaviour
  link_other_dotfiles "$repo_root" # link the rest

  msg "Done!  Start a new zsh or log out/in to load the changes."

  msg "Done!  Log out & back in (or chsh -s $(which zsh)) then run: p10k configure"
}

main "$@"
