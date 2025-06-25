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
from litellm import completion
from loguru import logger


class AICommit:
    """Generate commit messages using LLMs based on staged changes."""

    @staticmethod
    def get_default_config_path() -> str:
        """Return the default configuration path based on the platform.

        Returns:
            Path to the default configuration file
        """
        if sys.platform == "win32":
            if appdata := os.environ.get("APPDATA"):
                return str(Path(appdata) / "ai-commit" / "config.ini")
            return str(Path.home() / "ai-commit" / "config.ini")
        return str(Path.home() / ".config" / "ai-commit" / "config.ini")

    DEFAULT_CONFIG_PATH = get_default_config_path()
    DEFAULT_TEMPLATE = """
You are an expert developer tasked with writing clear, concise, and \
informative git commit messages. Analyze the provided git diff and create a \
commit message that follows these guidelines:

1. Use the imperative mood (e.g., "Add feature" not "Added feature")
2. First line should be a summary (max 50 chars)
3. If needed, leave a blank line after the summary and provide more \
detailed explanation
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
            config_path: Path to the configuration file.
                If None, uses the default path.
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
        config_dir = Path(self.config_path).parent
        if not Path(self.config_path).exists():
            config_dir.mkdir(parents=True, exist_ok=True)
            self._create_default_config(config)

        config.read(self.config_path)
        if "PROJECT_TEMPLATES" not in config:
            config["PROJECT_TEMPLATES"] = {}

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
            "temperature": "0",
            "max_tokens": "500",
            "template_commit_count": "10",
            "editor": "",
        }
        config["API_KEYS"] = {
            "openai": "",
            "anthropic": "",
            "google": "",
            "aws": "",
        }
        config["PROJECT_TEMPLATES"] = {"*": self.DEFAULT_TEMPLATE}
        Path(self.config_path).parent.mkdir(parents=True, exist_ok=True)
        with open(self.config_path, "w", encoding="utf-8") as config_file:
            config.write(config_file)

        logger.info(f"Created default configuration at {self.config_path}")
        logger.info("Please inspect the config and customize as needed.")
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

    def _ensure_git_repo(self, path: str = ".") -> None:
        """Ensure that the given path is a git repository."""
        try:
            subprocess.run(
                ["git", "-C", path, "rev-parse", "--is-inside-work-tree"],
                capture_output=True,
                text=True,
                check=True,
            )
        except subprocess.CalledProcessError:
            logger.error(f"{path} is not a git repository.")
            sys.exit(1)
        except FileNotFoundError:
            logger.error("Git command not found. Please install git.")
            sys.exit(1)

    def get_diff(self, include_all: bool = False) -> str:
        """Get the git diff of changes.

        Args:
            include_all: Include unstaged changes as well as staged ones.

        Returns:
            Git diff output as a string.
        """
        self._ensure_git_repo()
        if not include_all:
            try:
                status_result = subprocess.run(
                    ["git", "diff", "--staged", "--name-only"],
                    capture_output=True,
                    text=True,
                    check=True,
                )
                if not status_result.stdout.strip():
                    logger.warning("No staged changes found.")
                    if click.confirm(
                        "Include all changes instead?", default=True
                    ):
                        include_all = True
                    else:
                        logger.error("No changes to commit.")
                        sys.exit(1)
            except subprocess.CalledProcessError as e:
                logger.error(f"Error checking git status: {e}")
                sys.exit(1)

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

    def get_previous_commits(
        self,
        repository: str = ".",
        start: str | None = None,
        end: str | None = None,
    ) -> str:
        """Get commit messages from a specified range."""
        self._ensure_git_repo(repository)
        end = end or "HEAD"
        if start is None:
            commit_count = self.config["DEFAULT"].getint(
                "template_commit_count", 10
            )
            try:
                count_result = subprocess.run(
                    ["git", "-C", repository, "rev-list", "--count", "HEAD"],
                    capture_output=True,
                    text=True,
                    check=True,
                )
                available_commits = int(count_result.stdout.strip())
                commit_count = min(commit_count, available_commits)
            except (subprocess.CalledProcessError, ValueError) as exc:
                logger.warning(
                    "Could not determine commit count, using default value.\n"
                    f"Failed with exception: {exc}"
                )
            start = f"{end}~{commit_count}"
        try:
            result = subprocess.run(
                [
                    "git",
                    "-C",
                    repository,
                    "log",
                    f"{start}..{end}",
                    "--pretty=format:<commit>%n%s%n%b</commit>%n",
                ],
                capture_output=True,
                text=True,
                check=True,
            )
            return result.stdout
        except subprocess.CalledProcessError as exc:
            logger.warning(f"Could not get previous commits: {exc}")
            return ""

    def generate_commit_template(self, commits: str) -> str:
        """Generate a commit message template from previous commits."""
        max_tokens = int(self.config["DEFAULT"]["max_tokens"])
        provider = self.config["DEFAULT"]["provider"]
        model = self.config["DEFAULT"]["model"]
        system_prompt = (
            "You are a git commit style analyzer. Given a list of commit"
            " messages, produce a concise template or set of guidelines that"
            " describes the style so it can be followed later. Produce it in"
            " the form of a system message that will be used for auto-"
            "generating the commit message."
        )
        user_message = f"Here are past commit messages:\n\n```\n{commits}\n```"
        provider_model_map = {
            "openai": f"openai/{model}",
            "anthropic": f"anthropic/{model}",
            "google": f"google/{model}",
            "bedrock": f"bedrock/{model}",
        }
        try:
            response = completion(
                model=provider_model_map.get(provider, f"{provider}/{model}"),
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message},
                    {
                        "role": "assistant",
                        "content": (
                            "Here is the commit template"
                            " based on the provided commit messages:\n"
                        ),
                    },
                ],
                max_tokens=max_tokens,
                temperature=0,
            )
            return response.choices[0].message.content.strip()
        except Exception as exc:
            logger.error(f"Error generating commit template: {exc}")
            sys.exit(1)

    def get_project_name(self, repository: str = ".") -> str:
        """Get the current project name from the git repository.

        Args:
            repository: Path to the git repository

        Returns:
            Project name extracted from the repository
        """
        try:
            result = subprocess.run(
                [
                    "git",
                    "-C",
                    repository,
                    "config",
                    "--get",
                    "remote.origin.url",
                ],
                capture_output=True,
                text=True,
                check=True,
            )
            url = result.stdout.strip()
            if url and url.endswith(".git"):
                return url[:-4].split("github.com", 1)[-1][1:]
        except subprocess.CalledProcessError:
            logger.warning(f"Could not get remote URL for {repository}.")
        return Path(repository).resolve().name

    def get_template_for_project(self, project_name: str | None = None) -> str:
        """Get the commit template for the specified project.

        Args:
            project_name: The name of the project to get the template for.
                If None, uses the current directory.

        Returns:
            The commit template for the project,
            or the default template if not found.
        """
        if project_name is None:
            project_name = self.get_project_name()

        for name in (project_name, "*"):
            if template := self.config["PROJECT_TEMPLATES"].get(name):
                return template

        return self.DEFAULT_TEMPLATE

    def save_commit_template(
        self, template: str, project_name: str | None = None
    ) -> None:
        """Save generated commit template to config.

        Args:
            template: The commit template to save
            project_name: The name of the project to save the template for.
                If None or "global", saves to the global template (*).
        """
        if project_name is None or project_name == "global":
            self.config["PROJECT_TEMPLATES"]["*"] = template
        else:
            self.config["PROJECT_TEMPLATES"][project_name] = template

        with open(self.config_path, "w", encoding="utf-8") as f:
            self.config.write(f)

    def list_templates(self) -> dict[str, str]:
        """List all stored templates.

        Returns:
            Dictionary mapping project names to templates
        """
        templates = {}
        for project, template in self.config["PROJECT_TEMPLATES"].items():
            if template:
                templates[project] = template

        return templates

    # def delete_template(self, project_name: str) -> bool:
    #     """Delete a project template.

    #     Args:
    #         project_name: The name of the project to delete the template for.
    #             Use "global" for the global template.

    #     Returns:
    #         True if the template was deleted, False if it didn't exist
    #     """
    #     if project_name == "global":
    #         if "*" in self.config["PROJECT_TEMPLATES"]:
    #             self.config["PROJECT_TEMPLATES"].pop("*")
    #             with open(self.config_path, "w", encoding="utf-8") as f:
    #                 self.config.write(f)
    #             return True
    #         return False
    #     if project_name in self.config["PROJECT_TEMPLATES"]:
    #         self.config["PROJECT_TEMPLATES"].pop(project_name)
    #         with open(self.config_path, "w", encoding="utf-8") as f:
    #             self.config.write(f)
    #         return True
    #     return False

    def generate_commit_message(self, diff: str) -> str:
        """Generate a commit message using an LLM.

        Args:
            diff: Git diff output

        Returns:
            Generated commit message

        Raises:
            Exception: If LLM API call fails
        """
        if not diff.strip():
            logger.error("Nothing to commit.")
            sys.exit(1)

        provider = self.config["DEFAULT"]["provider"]
        model = self.config["DEFAULT"]["model"]
        temperature = float(self.config["DEFAULT"]["temperature"])
        max_tokens = int(self.config["DEFAULT"]["max_tokens"])
        project_name = self.get_project_name()
        system_prompt = self.get_template_for_project(project_name)

        user_message = (
            f"Here is the git diff of changes:\n\n```\n{diff}\n```\n\n"
            "Please generate a commit message based on these changes."
        )
        provider_model_map = {
            "openai": f"openai/{model}",
            "anthropic": f"anthropic/{model}",
            "google": f"google/{model}",
            "bedrock": f"bedrock/{model}",
        }
        try:
            response = completion(
                model=provider_model_map.get(provider, f"{provider}/{model}"),
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message},
                    {
                        "role": "assistant",
                        "content": (
                            "Here is the commit message"
                            " based on the provided changes:\n"
                        ),
                    },
                ],
                temperature=temperature,
                max_tokens=max_tokens,
            )
            result = response.choices[0].message.content.strip()
            if not result:
                logger.debug(f"Response: {response}")
                logger.error("Received empty response from LLM.")
                sys.exit(1)

            lines = result.splitlines()
            if len(lines) > 3:
                _slice: tuple[int | None, int | None] = (None, None)
                if lines[0].strip() == "```":
                    _slice = (1, None)
                if lines[-1].strip() == "```":
                    _slice = (_slice[0], -1)
            return "\n".join(lines[slice(*_slice)])
        except Exception as exc:
            logger.error(f"Error generating commit message: {exc}")
            sys.exit(1)

    def confirm_text(self, text: str, prompt: str) -> tuple[bool, str]:
        """Show the text and ask for confirmation with edit option.

        Args:
            text: Text to display
            prompt: Prompt to show for confirmation

        Returns:
            Tuple of (is_confirmed, possibly_edited_text)
            is_confirmed is True if confirmed, False otherwise
            possibly_edited_text is the original text or edited version

        Note:
            If the edited message is empty, the operation is aborted.
        """
        click.echo("\n" + text)
        choice = click.prompt(
            prompt,
            type=click.Choice(["y", "e", "n"], case_sensitive=False),
            default="y",
            show_choices=True,
        ).lower()

        if choice == "e":
            edited_text = self.edit_message(text.split("-" * 50)[1].strip())
            return bool(edited_text.strip()), edited_text

        return choice == "y", text.split("-" * 50)[1].strip()

    def commit_with_message(self, message: str) -> None:
        """Commit changes with the generated message.

        Args:
            message: Commit message to use

        Raises:
            subprocess.CalledProcessError: If git commit fails
        """
        try:
            result = subprocess.run(
                ["git", "commit", "-m", message],
                capture_output=True,
                text=True,
                check=True,
            )
            logger.info("Successfully committed changes.")
            logger.debug(result.stdout)
        except subprocess.CalledProcessError as exc:
            logger.error(f"Error committing changes: {exc}")
            if exc.stderr:
                logger.error(f"Details: {exc.stderr}")
            sys.exit(1)

    def get_editor(self) -> str:
        """Get the editor to use for editing files.

        First checks the config file, then git config, then environment.

        Returns:
            The editor command to use
        """
        if editor := self.config["DEFAULT"].get("editor"):
            return editor

        try:
            editor = subprocess.run(
                ["git", "config", "core.editor"],
                capture_output=True,
                text=True,
                check=True,
            ).stdout.strip() or os.environ.get("EDITOR", "vim")
        except subprocess.CalledProcessError:
            editor = os.environ.get("EDITOR", "vim")

        self.config["DEFAULT"]["editor"] = editor
        with open(self.config_path, "w", encoding="utf-8") as f:
            self.config.write(f)

        return editor

    def edit_message(self, message: str) -> str:
        """Open the generated message in an editor for modification."""
        with NamedTemporaryFile("w+", delete=False) as tmp:
            tmp.write(message)
            tmp_path = tmp.name

        editor = self.get_editor()
        subprocess.run([editor, tmp_path], check=True)
        with open(tmp_path, "r", encoding="utf-8") as f:
            edited = f.read()

        os.unlink(tmp_path)
        return edited


@click.group()
@click.option("--config", help="Path to configuration file")
@click.pass_context
@click.help_option("-h", "--help")
def cli(ctx: click.Context, config: str | None) -> None:
    """AI-Commit command line interface."""
    ctx.obj = {"CONFIG": config}


@cli.command()
@click.option("--provider", help="LLM provider")
@click.option("--model", help="Model to use")
@click.option("--temperature", type=float, help="Temperature for generation")
@click.option(
    "--commit",
    "do_commit",
    is_flag=True,
    help="Commit after generation",
)
@click.option(
    "--all",
    "include_all",
    is_flag=True,
    help="Use all modified files",
)
@click.pass_context
def commit(
    ctx: click.Context,
    provider: str | None,
    model: str | None,
    temperature: float | None,
    do_commit: bool,
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
    is_confirmed, commit_message = ai_commit.confirm_text(
        f"Generated commit message:\n{'-' * 50}\n{commit_message}\n{'-' * 50}",
        "Use this commit message?",
    )
    if is_confirmed:
        if do_commit:
            ai_commit.commit_with_message(commit_message)
        else:
            click.echo("\nTo use this message, run:")
            click.echo(f"git commit -m '{commit_message.splitlines()[0]}'")

            if len(commit_message.splitlines()) > 1:
                click.echo(
                    "(Note: The message has multiple lines."
                    " For full message, use:"
                )
                click.echo("git commit -F <(cat << 'EOF'")
                click.echo(commit_message)
                click.echo("EOF")
                click.echo(")")
    else:
        logger.info("Commit message rejected. Exiting.")
        sys.exit(0)


@cli.command(name="mimic")
@click.argument("start", required=False)
@click.argument("end", required=False)
@click.option(
    "-i",
    "--idol",
    default=".",
    help="Source repository to extract commits from",
)
@click.option(
    "-t",
    "--target",
    help=(
        "Target project to save the template for. "
        "Use '*' or 'global' for global template. "
        "Default is current project."
    ),
)
@click.pass_context
def mimic(
    ctx: click.Context,
    start: str | None,
    end: str | None,
    idol: str,
    target: str | None,
) -> None:
    """Generate and store commit templates for specific projects.

    This command can:
    - Generate a template from commits in a source repository
    - Save templates for specific projects
    - List all stored templates

    Examples:
    - Use current project for both source and target:
      ai-commit mimic
    - Use a specific source repository:
      ai-commit mimic -i /path/to/source/repo
    - Generate template for a different target project:
      ai-commit mimic -t project-name
    - Generate a global template (applied to projects without specific templates):
      ai-commit mimic -t "*"
    """
    ai_commit = AICommit(config_path=ctx.obj.get("CONFIG"))
    target = (
        "global"
        if target in ["*", "global"]
        else ai_commit.get_project_name(target or ".")
    )
    reference_commits = ai_commit.get_previous_commits(
        repository="." if idol == "." else idol, start=start, end=end
    )
    if not reference_commits:
        logger.error("No commit messages found in the specified range.")
        sys.exit(1)

    template = ai_commit.generate_commit_template(reference_commits)
    target_desc = (
        "as global template"
        if target == "global"
        else f"for project '{target}'"
    )
    is_confirmed, template = ai_commit.confirm_text(
        f"Generated commit template:\n{'-' * 50}\n{template}\n{'-' * 50}",
        f"Save this template {target_desc}?",
    )
    if is_confirmed:
        ai_commit.save_commit_template(template, target)
        click.echo(f"Stored commit message template {target_desc}.")
    else:
        logger.info("Template rejected. Exiting.")
        sys.exit(0)


@cli.command()
def config() -> None:
    """Open the configuration file for editing."""
    ai_commit = AICommit()
    config_path = ai_commit.config_path
    editor = ai_commit.get_editor()

    try:
        subprocess.run([editor, config_path], check=True)
    except subprocess.CalledProcessError as exc:
        logger.error(f"Error opening configuration file: {exc}")
        sys.exit(1)
    except FileNotFoundError:
        logger.error(
            f"Editor '{editor}' not found."
            " Please set EDITOR environment variable."
        )
        sys.exit(1)


@cli.command(name="help")
@click.pass_context
def show_help(ctx: click.Context) -> None:
    """Show help information for the command."""
    if ctx.parent:
        click.echo(ctx.parent.get_help())
    else:
        click.echo(ctx.get_help())


if __name__ == "__main__":
    cli()  # pylint: disable=no-value-for-parameter
