mkdir -p previous-local-config
cp -f $HOME/.gitconfig $HOME/eka-config/previous-local-config/
cp -f $HOME/.bash_profile $HOME/eka-config/previous-local-config/
cp -rf $HOME/eka-helpers $HOME/eka-config/previous-local-config/

cp -f $HOME/eka-config/.gitconfig $HOME/
cp -f $HOME/eka-config/.bash_profile $HOME/
cp -rf $HOME/eka-config/eka-helpers $HOME/
