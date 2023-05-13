# =============================================================================
# cd-select.zsh
# v0.1.0
# =============================================================================

declare CD_SELECT_VERSION="0.1.0"

# `CD_SELECT_PROMPT` uses the same specification for prompt sequences.
# See the "EXPANSION OF PROMPT SEQUENCES" section of "zshmisc(1)".
declare CD_SELECT_PROMPT=$' %{\e[33m%}..%{\e[0m%} '

# `CD_SELECT_HIGHLIGHTS` uses the same highlight specification as
# `region_highlight`.
# See the "USER-DEFINED WIDGETS" section of "zshzle(1)".
declare -A CD_SELECT_HIGHLIGHTS
CD_SELECT_HIGHLIGHTS[selected]="fg=yellow,bold"
CD_SELECT_HIGHLIGHTS[deselected]="fg=8"

zle -N cd-select-enter __cd_select_enter
zle -N cd-select-exit __cd_select_exit
zle -N cd-select-draw __cd_select_draw
zle -N cd-select-up __cd_select_up
zle -N cd-select-down __cd_select_down
zle -N cd-select-accept __cd_select_accept

bindkey -N cd-select

bindkey '^H' cd-select-enter
bindkey ';h' cd-select-enter
bindkey -M cd-select 'x' cd-select-exit
bindkey -M cd-select ';' cd-select-exit
bindkey -M cd-select '^M' cd-select-accept # return

bindkey -M cd-select '.' cd-select-up
bindkey -M cd-select 'h' cd-select-up
bindkey -M cd-select '^H' cd-select-up
bindkey -M cd-select '^[[D' cd-select-up   # left arrow

bindkey -M cd-select '/' cd-select-down
bindkey -M cd-select 'l' cd-select-down
bindkey -M cd-select '^L' cd-select-down
bindkey -M cd-select '^[[C' cd-select-down # right arrow

declare -a __cd_select_dirs
declare -i __cd_select_dirs_length
declare -i __cd_select_index
declare __cd_select_saved_keymap=
declare __cd_select_saved_prompt=
declare __cd_select_saved_buffer=
declare -i __cd_select_saved_cursor

# Disable zsh autosuggestions for this widget.
() {
  local widget
  local widgets=("cd-select-enter" "cd-select-draw")

  (( ! $+ZSH_AUTOSUGGEST_CLEAR_WIDGETS )) && return

  for widget in "$widgets[@]"; do
    (( ! $ZSH_AUTOSUGGEST_CLEAR_WIDGETS[(Ie)"$widget"] )) \
      && ZSH_AUTOSUGGEST_CLEAR_WIDGETS+=("$widget")
  done
}

__cd_select_enter() {
  __cd_select_dirs=("${(s:/:)PWD}")
  __cd_select_dirs_length=$#__cd_select_dirs
  __cd_select_index=$(( __cd_select_dirs_length - 1 ))
  __cd_select_saved_keymap="$KEYMAP"
  __cd_select_saved_prompt="$PROMPT"
  __cd_select_saved_buffer="$BUFFER"
  __cd_select_saved_cursor="$CURSOR"

  local ZSH_HIGHLIGHT_MAXLENGTH=0

  zle kill-whole-line
  zle -K cd-select

  PROMPT="$CD_SELECT_PROMPT"
  zle .reset-prompt
  zle cd-select-draw
}

__cd_select_exit() {
  BUFFER="$__cd_select_saved_buffer"
  PROMPT="$__cd_select_saved_prompt"
  CURSOR="$__cd_select_saved_cursor"
  zle -K "$__cd_select_saved_keymap"
  zle .reset-prompt
}

__cd_select_draw() {
  local selected="${(j:/:)__cd_select_dirs[@]:0:$__cd_select_index}"
  local -i selected_len=$(( $#selected + 1 ))
  local -i total_len=$#PWD

  region_highlight=(
    "0 $selected_len $CD_SELECT_HIGHLIGHTS[selected]"
    "$selected_len $total_len $CD_SELECT_HIGHLIGHTS[deselected]"
  )

  BUFFER="$PWD"
  CURSOR=$selected_len
}

__cd_select_up() {
  (( __cd_select_index > 1 && __cd_select_index-- ))
  zle cd-select-draw
}

__cd_select_down() {
  (( __cd_select_index < __cd_select_dirs_length && __cd_select_index++ ))
  zle cd-select-draw
}

__cd_select_accept() {
  local selected="${(j:/:)__cd_select_dirs[@]:0:$__cd_select_index}"
  cd "$selected/"
  zle cd-select-exit
}
