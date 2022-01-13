function ask
  # http://djm.me/ask
  #while true; do

    #if [ "${2:-}" = "Y" ]; then
      #opts="Y/n"
      #default=Y
    #elif [ "${2:-}" = "N" ]; then
      #opts="y/N"
      #default=N
    #else
      #opts="y/n"
      #default=
    #fi

    ## Ask the question
    #read "REPLY?$1 [$opts]"

    ## Default?
    #if [ -z "$REPLY" ]; then
      #REPLY=$default
    #fi

    ## Check if the reply is valid
    #case "$REPLY" in
      #Y*|y*) return 0 ;;
      #N*|n*) return 1 ;;
    #esac

  #end
end
