
eval "$(devbox global shellenv)"

# Ghostty shell integration for Bash. This should be at the top of your bashrc!
if [ -n "${GHOSTTY_RESOURCES_DIR}" ]; then
    builtin source "${GHOSTTY_RESOURCES_DIR}/shell-integration/zsh/ghostty-integration"
fi


# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

P10K_CACHE="$HOME/.cache/p10k_path"
if [ -f "$P10K_CACHE" ]; then
  P10K=$(cat "$P10K_CACHE")
else
  P10K=$(find /nix/store -type d -name "*powerlevel10k-*" 2>/dev/null | grep -m 1 "powerlevel10k")
  echo "$P10K" > "$P10K_CACHE"
fi

source $P10K/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

ZSH_CACHE="$HOME/.cache/ohmyzsh_path"
if [ -f "$ZSH_CACHE" ]; then
  ZSH=$(cat "$ZSH_CACHE")
else
  ZSH=$(find /nix/store -type d -name "oh-my-zsh" 2>/dev/null | grep -m 1 "share/oh-my-zsh")
  echo "$ZSH" > "$ZSH_CACHE"
fi

ZSH_CUSTOM=$HOME/.config/ohmyzsh/custom

plugins=(git aws colored-man-pages command-not-found common-aliases docker-compose docker git-extras git-flow gitignore helm kubectl minikube nmap rsync screen sudo systemadmin copyzshell zsh-peco-history terraform kubetail)

source $ZSH/oh-my-zsh.sh
#source <(kubectl completion zsh)
#source <(kind completion zsh)
#source <(minikube docker-env -p my-profile)

# Save the history in your home directory as .zsh_history
export HISTFILE=$HOME/.zsh_history 

# Set the history size to 2000 commands
export HISTSIZE=2000               

# Store the same number to disk
export SAVEHIST=$HISTSIZE          

# Share history between sessions
setopt share_history               

# Remove duplicates first when HISTSIZE is met
setopt hist_expire_dups_first      

# If a command is issued multiple times in a row, ignore dupes
setopt hist_ignore_dups  

# Allow editing the command before executing again
setopt hist_verify                 

# Do not add commands prefixed with a space to the history
setopt hist_ignore_space  

alias repos="cd ~/repos"
alias vim="nvim"
alias cat="bat"

export LLM_KEY=NONE

#source <(kubectl completion zsh)
#alias kubectl="kubecolor"
#compdef kubecolor=kubectl

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

autoload -U +X bashcompinit && bashcompinit
#complete -o nospace -C /usr/local/bin/terraform terraform

autoload -Uz compinit
if [ -f ~/.zcompdump ]; then
    compinit -C
else
    compinit
fi

eval "$(direnv hook zsh)"
eval "$(zellij setup --generate-auto-start zsh)"

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

source <(fzf --zsh)
