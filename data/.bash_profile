if [ -f "$(brew --prefix)/opt/bash-git-prompt/share/gitprompt.sh" ]; then
  __GIT_PROMPT_DIR=$(brew --prefix)/opt/bash-git-prompt/share
  GIT_PROMPT_ONLY_IN_REPO=1
  source "$(brew --prefix)/opt/bash-git-prompt/share/gitprompt.sh"
fi

[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"

if [ -f $HOME/.git-completion.bash ]; then
  . $HOME/.git-completion.bash
fi

export PATH="/opt/homebrew/opt/node@16/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"

export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

# git aliases
alias edit-bash="code $HOME/.bash_profile"
alias source-bash="source $HOME/.bash_profile"
alias edit-git="code $HOME/.gitconfig"
alias diff="git diff > git.diff && code -r git.diff --wait && rm git.diff"
alias stash-u="git ci -m 'WIP' && git stash -u -m 'stash-unstaged' && git undo"
alias stash-s="stash-u && git stash -m 'stash-staged' && git stash pop stash@{1}"
alias gpsup='git push --set-upstream origin $(git_current_branch)'
alias save='git add . && git sv'

# yarn project aliases
alias yd="yarn dev"
alias yg="yarn generate"
alias yyd="yarn && yarn dev"
alias ytw="yarn test:watch"

# db-migrate aliases
alias db-check-down='grep ^DATABASE_URL .env &&  db-migrate down --check'
alias db-check-up='grep ^DATABASE_URL .env && db-migrate up --check'
alias migrate-down='grep ^DATABASE_URL .env && db-migrate down --check && confirm && db-migrate down'
alias migrate-up='grep ^DATABASE_URL .env && db-migrate up --check && confirm && db-migrate up'

# aws / kubernetes aliases
alias kcluster='kubectl config get-contexts | fzf | tr -s " " | cut -d" " -f2 | xargs kubectl config use-context'
alias kns='kubectl get ns | fzf | cut -d" " -f1 | xargs kubectl config set-context --current --namespace'

new_file () {
  touch $1
  code $1
}

confirm () {
  read -p "Do you want to proceed? (y/n) " yn

  case $yn in 
    y ) echo ok, we will proceed;;
    n ) echo exiting...;
      exit 0;;
    * ) echo invalid response;
      exit 0;;
  esac

  echo doing stuff...
}

code () { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args "$*" ;}

[ -f $HOME/.fzf.bash ] && source $HOME/.fzf.bash

git_current_branch () {
	cat "$(git rev-parse --git-dir 2>/dev/null)/HEAD" | gsed -e 's/^.*refs\/heads\///'
}



export EKA="/Users/erikbjorn/eka-config"
eka () { . $EKA/scripts.sh ;}

