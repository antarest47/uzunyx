# ZDOTDIR points here from the Uzunyx Konsole profiles: nothing is written to
# the user's home and zsh's new-user wizard never starts. Their own files
# still count.
[[ -r $HOME/.zshenv ]] && source $HOME/.zshenv
# zsh-autocomplete runs compinit itself.
skip_global_compinit=1
