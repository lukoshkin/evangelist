#!/usr/bin/env python3
"""
AI-Commit: Generate commit messages using LLMs based on staged changes.

This script takes the output of `git diff --staged` and sends it to an LLM
to compose a meaningful commit message. It supports multiple LLM providers
through litellm and can analyze previous commit messages to maintain
consistent formatting and style.
"""

import argparse
import configparser
import os
import subprocess
import sys
from pathlib import Path

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

        print(f"Created default configuration at {self.config_path}")
        print(
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

    def get_staged_diff(self) -> str:
        """Get the git diff of staged changes.

        Returns:
            String containing the git diff output

        Raises:
            subprocess.CalledProcessError: If git command fails
        """
        try:
            result = subprocess.run(
                ["git", "diff", "--staged"],
                capture_output=True,
                text=True,
                check=True,
            )
            return result.stdout
        except subprocess.CalledProcessError as e:
            print(f"Error getting git diff: {e}")
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
            print(f"Warning: Could not get previous commits: {e}")
            return ""

    def generate_commit_message(
        self, diff: str, previous_commits: str | None = None
    ) -> str:
        """Generate a commit message using an LLM.

        Args:
            diff: Git diff output
            previous_commits: Previous commit messages for context

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

        # Prepare the user message
        user_message = (
            f"Here is the git diff of staged changes:\n\n```\n{diff}\n```\n\n"
        )

        if previous_commits:
            user_message += (
                f"Here are the previous commit messages for context:\n\n"
                f"```\n{previous_commits}\n```\n\n"
                f"Please generate a commit message that follows a similar style and format."
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
                temperature=temperature,
                max_tokens=max_tokens,
            )

            return response.choices[0].message.content.strip()
        except Exception as e:
            print(f"Error generating commit message: {e}")
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
            print("Successfully committed changes with AI-generated message.")
        except subprocess.CalledProcessError as e:
            print(f"Error committing changes: {e}")
            sys.exit(1)


def main():
    """Main entry point for the script."""
    parser = argparse.ArgumentParser(
        description="Generate commit messages using LLMs based on staged changes."
    )

    parser.add_argument("--config", help="Path to configuration file")

    parser.add_argument(
        "--provider",
        help="LLM provider to use (openai, anthropic, google, bedrock)",
    )

    parser.add_argument(
        "--model", help="Model to use for generating commit messages"
    )

    parser.add_argument(
        "--temperature", type=float, help="Temperature for LLM generation"
    )

    parser.add_argument(
        "--previous-commits",
        action="store_true",
        help="Include previous commit messages for context",
    )

    parser.add_argument(
        "--commit",
        action="store_true",
        help="Automatically commit with the generated message",
    )

    parser.add_argument(
        "--edit",
        action="store_true",
        help="Open the generated message in an editor before committing",
    )

    args = parser.parse_args()

    # Initialize AICommit with optional config path
    ai_commit = AICommit(config_path=args.config)

    # Override config with command line arguments if provided
    if args.provider:
        ai_commit.config["DEFAULT"]["provider"] = args.provider

    if args.model:
        ai_commit.config["DEFAULT"]["model"] = args.model

    if args.temperature is not None:
        ai_commit.config["DEFAULT"]["temperature"] = str(args.temperature)

    # Get git diff
    diff = ai_commit.get_staged_diff()

    if not diff:
        print(
            "No staged changes found. Please stage your changes with 'git add' first."
        )
        sys.exit(1)

    # Get previous commits if requested
    previous_commits = None
    if args.previous_commits:
        previous_commits = ai_commit.get_previous_commits()

    # Generate commit message
    commit_message = ai_commit.generate_commit_message(diff, previous_commits)

    # Edit message if requested
    if args.edit:
        commit_message = edit_message(commit_message)

    # Print the generated message
    print("\nGenerated commit message:")
    print("-" * 50)
    print(commit_message)
    print("-" * 50)

    # Commit if requested
    if args.commit:
        ai_commit.commit_with_message(commit_message)
    else:
        print("\nTo use this message, run:")
        print(f"git commit -m '{commit_message.splitlines()[0]}'")

        if len(commit_message.splitlines()) > 1:
            print(
                "(Note: The message has multiple lines. For full message, use:"
            )
            print("git commit -F <(cat << 'EOF'")
            print(commit_message)
            print("EOF")
            print(")")


def edit_message(message: str) -> str:
    """Open the generated message in an editor for modification.

    Args:
        message: Initial commit message

    Returns:
        Edited commit message
    """
    # Create a temporary file
    temp_file = Path("/tmp/ai-commit-message.txt")
    temp_file.write_text(message, encoding="utf-8")

    # Get the editor from git config or environment
    try:
        editor = subprocess.run(
            ["git", "config", "core.editor"],
            capture_output=True,
            text=True,
            check=True,
        ).stdout.strip()
    except subprocess.CalledProcessError:
        editor = os.environ.get("EDITOR", "vim")

    # Open the editor
    subprocess.run([editor, temp_file], check=True)

    # Read the edited message
    edited_message = temp_file.read_text(encoding="utf-8")

    # Remove the temporary file
    temp_file.unlink()

    return edited_message


if __name__ == "__main__":
    main()
