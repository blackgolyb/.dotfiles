#!/usr/bin/env python3
import os
import re
import subprocess
import tempfile
from pathlib import Path
from shutil import copyfile
from typing import Sequence

import click

KEY_NAME_RE = re.compile(r"^[A-Za-z0-9._-]+$")
SSH_STORE_ALIASES = {
    "system": Path("secrets/ssh/system"),
    "user": Path("secrets/ssh/user"),
}


def run(command: Sequence[str]) -> None:
    try:
        subprocess.run(command, check=True)
    except FileNotFoundError as error:
        raise click.ClickException(f"Required command not found: {command[0]}") from error
    except subprocess.CalledProcessError as error:
        raise click.ClickException(
            f"Command failed with exit code {error.returncode}: {' '.join(command)}"
        ) from error


def repo_root() -> Path:
    configured_root = os.environ.get("DOTFILES_ROOT")
    if not configured_root:
        raise click.ClickException("DOTFILES_ROOT is not set")
    return Path(configured_root).expanduser().resolve()


def resolve_ssh_store(root: Path, store: str) -> Path:
    try:
        return root / SSH_STORE_ALIASES[store]
    except KeyError as error:
        raise click.ClickException("STORE must be either 'system' or 'user'") from error


def ensure_key_name(name: str) -> None:
    if not KEY_NAME_RE.match(name):
        raise click.ClickException(
            "SSH key name may contain only letters, numbers, dot, underscore, and dash"
        )


def ssh_key_paths(store_dir: Path, name: str) -> tuple[Path, Path]:
    encrypted_private_key = store_dir / f"{name}.key"
    return encrypted_private_key, encrypted_private_key.with_suffix(".pub")


def ensure_output_paths(private_key: Path, public_key: Path, force: bool) -> None:
    if not force and (private_key.exists() or public_key.exists()):
        raise click.ClickException(f"SSH key files already exist: {private_key} / {public_key}")

    private_key.parent.mkdir(parents=True, exist_ok=True)
    public_key.parent.mkdir(parents=True, exist_ok=True)


def generate_plain_ssh_key(
    output_dir: Path, name: str, key_type: str, comment: str
) -> tuple[Path, Path]:
    priv = output_dir / name
    pub = output_dir / f"{name}.pub"
    run(
        [
            "ssh-keygen",
            "-q",
            "-t",
            key_type,
            "-N",
            "",
            "-C",
            comment,
            "-f",
            str(priv),
        ]
    )
    return priv, pub


def encrypt_private_key(root: Path, plain_key: Path, encrypted_key: Path) -> None:
    run(
        [
            "sops",
            "--config",
            str(root / ".sops.yaml"),
            "--encrypt",
            "--input-type",
            "binary",
            "--output-type",
            "binary",
            "--filename-override",
            str(encrypted_key),
            "--output",
            str(encrypted_key),
            str(plain_key),
        ]
    )


def relative_to_root(root: Path, path: Path) -> Path:
    return path.relative_to(root) if path.is_relative_to(root) else path


def print_ssh_key_summary(
    root: Path, store: str, name: str, private_key: Path, public_key: Path
) -> None:
    rel_private_key = relative_to_root(root, private_key)
    rel_public_key = relative_to_root(root, public_key)

    click.echo(f"Wrote encrypted private key to {rel_private_key}")
    click.echo(f"Wrote public key to {rel_public_key}")

    if store == "system":
        click.echo()
        click.echo("Add an explicit sops-nix declaration, for example:")
        click.echo(f'  my.apps.secrets.secrets."ssh/system/{name}" = {{')
        click.echo(f"    sopsFile = ./{rel_private_key};")
        click.echo('    format = "binary";')
        click.echo("  };")
    elif store == "user":
        click.echo()
        click.echo("With the default SSH module settings, it will appear at:")
        click.echo(f"  ~/.ssh/{name}")


def generate_ssh_key(
    store: str, name: str, key_type: str, comment: str | None, force: bool
) -> None:
    ensure_key_name(name)

    root = repo_root()
    store_dir = resolve_ssh_store(root, store)
    encrypted_private_key, public_key = ssh_key_paths(store_dir, name)
    ensure_output_paths(encrypted_private_key, public_key, force)

    with tempfile.TemporaryDirectory(prefix="dotfiles-ssh-keygen-") as tmp_dir:
        tmp_priv, tmp_pub = generate_plain_ssh_key(Path(tmp_dir), name, key_type, comment or name)
        copyfile(tmp_pub, public_key)
        encrypt_private_key(root, tmp_priv, encrypted_private_key)

    print_ssh_key_summary(root, store, name, encrypted_private_key, public_key)


@click.group()
def cli() -> None:
    """Dotfiles maintenance commands."""


@cli.command("ssh-keygen")
@click.argument("store")
@click.argument("name")
@click.option(
    "--type", "key_type", default="ed25519", show_default=True, help="ssh-keygen key type."
)
@click.option("--comment", help="SSH public key comment.")
@click.option("--force", is_flag=True, help="Replace an existing ssh.<name> secret.")
def ssh_keygen_command(
    store: str, name: str, key_type: str, comment: str | None, force: bool
) -> None:
    """Generate an SSH key as a separate SOPS-encrypted file.

    STORE must be 'system' or 'user'.
    """
    generate_ssh_key(store, name, key_type, comment, force)


if __name__ == "__main__":
    cli(prog_name="dotfiles")
