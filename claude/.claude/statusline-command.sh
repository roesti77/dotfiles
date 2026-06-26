#!/usr/bin/env bash
# Claude Code status line — 3 lines:
#   1) model · effort        session_name              output_style (right-aligned)
#   2) ctx [bar] N% SIZE   $COST   IN↓ OUT↑   cache N%
#   3) 5h [bar] N% RESET    7d [bar] N% RESET
# All data comes from the stdin JSON Claude Code provides. Pure bash + jq.
input=$(cat)

# ---- colors (256-color) -------------------------------------------------
R=$'\033[0m'
DIM=$'\033[38;5;245m'      # label grey
DARK=$'\033[38;5;240m'     # model / muted
GRN=$'\033[38;5;42m'       # bar fill / accent green
EMPTY=$'\033[38;5;237m'    # bar empty
CYN=$'\033[38;5;39m'       # session name
WHT=$'\033[38;5;252m'      # values
YEL=$'\033[38;5;179m'      # cost
RED=$'\033[38;5;203m'      # reset marker
ARR=$'\033[38;5;108m'      # token arrows

DE_DOW=( [1]="Mo." [2]="Di." [3]="Mi." [4]="Do." [5]="Fr." [6]="Sa." [7]="So." )

# ---- layout -------------------------------------------------------------
BAR_W=16   # width of every progress bar (ctx / 5h / 7d), in chars

# ---- read all fields at once (newline-separated, empty-safe) ------------
# Bash 3.2 compatible (macOS system bash has no `mapfile`).
F=()
while IFS= read -r __line; do F+=("$__line"); done < <(echo "$input" | jq -r '[
  (.model.display_name // ""),
  (.effort.level // ""),
  (.session_name // ""),
  (.output_style.name // ""),
  (.context_window.used_percentage // 0),
  (.context_window.context_window_size // 0),
  (.cost.total_cost_usd // 0),
  (.context_window.total_input_tokens // 0),
  (.context_window.total_output_tokens // 0),
  (.context_window.current_usage.input_tokens // 0),
  (.context_window.current_usage.cache_creation_input_tokens // 0),
  (.context_window.current_usage.cache_read_input_tokens // 0),
  (.rate_limits.five_hour.used_percentage // -1),
  (.rate_limits.five_hour.resets_at // 0),
  (.rate_limits.seven_day.used_percentage // -1),
  (.rate_limits.seven_day.resets_at // 0),
  (.workspace.current_dir // "")
] | .[]')

model=${F[0]};   effort=${F[1]};  session=${F[2]};  style=${F[3]}
ctx_pct=${F[4]}; ctx_size=${F[5]}; cost=${F[6]}
in_tok=${F[7]};  out_tok=${F[8]}
cu_in=${F[9]};   cu_cc=${F[10]};  cu_cr=${F[11]}
fh_pct=${F[12]}; fh_reset=${F[13]}
sd_pct=${F[14]}; sd_reset=${F[15]}
cwd=${F[16]}

# ---- helpers ------------------------------------------------------------
to_int() { printf '%.0f' "${1:-0}" 2>/dev/null || echo 0; }

fmt_num() {  # 93300 -> 93.3K, 1000000 -> 1M
  awk -v n="${1:-0}" 'BEGIN{
    if(n>=1000000){v=n/1000000;u="M"}
    else if(n>=1000){v=n/1000;u="K"}
    else{printf "%d",n; exit}
    s=sprintf("%.1f",v); sub(/\.0$/,"",s); printf "%s%s",s,u
  }'
}

fmt_reset() {  # $1 epoch, $2 = 1 for 5h (time only if today), else weekday+time
  local e=$1 mode=$2
  [ "${e:-0}" -le 0 ] 2>/dev/null && { printf '%s' '--:--'; return; }
  local hm dow; hm=$(date -r "$e" +%H:%M 2>/dev/null) || { printf '%s' '--:--'; return; }
  if [ "$mode" = "1" ] && [ "$(date -r "$e" +%Y%j)" = "$(date +%Y%j)" ]; then
    printf '%s' "$hm"
  else
    dow=$(date -r "$e" +%u)
    printf '%s %s' "${DE_DOW[$dow]}" "$hm"
  fi
}

bar() {  # $1 pct $2 width $3 fillcolor
  local pct width col filled i out
  pct=$(to_int "$1"); width=$2; col=$3
  (( pct < 0 )) && pct=0; (( pct > 100 )) && pct=100
  filled=$(( (pct*width + 50) / 100 ))
  (( filled > width )) && filled=$width
  out="$col"
  for ((i=0;i<filled;i++)); do out+="█"; done
  out+="$EMPTY"
  for ((i=filled;i<width;i++)); do out+="█"; done
  out+="$R"
  printf '%s' "$out"
}

# ---- derived values -----------------------------------------------------
ctx_i=$(to_int "$ctx_pct")
total_cu=$(( cu_in + cu_cc + cu_cr ))
cache_pct=0; (( total_cu > 0 )) && cache_pct=$(( cu_cr * 100 / total_cu ))
size_fmt=$(fmt_num "$ctx_size")
in_fmt=$(fmt_num "$in_tok")
out_fmt=$(fmt_num "$out_tok")
cost_fmt=$(printf '%.2f' "${cost:-0}" 2>/dev/null || echo "0.00")

# ============================ LINE 1 =====================================
left="${DARK}${model}${R}"
[ -n "$effort" ] && left+="${DARK}·${GRN}${effort}${R}"
[ -n "$session" ] && left+="   ${CYN}${session}${R}"

right=""
[ -n "$style" ] && right="${DIM}${style}${R}"

# plain (no-ANSI) versions for width math
lp="${model}"; [ -n "$effort" ] && lp+="·${effort}"; [ -n "$session" ] && lp+="   ${session}"
rp="${style}"

cols=${COLUMNS:-0}
[ "$cols" -le 0 ] 2>/dev/null && cols=$(tput cols 2>/dev/null || echo 0)
line1="$left"
if [ -n "$right" ]; then
  pad=$(( cols - ${#lp} - ${#rp} ))
  if [ "$cols" -gt 0 ] && [ "$pad" -ge 1 ]; then
    line1+=$(printf '%*s' "$pad" '')"$right"
  else
    line1+="   ${right}"
  fi
fi

# ============================ LINE 2 =====================================
line2="${DIM}ctx${R} $(bar "$ctx_i" "$BAR_W" "$GRN") ${WHT}${ctx_i}%${R} ${DIM}${size_fmt}${R}"
line2+="   ${YEL}\$${cost_fmt}${R}"
line2+="   ${WHT}${in_fmt}${ARR}↓${R} ${WHT}${out_fmt}${ARR}↑${R}"
line2+="   ${DIM}cache${R} ${WHT}${cache_pct}%${R}"

# ============================ LINE 3 =====================================
line3=""
if [ "$(to_int "$fh_pct")" -ge 0 ] && [ "${fh_pct%.*}" != "-1" ]; then
  fh_i=$(to_int "$fh_pct")
  line3+="${DIM}5h ${R} $(bar "$fh_i" "$BAR_W" "$GRN") ${WHT}${fh_i}%${RED}→100%${R} ${DIM}$(fmt_reset "$fh_reset" 1)${R}"
fi
if [ "${sd_pct%.*}" != "-1" ] && [ "$(to_int "$sd_pct")" -ge 0 ]; then
  sd_i=$(to_int "$sd_pct")
  [ -n "$line3" ] && line3+="    "
  line3+="${DIM}7d ${R} $(bar "$sd_i" "$BAR_W" "$GRN") ${WHT}${sd_i}%${RED}→100%${R} ${DIM}$(fmt_reset "$sd_reset" 0)${R}"
fi

# ---- output -------------------------------------------------------------
printf '%s\n' "$line1"
printf '%s\n' "$line2"
[ -n "$line3" ] && printf '%s\n' "$line3"
exit 0
