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
alias edit-bash="vim $HOME/.bash_profile"
alias source-bash="source $HOME/.bash_profile"
alias edit-git="code $HOME/.gitconfig"
alias diff="git diff > git.diff && code -r git.diff --wait && rm git.diff"
alias stash-u="git commit -m 'WIP' && git stash -u -m 'stash-unstaged' && git undo"
alias stash-s="stash-u && git stash -m 'stash-staged' && git stash pop stash@{1}"
alias gpsup='git push --set-upstream origin $(git_current_branch)'
alias save='git add . && git sv'
alias m='git checkout master'

gib() {
  # get history of branches commited on, sort by latest commit date, find the latest one that is not the current branch
  local branch=$(git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short)' | grep -v $(git rev-parse --abbrev-ref HEAD) | head -n 1)

  git switch $branch
}

gih() {
  # get history of branches commited on, sort by latest commit date, find the one n steps back, even if it is the current branch
  local branch=$(git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short)' | head -n ${1:-1} | tail -n 1)

  git switch $branch
}

print_branch_history() {
  local mode="$1"
  local flag="$2"
  local count="${3:-10}"

  echo "$flag"

  # get branches, sort by commit date, list the $count latest
  local branches=$(git branch $flag --sort=-committerdate | head -n $count)

  echo "$mode branches:"
  echo ""
  echo "$branches" | awk '{gsub(/[\S\n]+/,"\n")}1'
}

gif() {
  # fuzzy find branches, sort by latest commit date, find the latest one that is not the current branch
  git switch $(git branch ${2:-"-l"} --sort=-committerdate | head -n ${1:-10} | awk '{gsub(/[\S\n]+/,"\n")}1' | fzf)
}

gihl() {
  # history list (of local branches)
  print_branch_history "Local" "-l" $1
}

gihlr() {
  # history list of remote branches
  print_branch_history "Remote" "-r" $1
}

gibrclean() {
  # delete all branches that have been merged into the current branch
  git branch --merged | grep -v \* | xargs git branch -D
}
gibrdel() {
  # delete all branches matching the given pattern
  branches=$(git branch | grep -v \* | grep -E $1)
  if [ -n "$branches" ]; then
    echo "The following branches will be deleted:"
    echo "$branches"
    read -p "Are you sure you want to delete these branches? (y/n) " -n 1 confirm
    echo
    if [ "$confirm" = "y" ]; then
      git branch -D $(echo "$branches")
    fi
  else
    echo "No branches found matching the given pattern."
  fi
}

gilc() {
  # latest change of file
  if [ "$2" = "--hash" ]; then
    git log --follow --pretty=format:"%h" -- $1 | head -n 1
  else
    git log --follow --pretty=format:"%h %cd %s" --date=short -- $1 | grep -m ${2:-1} .
  fi
}
alias qd="./mvnw compile quarkus:dev"

# yarn project aliases
alias yd="yarn dev"
alias yg="yarn generate"
alias yyd="yarn && yarn dev"
alias ytw="yarn test:watch"

# db-migrate aliases
alias db-check-down="grep -E '^\s*DATABASE_URL=' .env &&  db-migrate down --check"
alias db-check-up="grep -E '^\s*DATABASE_URL=' .env && db-migrate up --check"
alias migrate-down="grep -E '^\s*DATABASE_URL=' .env && db-migrate down --check && confirm && db-migrate down"
alias migrate-up="grep -E '^\s*DATABASE_URL=' .env && db-migrate up --check && confirm && db-migrate up"

# aws / kubernetes aliases
alias kcluster='kubectl config get-contexts | fzf | tr -s " " | cut -d" " -f2 | xargs kubectl config use-context'
alias kns='kubectl get ns | fzf | cut -d" " -f1 | xargs kubectl config set-context --current --namespace'

alias code-obsidian='code /Users/Shared/obsidian/obsidian-files/scripts'

new_file() {
  touch $1
  code $1
}

confirm() {
  read -p "Do you want to proceed? (y/n) " yn

  case $yn in
  y) echo ok, we will proceed ;;
  n)
    echo exiting...
    exit 0
    ;;
  *)
    echo invalid response
    exit 0
    ;;
  esac

  echo doing stuff...
}

code() { VSCODE_CWD="$PWD" open -n -b "com.microsoft.VSCode" --args "$*"; }

[ -f $HOME/.fzf.bash ] && source $HOME/.fzf.bash

git_current_branch() {
  cat "$(git rev-parse --git-dir 2>/dev/null)/HEAD" | gsed -e 's/^.*refs\/heads\///'
}

eka () { . $EKA/scripts.sh ;}

changelog() {
  local PREVIOUS_VERSION=$1
  local VERSION=$2
  local CHANGES=$(git log --pretty="- %s" $PREVIOUS_VERSION...$VERSION --no-merges) 
  printf "# 🎁 Release notes (\`$VERSION\`)\n\n## Changes\n$CHANGES\n\n## Metadata\n\`\`\`\nThis version -------- $VERSION\nPrevious version ---- $PREVIOUS_VERSION\nTotal commits ------- $(echo "$CHANGES" | wc -l)\n\`\`\`\n" > release_notes.md
}


# function chooseTaskId () {
#   taskname=$(jira list --gjq="issues" --query "$1" | jq ".[] | \"\(.key) \(.fields.summary)\"" --raw-output | fzf)
#   if [ $? -ne 0 ]; then
#     return $?
#   fi
#   taskId=$(echo $taskname | awk "{print \$1}")
#   echo $taskId
# }

# #!/bin/bash

# source ~/scripts/lib/choosejirataskid

# query="resolution = unresolved and project = \"FEATURES\" ORDER BY priority asc, created"
# chosenTask=$(chooseTaskId "$query")

# if [ $? -ne 0 ]; then
#   echo "Aborted. Exit code $?"
#   exit $?
# fi

# echo $chosenTask
# #!/bin/bash
# url="https://voady.atlassian.net/browse/$(tjt)"
# open $url
# #!/bin/bash

# source ~/scripts/lib/choosejirataskid

# query="resolution = unresolved and assignee=currentuser() ORDER BY priority asc, created"
# chosenTask=$(chooseTaskId "$query")

# if [ $? -ne 0 ]; then
#   echo "Aborted. Exit code $?"
#   exit $?
# fi

# echo "Enter suffix of branch name, will be appended as <taskid>_<input>"
# read branchName

# git checkout -b "${chosenTask}_${branchName}"
# #!/bin/bash
# source ~/scripts/lib/choosejirataskid

# query="resolution = unresolved and project = \"FEATURES\" ORDER BY priority asc, created"
# chosenTask=$(chooseTaskId "$query")

# if [ $? -ne 0 ]; then
#   echo "Aborted. Exit code $?"
#   exit $?
# fi

# echo "Enter suffix of branch name, will be appended as <taskid>_<input>"
# read branchName

# git cob "${chosenTask}_${branchName}"
export NODE_AUTH_TOKEN=


chrome-debug() {
  /Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222
}
export PATH=$HOME/.local/bin:$PATH
export PATH="/usr/local/sbin:$PATH"
export GCP_DAI="/Users/erikbjorn/personal/gcp"

function delete_last_lines() {
    local num_lines="$1"
    local file="$2"
    sed -i.bak -e :a -e "$((num_lines+1)),\$d;N;2,3ba" -e 'P;D' "$file"
}

function prba() {
  gh pr edit -b "$(git log --reverse --oneline --no-merges master..HEAD --pretty='- %s'
)"
}

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

