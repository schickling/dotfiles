function abbr --description "Manage abbreviations"
		set -U fish_user_abbreviations $fish_user_abbreviations $argv[1]
end
