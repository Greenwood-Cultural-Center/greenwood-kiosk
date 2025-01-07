#!/usr/bin/zsh
echo -e "\e[33mSetting up the dev container...\e[0m"
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
if [ -e .env ]; then
    echo -e "\e[33m.env file found: skipping creation\e[0m"
else
    echo -e "\e[33mSetting up the environment...\e[0m"
    cp .exampleenv .env
fi
echo -e "\e[33mCreating the secret key env vars...\e[0m"
devise_secret=$(rails secret)
secret_key_base=$(rails secret)

export DEVISE_SECRET_KEY=$devise_secret
export SECRET_KEY_BASE=$secret_key_base

echo -e "\e[33mSetting up the database...\e[0m"
if [ -e config/database.yml ]; then
    echo -e "\e[33mdatabase.yml file found: skipping creation\e[0m"
else
    echo -e "\e[33mCreating database.yml file...\e[0m"
    cp config/database.example.yml config/database.yml
fi
echo -e "\e[33mCreating the database...\e[0m"
rails db:create
echo -e "\e[33mLoading schema and seeding the DB...\e[0m"
rails db:schema:load db:seed