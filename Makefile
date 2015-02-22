dot = $(shell pwd)

default:
	# tmux
	ln -sfv $(dot)/tmux/.tmux.conf ~/.tmux.conf
	# vim
	ln -sfv $(dot)/vim/.vimrc ~/.vimrc
	ln -sfv $(dot)/vim/.vimrc ~/.nvimrc
	# haskell
	ln -sfv $(dot)/haskell/.ghci ~/.ghci
