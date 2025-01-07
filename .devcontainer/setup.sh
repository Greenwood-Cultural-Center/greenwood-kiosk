#!/usr/bin/zsh
sudo apt-get update && export DEBIAN_FRONTEND=noninteractive && sudo apt-get -y install --no-install-recommends libvips libvips-dev libvips-tools libpq-dev
sudo mkdir /root/.config
cd /root/.config
current_dir=$(pwd)
if [ "$current_dir" = "/root/.config" ]; then 
    git init .
    git remote add origin https://github.com/Greenwood-Cultural-Center/dotfiles.git
    git pull origin main
    cp /home/vscode/.config .
else 
    echo "Not in /root/.config: skipping dotfiles setup for root: Please manually clone the dotfiles repo, https://github.com/Greenwood-Cultural-Center/dotfiles.git, to /root/.config"
fi
cd /workspaces/greenwood-kiosk
brew install fzf
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-/root/.oh-my-zsh/custom}/themes/powerlevel10k
bundle install
yarn install