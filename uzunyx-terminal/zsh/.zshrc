# Uzunyx terminal: Oh My Zsh, Starship and zsh-autocomplete. ~/.zshrc runs last, so
# anything here can be changed there.
export ZSH=/usr/share/uzunyx-terminal/oh-my-zsh
ZSH_THEME=""
ZSH_CACHE_DIR=${XDG_CACHE_HOME:-$HOME/.cache}/oh-my-zsh
ZSH_COMPDUMP=$ZSH_CACHE_DIR/zcompdump-$ZSH_VERSION
ZSH_CUSTOM=${XDG_DATA_HOME:-$HOME/.local/share}/oh-my-zsh-custom
ZSH_DISABLE_COMPFIX=true
DISABLE_AUTO_UPDATE=true
zstyle ':omz:update' mode disabled
plugins=(git sudo colored-man-pages command-not-found)
HISTFILE=$HOME/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
mkdir -p $ZSH_CACHE_DIR/completions ${XDG_DATA_HOME:-$HOME/.local/share}/zsh
# Before Oh My Zsh: it takes over compinit, which Oh My Zsh would call.
source /usr/share/uzunyx-terminal/zsh-autocomplete/zsh-autocomplete.plugin.zsh
source $ZSH/oh-my-zsh.sh
# Down goes into the list of completions again: Oh My Zsh's key bindings had
# taken it for the history.
bindkey '^[[B' down-line-or-select
bindkey '^[OB' down-line-or-select

# The prompt follows the edition, also in open tabs; ~/.config/starship.toml wins.
_uzunyx_edition() {
    local file=${XDG_CONFIG_HOME:-$HOME/.config}/kdeglobals
    REPLY=akane
    [[ -r $file && "$(<$file)" == *LookAndFeelPackage=org.uzunyx.sora* ]] && REPLY=sora
}
_uzunyx_starship_edition() {
    local REPLY
    _uzunyx_edition
    export STARSHIP_CONFIG=/usr/share/uzunyx-terminal/starship/$REPLY.toml
}
if [[ ! -e ${XDG_CONFIG_HOME:-$HOME/.config}/starship.toml ]]; then
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd _uzunyx_starship_edition
    _uzunyx_starship_edition
fi
eval "$(starship init zsh)"

# The PNG logo of the edition where images work: Konsole, not inside tmux or ssh.
# Anywhere else, or with a config of the user's, the ASCII logo of the system.
fastfetch() {
    local REPLY logo
    _uzunyx_edition
    logo=/usr/share/icons/hicolor/512x512/apps/uzunyx-$REPLY.png
    if [[ -n $KONSOLE_VERSION && -z $TMUX$SSH_CONNECTION && -r $logo &&
          ! -e ${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/config.jsonc ]]; then
        command fastfetch --logo $logo --logo-type kitty --logo-width 30 --logo-height 15 "$@"
    else
        command fastfetch "$@"
    fi
}

# Ctrl+R and Up: Atuin's list of recent commands. It only syncs after logging in
# to an account. The first time it brings in the history that zsh already has.
export ATUIN_UPDATE_CHECK=false
[[ -e ${XDG_DATA_HOME:-$HOME/.local/share}/atuin/history.db ]] || HISTFILE=$HISTFILE atuin import zsh >/dev/null 2>&1
eval "$(atuin init zsh)"

# Must be the last plugin to load.
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# A command sent from elsewhere (Tsunyx's search, UZUNYX_TERMINAL_RUN): typed
# in at the first prompt and run, as if by hand, so the prompt and the command
# stay on screen above its output, and it goes into the history.
if [[ -n $UZUNYX_TERMINAL_RUN ]]; then
    _uzunyx_run=$UZUNYX_TERMINAL_RUN
    unset UZUNYX_TERMINAL_RUN
    _uzunyx_run_once() {
        add-zle-hook-widget -d line-init _uzunyx_run_once
        BUFFER=$_uzunyx_run
        unset _uzunyx_run
        zle accept-line
    }
    autoload -Uz add-zle-hook-widget
    zle -N _uzunyx_run_once
    add-zle-hook-widget line-init _uzunyx_run_once
fi

[[ -r $HOME/.zshrc ]] && source $HOME/.zshrc
