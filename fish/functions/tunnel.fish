function tunnel
  n=$#@[@]
  host=$@[$n]
  echo $n $host
  #ports=("${@[@]:1:$n-1}")
  #mapped_ports=()
  #for port in $ports
  #do
    #mapped_ports+=("-L $port":localhost:"$port")
    #mapped_ports+=("-L $(lip)":"$port":localhost:"$port")
  #done
  #ports_str=$(join " " ${mapped_ports[@]})
  #ssh $(echo "-nNT $ports_str $host")
end
