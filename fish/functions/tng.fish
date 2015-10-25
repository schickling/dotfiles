function tng
  # enable tmux sharing
  set -e TMUX

  set gotty_port 34567
  set gotty_profile "/tmp/gotty_profile.json"
  set tmux_id (tmux display -p '#S')

  # prepare gotty profile file
  printf '{
    "enable-bold": false,
    "background-color": "#002B36",
    "foreground-color": "#839496",
    "font-size": 13,
    "font-family": "Menlo",
    "font-smoothing": "subpixel-antialiased"
  }' > $gotty_profile

  gotty --port=$gotty_port \
        --reconnect="1" \
        --config=$gotty_profile \
        tmux attach -t $tmux_id &

  # store pid to kill later
  set PID %gotty

  # prepare auth data
  set ngrok_subdomain "schickling"
  set ngrok_user "user"
  set ngrok_password (random)
  echo -n "http://$ngrok_user:$ngrok_password@$ngrok_subdomain.ngrok.io" | pbcopy

  ngrok http \
        --subdomain=$ngrok_subdomain \
        --auth="$ngrok_user:$ngrok_password" \
        $gotty_port

  # kill gotty on exit
  kill -9 $PID
end
