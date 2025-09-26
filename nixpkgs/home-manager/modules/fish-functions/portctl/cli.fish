# Port control CLI with subcommands: kill, tree

set -l usage_lines \
  "Usage:" \
  "  portctl kill [-9 | -SIGKILL | -s SIGNAL] <port> [port ...]" \
  "  portctl tree <port> [port ...]" \
  "" \
  "Examples:" \
  "  portctl kill 8787" \
  "  portctl kill -9 3000 3001" \
  "  portctl kill -s HUP 8080" \
  "  portctl tree 127.0.0.1:8787"

function __portctl_print_usage
  for line in $usage_lines
    echo $line
  end
end

if test (count $argv) -lt 1
  __portctl_print_usage >&2
  return 1
end

set -l sub $argv[1]
set -e argv[1]

switch $sub
  case '-h' '--help' 'help'
    __portctl_print_usage
    return 0

  case kill
    set -l signal '-TERM'
    set -l ports

    if test (count $argv) -eq 0
      __portctl_print_usage >&2
      return 2
    end

    set -l i 1
    while test $i -le (count $argv)
      set -l arg $argv[$i]
      switch $arg
        case '-s'
          set i (math $i + 1)
          if test $i -le (count $argv)
            set -l s $argv[$i]
            if string match -rq '^[0-9]+$' -- $s
              set signal "-"$s
            else
              set -l name (string upper -- $s)
              set name (string replace -r '^SIG' '' -- $name)
              set signal "-SIG"$name
            end
          else
            echo "portctl: -s requires a SIGNAL" >&2
            return 2
          end
        case '-*'
          set -l stripped (string sub -s 2 -- $arg)
          if string match -rq '^[0-9]+$' -- $stripped
            set signal "-"$stripped
          else
            set -l name (string upper -- $stripped)
            set name (string replace -r '^SIG' '' -- $name)
            set signal "-SIG"$name
          end
        case '*'
          set ports $ports $arg
      end
      set i (math $i + 1)
    end

    if test (count $ports) -eq 0
      echo "portctl: missing PORT." >&2
      return 2
    end

    if not type -q lsof
      echo "portctl: 'lsof' is required but not found in PATH." >&2
      return 127
    end

    set -l pids
    for p in $ports
      set -l pn $p
      if string match -q '*:*' -- $p
        set pn (string split -r -m1 ':' -- $p)[-1]
      end
      if not string match -rq '^[0-9]+$' -- $pn
        echo "portctl: invalid port '$p'" >&2
        continue
      end
      set -l tpids (lsof -nP -tiTCP:$pn -sTCP:LISTEN 2>/dev/null)
      set -l upids (lsof -nP -tiUDP:$pn 2>/dev/null)
      set pids $pids $tpids $upids
    end

    set -l uniq_pids
    for pid in (printf '%s\n' $pids | sort -u)
      if test -n "$pid"
        set uniq_pids $uniq_pids $pid
      end
    end

    if test (count $uniq_pids) -eq 0
      for p in $ports
        echo "No process found listening on port $p"
      end
      return 0
    end

    echo "Killing with signal $signal: $uniq_pids"
    for pid in $uniq_pids
      set -l info (ps -o pid=,comm= -p $pid 2>/dev/null | string trim)
      if test -n "$info"
        echo "  $info"
      end
    end

    kill $signal -- $uniq_pids
    set -l rc $status
    if test $rc -ne 0
      echo "portctl: kill failed (exit $rc). You may need elevated privileges." >&2
    end
    return $rc

  case tree
    set -l ports $argv
    if test (count $ports) -eq 0
      __portctl_print_usage >&2
      return 2
    end

    if not type -q lsof
      echo "portctl: 'lsof' is required but not found in PATH." >&2
      return 127
    end

    set -l pids
    for p in $ports
      set -l pn $p
      if string match -q '*:*' -- $p
        set pn (string split -r -m1 ':' -- $p)[-1]
      end
      if not string match -rq '^[0-9]+$' -- $pn
        echo "portctl: invalid port '$p'" >&2
        continue
      end
      set -l tpids (lsof -nP -tiTCP:$pn -sTCP:LISTEN 2>/dev/null)
      set -l upids (lsof -nP -tiUDP:$pn 2>/dev/null)
      set pids $pids $tpids $upids
    end

    set -l uniq_pids
    for pid in (printf '%s\n' $pids | sort -u)
      if test -n "$pid"
        set uniq_pids $uniq_pids $pid
      end
    end

    if test (count $uniq_pids) -eq 0
      for p in $ports
        echo "No process found listening on port $p"
      end
      return 0
    end

    for pid in $uniq_pids
      echo "Process ancestry for PID $pid (ports: $ports)"
      set -l ancestors
      set -l cur $pid
      set -l guard 0
      while test -n "$cur"; and test "$cur" != "0"; and test $guard -lt 64
        set -l ppid (ps -o ppid= -p $cur 2>/dev/null | string trim)
        set -l user (ps -o user= -p $cur 2>/dev/null | string trim)
        set -l comm (ps -o comm= -p $cur 2>/dev/null | string trim)
        if test -z "$comm"
          set comm "?"
        end
        set -l entry "$cur $user $comm"
        set ancestors $ancestors $entry
        if test -z "$ppid"; or test "$ppid" = "$cur"; or test "$ppid" = "0"
          break
        end
        set cur $ppid
        set guard (math $guard + 1)
      end

      set -l depth 0
      for idx in (seq (count $ancestors) -1 1)
        set -l row $ancestors[$idx]
        set -l indent (string repeat -n $depth '  ')
        echo "$indent$row"
        set depth (math $depth + 1)
      end
      echo ""
    end
    return 0

  case '*'
    echo "portctl: unknown subcommand '$sub'" >&2
    __portctl_print_usage >&2
    return 1
end

