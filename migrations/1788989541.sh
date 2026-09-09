echo "Select Monarchy's bridge console as the bar"

# monarchy: a user who already turned the bridge off keeps the stock bar; this
# only moves users still on the shipped default onto the bridge.
if [[ -f $HOME/.config/omarchy/shell.json ]] && [[ $(jq -r '.bar.id // ""' "$HOME/.config/omarchy/shell.json") != "" ]]; then
  exit 0
fi

omarchy-toggle-bridge on
