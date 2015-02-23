function short --description "Add abbreviation"
		set -U fish_user_abbreviations $fish_user_abbreviations $argv[1]=$argv[2]
end
