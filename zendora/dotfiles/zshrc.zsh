[ -d "${ZSH_ROOT:="${HOME}/.zsh"}" ] || mkdir -p "${ZSH_ROOT}"

#-----------------------------------------------------------------------------
# Aliases
#-----------------------------------------------------------------------------

alias ls='ls --color=auto'
alias la='ls -A'
alias lt='ls -lahrt'
alias ll='ls -lah'

#-----------------------------------------------------------------------------
# Command line
#-----------------------------------------------------------------------------

# See: zshzle(1) ZLE BUILTINS
bindkey -v

# Empty command line executes ls. See: zshzle(1) accept-line
accept-line() {
    : ${BUFFER:=default}
    zle .${WIDGET} "$@"
}
zle -N accept-line

default() {
    ls -Art
}

# See: zshparam(1) REPORTTIME
REPORTTIME=3

# See zshoptions(1) AUTO_CD, AUTO_PUSHD
setopt AUTO_CD
setopt AUTO_PUSHD

# Guard from accidentally exiting from a shell session by pressing Ctrl+D when
# running background job(s). See: zshoptions(1) IGNORE_EOF
setopt IGNORE_EOF

zshrc::safeexit() {
    if [ ${#jobstates} -gt 0 ]; then
        case ${#jobstates} in
        1)  echo -n " ** You have a running job **" ;;
        *)  echo -n " ** You have ${#jobstates} running jobs **"
        esac
        zle .accept-line
        return
    fi
    exit
}

zshrc::handle_Ctrl+D() {
    if [ ${CURSOR} -eq 0 ]; then
        zshrc::safeexit
    fi
}
zle -N zshrc::handle_Ctrl+D

bindkey "^D" zshrc::handle_Ctrl+D

#-----------------------------------------------------------------------------
# Completion
#-----------------------------------------------------------------------------

# See: zshcompsys(1) compinit
autoload -U compinit
compinit -d "${ZSH_ROOT}/.zcompdump"

# See: zshoptions(1) BRACE_CCL
# See: zshexpn(1) BRACE EXPANSION
setopt BRACE_CCL

# See: zshoptions(1)
setopt COMPLETE_ALIASES
setopt CORRECT
setopt AUTO_REMOVE_SLASH
setopt COMPLETE_IN_WORD

# Tab for forward completion, Shift-Tab for backward completion. See:
# zshcompsys(1) reverse-menu-complete
bindkey "\e[Z" reverse-menu-complete

# Enable filename expansion in foo=bar style command options. See: zshoptions(1)
# MAGIC_EQUAL_SUBST
setopt MAGIC_EQUAL_SUBST

# See: zshoptions(1) CASE_GLOB
setopt CASE_GLOB

# Smart case completion.
#
# 0 -- vanilla completion (abc => abc)
# 1 -- smart case completion (abc => Abc)
# 2 -- word flex completion (abc => A-big-Car)
# 3 -- full flex completion (abc => ABraCadabra)
#
# See:
#  - https://superuser.com/a/815317
#  - zshcompsys(1) matcher-list
#  - zshcompwid(1) COMPLETION MATCHING CONTROL
#  - zshexpn(1) FILENAME GENERATION
zstyle ':completion:*' matcher-list                                        \
       ''                                                                  \
       '                                     m:{[:lower:]\-}={[:upper:]_}' \
       'r:[^[:alpha:]]||[[:alpha:]]=** r:|=* m:{[:lower:]\-}={[:upper:]_}' \
       'r:|?=**                              m:{[:lower:]\-}={[:upper:]_}'

#-----------------------------------------------------------------------------
# History
#-----------------------------------------------------------------------------

# See: zshoptions(1) HIST_IGNORE_DUPS
setopt HIST_IGNORE_DUPS

# See: zshoptions(1) HIST_IGNORE_SPACE
setopt HIST_IGNORE_SPACE

# Move cursor to the end of the line when showing each line of the history. See:
# zshcontrib(1) history-search-end
autoload history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end
bindkey "^P" history-beginning-search-backward-end
bindkey "^N" history-beginning-search-forward-end

# See: zshparam(1) PARAMETERS USED BY THE SHELL
# See: zshoptions(1) SHARE_HISTORY
HISTSIZE=10000000
SAVEHIST=10000000
HISTFILE="${ZSH_ROOT}/.zsh_history"
setopt SHARE_HISTORY

#-----------------------------------------------------------------------------
# Command prompt
#-----------------------------------------------------------------------------

PS1="%F{red}%m%F{default}:%n %F{green}%~%%%F{default} "
PS2="%_ "
RPROMPT="[%T]"

# See: PROMPT_SUBST in zshoptions(1)
setopt PROMPT_SUBST

# See:
#  - zshparam(1) RPROMPT
#  - zshmisc(1) SIMPLE PROMPT ESCAPES
RPROMPT='${ZSHRC_VCS_SUMMARY}[%T]'

# Hook precmd (see zshmisc(1) precmd) so that the variable ${zshrc::vcs_summary}
# is updated before shown on the prompt. See: zshcontrib(1) add-zxsh-hool
autoload -Uz add-zsh-hook

zshrc::set_vcs_summary() {
    vcs_info
    ZSHRC_VCS_SUMMARY="$(eval zshrc::reformat_vcs_info ${vcs_info_msg_0_})"
}
add-zsh-hook precmd zshrc::set_vcs_summary

# See: zshcontrib(1) vcs_info
autoload -Uz vcs_info

zstyle ':vcs_info:*'     enable            git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' formats           "'%u%c' '%b' ''"
zstyle ':vcs_info:git:*' actionformats     "'%u%c' '%b' '%a'"
zstyle ':vcs_info:git:*' unstagedstr       'U'
zstyle ':vcs_info:git:*' stagedstr         'C'

zshrc::reformat_vcs_info() {
    if test $# -ne 3; then
        return 1
    fi
    local change_info=$1    # %u%c
    local branch_info=$2    # %b
    local action_info=$3    # %a
    local output
    case ${change_info} in
    UC) output="! %F{red}${branch_info}%F{default}" ;;
    U)  output="* %F{red}${branch_info}%F{default}" ;;
    C)  output="! %F{green}${branch_info}%F{default}" ;;
    *)  output="* %F{green}${branch_info}%F{default}"
    esac
    if [ ! -z "${action_info}" ]; then
        output="${output}|%F{red}${action_info}%F{default}"
    fi
    echo "${output} "
}

#-----------------------------------------------------------------------------
# External plugins
#-----------------------------------------------------------------------------

zshrc::plugin() {
    local repo
    local url
    local repopath
    local plugname

    repo=$1
    url="https://github.com/${repo}.git"
    repopath="${ZSH_ROOT}/plugins/${repo}"
    plugname=${repo:t}

    if [ ! -d "${repopath}" ]; then
        git clone -q "${url}" "${repopath}"
    fi
    source "${repopath}/${plugname}.zsh"
}

# zsh-syntax-highlighting
zshrc::plugin 'zsh-users/zsh-syntax-highlighting'

ZSH_HIGHLIGHT_HIGHLIGHTERS=(
    main
    brackets
    pattern
    cursor
)

ZSH_HIGHLIGHT_STYLES+=(
    default                       'none'
    unknown-token                 'fg=red,bold'
    reserved-word                 'fg=yellow'
    alias                         'fg=green'
    builtin                       'fg=green'
    function                      'fg=green'
    command                       'fg=green,bold'
    precommand                    'fg=green,underline'
    commandseparator              'none'
    hashed-command                'fg=green'
    path                          'fg=cyan,underline'
    path_prefix                   'underline'
    path_approx                   'fg=yellow,underline'
    globbing                      'fg=blue'
    history-expansion             'fg=blue'
    single-hyphen-option          'none'
    double-hyphen-option          'none'
    back-quoted-argument          'none'
    single-quoted-argument        'fg=yellow'
    double-quoted-argument        'fg=yellow'
    dollar-double-quoted-argument 'fg=cyan'
    back-double-quoted-argument   'fg=cyan'
    assign                        'none'
    bracket-error                 'fg=red,bold'
    bracket-level-1               'fg=blue,bold'
    bracket-level-2               'fg=green,bold'
    bracket-level-3               'fg=magenta,bold'
    bracket-level-4               'fg=yellow,bold'
    bracket-level-5               'fg=cyan,bold'
    cursor-matchingbracket        'standout'
)
