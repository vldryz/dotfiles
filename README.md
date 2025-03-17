# dotfiles

```shell
ln -s ~/dotfiles/zsh/.zshrc ~/.config/zsh/.zshrc
ln -s ~/dotfiles/zsh/.zprofile ~/.config/zsh/.zprofile
ln -s ~/dotfiles/zsh/aliases.zsh ~/.config/zsh/aliases.zsh
ln -s ~/dotfiles/zsh/.zshenv ~/.zshenv

# Remove login message
touch ~/.hushlogin

# zsh-completions
chmod go-w /opt/homebrew/share
chmod -R go-w /opt/homebrew/share/zsh
```
