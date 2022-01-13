function o
  if test (count $argv) -eq 0
    open .
  else
    open $argv
  end
end
