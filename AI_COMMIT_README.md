# AI-Commit

Generate intelligent commit messages using LLMs based on your staged git changes.

## Overview

AI-Commit is a command-line tool that analyzes your staged git changes and uses Large Language Models (LLMs) to generate meaningful, well-structured commit messages. It supports multiple LLM providers and can learn from your previous commit messages to maintain a consistent style.

## Features

- 🤖 **AI-Powered**: Leverages state-of-the-art LLMs to analyze code changes and generate appropriate commit messages
- 🔄 **Multi-Provider Support**: Works with OpenAI, Anthropic (Claude), Google (Gemini), and AWS Bedrock models
- 📝 **Context-Aware**: Can analyze previous commit messages to maintain consistent formatting and style
- ⚙️ **Highly Customizable**: Configure your preferred LLM provider, model, temperature, and system prompt
- 🔑 **Secure**: Stores API keys in a local configuration file
- ✏️ **Editor Integration**: Option to edit the generated message before committing

## Installation

### Prerequisites

- Python 3.6+
- Git
- pip

### Install from source

```bash
# Clone the repository
git clone https://github.com/yourusername/ai-commit.git
cd ai-commit

# Install dependencies
pip install litellm

# Make the script executable
chmod +x ai-commit.py

# Optional: Create a symlink to make it available system-wide
ln -s $(pwd)/ai-commit.py /usr/local/bin/ai-commit
```

## Configuration

On first run, AI-Commit will create a default configuration file at `~/.config/ai-commit/config.ini`. You'll need to edit this file to add your API keys:

```ini
[DEFAULT]
provider = openai
model = gpt-4o
temperature = 0.7
max_tokens = 500
system_prompt = You are an expert developer tasked with writing clear, concise...

[API_KEYS]
openai = your_openai_api_key
anthropic = your_anthropic_api_key
google = your_google_api_key
aws =
aws_access_key_id = your_aws_access_key_id
aws_secret_access_key = your_aws_secret_access_key
aws_region = us-east-1
```

## Usage

### Basic Usage
```bash

# Generate a commit message for staged changes
ai-commit.py commit

# Include unstaged modifications
ai-commit.py commit --all

# Generate and automatically commit
ai-commit.py commit --commit

# Edit the message before committing
ai-commit.py commit --edit --commit

# Create a commit style template from previous commits
ai-commit.py mimic --count 20
```

### Command-line Options

| Option                | Description                                               |
| --------------------- | --------------------------------------------------------- |
| `--config PATH`       | Path to custom configuration file |
| `--provider PROVIDER` | LLM provider to use (openai, anthropic, google, bedrock) |
| `--model MODEL`       | Model to use for generating commit messages |
| `--temperature FLOAT` | Temperature for LLM generation (0.0-1.0) |
| `--commit`            | Automatically commit with the generated message |
| `--edit`              | Open the generated message in an editor before committing |
| `--all`               | Use all modified files instead of just staged |

## Examples

### Generate a commit message

```bash
$ ai-commit.py commit

Generated commit message:
--------------------------------------------------
feat(auth): implement JWT authentication

Add JWT token generation and validation for secure API access.
Includes token refresh mechanism and expiration handling.
--------------------------------------------------

To use this message, run:
git commit -m 'feat(auth): implement JWT authentication'
```

### Create a commit style template

```bash
$ ai-commit.py mimic --count 20
```

### Use a different provider and model

```bash
$ ai-commit.py commit --provider anthropic --model claude-3-opus

Generated commit message:
--------------------------------------------------
refactor(core): optimize database query performance

Reduce query execution time by 40% through index optimization
and connection pooling improvements.
--------------------------------------------------
```

## Customizing the System Prompt

You can customize the system prompt in the configuration file to guide the LLM in generating commit messages that match your team's style and conventions.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
