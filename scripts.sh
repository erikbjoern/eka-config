git_current_branch () {
	cat "$(git rev-parse --git-dir 2>/dev/null)/HEAD" | gsed -e 's/^.*refs\/heads\///'
}

set_highest_accepted_arg () {
  # if argument is higher than highest_accepted_argument, update highest_accepted_argument
  if [[ $1 > $highest_accepted_argument ]]; then
    highest_accepted_argument=$1
  fi
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
    echo "Creating log entry (log-file.txt):"
    echo "$(git diff --stat -- ':!log-file.txt' ':!.obsidian')"
    git diff --stat -- ':!log-file.txt' ':!.obsidian' >> log-file.txt
  else 
    echo "No changes to commit"
  fi
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
  echo "Copying local config into repo at $HOME/eka-config/"

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

  if [[ "$commitmessage" == "" ]]; then
    commitmessage="auto-push $(date)"
  fi

  create_log_entry $commitmessage

  if [[ -n $(git status -s) ]]; then
    git add .
    git commit -m "$commitmessage"
    git push -q --set-upstream origin $(git_current_branch)
  fi
}

pull_eka_config () {
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
  if [[ $# < 3 ]]; then
    set_highest_accepted_arg 2
    create_log_entry $arg2
  fi
}

sync () {
  if [[ "$2" == "up" ]]; then
    set_highest_accepted_arg 2
    sync_config_from_home_into_repo
  elif [[ "$2" == "down" ]]; then
    set_highest_accepted_arg 2
    sync_config_from_repo_into_home
  elif [[ "$2" == "push" ]]; then
    set_highest_accepted_arg 3
    sync_config_from_home_into_repo
    push_eka_config $arg3
  elif [[ "$2" == "pull" ]]; then
    set_highest_accepted_arg 2
    pull_eka_config
    sync_config_from_repo_into_home
  else
    set_highest_accepted_arg 2
    echo "Invalid argument for 'sync'. Use 'up'/'down' to sync local config into or from this repo."
    echo "Or chain with 'push'/'pull' to push/pull this repo to/from github."
  fi
}

push () {
  if [[ "$2" == "sync" ]]; then
    set_highest_accepted_arg 3
    sync_config_from_home_into_repo
    push_eka_config $arg3
  elif [[ $number_of_arguments == 2 ]]; then
    set_highest_accepted_arg 2
    push_eka_config $arg2
  elif [[ $number_of_arguments == 1 ]]; then
    push_eka_config
  fi
}

pull () {
  if [[ "$2" == "sync" ]]; then
    set_highest_accepted_arg 2
    pull_eka_config
    set_local_config
  elif [[ $# == 1 ]]; then
    pull_eka_config
  fi
}

display_word_mark () {
  echo "            _____,                     "
  echo "              |  †                     "
  echo "   _________, |  |     __________,     "
  echo "    /   _,  † |  |  ---, /_____   \    "
  echo "   /   /_!  | |  |,/  /    ___ \   +   "
  echo "  /  ,______/ |   _   \   /         \  "
  echo ",/   |______, !   ,\   \_ †    !\    \,"
  echo "[__________/ [____] [____][___________]"
  echo "ekaekaekaeka ekaeka ekaeka ekaekaekaeka"
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
  echo "|-------------------------------------'"
  echo "|"

  for (( i=0; i<${#labels[@]}; i++ )); do
    # print label with padding to match longest label
    printf "| %-${longest_label_length}s" "${labels[$i]}:"
    echo "${descriptions[$i]}"
    printf "| %-${longest_label_length}s" ""

    if [[ "${options[$i]}" != "" ]]; then
      echo "[${options[$i]}]"
    fi

    echo "|"
  done
  echo "'--------------------------------------"
}

labels=()
descriptions=()
actions=()
options=()

labels+=("log")
descriptions+=("Create a new entry in the log")
actions+=(log)
options+=("'<message>'")

labels+=("sync")
descriptions+=("Sync local config into repo (will extract sensitive data into .git-credentials)")
actions+=(sync)
options+=("'up', 'down', 'push <message>', 'pull'")

labels+=("push")
descriptions+=("Create log entry etc, then push changes to GitHub")
actions+=(push)
options+=("'<message>', 'sync'")

labels+=("pull")
descriptions+=("Pull changes from GitHub")
actions+=(pull)
options+=("'sync'")

arg1="$1"
arg2="$2"
arg3="$3"
arg4="$4"
args="$@"
number_of_arguments="$#"
highest_accepted_argument=0
origin_path=$PWD
repo_path="$HOME/eka-config/"

cd $repo_path

echo ""

if [[ $# == 0 ]]; then
  echo "Are you lost? Flag with '-h' or something, if you want help"
elif [[ $1 == "init" ]]; then
  display_word_mark
  echo ""
  echo "Initialising eka-config"

  set_local_config

  config_backup_directory=$HOME/original-local-config/$(date -I seconds)

  mkdir -p $config_backup_directory
  cp -rf $PWD/previous-local-config $config_backup_directory
  source $HOME/.bash_profile

  echo "eka-config initialised and sourced"
  echo "Your original config has been moved to $config_backup_directory"

  origin_path=$repo_path
else 
  for (( i=0; i<${#labels[@]}; i++ )); do
    #if argument matches label, invoke action at the same index
    if [[ "$1" == "${labels[$i]}" ]]; then
      set_highest_accepted_arg 1
      ${actions[$i]} $arg1 $arg2 $arg3 $arg4
    fi
  done

  if [[ $highest_accepted_argument == 0 ]]; then
    # if no action was invoked, check if help was requested
    help_flags=("-h" "--help" "help")

    if [[ " ${help_flags[@]} " =~ " $1 " ]]; then
      display_help
    else
      display_help verbose
    fi
  elif [[ $highest_accepted_argument < $number_of_arguments ]]; then
    display_help verbose
  fi
fi

echo ""

cd $origin_path
