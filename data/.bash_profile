if [ -f "$(brew --prefix)/opt/bash-git-prompt/share/gitprompt.sh" ]; then
  __GIT_PROMPT_DIR=$(brew --prefix)/opt/bash-git-prompt/share
  GIT_PROMPT_ONLY_IN_REPO=1
  source "$(brew --prefix)/opt/bash-git-prompt/share/gitprompt.sh"
fi

[[ -r "/usr/local/etc/profile.d/bash_completion.sh" ]] && . "/usr/local/etc/profile.d/bash_completion.sh"

if [ -f $HOME/.git-completion.bash ]; then
  . $HOME/.git-completion.bash
fi

if [ -r "/Users/erikbjorn/.fzf-git.sh" ]; then
	echo "yes";
  . "/Users/erikbjorn/.fzf-git.sh" 
fi
export FZF_CTRL_T_COMMAND="find . \( -path './.git' -o -path './node_modules' -o -path './target' -o -path './dist' \) -prune -o -type f -print"

export PATH="/opt/homebrew/opt/node@16/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

[ -s "/usr/local/opt/nvm/etc/bash_completion.d/nvm" ] && . "/usr/local/opt/nvm/etc/bash_completion.d/nvm" # This loads nvm bash_completion

# aichat aliases
alias ai="aichat -s aisession"

alias edit-bash="vim $HOME/.bash_profile"
alias edit-bash-code="code $HOME/.bash_profile"
alias source-bash="source $HOME/.bash_profile"
alias edit-git="vim $HOME/.gitconfig"
alias edit-git-code="code $HOME/.gitconfig"

# git aliases
alias diff="git diff > git.diff && code -r git.diff --wait && rm git.diff"
alias stash-u="git commit -m 'WIP' && git stash -u -m 'stash-unstaged' && git undo"
alias stash-s="stash-u && git stash -m 'stash-staged' && git stash pop stash@{1}"
alias gpsup='git push --set-upstream origin $(git_current_branch)'
alias save='git add . && git sv'

# github aliases
alias ghprc="gh pr create --fill --reviewer voady/voady"
alias ghprw="gh pr create --fill -w"
alias ghprd="gh pr create --fill --draft"
alias ghprv="gh pr view -w"
alias gipr="gh pr checkout"
_gh_branch_completion() {
    local branches
    branches=$(git for-each-ref --format '%(refname:short)' refs/heads/)
    COMPREPLY=( $(compgen -W "$branches" -- "${COMP_WORDS[COMP_CWORD]}") )
}
complete -F _gh_branch_completion gh
complete -F _gh_branch_completion ghprc
complete -F _gh_branch_completion ghprw
complete -F _gh_branch_completion ghprd
complete -F _gh_branch_completion ghprv

pr() {
  # Find the name of the default branch (main or master)
  local default_branch=$(git symbolic-ref refs/remotes/origin/HEAD --short | sed 's@origin/@@')

  local aheadCount=$(git log --oneline origin/$default_branch..HEAD | wc -l | tr -d ' ')
  local featCount=$(git log --oneline --no-merges origin/$default_branch..HEAD --grep="^feat" | wc -l | tr -d ' ')
  local fixCount=$(git log --oneline --no-merges origin/$default_branch..HEAD --grep="^fix" | wc -l | tr -d ' ')

  if [ "$aheadCount" -eq 1 ]; then
    # if there is only one commit ahead, create a PR with the default reviewer
    ghprc $@
  elif [ "$featCount" -eq 1 ]; then
    # if there is only one commit starting with "feat" create a PR with that commit as title
    local commit=$(git log --oneline --no-merges origin/$default_branch..HEAD --grep="^feat" | head -n 1)
    local commitMessage=$(echo $commit | cut -d' ' -f2-)
    gh pr create --fill --title "$commitMessage" --reviewer voady/voady $@
  elif [ "$fixCount" -eq 1 ]; then
    # if there is only one commit starting with "fix" create a PR with that commit as title
    local commit=$(git log --oneline --no-merges origin/$default_branch..HEAD --grep="^fix" | head -n 1)
    local commitMessage=$(echo $commit | cut -d' ' -f2-)
    gh pr create --fill --title "$commitMessage" --reviewer voady/voady $@
  else
    ghprw $@
  fi
}
complete -F _gh_branch_completion pr

# telepresence aliases
alias tpq="telepresence quit -s"
alias tpc="telepresence connect"

# docker aliases
alias docker-login-aws-north="aws ecr get-login-password --region eu-north-1 | docker login --username AWS --password-stdin 311100645816.dkr.ecr.eu-north-1.amazonaws.com"
alias docker-login-aws-west="aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin 311100645816.dkr.ecr.eu-west-1.amazonaws.com"

gib() {
  # get history of branches commited on, sort by latest commit date, find the latest one that is not the current branch or main/master
  local branch=$(git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short)' | grep -vE "main|master|$(git rev-parse --abbrev-ref HEAD)" | head -n 1)

  # if no branch found, return
  if [ -z "$branch" ]; then
    return
  fi

  # if last commit on found branch was > 30 days ago, switch to main/master instead
  local last_commit_date=$(git log -1 --format=%cd --date=short $branch)
  local days_since_last_commit=$(echo $((($(date +%s) - $(date -j -f "%Y-%m-%d" $last_commit_date +%s)) / 86400)))
  if [ $days_since_last_commit -gt 30 ]; then
    git m
  fi

  git switch $branch
}

gih() {
  # get history of branches commited on, sort by latest commit date, find the one n steps back
  local branch=$(git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short)' | grep -vE "main|master|$(git rev-parse --abbrev-ref HEAD)" | head -n ${1:-1} | tail -n 1)

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
  echo "$branches"
}

gif() {
  # fuzzy find branches, sort by latest commit date, find the latest one that is not the current branch
  git switch $(git branch ${2:-"-l"} --sort=-committerdate | head -n ${1:-10} | fzf)
}

gihl() {
  # history list (of local branches)
  print_branch_history "Local" "-l" $1
}

gihlr() {
  # history list of remote branches
  print_branch_history "Remote" "-r" $1
}

gibrdel() {
  # delete all branches matching the given pattern
  local pattern=""
  for arg in "$@"; do
    pattern="$pattern|$arg"
  done
  pattern="($(echo "$pattern" | cut -c 2-))"

  branches=$(git branch | grep -v \* | grep -E $pattern)
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
complete -F _gh_branch_completion gibrdel


gibrddd() {
  # capture current branch name
  local branch_to_delete=$(git_current_branch)
  # switch to main and delete the captured branch
  git m && git branch -D $branch_to_delete
  gib
}

gilc() {
  # latest change of file
  if [ "$2" = "--hash" ]; then
    git log --follow --pretty=format:"%h" -- $1 | head -n 1
  else
    git log --follow --pretty=format:"%h %cd %s" --date=short -- $1 | grep -m ${2:-1} .
  fi
}

# java project aliases
alias qd="quarkus dev"
alias qdc="./mvnw clean compile quarkus:dev"

# yarn project aliases
alias yd="yarn dev"
alias yg="yarn generate"
alias yyd="yarn && yarn dev"
alias ytw="yarn test:watch"

# db-migrate aliases
alias db-check-down="grep -E '^\s*DATABASE_URL=' .env &&  db-migrate down --check"
alias db-check-up="grep -E '^\s*DATABASE_URL=' .env && db-migrate up --check"
alias migrate-down="grep -E '^\s*DATABASE_URL=' .env && db-migrate down --check && confirm && db-migrate down"
alias migrate-up="grep -E '^\s*DATABASE_URL=' .env && db-migrate up --check && confirm && db-migrate up -c 1"

# aws / kubernetes aliases
alias kcluster='kubectl config get-contexts | fzf | tr -s " " | cut -d" " -f2 | xargs kubectl config use-context'
alias kns='kubectl get ns | fzf | cut -d" " -f1 | xargs kubectl config set-context --current --namespace'

alias code-obsidian='code /Users/Shared/obsidian/obsidian-files/scripts'

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

export CODE_BASE=/Users/erikbjorn/kodbas

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

eval "$(gh completion -s bash)"
function prba() {
  gh pr edit -b "$(git log --reverse --oneline --no-merges origin/master..HEAD --pretty='- %s')"
}

vdy() {
  cd $CODE_BASE;

  # store list of directories
  local dirs=$(find . -maxdepth 1 -type d -not -path '*/\.*' | sed 's|^\./||')

  # append subdirectories of ./voady-project
  dirs="$dirs
$(find ./voady-project/packages -maxdepth 2 -type d -not -path '*/\.*' -not -path '*/kubernetes/*' | sed 's|^\./||')
$(find ./voady-project/packages/backend/payments -maxdepth 1 -type d -not -path '*/\.*' | sed 's|^\./||')"

  # select dir using fzf
  local dir=$(echo "$dirs" | fzf --query="'$1" --select-1 --scheme=path)

  # if a directory was found, change to it
  if [ -n "$dir" ]; then
    cd "$dir"
    git status
  fi
}

_gt_yargs_completions()
{
    local cur_word args type_list

    cur_word="${COMP_WORDS[COMP_CWORD]}"
    args=("${COMP_WORDS[@]}")

    # ask yargs to generate completions.
    type_list=$(gt --get-yargs-completions "${args[@]}")

    COMPREPLY=( $(compgen -W "${type_list}" -- ${cur_word}) )

    # if no match was found, fall back to filename completion
    if [ ${#COMPREPLY[@]} -eq 0 ]; then
      COMPREPLY=()
    fi

    return 0
}
complete -o bashdefault -o default -F _gt_yargs_completions gt

eval "$(/usr/local/bin/brew shellenv)"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

