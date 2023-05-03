# vi: set ft=sh :

alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'

#calculator with math support
alias bc='bc -l'

#sha1 digest
#alias sha1='openssl sha1'

#show a nice path
alias path='echo -e ${PATH//:/\\n}'

#show a code tree
alias ctree='\tree -a -I .git'

#git diff for non-repo files
alias diff="git diff --no-index --no-prefix -U1000"

# -A      List all entries except for . and ...  Always set for the super-user.
# -F      Display a slash ('/') immediately after each pathname that is a directory, an asterisk ('*') after each that is executable, an at sign ('@') after each symbolic link,
#         an equals sign ('=') after each socket, a percent sign ('%') after each whiteout, and a vertical bar ('|') after each that is a FIFO.
# -G      Enable colorized output.
# -h      When used with the -l option, use unit suffixes: Byte, Kilobyte, Megabyte, Gigabyte, Terabyte and Petabyte in order to reduce the number of digits to three or less
#         using base 2 for sizes.
alias ls="ls -AFh --color=auto"
# ls -d1 */	# list directories in current dir
# ls -1 M*	# list directories only starting with M
# \ls		# ingore alias for ls

alias mux='tmux has && tmux -2 attach || tmux -2 new'

alias mailserver='sudo python -m smtpd -n -c DebuggingServer localhost:25'
alias nl="npm list -depth=0"

alias historyc='history | awk '\''{ out=$4; for (i=5; i<=NF; i++) {out=out" "$i} ; print out }'\'''

# TODO: need to factor out default branch, instead of just master
alias git_merged=$'git branch -r --no-color --merged | awk \'{if ($1 ~ /^origin\//){ x=substr($1, 8); if (x !~ /(master|HEAD)/) print x }}\''
alias git_merged_age=$'git_merged | xargs -I {} bash -c \'echo $(git show -s --format=format:%ci $(git merge-base origin/{} master)) {}\' | sort'
alias git_remote=$'git branch -r --no-color | awk \'{if ($1 ~ /^origin\//){ if ($1 !~ /(master|HEAD)/) print $1 }}\''
alias git_no_tracking=$'git branch -r | awk \'{print $1}\' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk \'{print $1}\''

alias ag="ag --hidden --ignore 'node_modules' --ignore '.git'"
alias deps='jq "{"prod":.dependencies, "dev":.devDependencies}" package.json'

alias recolor="source $HOME/.config/base16-shell/base16-default.dark.sh"

alias k=kubectl

alias tfver="${HOME}/env-ubuntu/installers/terraform-cli.install.manual"
which bat > /dev/null || alias bat='batcat'

# AT HOME ONLY
alias fix_fn="echo 2 | sudo tee /sys/module/hid_apple/parameters/fnmode"
alias code="vscodium"
alias ssh="kitty +kitten ssh"
alias purge="printf '\x1b[2J\x1b[3J\x1b[1;1H'"
#history + percol - date
alias hp="history | percol --match-method regex | awk '{\$1=\$2=\$3=\"\"; print \$0;}'"
alias bu='brew update; brew upgrade; brew cleanup; brew doctor && brew cask upgrade; brew cask doctor'
alias bat &> /dev/null && alias cat='bat -pp'
alias sso='export AWS_PROFILE=$(sed -n "s/\[profile \(.*\)\]/\1/gp" ~/.aws/config | fzf)'
alias assume="source assume"
alias iambic="docker run -it -u $(id -u):$(id -g) -v ${HOME}/.aws:/app/.aws:ro -e AWS_CONFIG_FILE=/app/.aws/config -e AWS_SHARED_CREDENTIALS_FILE=/app/.aws/credentials -e "AWS_PROFILE" -e HOME=/app -v /home/datfinesoul/github/undefined-io/iambic-templates:/templates:Z public.ecr.aws/iambic/iambic:latest"
