#!/usr/bin/env python3
import re
import subprocess
import tempfile
from pathlib import Path

import click


KEY_NAME_RE = re.compile(r"^[A-Za-z0-9._-]+$")


def run(args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)


def repo_root():
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
        )
        return Path(result.stdout.strip())
    except subprocess.CalledProcessError:
        current = Path.cwd().resolve()
        for path in [current, *current.parents]:
            if (path / "flake.nix").exists():
                return path
        raise SystemExit("Could not find dotfiles repo root")


def resolve_ssh_store(root, target):
    aliases = {
        "system": root / "secrets" / "ssh" / "system",
        "user": root / "secrets" / "ssh" / "user",
    }
    if target in aliases:
        return aliases[target]

    path = Path(target)
    if not path.is_absolute():
        path = root / path
    return path


def ensure_key_name(name):
    if not KEY_NAME_RE.match(name):
        raise click.ClickException("SSH key name may contain only letters, numbers, dot, underscore, and dash")


def generate_ssh_key(store, name, key_type, comment, force, private_file):
    root = repo_root()
    store_dir = resolve_ssh_store(root, store)
    ensure_key_name(name)

    if private_file is None:
        encrypted_private_key = store_dir / f"{name}.key"
    else:
        encrypted_private_key = Path(private_file)
        if not encrypted_private_key.is_absolute():
            encrypted_private_key = root / encrypted_private_key

    public_key = encrypted_private_key.with_suffix(".pub")

    if (encrypted_private_key.exists() or public_key.exists()) and not force:
        raise click.ClickException(f"SSH key files already exist: {encrypted_private_key} / {public_key}")

    encrypted_private_key.parent.mkdir(parents=True, exist_ok=True)
    public_key.parent.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory(prefix="dotfiles-ssh-keygen-") as tmp_dir:
        private_key = Path(tmp_dir) / name
        run([
            "ssh-keygen",
            "-q",
            "-t",
            key_type,
            "-N",
            "",
            "-C",
            comment or name,
            "-f",
            str(private_key),
        ])

        public_key.write_text((private_key.with_suffix(private_key.suffix + ".pub")).read_text())
        run([
            "sops",
            "--encrypt",
            "--input-type",
            "binary",
            "--output-type",
            "binary",
            "--output",
            str(encrypted_private_key),
            str(private_key),
        ])

    rel_private_key = encrypted_private_key.relative_to(root) if encrypted_private_key.is_relative_to(root) else encrypted_private_key
    rel_public_key = public_key.relative_to(root) if public_key.is_relative_to(root) else public_key

    click.echo(f"Wrote encrypted private key to {rel_private_key}")
    click.echo(f"Wrote public key to {rel_public_key}")
    if store == "system":
        click.echo()
        click.echo("Add an explicit sops-nix declaration, for example:")
        click.echo(f'  my.apps.secrets.secrets."ssh/system/{name}" = {{')
        click.echo(f"    sopsFile = ./{rel_private_key};")
        click.echo('    format = "binary";')
        click.echo("  };")
    if store == "user":
        click.echo()
        click.echo("With the default SSH module settings, it will appear at:")
        click.echo(f"  ~/.ssh/{name}")


@click.group()
def cli():
    """Dotfiles maintenance commands."""


@cli.command("ssh-keygen")
@click.argument("store")
@click.argument("name")
@click.argument("private_file", required=False)
@click.option("--type", "key_type", default="ed25519", show_default=True, help="ssh-keygen key type.")
@click.option("--comment", help="SSH public key comment.")
@click.option("--force", is_flag=True, help="Replace an existing ssh.<name> secret.")
def ssh_keygen_command(store, name, private_file, key_type, comment, force):
    """Generate an SSH key as a separate SOPS-encrypted file.

    STORE can be 'system', 'user', or a directory path.
    """
    generate_ssh_key(store, name, key_type, comment, force, private_file)


if __name__ == "__main__":
    cli(prog_name="dotfiles")
