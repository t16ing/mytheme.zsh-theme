# user, host, full path, and time/date on two lines for easier vgrepping
# [refered from] zsh-theme jonathan, Soliah, and rkj-repos

functions rbenv_prompt_info >& /dev/null || rbenv_prompt_info(){}

function theme_precmd {
    local TERMWIDTH
    (( TERMWIDTH = ${COLUMNS} - 1 ))


    ###
    # Truncate the path if it's too long.

    PR_FILLBAR=""
    PR_PWDLEN=""

    local ZSH_THEME_GIT_PROMPT_ADDED="+"
    local ZSH_THEME_GIT_PROMPT_MODIFIED="?"
    local ZSH_THEME_GIT_PROMPT_DELETED="?"
    local ZSH_THEME_GIT_PROMPT_RENAMED="?"
    local ZSH_THEME_GIT_PROMPT_UNMERGED="?"
    local ZSH_THEME_GIT_PROMPT_UNTRACKED="?"
    local ZSH_THEME_GIT_PROMPT_DIVERGED=
    local ZSH_THEME_GIT_PROMPT_SHA_BEFORE=
    local ZSH_THEME_GIT_PROMPT_SHA_AFTER=
    local ZSH_THEME_GIT_PROMPT_LOCAL_BEFORE=
    local ZSH_THEME_GIT_PROMPT_LOCAL_AFTER=
    local ZSH_THEME_GIT_PROMPT_REMOTE_BEFORE=
    local ZSH_THEME_GIT_PROMPT_REMOTE_AFTER=
    local ZSH_THEME_GIT_TIME_SINCE_COMMIT_SHORT=
    local ZSH_THEME_GIT_TIME_SHORT_COMMIT_MEDIUM=
    local ZSH_THEME_GIT_TIME_SINCE_COMMIT_LONG=
    local ZSH_THEME_GIT_TIME_SINCE_COMMIT_NEUTRAL=

    local promptsize=${#${(%):---(%n@%m:%l)---()--}}
    local rubyprompt=`rvm_prompt_info || rbenv_prompt_info`
    local rubypromptsize=${#${rubyprompt}}
    local git="$(mygit)"
    [[ "$git" != "" ]] \
        && local gitsize=${#${git}}+1 \
        || local gitsize=0

    if [[ "$promptsize + $rubypromptsize + $gitsize" -gt $TERMWIDTH ]]; then
      ((PR_PWDLEN=$TERMWIDTH - $promptsize))
    else
      PR_FILLBAR="\${(l.(($TERMWIDTH - ($promptsize + $rubypromptsize + $gitsize)))..${PR_HBAR}.)}"
    fi

    now=$(($(date +%s%N)/1000000))
    elapsed="$PR_RED$(($now-$timer))ms"
}


setopt extended_glob
theme_preexec () {
    if [[ "$TERM" == "screen" ]]; then
	local CMD=${1[(wr)^(*=*|sudo|-*)]}
	echo -n "\ek$CMD\e\\"
    fi

    timer=$(($(date +%s%N)/1000000))
}

ZSH_THEME_GIT_PROMPT_ADDED="%{$fg[cyan]%}+"
ZSH_THEME_GIT_PROMPT_MODIFIED="%{$fg[yellow]%}✱"
ZSH_THEME_GIT_PROMPT_DELETED="%{$fg[red]%}✗"
ZSH_THEME_GIT_PROMPT_RENAMED="%{$fg[blue]%}➦"
ZSH_THEME_GIT_PROMPT_UNMERGED="%{$fg[magenta]%}✂"
ZSH_THEME_GIT_PROMPT_UNTRACKED="%{$fg[blue]%}✈"
ZSH_THEME_GIT_PROMPT_SHA_BEFORE=" %{$fg[grey]%}"
ZSH_THEME_GIT_PROMPT_SHA_AFTER=
ZSH_THEME_GIT_PROMPT_LOCAL_BEFORE="%{$fg[magenta]%}"
ZSH_THEME_GIT_PROMPT_LOCAL_AFTER=
ZSH_THEME_GIT_PROMPT_REMOTE_BEFORE="%{$fg[magenta]%}"
ZSH_THEME_GIT_PROMPT_REMOTE_AFTER=

function mygit() {
  if [[ "$(git config --get oh-my-zsh.hide-status)" != "1" ]]; then
    ref=$(command git symbolic-ref HEAD 2> /dev/null) || \
    ref=$(command git rev-parse --short HEAD 2> /dev/null) || return
    origin=$(command git remote show -n origin 2>/dev/null | grep 'Fetch URL' | cut -d ':' -f 2- | cut -d' ' -f 2 | sed 's/\.git$//')
    repo=$(basename ${origin})
    message=$(git log -1 --pretty=%B)
    [[ "$(git_commits_ahead)" != "" ]] && remote_status=$ZSH_THEME_GIT_PROMPT_MODIFIED || remote_status=""
    echo "$ZSH_THEME_GIT_PROMPT_LOCAL_BEFORE$(git_prompt_status)${ref#refs/heads/}$ZSH_THEME_GIT_PROMPT_LOCAL_AFTER$(git_prompt_short_sha) $message $ZSH_THEME_GIT_PROMPT_REMOTE_BEFORE$remote_status$(git_current_user_name)@${repo}$ZSH_THEME_GIT_PROMPT_REMOTE_AFTER"
  fi
}

setprompt () {
    ###
    # Need this so the prompt will work.

    setopt prompt_subst


    ###
    # See if we can use colors.

    autoload zsh/terminfo
    for color in RED GREEN YELLOW BLUE MAGENTA CYAN WHITE GREY; do
	eval PR_$color='%{$terminfo[bold]$fg[${(L)color}]%}'
	eval PR_LIGHT_$color='%{$fg[${(L)color}]%}'
	(( count = $count + 1 ))
    done
    PR_NO_COLOUR="%{$terminfo[sgr0]%}"

    ###
    # See if we can use extended characters to look nicer.
    # UTF-8 Fixed

    if [[ $(locale charmap) == "UTF-8" ]]; then
	PR_SET_CHARSET=""
	PR_SHIFT_IN=""
	PR_SHIFT_OUT=""
	PR_HBAR="─"
        PR_ULCORNER="┌"
        PR_LLCORNER="└"
        PR_LRCORNER="┘"
        PR_URCORNER="┐"
    else
        typeset -A altchar
        set -A altchar ${(s..)terminfo[acsc]}
        # Some stuff to help us draw nice lines
        PR_SET_CHARSET="%{$terminfo[enacs]%}"
        PR_SHIFT_IN="%{$terminfo[smacs]%}"
        PR_SHIFT_OUT="%{$terminfo[rmacs]%}"
        PR_HBAR='$PR_SHIFT_IN${altchar[q]:--}$PR_SHIFT_OUT'
        PR_ULCORNER='$PR_SHIFT_IN${altchar[l]:--}$PR_SHIFT_OUT'
        PR_LLCORNER='$PR_SHIFT_IN${altchar[m]:--}$PR_SHIFT_OUT'
        PR_LRCORNER='$PR_SHIFT_IN${altchar[j]:--}$PR_SHIFT_OUT'
        PR_URCORNER='$PR_SHIFT_IN${altchar[k]:--}$PR_SHIFT_OUT'
     fi


    ###
    # Decide if we need to set titlebar text.

    case $TERM in
	xterm*)
	    PR_TITLEBAR=$'%{\e]0;%(!.-=*[ROOT]*=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\a%}'
	    ;;
	screen)
	    PR_TITLEBAR=$'%{\e_screen \005 (\005t) | %(!.-=[ROOT]=- | .)%n@%m:%~ | ${COLUMNS}x${LINES} | %y\e\\%}'
	    ;;
	*)
	    PR_TITLEBAR=''
	    ;;
    esac


    ###
    # Decide whether to set a screen title
    if [[ "$TERM" == "screen" ]]; then
	PR_STITLE=$'%{\ekzsh\e\\%}'
    else
	PR_STITLE=''
    fi


    ###
    # Finally, the prompt.

    PROMPT='
$PR_SET_CHARSET$PR_STITLE${(e)PR_TITLEBAR}\
$PR_CYAN$PR_ULCORNER$PR_HBAR\
$PR_GREY($PR_BLUE$(mygit)$PR_GREY)\
`rvm_prompt_info || rbenv_prompt_info`\
$PR_CYAN$PR_HBAR$PR_HBAR${(e)PR_FILLBAR}$PR_HBAR$PR_GREY(\
$PR_CYAN%(!.%SROOT%s.%n)$PR_GREY@$PR_GREEN%m:%l\
$PR_GREY)$PR_CYAN$PR_HBAR$PR_URCORNER\

$PR_CYAN$PR_LLCORNER$PR_BLUE$PR_HBAR(\
$PR_LIGHT_BLUE%{$reset_color%}\
$PR_GREEN%$PR_PWDLEN<...<%~%<<\
$PR_BLUE)$PR_CYAN$PR_HBAR\
$PR_HBAR\
>$PR_NO_COLOUR '

    # display exitcode on the right when >0
    return_code="%(?..%{$fg[red]%}%? ↵ %{$reset_color%})"
    RPROMPT=' $return_code $elapsed $PR_CYAN$PR_HBAR$PR_BLUE$PR_HBAR\
($PR_YELLOW%D{%a %Y-%m-%d %H:%M:%S}\
$PR_BLUE)$PR_HBAR$PR_CYAN$PR_LRCORNER$PR_NO_COLOUR'

    PS2='$PR_CYAN$PR_HBAR\
$PR_BLUE$PR_HBAR(\
$PR_LIGHT_GREEN%_$PR_BLUE)$PR_HBAR\
$PR_CYAN$PR_HBAR$PR_NO_COLOUR '
}

setprompt

autoload -U add-zsh-hook
add-zsh-hook precmd  theme_precmd
add-zsh-hook preexec theme_preexec

timer=$(($(date +%s%N)/1000000))
