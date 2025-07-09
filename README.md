# dotfiles

```shell
# zsh
ln -s ~/dotfiles/zsh/.zshrc ~/.config/zsh/.zshrc
ln -s ~/dotfiles/zsh/.zprofile ~/.config/zsh/.zprofile
ln -s ~/dotfiles/zsh/aliases.zsh ~/.config/zsh/aliases.zsh
ln -s ~/dotfiles/zsh/.zshenv ~/.zshenv

# zed
ln -s ~/dotfiles/zed/keymap.json ~/.config/zed/keymap.json
ln -s ~/dotfiles/zed/settings.json ~/.config/zed/settings.json

# ghostty
ln -s ~/dotfiles/ghostty/config ~/.config/ghostty/config

# karabiner
ln -s ~/dotfiles/karabiner/karabiner.json ~/.config/karabiner/karabiner.json

# starship
ln -s ~/dotfiles/starship/starship.toml ~/.config/starship/starship.toml

# pixi
ln -s ~/dotfiles/pixi/config.toml ~/.config/pixi/config.toml

# Remove login message
touch ~/.hushlogin

# zsh-completions
chmod go-w /opt/homebrew/share
chmod -R go-w /opt/homebrew/share/zsh
```
