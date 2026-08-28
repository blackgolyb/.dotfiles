.PHONY: help dev fmt format check test ci update switch openclaw-secrets pre-commit pre-commit-all hooks

help:
	@printf '%s\n' 'Available targets:'
	@printf '  %-16s %s\n' 'dev' 'Enter the dotfiles dev shell'
	@printf '  %-16s %s\n' 'fmt' 'Format the repository with treefmt-nix'
	@printf '  %-16s %s\n' 'format' 'Alias for fmt'
	@printf '  %-16s %s\n' 'check' 'Run all flake checks, including QML lint'
	@printf '  %-16s %s\n' 'test' 'Run Python tests'
	@printf '  %-16s %s\n' 'ci' 'Run checks and tests'
	@printf '  %-16s %s\n' 'update' 'Update flake inputs'
	@printf '  %-16s %s\n' 'switch' 'Switch the NixOS configuration'
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

test:
	nix develop .#dotfiles -c pytest modules/apps/tmux

ci: check test

update:
	nix flake update

switch:
	sudo nixos-rebuild switch --flake .#nixos

openclaw-secrets:
	sops --input-type dotenv --output-type dotenv secrets/openclaw.yaml

pre-commit:
	nix develop .#dotfiles -c pre-commit run

pre-commit-all:
	nix develop .#dotfiles -c pre-commit run --all-files

hooks:
	nix develop .#dotfiles -c pre-commit install --install-hooks
