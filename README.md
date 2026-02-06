<a href="https://github.com/devxb/gitanimals">
  <img src="https://render.gitanimals.org/lines/koke2y?pet-id=1" width="1000" height="120"/>
</a>

# dotfiles

Managed by [chezmoi](https://www.chezmoi.io/).

## Setup

```bash
bash install.sh
```

## Daily Usage

```bash
# Edit dotfiles
chezmoi edit ~/.zshrc
chezmoi diff
chezmoi apply

# Git operations
chezmoi cd
git add -A && git commit -m "update zshrc"
git push
```
