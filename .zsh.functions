# repeats a command
function again() {
	while [ 1 ]; do
		eval $2 $3 $4 $5
		sleep $1
	done
}

function s() {
    if [ $# -gt 0 ]; then
        subl "$@"
    elif [ -e ".sublime.sublime-project"  ]; then
        subl .sublime.sublime-project
    else
        subl .
    fi
}

function gf() {
    git pull
    git add .
    git commit -m $1
    git push
}

function jj () {
    jekyll serve -w &
    sleep 5
    open http://localhost:4000
    fg
}

function haste() { a=$(cat); curl -X POST -s -d "$a" http://hastebin.com/documents | awk -F '"' '{print "http://hastebin.com/"$4}'; }
