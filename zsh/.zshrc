
eval "$(devbox global shellenv)"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

P10K=$(find /nix/store -type d -name "*powerlevel10k*" 2>/dev/null | grep -m 1 "powerlevel10k")
if [ -n "$P10K" ]; then
  source $P10K/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
else
  echo "Powerlevel10k not found"
fi

[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# Path to your oh-my-zsh installation.
ZSH=$(find /nix/store -type d -name "oh-my-zsh" 2>/dev/null | grep -m 1 "share/oh-my-zsh")

if [ -n "$ZSH" ] && [ -f "$ZSH/oh-my-zsh.sh" ]; then
    export ZSH="$ZSH"
    source $ZSH/oh-my-zsh.sh
else
    echo "oh-my-zsh not found"
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

#source <(kubectl completion zsh)
#alias kubectl="kubecolor"
#compdef kubecolor=kubectl

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

autoload -U +X bashcompinit && bashcompinit
#complete -o nospace -C /usr/local/bin/terraform terraform

autoload -U compinit
compinit -i

eval "$(direnv hook zsh)"
eval "$(zellij setup --generate-auto-start zsh)"
