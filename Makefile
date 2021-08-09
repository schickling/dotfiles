dot = $(shell pwd)

default:
	# tmux
	ln -sfv $(dot)/tmux/.tmux.conf ~/.tmux.conf

	# neovim
	mkdir -p ~/.config/nvim
	curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
	ln -sfv $(dot)/vim/.vimrc ~/.config/nvim/init.vim

	# haskell
	ln -sfv $(dot)/haskell/.ghci ~/.ghci

	# ssh
	ln -sfv $(dot)/ssh ~/.ssh

	# other
	ln -sfv $(dot)/home/.netrc ~/.netrc
	ln -sfv $(dot)/home/.npmrc ~/.npmrc
	ln -sfv $(dot)/home/.dockercfg ~/.dockercfg
