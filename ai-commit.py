#!/usr/bin/env python3
"""
AI-Commit: Generate commit messages using LLMs based on staged changes.

This script takes the output of `git diff --staged` and sends it to an LLM
to compose a meaningful commit message. It supports multiple LLM providers
through litellm and can analyze previous commit messages to maintain
consistent formatting and style.
"""

import configparser
import os
import subprocess
import sys
from pathlib import Path
from tempfile import NamedTemporaryFile

import click
from loguru import logger

from litellm import completion


class AICommit:
    """Generate commit messages using LLMs based on staged changes."""

    DEFAULT_CONFIG_PATH = os.path.expanduser("~/.config/ai-commit/config.ini")
    DEFAULT_SYSTEM_PROMPT = """
You are an expert developer tasked with writing clear, concise, and informative git commit messages.
Analyze the provided git diff and create a commit message that follows these guidelines:

1. Use the imperative mood (e.g., "Add feature" not "Added feature")
2. First line should be a summary (max 50 chars)
3. If needed, leave a blank line after the summary and provide more detailed explanation
4. Mention relevant component names and key changes
5. Be specific about what changed and why, not how
6. Keep the message clear and concise

Format:
<type>(<scope>): <subject>

<body>

<footer>

Types: feat, fix, docs, style, refactor, test, chore
Example: "feat(auth): implement JWT authentication"
"""

    def __init__(self, config_path: str | None = None):
        """Initialize the AICommit class.

        Args:
            config_path: Path to the configuration file. If None, uses the default path.
        """
        self.config_path = config_path or self.DEFAULT_CONFIG_PATH
        self.config = self._load_config()

        # Configure litellm with API keys from config
        self._configure_litellm()

    def _load_config(self) -> configparser.ConfigParser:
        """Load configuration from file or create default if not exists.

        Returns:
            ConfigParser object with loaded configuration
        """
        config = configparser.ConfigParser()

        # Create default config if it doesn't exist
        if not os.path.exists(self.config_path):
            self._create_default_config(config)

        config.read(self.config_path)
        return config

    def _create_default_config(
        self, config: configparser.ConfigParser
    ) -> None:
        """Create default configuration file.

        Args:
            config: ConfigParser object to populate with default values
        """
        config["DEFAULT"] = {
            "provider": "openai",
            "model": "gpt-4o",
            "temperature": "0.7",
            "max_tokens": "500",
            "system_prompt": self.DEFAULT_SYSTEM_PROMPT,
            "commit_template": "",
        }

        config["API_KEYS"] = {
            "openai": "",
            "anthropic": "",
            "google": "",
            "aws": "",
        }

        # Create directory if it doesn't exist
        os.makedirs(os.path.dirname(self.config_path), exist_ok=True)

        # Write config to file
        with open(self.config_path, "w", encoding="utf-8") as config_file:
            config.write(config_file)

        logger.info(f"Created default configuration at {self.config_path}")
        logger.info(
            "Please edit this file to add your API keys and customize settings."
        )
        sys.exit(0)

    def _configure_litellm(self) -> None:
        """Configure litellm with API keys from config."""
        api_keys = self.config["API_KEYS"]

        if api_keys.get("openai"):
            os.environ["OPENAI_API_KEY"] = api_keys["openai"]

        if api_keys.get("anthropic"):
            os.environ["ANTHROPIC_API_KEY"] = api_keys["anthropic"]

        if api_keys.get("google"):
            os.environ["GOOGLE_API_KEY"] = api_keys["google"]

        if api_keys.get("aws"):
            os.environ["AWS_ACCESS_KEY_ID"] = api_keys.get(
                "aws_access_key_id", ""
            )
            os.environ["AWS_SECRET_ACCESS_KEY"] = api_keys.get(
                "aws_secret_access_key", ""
            )
            os.environ["AWS_REGION_NAME"] = api_keys.get(
                "aws_region", "us-east-1"
            )

    def _ensure_git_repo(self) -> None:
        """Ensure the current directory is a git repository."""
        try:
            subprocess.run(
                ["git", "rev-parse", "--is-inside-work-tree"],
                capture_output=True,
                text=True,
                check=True,
            )
        except subprocess.CalledProcessError:
            logger.error("Current directory is not a git repository.")
            sys.exit(1)

    def get_diff(self, include_all: bool = False) -> str:
        """Get the git diff of changes.

        Args:
            include_all: Include unstaged changes as well as staged ones.

        Returns:
            Git diff output as a string.
        """
        self._ensure_git_repo()

        diff_cmd = ["git", "diff", "--staged"]
        if include_all:
            diff_cmd = ["git", "diff"]

        try:
            result = subprocess.run(
                diff_cmd,
                capture_output=True,
                text=True,
                check=True,
            )
            return result.stdout
        except subprocess.CalledProcessError as e:
            logger.error(f"Error getting git diff: {e}")
            sys.exit(1)

    def get_previous_commits(self, count: int = 5) -> str:
        """Get previous commit messages for context.

        Args:
            count: Number of previous commit messages to retrieve

        Returns:
            String containing the previous commit messages
        """
        try:
            result = subprocess.run(
                ["git", "log", f"-{count}", "--pretty=format:%s%n%b%n---"],
                capture_output=True,
                text=True,
                check=True,
            )
            return result.stdout
        except subprocess.CalledProcessError as e:
            logger.warning(f"Could not get previous commits: {e}")
            return ""

    def generate_commit_template(self, commits: str) -> str:
        """Generate a commit message template from previous commits."""
        provider = self.config["DEFAULT"]["provider"]
        model = self.config["DEFAULT"]["model"]
        max_tokens = int(self.config["DEFAULT"]["max_tokens"])

        system_prompt = (
            "You are a git commit style analyzer. "
            "Given a list of commit messages, produce a concise template or set "
            "of guidelines that describes the style so it can be followed later."
        )

        user_message = f"Here are past commit messages:\n\n```\n{commits}\n```"

        provider_model_map = {
            "openai": f"openai/{model}",
            "anthropic": f"anthropic/{model}",
            "google": f"google/{model}",
            "bedrock": f"bedrock/{model}",
        }

        model_name = provider_model_map.get(provider, f"{provider}/{model}")

        try:
            response = completion(
                model=model_name,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message},
                ],
                temperature=0,
                max_tokens=max_tokens,
            )
            return response.choices[0].message.content.strip()
        except Exception as e:
            logger.error(f"Error generating commit template: {e}")
            sys.exit(1)

    def save_commit_template(self, template: str) -> None:
        """Save generated commit template to config."""
        self.config["DEFAULT"]["commit_template"] = template
        with open(self.config_path, "w", encoding="utf-8") as f:
            self.config.write(f)

    def generate_commit_message(self, diff: str) -> str:
        """Generate a commit message using an LLM.

        Args:
            diff: Git diff output

        Returns:
            Generated commit message

        Raises:
            Exception: If LLM API call fails
        """
        provider = self.config["DEFAULT"]["provider"]
        model = self.config["DEFAULT"]["model"]
        temperature = float(self.config["DEFAULT"]["temperature"])
        max_tokens = int(self.config["DEFAULT"]["max_tokens"])
        system_prompt = self.config["DEFAULT"]["system_prompt"]
        commit_template = self.config["DEFAULT"].get("commit_template", "")

        # Prepare the user message
        user_message = (
            f"Here is the git diff of changes:\n\n```\n{diff}\n```\n\n"
        )

        if commit_template:
            user_message += (
                "Please use the following commit style template when generating the message:\n"
                f"```\n{commit_template}\n```\n"
            )
        else:
            user_message += (
                "Please generate a commit message based on these changes."
            )

        # Map provider names to litellm model names
        provider_model_map = {
            "openai": f"openai/{model}",
            "anthropic": f"anthropic/{model}",
            "google": f"google/{model}",
            "bedrock": f"bedrock/{model}",
        }

        model_name = provider_model_map.get(provider, f"{provider}/{model}")

        try:
            response = completion(
                model=model_name,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message},
                ],
                temperature=0,
                max_tokens=max_tokens,
            )

            return response.choices[0].message.content.strip()
        except Exception as e:
            logger.error(f"Error generating commit message: {e}")
            sys.exit(1)

    def commit_with_message(self, message: str) -> None:
        """Commit changes with the generated message.

        Args:
            message: Commit message to use

        Raises:
            subprocess.CalledProcessError: If git commit fails
        """
        try:
            subprocess.run(["git", "commit", "-m", message], check=True)
            logger.info("Successfully committed changes with AI-generated message.")
        except subprocess.CalledProcessError as e:
            logger.error(f"Error committing changes: {e}")
            sys.exit(1)

    def edit_message(self, message: str) -> str:
        """Open the generated message in an editor for modification."""
        with NamedTemporaryFile("w+", delete=False) as tmp:
            tmp.write(message)
            tmp_path = tmp.name

        try:
            editor = (
                subprocess.run(
                    ["git", "config", "core.editor"],
                    capture_output=True,
                    text=True,
                    check=True,
                ).stdout.strip()
                or os.environ.get("EDITOR", "vim")
            )
        except subprocess.CalledProcessError:
            editor = os.environ.get("EDITOR", "vim")

        subprocess.run([editor, tmp_path], check=True)

        with open(tmp_path, "r", encoding="utf-8") as f:
            edited = f.read()

        os.unlink(tmp_path)
        return edited


@click.group()
@click.option("--config", help="Path to configuration file")
@click.pass_context
def cli(ctx: click.Context, config: str | None) -> None:
    """AI-Commit command line interface."""
    ctx.obj = {"CONFIG": config}


@cli.command()
@click.option("--provider", help="LLM provider")
@click.option("--model", help="Model to use")
@click.option("--temperature", type=float, help="Temperature for generation")
@click.option("--commit", "do_commit", is_flag=True, help="Commit after generation")
@click.option("--edit", is_flag=True, help="Edit the message before committing")
@click.option("--all", "include_all", is_flag=True, help="Use all modified files")
@click.pass_context
def commit(
    ctx: click.Context,
    provider: str | None,
    model: str | None,
    temperature: float | None,
    do_commit: bool,
    edit: bool,
    include_all: bool,
) -> None:
    """Generate a commit message based on repository changes."""
    ai_commit = AICommit(config_path=ctx.obj.get("CONFIG"))

    if provider:
        ai_commit.config["DEFAULT"]["provider"] = provider
    if model:
        ai_commit.config["DEFAULT"]["model"] = model
    if temperature is not None:
        ai_commit.config["DEFAULT"]["temperature"] = str(temperature)

    diff = ai_commit.get_diff(include_all)
    if not diff:
        logger.error("No changes found to commit.")
        sys.exit(1)

    commit_message = ai_commit.generate_commit_message(diff)

    if edit:
        commit_message = ai_commit.edit_message(commit_message)

    click.echo("\nGenerated commit message:")
    click.echo("-" * 50)
    click.echo(commit_message)
    click.echo("-" * 50)

    if do_commit:
        ai_commit.commit_with_message(commit_message)
    else:
        click.echo("\nTo use this message, run:")
        click.echo(f"git commit -m '{commit_message.splitlines()[0]}'")

        if len(commit_message.splitlines()) > 1:
            click.echo("(Note: The message has multiple lines. For full message, use:")
            click.echo("git commit -F <(cat << 'EOF'")
            click.echo(commit_message)
            click.echo("EOF")
            click.echo(")")


@cli.command(name="mimic")
@click.option("--count", default=20, help="Number of previous commits to analyze")
@click.pass_context
def mimic(ctx: click.Context, count: int) -> None:
    """Generate and store a commit message template from previous commits."""
    ai_commit = AICommit(config_path=ctx.obj.get("CONFIG"))
    previous = ai_commit.get_previous_commits(count)
    if not previous:
        logger.error("No previous commits available to analyze.")
        sys.exit(1)

    template = ai_commit.generate_commit_template(previous)
    ai_commit.save_commit_template(template)
    click.echo("Stored commit message template in configuration.")


if __name__ == "__main__":
    cli()
