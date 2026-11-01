#!/bin/sh

set -eu

direction=${1:?expected counterclockwise or clockwise}
herdr_bin=${HERDR_BIN_PATH:-herdr}
current_pane=${HERDR_ACTIVE_PANE_ID:?HERDR_ACTIVE_PANE_ID is required}

layout=$(${herdr_bin} pane layout --current)

target_pane=$(printf '%s\n' "$layout" | jq -r \
    --arg current "$current_pane" \
    --arg direction "$direction" '
      (.result.layout // .result) as $layout
      | ($layout.panes | map(.pane_id)) as $panes
      | ($panes | index($current)) as $index
      | if ($index == null or ($panes | length) < 2) then
          empty
        elif $direction == "counterclockwise" then
          $panes[(($index - 1) + ($panes | length)) % ($panes | length)]
        elif $direction == "clockwise" then
          $panes[($index + 1) % ($panes | length)]
        else
          error("unknown rotation direction")
        end')

[ -n "$target_pane" ] || exit 0

exec ${herdr_bin} pane swap \
    --source-pane "$current_pane" \
    --target-pane "$target_pane"
