git_current_branch () {
	cat "$(git rev-parse --git-dir 2>/dev/null)/HEAD" | gsed -e 's/^.*refs\/heads\///'
}

create_log_entry () {
  logmessage=$@

  if [[ "$logmessage" == "" ]]; then
    logmessage="$(date)"
  fi

  if [[ -n $(git status -s) ]]; then
    echo "" >> log-file.txt
    echo $logmessage >> log-file.txt
    git add -N .
    echo "Creating git log (log-file.txt):"
    echo $(git diff --stat -- ':!log-file.txt' ':!.obsidian')
    git diff --stat -- ':!log-file.txt' ':!.obsidian' >> log-file.txt
  else 
    echo "No changes to commit"
  fi
}

log_and_push () {
  commitmessage=$@

  if [[ "$commitmessage" == "" ]]; then
    commitmessage="auto-push $(date)"
  fi

  create_log_entry $commitmessage

  git add .
  echo "Committing: $commitmessage"
  git commit -m "$commitmessage"
  git push -q --set-upstream origin $(git_current_branch)
}

get_local_config () {
  # overwrite config in repo with config in home directory
  cp -f $HOME/.gitconfig $HOME/eka-config/data/
  cp -f $HOME/.bash_profile $HOME/eka-config/data/
}

set_local_config () {
  # backup current config
  mkdir -p previous-local-config
  cp -f $HOME/.gitconfig $HOME/eka-config/previous-local-config/
  cp -f $HOME/.bash_profile $HOME/eka-config/previous-local-config/

  # copy new config into home directory
  cp -f $HOME/eka-config/data/.gitconfig $HOME/

  # append credentials to gitconfig
  cat $PWD/data/.git-credentials >> $HOME/.gitconfig
}

sync_config_from_home_into_repo () {
  echo "Copying local config into repo at '$HOME/eka-config/"

  get_local_config
  store_git_credentials
}

sync_config_from_repo_into_home () {
  echo "Copying config from '$HOME/eka-config/data/ to $HOME/"

  set_local_config

  echo "Previous local config stored in $HOME/eka-config/previous-local-config/"

  source $HOME/.bash_profile

  echo "Local config updated and sourced"set_local_config
}

push_eka_config () {
  commitmessage=$@
  echo "Triggering eka-config push to github"
  log_and_push $commitmessage
}

pull_eka_config () {
  cd $HOME/eka-config/
  # if any changes on remote, pull them
  if [[ $(git rev-parse HEAD) != $(git rev-parse @{u}) ]]; then
    echo "Pulling eka-config from github"
    git pull
  else
    echo "No changes on remote"
  fi
}

store_git_credentials () {
  sed -n '/\[user\]/,/\[/ {
    /\[?[^u]?/b
    p
  }' $PWD/data/.gitconfig > temp-file-1.txt

  if [ -s temp-file-1.txt ]; then
    echo "Storing git credentials in $PWD/data/.git-credentials"
    cat temp-file-1.txt > $PWD/data/.git-credentials
  else
    echo "No git credentials found in $PWD/data/.gitconfig"
  fi
  rm temp-file-1.txt

  echo "Deleting git credentials from $PWD/data/.gitconfig"
  sed '/\[user\]/,/\[/{/\[[^u]/!d;}' $PWD/data/.gitconfig > temp-file-2.txt
  cat temp-file-2.txt > $PWD/data/.gitconfig
  rm temp-file-2.txt
}

log () {
  if [ $# <= 2 ]; then
    highest_accepted_argument=2
    create_log_entry $arg2
  fi
}

sync () {
  if [[ "$2" == "up" ]]; then
    highest_accepted_argument=2
    sync_config_from_home_into_repo
  elif [[ "$2" == "down" ]]; then
    highest_accepted_argument=2
    sync_config_from_repo_into_home
  elif [[ "$2" == "push" ]]; then
    highest_accepted_argument=3
    sync_config_from_home_into_repo
    push_eka_config $arg3
  elif [[ "$2" == "pull" ]]; then
    highest_accepted_argument=2
    pull_eka_config
    sync_config_from_repo_into_home
  else
    highest_accepted_argument=2
    echo "Invalid argument for 'sync'. Use 'up'/'down' to sync local config into or from this repo."
    echo "Or chain with 'push'/'pull' to push/pull this repo to/from github."
  fi
}

push () {
  if [[ "$2" == "sync" ]]; then
    sync_config_from_home_into_repo
    push_eka_config $arg3
    highest_accepted_argument=3
  elif [[ $# == 1 ]]; then
    push_eka_config $arg2
  fi
}

pull () {
  if [[ "$2" == "sync" ]]; then
    pull_eka_config
    set_local_config
    highest_accepted_argument=2
  elif [[ $# == 1 ]]; then
    pull_eka_config
  fi
}

labels=()
descriptions=()
actions=()
options=()

labels+=("log")
descriptions+=("Create a new entry in the log")
actions+=(log)
options+=("'<commit message>'")

labels+=("sync")
descriptions+=("Sync local config into repo (will extract sensitive data into .git-credentials)")
actions+=(sync)
options+=("'up', 'down', 'push <commit message>', 'pull'")

labels+=("push")
descriptions+=("Create log entry etc, then push changes to GitHub")
actions+=(push)
options+=("'sync'")

labels+=("pull")
descriptions+=("Pull changes from GitHub")
actions+=(pull)
options+=("'sync'")

display_word_mark () {
  echo "           ______,                "
  echo "              |  |                "
  echo " ___________, |  |    ___________, "
  echo "    /   _,  | |  | ----, |_____   \ "
  echo " __/   /_!  | |  |,/  /  _____ \   \ "
  echo "  /  ,______| |   _   \   |         \ "
  echo ",/   |______, !   ,\   \_ |    !\    \, "
  echo "[__________/ [____] [____]|___________] "
  echo "ekaekaekaeka ekaeka ekaeka ekaekaekaeka "
}

display_help () {
  if [[ "$1" == "verbose" ]]; then
    echo "I didn't understand '$args' ...Did you mean any of these?"
  else
    display_word_mark
  fi

  longest_label_length=0
  get_length_of_longest_label () {
    for (( i=0; i<${#labels[@]}; i++ )); do
      if [ ${#labels[$i]} -gt $longest_label_length ]; then
        longest_label_length=${#labels[$i]}
      fi
    done

    longest_label_length=$((longest_label_length + 4))
  }

  get_length_of_longest_label

  echo ""
  echo ",-------------------------------------,"
  echo "|          Available actions          |"
  echo "'-------------------------------------'"

  for (( i=0; i<${#labels[@]}; i++ )); do
    # print label with padding to match longest label
    printf "%-${longest_label_length}s" "${labels[$i]}:"
    echo "${descriptions[$i]}"
    printf "%-${longest_label_length}s" ""

    if [[ "${options[$i]}" != "" ]]; then
      echo "[${options[$i]}]"
    fi

    echo ""
  done
}

arg1="$1"
arg2="$2"
arg3="$3"
arg4="$4"
args="$@"
number_of_arguments="$#"
highest_accepted_argument=0

echo ""

if [[ $# == 0 ]]; then
  echo "Are you lost? Flag with '-h' or something, if you want help"
elif [[ $1 == "init" ]]; then
  display_word_mark
  echo ""
  echo "Initialising eka-config"

  set_local_config
  cp -rf $PWD/previous-local-config $HOME/original-local-config
  source $HOME/.bash_profile

  echo "eka-config initialised and sourced"
  echo "Your original config has been moved to $HOME/original-local-config"
else 
  for (( i=0; i<${#labels[@]}; i++ )); do
    #if argument matches label, invoke action at the same index
    if [[ "$1" == "${labels[$i]}" ]]; then
      highest_accepted_argument=1
      ${actions[$i]} $arg1 $arg2 $arg3 $arg4
    fi
  done

  echo $highest_accepted_argument
  echo $#

  if [[ $highest_accepted_argument == 0 ]]; then
    # if no action was invoked, check if help was requested
    help_flags=("-h" "--help" "help")

    if [[ " ${help_flags[@]} " =~ " $1 " ]]; then
      display_help
    else
      display_help verbose
    fi
  elif [[ $highest_accepted_argument < $# ]]; then
    display_help verbose
  fi
fi

echo ""