.PHONY: help dev fmt format check pre-commit pre-commit-all hooks

help:
	@printf '%s\n' 'Available targets:'
	@printf '  %-16s %s\n' 'dev' 'Enter the dotfiles dev shell'
	@printf '  %-16s %s\n' 'fmt' 'Format the repository with treefmt-nix'
	@printf '  %-16s %s\n' 'format' 'Alias for fmt'
	@printf '  %-16s %s\n' 'check' 'Run all flake checks'
	@printf '  %-16s %s\n' 'pre-commit' 'Run hooks for staged files'
	@printf '  %-16s %s\n' 'pre-commit-all' 'Run hooks for all files'
	@printf '  %-16s %s\n' 'hooks' 'Install generated pre-commit hooks'

dev:
	nix develop .#dotfiles

fmt:
	nix fmt

format: fmt

check:
	nix flake check

pre-commit:
	nix develop .#dotfiles -c pre-commit run

pre-commit-all:
	nix develop .#dotfiles -c pre-commit run --all-files

hooks:
	nix develop .#dotfiles -c pre-commit install --install-hooks
