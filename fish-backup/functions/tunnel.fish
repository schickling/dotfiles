function tunnel
  set host $argv[1]
  set ports $argv[2..-1]
  set mapped_ports
  for port in $ports
    set local "-L $port":localhost:"$port"
    set remote "-L "(lip)":"$port":localhost:"$port
    set mapped_ports $local $remote $mapped_ports
  end
  ssh -nNT $mapped_ports $host
end
