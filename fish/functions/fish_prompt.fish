function _git_branch_name
  echo (command git symbolic-ref HEAD ^/dev/null | sed -e 's|^refs/heads/||')
end

function _git_dirty
  echo (command git status -s --ignore-submodules=dirty ^/dev/null)
end

function fish_prompt
  set -l last_status $status
  set -l magenta (set_color magenta)
  set -l red (set_color red)
  set -l blue (set_color blue)
  set -l yellow (set_color yellow)
  set -l normal (set_color normal)

  echo -e ''
  echo -n -s $blue (prompt_pwd)

  if [ (_git_branch_name) ]
    if [ (_git_dirty) ]
      echo -n $yellow
    else
      echo -n $normal
    end
    set -l git_branch (_git_branch_name)
    echo -n -s ' ' $git_branch
  end
  echo -e ''

  if test $last_status -eq 0
    echo -n $magenta
  else
    echo -n $red
  end
  echo -n '❯ '
end
