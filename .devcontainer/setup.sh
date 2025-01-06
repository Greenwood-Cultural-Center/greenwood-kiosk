#!/usr/bin/zsh
sudo apt-get update && export DEBIAN_FRONTEND=noninteractive && sudo apt-get -y install --no-install-recommends libvips libvips-dev libvips-tools libpq-dev
sudo mkdir /home/root/.config
cd /home/root/.config
git init .
git remote add origin https://github.com/Greenwood-Cultural-Center/dotfiles.git
git pull origin main
cp /home/vscode/.config .
cd /workspaces/greenwood-kiosk
brew install fzf
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
bundle install
yarn install