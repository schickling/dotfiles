# Fish completions for portctl

if functions -q __portctl_list_ports
  functions -e __portctl_list_ports
end
function __portctl_list_ports --description 'User-owned TCP ports >=3000'
  if not type -q lsof
    return
  end
  set -l me (id -un 2>/dev/null)
  if test -z "$me"; set me (whoami); end
  set -l ports
  set -l tcp_lines (lsof -nP -iTCP -sTCP:LISTEN -F n -u $me 2>/dev/null | string match -r '^n.*:[0-9]+$')
  for line in $tcp_lines
    set -l port (string split -r -m1 ':' -- $line)[-1]
    if string match -rq '^[0-9]+$' -- $port
      set -l p (math $port)
      if test $p -ge 3000 -a $p -le 65535
        set -l skip 0
        for noisy in 5353 6463
          if test $p -eq $noisy
            set skip 1; break
          end
        end
        if test $skip -eq 0
          set ports $ports $port
        end
      end
    end
  end
  for p in (printf '%s\n' $ports | sort -u)
    if test -n "$p"; printf "%s\tListening port\n" $p; end
  end
end

complete -c portctl -e
complete -c portctl -f

# Subcommands
complete -c portctl -n '__fish_use_subcommand' -a kill -d 'Kill process(es) by port'
complete -c portctl -n '__fish_use_subcommand' -a tree -d 'Show process ancestry by port'

# kill options + ports
complete -c portctl -n '__fish_seen_subcommand_from kill' -s s -r -d 'Signal (name or number)' -a 'HUP INT QUIT KILL TERM USR1 USR2 STOP CONT PIPE ALRM WINCH'
complete -c portctl -n '__fish_seen_subcommand_from kill' -a '-9' -d 'SIGKILL'
complete -c portctl -n '__fish_seen_subcommand_from kill' -a '-KILL' -d 'SIGKILL'
complete -c portctl -n '__fish_seen_subcommand_from kill' -a '-SIGKILL' -d 'SIGKILL'
complete -c portctl -n '__fish_seen_subcommand_from kill' -a '(__portctl_list_ports)'

# tree ports
complete -c portctl -n '__fish_seen_subcommand_from tree' -a '(__portctl_list_ports)'

