eval "$(starship init zsh)"

# Listing (eza with icons and grouped directories to match user setup)
if command -v eza &>/dev/null; then
  alias ls='eza -l --icons=always --group-directories-first'
  alias ll='eza -la --icons=always --group-directories-first'
  alias la='eza -a --icons=always --group-directories-first'
  alias l='eza -l --icons=always --group-directories-first'
else
  alias ls='ls --color=auto'
  alias ll='ls -lah --color=auto'
  alias la='ls -A --color=auto'
  alias l='ls -CF --color=auto'
fi

# Clear screen and entire terminal scrollback buffer completely
alias clear="printf '\033[2J\033[3J\033[H'"


# --------------------------------------------------
# Completion
# --------------------------------------------------

autoload -Uz compinit
compinit

# Better completion menu
zstyle ':completion:*' menu select

# Case-insensitive matching
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

# Completion colors — grayscale
zstyle ':completion:*' list-colors \
  '=(#b)*(=0)=38;5;250' \
  '=(#b)*(=1)=38;5;255' \
  '=(#b)*(=2)=38;5;245' \
  '=(#b)*(=3)=38;5;240'

# Autosuggestions — dark gray
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

# --------------------------------------------------
# History
# --------------------------------------------------

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_REDUCE_BLANKS

# Prefix history search with Up / Down arrows
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

bindkey '^[[A' up-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search
[[ -n "$terminfo[kcuu1]" ]] && bindkey "$terminfo[kcuu1]" up-line-or-beginning-search
[[ -n "$terminfo[kcud1]" ]] && bindkey "$terminfo[kcud1]" down-line-or-beginning-search
bindkey -M vicmd '^[[A' up-line-or-beginning-search 2>/dev/null || true
bindkey -M vicmd '^[OA' up-line-or-beginning-search 2>/dev/null || true
bindkey -M vicmd '^[[B' down-line-or-beginning-search 2>/dev/null || true
bindkey -M vicmd '^[OB' down-line-or-beginning-search 2>/dev/null || true

source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Syntax highlighting
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Grayscale
ZSH_HIGHLIGHT_STYLES[command]='fg=white'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=white'
ZSH_HIGHLIGHT_STYLES[function]='fg=white'
ZSH_HIGHLIGHT_STYLES[alias]='fg=white'
ZSH_HIGHLIGHT_STYLES[path]='fg=245'
ZSH_HIGHLIGHT_STYLES[comment]='fg=240'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=245'


# Tegmentum theme controller
theme() { python3 "$HOME/.config/tegmentum/bin/theme.py" "$@"; }

# Toolkit & theme environment
export QT_QPA_PLATFORM=wayland
export QT_QPA_PLATFORMTHEME=xdgdesktopportal

