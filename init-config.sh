echo "Initialising eka-config"
echo "..."

chmod ug+x $PWD/eka-helpers/set-local-config.sh
$PWD/eka-helpers/set-local-config.sh

cp -rf $PWD/previous-local-config $HOME/original-local-config

source $HOME/.bash_profile

echo "eka-config initialised and sourced"
echo "..."

echo "Your original config has been moved to $HOME/original-local-config"
echo "..."
