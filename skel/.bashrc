# Only run in interactive shell
case $- in
    *i*) ;;
      *) return;;
esac

# History settings
HISTCONTROL=ignoreboth
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s histappend
shopt -s checkwinsize

# Detect chroot (optional)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# Enable color if supported
if command -v tput >/dev/null 2>&1 && [ "$(tput colors)" -ge 8 ]; then
    color_prompt=yes
fi

# Git branch (safe fallback)
current_git_branch() {
    command -v git >/dev/null 2>&1 || return
    git rev-parse --abbrev-ref HEAD 2>/dev/null | sed 's/.*/(&)/'
}

# Prompt
if [ "$color_prompt" = yes ]; then
    PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\[\033[01;33m\]$(current_git_branch)\[\033[00m\]\$ '
else
    PS1='\u@\h:\w\$ '
fi

unset color_prompt

# Terminal title (optional)
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;\u@\h: \w\a\]$PS1"
    ;;
esac

# ls colors (safe)
if command -v dircolors >/dev/null 2>&1; then
    eval "$(dircolors -b 2>/dev/null)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
fi

# Common aliases
alias ll='ls -l'
alias la='ls -A'
alias l='ls -CF'

# Load custom aliases if exist
[ -f ~/.bash_aliases ] && . ~/.bash_aliases

# Bash completion (cross-distro)
for f in \
    /usr/share/bash-completion/bash_completion \
    /etc/bash_completion
do
    [ -f "$f" ] && . "$f" && break
done

# Safe command_not_found
command_not_found_handle() {
    if command -v command-not-found >/dev/null 2>&1; then
        command-not-found "$@"
    else
        echo "Command not found: $1"
        return 127
    fi
}