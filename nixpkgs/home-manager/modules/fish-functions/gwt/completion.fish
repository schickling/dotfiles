# Fish completions for gwt

if not set -q __gwt_worktrees_root
    set -g __gwt_worktrees_root /home/schickling/code/worktrees
end

if functions -q __gwt_list_repos_for_completion
    functions -e __gwt_list_repos_for_completion
end
function __gwt_list_repos_for_completion --description 'List gwt repositories for completions'
    set -l tokens (commandline -opc)
    set -l current (commandline -ct)
    if test (count $tokens) -ge 3
        if test -z "$current"
            return
        end
    end

    set -l root $__gwt_worktrees_root
    if test -z "$root"; or not test -d $root
        return
    end

    for repo_path in (command find -L $root -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null)
        set -l repo_name (string replace -r '^.*/' '' -- $repo_path)
        if test -z "$repo_name"
            continue
        end
        printf "%s\t%s\n" $repo_name $repo_path
    end
end

if functions -q __gwt_list_worktree_entries
    functions -e __gwt_list_worktree_entries
end
function __gwt_list_worktree_entries --description 'List worktree entries for archive completions'
    set -l tokens (commandline -opc)
    if test (count $tokens) -lt 3
        return
    end

    set -l repo_name $tokens[3]
    if test -z "$repo_name"
        return
    end

    set -l root $__gwt_worktrees_root
    if test -z "$root"
        return
    end

    set -l repo_root $root/$repo_name
    if not test -d $repo_root
        return
    end

    set -l emitted

    for dir_path in (command find -L $repo_root -mindepth 1 -maxdepth 1 -type d -print 2>/dev/null)
        set -l dir_name (string replace -r '^.*/' '' -- $dir_path)
        if test -z "$dir_name"
            continue
        end
        if test $dir_name = '.main'; or test $dir_name = '.archive'
            continue
        end
        if contains -- $dir_name $emitted
            continue
        end
        set emitted $emitted $dir_name
        printf "%s\tWorktree directory\n" $dir_name
    end

    set -l main_worktree $repo_root/.main
    if not test -d $main_worktree
        return
    end

    set -l worktree_data (git -C $main_worktree worktree list --porcelain 2>/dev/null)
    if test -z "$worktree_data"
        return
    end

    for line in $worktree_data
        if string match -q 'worktree *' $line
            set -l worktree_path (string replace -r '^worktree ' '' -- $line)
            set -l base_name (string replace -r '^.*/' '' -- $worktree_path)
            if test -n "$base_name"; and test $base_name != '.main'; and not contains -- $base_name $emitted
                set emitted $emitted $base_name
                printf "%s\tWorktree directory\n" $base_name
            end
        else if string match -q 'branch *' $line
            set -l branch_name (string replace -r '^branch ' '' -- $line)
            set -l short_branch (string replace -r '^refs/heads/' '' -- $branch_name)
            if test -n "$short_branch"; and not contains -- $short_branch $emitted
                set emitted $emitted $short_branch
                printf "%s\tGit branch\n" $short_branch
            end
        end
    end
end

if functions -q __gwt_list_remote_branches
    functions -e __gwt_list_remote_branches
end
function __gwt_list_remote_branches --description 'List remote branches for gwt branch subcommand'
    set -l tokens (commandline -opc)
    if test (count $tokens) -lt 3
        return
    end

    set -l repo_name $tokens[3]
    set -l root $__gwt_worktrees_root
    set -l repo_root $root/$repo_name
    set -l main_worktree $repo_root/.main

    if not test -d $main_worktree
        return
    end

    set -l current (commandline -ct)
    if test -z "$current"
        if test (count $tokens) -ge 4
            set current $tokens[4]
        end
    end

    set -l desired_remote ""
    if test -n "$current"
        set -l split (string split -m1 '/' -- $current)
        if test (count $split) -ge 2
            set desired_remote $split[1]
        end
    end

    set -l refs (git -C $main_worktree for-each-ref --format='%(refname:strip=2)' refs/remotes 2>/dev/null)
    if test -z "$refs"
        return
    end

    set -l emitted
    for ref in $refs
        if test -n "$desired_remote"; and not string match -q "$desired_remote/*" $ref
            continue
        end
        if string match -q '*/HEAD' $ref
            continue
        end
        if contains -- $ref $emitted
            continue
        end
        set emitted $emitted $ref
        printf "%s\tRemote branch\n" $ref
    end
end

complete -c gwt -e
complete -c gwt -f

complete -c gwt -n '__fish_use_subcommand' -a setup-repo -d 'Bootstrap repository into .main worktree'
complete -c gwt -n '__fish_use_subcommand' -a new -d 'Create prefixed dated worktree (slug optional)'
complete -c gwt -n '__fish_use_subcommand' -a branch -d 'Create worktree for existing remote branch'
complete -c gwt -n '__fish_use_subcommand' -a archive -d 'Archive existing worktree'
complete -c gwt -n '__fish_use_subcommand' -a zellij -d 'Attach canonical Zellij session for worktree'

complete -c gwt -n "__fish_seen_subcommand_from new branch archive" -a '(__gwt_list_repos_for_completion)'
complete -c gwt -n "__fish_seen_subcommand_from archive" -a '(__gwt_list_worktree_entries)'
complete -c gwt -n "__fish_seen_subcommand_from branch" -a '(__gwt_list_remote_branches)'
