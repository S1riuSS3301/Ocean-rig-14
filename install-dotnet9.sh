#!/bin/bash
RUNTIME=dotnet #aspnetcore
CHANNEL="9.0"
while getopts "r:c:sh" opt; do
  case $opt in
    r) RUNTIME=$OPTARG ;;
    c) CHANNEL=$OPTARG ;;
    s) SDK=true ;;
    h) show_help; exit 1 ;;
    *) echo "Invalid option '$opt'"; exit 1 ;;
  esac
done

# Add the backport repo, which contains the aspnetcore-runtime-9.0 package, which will be used later to find and install dependancies
add-apt-repository -y ppa:dotnet/backports
# Update the apt database, including the new repo
apt update
# Install the default dotnet-host (version 8, as of the time of writing) and tools used in subsequent commands
apt install -y apt-rdepends wget grep gawk findutils
# Find all dependancies of aspnercore-runtime-9.0, excepts for debconf (which doesn't directly install) and *dotnet* packages which would cause the removal of dotnet 8 and 7, and install them
apt-rdepends -p $RUNTIME-runtime-$CHANNEL | grep NotInstalled | grep -E -v "(dotnet)|(debconf)" | awk '/Depends:/{print$2}' | xargs apt install
# Get the offical install script and execute it, passing in the directory where dotnet-host is located, ensuring seemless integration and system-wide availability

if [ "$SDK" -ne true ]; then
  RUNTIME="--runtime $RUNTIME"
else
  RUNTIME=
fi
wget -O - https://dot.net/v1/dotnet-install.sh | bash -s - --channel $CHANNEL $RUNTIME --install-dir $(dirname $(realpath $(which dotnet)))
