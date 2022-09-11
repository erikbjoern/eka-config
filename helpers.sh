if [[ -f ./local/eka-path.txt ]]; then
  export EKA=$(cat ./local/eka-path.txt)
fi

local_vscode_path="$HOME/Library/Application Support/Code/User"
repo_vscode_path=$EKA/data/vscode

display_word_mark () {
  echo "            _____,              v.1.0.0"
  echo "              |  †                     "
  echo "   _________, |  |     __________,     "
  echo "    /   _,  † |  |  ---, /_____   \    "
  echo "   /   /_!  | |  |,/  /    ___ \   +   "
  echo "  /  ,______/ |   _   \   /         \  "
  echo ",/   |______, !   ,\   \_ †    !\    \,"
  echo "[__________/ [____] [____][___________]"
  echo "ekaekaekaeka ekaeka ekaeka ekaekaekaeka"
}

get_local_config () {
  # pull local config into repo
  number_of_stashes=$(git stash list | wc -l)

  cp -f $HOME/.gitconfig $EKA/data/
  cp -f $HOME/.bash_profile $EKA/data/

  # copy vscode config
  if [ -d "$local_vscode_path" ]; then
    mkdir -p $repo_vscode_path
    cp -rf "$local_vscode_path/snippets" $repo_vscode_path/
    cp -f "$local_vscode_path/settings.json" $repo_vscode_path/
    cp -f "$local_vscode_path/keybindings.json" $repo_vscode_path/
  fi

  git stash -qm "This is the stash that contains the INCOMING files"

  git stash pop -q
  new_number_of_stashes=$(git stash list | wc -l)

  if [[ $number_of_stashes != $new_number_of_stashes ]]; then
    echo "Stash conflict. Please resolve the conflict and run 'eka sync' again."
    echo ""

    git stash show
  else 
    echo "No conflicts detected"
  fi
}

init () {
  display_word_mark

  if [[ -n $EKA ]]; then
    echo "eka seems to be already initialized"
    return
  fi

  echo ""
  echo "Initialising eka-config"

  repo_path=$PWD

  mkdir -p $repo_path/local

  echo $repo_path > $repo_path/local/eka-path.txt

  export EKA=$repo_path

  if [[ $(grep -c "eka" $EKA/data/.bash_profile) -gt 0 ]]; then
    sed -i '' '/export EKA/d' $EKA/data/.bash_profile
    sed -i '' '/eka/d' $EKA/data/.bash_profile
  fi
    echo "Adding command 'eka' to .bash_profile"

    echo "export EKA=\"$EKA\"" >> $EKA/data/.bash_profile
    echo "eka () { . \$EKA/scripts.sh ;}" >> $EKA/data/.bash_profile
    echo "" >> $EKA/data/.bash_profile

  # backup current config
  config_backup_directory=$HOME/original-local-config/$(date -I seconds)
  mkdir -p $config_backup_directory
  cp -f $HOME/.gitconfig $config_backup_directory
  cp -f $HOME/.bash_profile $config_backup_directory

  store_git_credentials_in_repo $HOME/

  set_local_config

  source $HOME/.bash_profile

  echo "eka-config initialised"
  echo "Your original config has been moved to $config_backup_directory"
}

set_local_config () {
  # backup current config
  mkdir -p local/previous-local-config
  cp -f $HOME/.gitconfig $EKA/local/previous-local-config/
  cp -f $HOME/.bash_profile $EKA/local/previous-local-config/
  
  # copy new config from repo into home directory
  cp -f $EKA/data/.bash_profile $HOME/
  cp -f $EKA/data/.gitconfig $HOME/

  if [[ -f $EKA/local/.git-credentials ]]; then
    # append credentials to gitconfig
    cat $EKA/local/.git-credentials >> $HOME/.gitconfig
  fi

  if [[ -d "$local_vscode_path" && -d "$repo_vscode_path" ]]; then
    # backup current vscode config
    mkdir -p $EKA/previous-local-config/vscode
    cp -rf "$local_vscode_path/snippets" "$EKA/previous-local-config/vscode/"
    cp -f "$local_vscode_path/settings.json" "$EKA/previous-local-config/vscode/"
    cp -f "$local_vscode_path/keybindings.json" "$EKA/previous-local-config/vscode/"

    # copy vscode config from repo into home directory
    cp -rf "$repo_vscode_path/snippets" "$local_vscode_path/"
    cp -f "$repo_vscode_path/settings.json" "$local_vscode_path/"
    cp -f "$repo_vscode_path/keybindings.json" "$local_vscode_path/"
  fi
}

store_git_credentials_in_repo () {
  path_to_gitconfig=$1
  
  if [[ "$path_to_gitconfig" == "" ]]; then
    path_to_gitconfig=$EKA/data/.gitconfig
  fi

  # check if path_to_gitconfig does not exist
  if [[ ! -f $path_to_gitconfig ]]; then
    return 1
  fi

  sed -n '/\[user\]/,/\[/ {
    /\[?[^u]?/b
    p
  }' $path_to_gitconfig > temp-file-1.txt

  if [ -s temp-file-1.txt ]; then
    echo "Storing git credentials in $EKA/local/.git-credentials"
    cat temp-file-1.txt > $EKA/local/.git-credentials
  fi
  rm -f temp-file-1.txt

  if [[ $path_to_gitconfig=$EKA/data/.gitconfig ]]; then
    echo "Deleting git credentials from $path_to_gitconfig"
    sed '/\[user\]/,/\[/{/\[[^u]/!d;}' $path_to_gitconfig > temp-file-2.txt
    cat temp-file-2.txt > $path_to_gitconfig
    rm temp-file-2.txt
  fi
}

helpers=(
  'display_word_mark',
  'get_local_config',
  'init',
  'set_local_config',
  'store_git_credentials_in_repo',
)

for helper in "${helpers[@]}"; do
  if [[ "$1," == "$helper" ]]; then
    $1
  fi
done
