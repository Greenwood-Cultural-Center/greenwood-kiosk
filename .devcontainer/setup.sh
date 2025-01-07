#!/usr/bin/zsh
echo -e "\e[33mSetting up the dev container...\e[0m"
echo -e "\e[33mInstalling dependencies...\e[0m"
sudo apt-get update && export DEBIAN_FRONTEND=noninteractive && sudo apt-get -y install --no-install-recommends libvips libvips-dev libvips-tools libpq-dev python3-pygments
echo -e "\e[33mConfiguring dotfiles...\e[0m"
sudo mkdir /root/.config
cd /root/.config
git config --global init.defaultBranch main
current_dir=$(pwd)
if [ "$current_dir" = "/root/.config" ]; then 
    git init .
    git remote add origin https://github.com/Greenwood-Cultural-Center/dotfiles.git
    git pull origin main
    mv /root/.config/.zshrc /root/.zshrc
    mv /root/.config/.p10k.zsh /root/.p10k.zsh
else 
    echo -e "\e[31mNot in /root/.config: skipping dotfiles setup for root: Please manually clone the dotfiles repo, https://github.com/Greenwood-Cultural-Center/dotfiles.git, to /root/.config"
fi
echo -e "\e[33mChanging to the project directory...\e[0m"
cd /workspaces/greenwood-kiosk
echo -e "\e[33mInstalling fzf via Homebrew...\e[0m"
brew install fzf
echo -e "\e[33mInstalling powerlevel10k...\e[0m"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /root/.oh-my-zsh/custom/themes/powerlevel10k
echo -e "\e[33mInstalling Gems...\e[0m"
bundle install
echo -e "\e[33mInstalling NPM packages...\e[0m"
yarn install