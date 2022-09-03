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

# eval "$(/opt/homebrew/bin/brew shellenv)"

code () { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args $* ;}

[ -f $HOME/.fzf.bash ] && source $HOME/.fzf.bash

git_current_branch () {
	cat "$(git rev-parse --git-dir 2>/dev/null)/HEAD" | gsed -e 's/^.*refs\/heads\///'
}

create_git_log () {
  echo "..."
  if [[ -n $(git status -s) ]]; 
    then
      echo "" >> log-file.txt
      date >> log-file.txt
      git add -N .
      echo "Creating git log (log-file.txt):"
      echo $(git diff --stat -- ':!log-file.txt' ':!.obsidian')
      git diff --stat -- ':!log-file.txt' ':!.obsidian' >> log-file.txt
    else 
      echo "No changes to commit"
  fi
}

auto_push () {
  commitmessage=$1

  create_git_log
  git add .


  if [[ "$1" == "" ]]; then
    commitmessage="auto-push $(date)"
  fi

  echo "..."
  echo "Commiting: $commitmessage"
  git commit -m "$commitmessage"
  gpsup
}

set_local_config () {
  echo "..."
  echo "Copying config from '$HOME/eka-config/ to $HOME/"

  . ./eka-helpers/set-local-config.sh

  echo "..."
  echo "Previous local config stored in $HOME/eka-config/previous-local-config/"

  source $HOME/.bash_profile

  echo "..."
  echo "Local config updated and sourced"
}

get_local_config () {
  echo "..."
  echo "Copying local config into '$HOME/eka-config/"

  cp -f $HOME/.gitconfig $HOME/eka-config/
  cp -f $HOME/.bash_profile $HOME/eka-config/
  cp -rf $HOME/eka-helpers $HOME/eka-config/
}


sync_eka_config_into_repo () {
  get_local_config

  store_git_credentials
}


push_eka_config () {
  commitmessage=$1

  sync_eka_config_into_repo
  
  echo "..."
  echo "Triggering eka-config push to github"
  auto_push $commitmessage
}

pull_eka_config () {
  cd $HOME/eka-config/
  echo "..."

  # if any changes on remote, pull them
  if [[ $(git rev-parse HEAD) != $(git rev-parse @{u}) ]]; 
    then
      echo "Pulling eka-config from github"
      git pull
      
      set_local_config
    else 
      echo "No changes on remote"
  fi
}

store_git_credentials () {
  echo "..."

  sed -n '/\[user\]/,/\[/ { 
    /\[?[^u]?/b
    p
  }' $PWD/.gitconfig > temp-file-1.txt

  if [ -s temp-file-1.txt ]
  then
    echo "Storing git credentials in $PWD/.git-credentials"
    cat temp-file-1.txt > $PWD/.git-credentials
  else
    echo "No git credentials found in $PWD/.gitconfig"
  fi

  rm temp-file-1.txt

  echo "..."
  echo "Deleting git credentials from $PWD/.gitconfig"

  sed '/\[user\]/,/\[/{/\[[^u]/!d;}' $PWD/.gitconfig > temp-file-2.txt
  cat temp-file-2.txt > $PWD/.gitconfig
  rm temp-file-2.txt
}
