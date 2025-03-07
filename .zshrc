# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

plugins=(git)
source $ZSH/oh-my-zsh.sh

find_git_exe() {
    # Define potential paths for git.exe
    local paths=(
        "/mnt/c/Program Files/Git/bin/git.exe"
        "/mnt/c/Users/$USER/AppData/Local/Programs/Git/cmd/git.exe"
    )

    # Check each path
    for path in "${paths[@]}"; do
        if [ -x "$path" ]; then
            echo "$path"
            return 0
        fi
    done

    # If not found, try to locate it under all users' AppData
    for user_dir in /mnt/c/Users/*; do
        local user_git="$user_dir/AppData/Local/Programs/Git/cmd/git.exe"
        if [ -x "$user_git" ]; then
            echo "$user_git"
            return 0
        fi
    done

    # If git.exe is not found
    echo "git.exe not found"
    return 1
}

alias git="$(find_git_exe)"

checkout() {
  local branch
  local input="$1"

  if [ -n "$input" ]; then
    # Find the first branch that matches the input argument
    branch=$(git branch -a | awk '{print $1}' | grep -m 1 "$input")
  else
    #        All branches  | Strip whitespace | Select branch and preview log
    branch=$(git branch -a | awk '{print $1}' | fzf --preview 'git log --oneline --graph --decorate --color=always $(echo {} | sed "s/.* //")')
  fi

  if [ -n "$branch" ]; then
    # if branch starts with remotes/origin/, replace it
    if [[ $branch == remotes/origin/* ]]; then
      branch=$(echo "$branch" | sed 's/remotes\/origin\///')
    fi

    git checkout "$(echo "$branch" | sed 's/.* //')"
  fi
}

# --------------------------------------------
# Workspace implementation  
# --------------------------------------------
# Function to normalize strings by removing non-alphanumeric characters and converting to lowercase
normalize() {
    echo "$1" | tr -cd '[:alnum:]' | tr '[:upper:]' '[:lower:]'
}

# Function to find and open the nearest sub-directory
workspace_find() {
    if [ "$#" -ne 1 ]; then
        echo "Usage: open_matching_subdir target"
        return 1
    fi

    local target
    target=$(normalize "$1")
    local shortest_dir=""
    local shortest_length=-1

    for dir in "$DEV_ROOT"/*/; do
        dir=${dir%/}  # Remove trailing slash
        normalized_dir=$(normalize "$dir")

        if [[ "$normalized_dir" == *"$target"* ]]; then
            dir_length=${#dir}
            if [ "$shortest_length" -eq -1 ] || [ "$dir_length" -lt "$shortest_length" ]; then
                shortest_length="$dir_length"
                shortest_dir="$dir"
            fi
        fi
    done

    if [ -n "$shortest_dir" ]; then
        cd "$shortest_dir" || return
        echo "Opened workspace: $shortest_dir"
        
        # Find potential .sln file in dir
        local sln_file
        sln_file=$(find . -maxdepth 1 -type f -name "*.sln" | head -n 1)
        # open using ps if found
        if [ -n "$sln_file" ]; then
            ps "$sln_file"
        fi
    else
        echo "No matching sub-directories found."
    fi
}

# Casing
setopt nocaseglob
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

# Escape to clear line, laggy but works
bindkey '^[' kill-whole-line


# ------------------
# History
# ------------------

HISTFILE=$HOME/.zsh_history
HISTSIZE=50000
SAVEHIST=50000

setopt INC_APPEND_HISTORY # Immediately append to history file
setopt EXTENDED_HISTORY # Record timestamp in history
setopt HIST_EXPIRE_DUPS_FIRST # Expire duplicate entries first when trimming history:
setopt HIST_IGNORE_DUPS # Dont record an entry that was just recorded again
setopt HIST_IGNORE_ALL_DUPS # Delete old recorded entry if new entry is a duplicate
setopt HIST_FIND_NO_DUPS # Do not display a line previously found
setopt HIST_IGNORE_SPACE # Dont record an entry starting with a space
setopt HIST_SAVE_NO_DUPS # Dont write duplicate entries in the history file
setopt SHARE_HISTORY # Share history between all sessions
unsetopt HIST_VERIFY # Execute commands using history (e.g.: using !$) immediatel

# ------------------
# Paths
# ------------------
convert-windows-dir() {
    # take the first argument, 
    # replace C:/ with /mnt/c/ and
    # replace all '\' with '/' and
    # return the result
    echo $1 | sed 's/C:/\/mnt\/c/' | sed 's/\\/\//g'
}

DEV_HOME=$(convert-windows-dir "C:/Dev")
USER_DIR=$(convert-windows-dir "C:/Users/$(whoami)")

# if user dir does not exist, remove the last s from the path
if [ ! -d $USER_DIR ]; then
    USER_DIR=$(convert-windows-dir "C:/Users/$(whoami | sed 's/s$//')")
fi

#if PWD contains /dev, keep it as default
STARTUP_DIR=$(pwd | grep -i "/dev") 
if [ -z "$STARTUP_DIR" ]; then
    STARTUP_DIR=$DEV_HOME
fi

# ------------------
# Aliases
# ------------------
alias cls=clear
alias cd..='cd ..'
alias start='cmd.exe /C start'
alias devops="start $(git config --get remote.origin.url | awk -F '_git' '{print $1}')"
alias explorer='pwsh.exe -c start -FilePath .'
alias hosts="code c:/Windows/System32/drivers/etc/hosts"
alias workspace=workspace_find
alias master='git checkout master ; git pull'

# ------------------
# Default behavior
# ------------------
cd $STARTUP_DIR
echo "default .zshrc executed"
