local_vscode_path="$HOME/Library/Application Support/Code/User"
repo_vscode_path=$EKA/data/vscode

git_current_branch() {
  cat "$(git rev-parse --git-dir 2>/dev/null)/HEAD" | gsed -e 's/^.*refs\/heads\///'
}

set_highest_accepted_arg() {
  # if argument is higher than highest_accepted_argument, update highest_accepted_argument
  if [[ $1 > $highest_accepted_argument ]]; then
    highest_accepted_argument=$1
  fi
}

create_log_entry() {
  logmessage="$@ $(date)"

  if [[ -n $(git status -s) ]]; then
    echo "" >>log-file.txt
    echo $logmessage >>log-file.txt
    git add -N .
    echo "Creating log entry (log-file.txt):"
    echo "$(git diff --stat -- ':!log-file.txt' ':!.obsidian')"
    git diff --stat -- ':!log-file.txt' ':!.obsidian' >>log-file.txt
  else
    echo "No changes to commit"
  fi
}

sync_config_from_home_into_repo() {
  if [[ -n $(git status -s) ]]; then
    echo ""
    echo "You have uncommitted changes in your eka repo. Please commit or stash them before syncing."
    return
  fi

  echo "Copying local config into repo at $EKA/"
  echo "Copying config from $local_vscode_path into $repo_vscode_path"

  $helper get_local_config
  $helper store_git_credentials_in_repo
}

sync_config_from_repo_into_home() {
  echo "Copying config from '$EKA/data/ to $HOME/"
  echo "Copying config from $repo_vscode_path to $local_vscode_path"

  $helper set_local_config

  echo "Previous local config stored in $EKA/local/previous-local-config/"

  source $HOME/.bash_profile

  echo "Local config updated and sourced"
}

detect_git_conflict() {
  ahead=$(git rev-list --count --left-only HEAD...origin/$(git_current_branch))
  behind=$(git rev-list --count --right-only HEAD...origin/$(git_current_branch))

  if [[ $ahead > 0 && $behind > 0 ]]; then
    return 1
  fi

  return 0
}

push_to_github() {
  commitmessage=$@
  echo "Triggering push to github in: $PWD"

  if [[ "$commitmessage" == "" ]]; then
    commitmessage="auto-push"
  fi

  create_log_entry $commitmessage

  if [[ -n $(git status -s) ]]; then
    git add .
    git commit -m "$commitmessage"
    git push -q --set-upstream origin $(git_current_branch)
  fi
}

pull_from_github() {
  # if any changes on remote, pull them
  if [[ $(git rev-parse HEAD) != $(git rev-parse @{u}) ]]; then
    echo "Pulling from github in: $PWD"
    git pull
  else
    echo "No changes on remote"
  fi
}

log() {
  if [[ "$2" == "show" ]]; then
    set_highest_accepted_arg 2

    if [[ ! -f ./log-file.txt ]]; then
      echo "No log-file.txt found"
      return
    fi

    if [[ "$3" == "" ]]; then
      awk '/^$/ { buf = "" } { buf = buf "\n" $0 } END { print buf }' log-file.txt
    else
      set_highest_accepted_arg 3

      if [[ "$3" == "full" ]]; then
        cat ./log-file.txt
      else
        tail "-$3" log-file.txt
      fi
    fi
  elif [[ $# < 3 ]]; then
    set_highest_accepted_arg 2
    create_log_entry "$2"
  fi
}

sync() {
  if [[ "$2" == "up" ]]; then
    set_highest_accepted_arg 2
    sync_config_from_home_into_repo
  elif [[ "$2" == "down" ]]; then
    set_highest_accepted_arg 2
    sync_config_from_repo_into_home
  elif [[ "$2" == "push" ]]; then
    set_highest_accepted_arg 3
    sync_config_from_home_into_repo
    push_to_github "$3"
  elif [[ "$2" == "pull" ]]; then
    set_highest_accepted_arg 2
    pull_from_github
    sync_config_from_repo_into_home
  else
    set_highest_accepted_arg 2
    echo "Invalid argument for 'sync'. Use 'up'/'down' to sync local config into or from this repo."
    echo "Or chain with 'push'/'pull' to push/pull this repo to/from github."
  fi
}

push() {
  if [[ "$2" == "sync" ]]; then
    set_highest_accepted_arg 3
    sync_config_from_home_into_repo
    push_to_github "$3"
  elif [[ "$2" != "" && -d $EKA/../$2 ]]; then
    set_highest_accepted_arg 3
    push_to_github "$3"
  elif [[ $number_of_arguments == 2 ]]; then
    set_highest_accepted_arg 2
    push_to_github "$2"
  elif [[ $number_of_arguments == 1 ]]; then
    push_to_github
  fi
}

pull() {
  if [[ "$2" == "sync" ]]; then
    set_highest_accepted_arg 2
    pull_from_github
    $helper set_local_config
  elif [[ "$2" != "" && -d $EKA/../$2 ]]; then
    set_highest_accepted_arg 3
    push_to_github "$3"
  elif [[ $# == 1 ]]; then
    pull_from_github
  fi
}

display_help() {
  if [[ "$1" == "verbose" ]]; then
    echo "I didn't fully understand '$args' ...Did you mean any of these?"
    #if argument is not no-wordmark
  elif [[ "$1" != "no-wordmark" ]]; then
    $helper display_word_mark
  fi

  longest_label_length=0
  get_length_of_longest_label() {
    for ((i = 0; i < ${#labels[@]}; i++)); do
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

  for ((i = 0; i < ${#labels[@]}; i++)); do
    # print label with padding to match longest label
    printf "| %-${longest_label_length}s" "${labels[$i]}:"
    echo "${descriptions[$i]}"

    if [[ "${options[$i]}" != "" ]]; then
      printf "| %-${longest_label_length}s" ""
      echo "[${options[$i]}]"
    fi

    echo "|"
  done
  echo "'--------------------------------------"
}

go() {
  echo ""

  if [[ "$2" == "show" ]]; then
    set_highest_accepted_arg 2
    ls -d $EKA/../*/
  elif [[ "$2" != "" && -d $EKA/../$2 ]]; then
    set_highest_accepted_arg 2
    destination_path="$EKA/../$2"
    clear
    echo "You are now in: $2"
  elif [[ "$2" == "" ]]; then
    destination_path="$EKA"
    clear
    $helper display_word_mark
    echo ""
    echo "You are now in the eka repo"
  else
    set_highest_accepted_arg 2
    echo "$2 is not a project. Use 'show' to list all available projects"
  fi
}

labels=()
descriptions=()
actions=()
options=()

labels+=("log")
descriptions+=("Create a new entry or show the log")
actions+=(log)
options+=("'<message>' 'show' ['last' ['<number of lines> (''=last entry)']")

labels+=("sync")
descriptions+=("Sync local config into repo (will extract sensitive data into .git-credentials)")
actions+=(sync)
options+=("'up' 'down' 'push <message>' 'pull'")

labels+=("push")
descriptions+=("Create log entry etc, then push changes to GitHub")
actions+=(push)
options+=("'<message>' 'sync'")

labels+=("pull")
descriptions+=("Pull changes from GitHub")
actions+=(pull)
options+=("'sync'")

labels+=("go")
descriptions+=("Go to the eka repo directory, or any of its siblings")
actions+=(go)
options+=("'show' '<name of sibling directory>'")

number_of_arguments="$#"
highest_accepted_argument=0
destination_path="$PWD"
args="$@"

if [[ $EKA == "" ]]; then
  helper=$PWD/helpers.sh
  chmod ug+x $helper
  . $helper

  display_help no-wordmark

  echo ""
  echo "To make 'eka' available, open a new terminal or run 'source $HOME/.bash_profile'"
  echo ""
else
  helper=$EKA/helpers.sh

  if [[ $# == 0 ]]; then
    echo "Are you lost? Flag with '-h' or something, if you want help"
  elif [[ "$1" == "init" ]]; then
    $helper display_word_mark
    echo ""

    echo ",-------------------------------------,"
    echo "|      eka is already initialised     |"
    echo "'-------------------------------------'"
  else
    git_actions=("push" "pull")

    if [[ " ${git_actions[@]} " =~ " $1 " ]]; then
      if [[ "$2" != "" && -d $EKA/../$2 ]]; then
        cd $EKA/../$2
      fi

      detect_git_conflict
    fi

    has_conflict=$?
    if [[ $has_conflict == 1 ]]; then
      echo "You seem to have a conflict with remote"
    else
      for ((i = 0; i < ${#labels[@]}; i++)); do
        #if argument matches label, invoke action at the same index
        if [[ "$1" == "${labels[$i]}" ]]; then
          set_highest_accepted_arg 1

          ${actions[$i]} "$@"
        fi
      done

      if [[ $highest_accepted_argument == 0 ]]; then
        help_flags=("-h" "--help" "help")

        if [[ "$1" == "go" && "$PWD" == "$EKA" && "$2" == "" ]]; then
          echo ""
          echo "You are already in the eka repo"
        elif [[ " ${help_flags[@]} " =~ " $1 " ]]; then
          display_help
        else
          display_help verbose
        fi
      elif [[ $highest_accepted_argument < $number_of_arguments ]]; then
        display_help verbose
      fi
    fi
  fi

  cd "$destination_path"

  echo ""
fi
