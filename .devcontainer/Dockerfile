FROM mcr.microsoft.com/devcontainers/base:ubuntu

USER vscode

# Claude CLI (the agent that operates in this container)
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/vscode/.local/bin:${PATH}"

# Persist auth + config between runs: consolidate ALL Claude state (.claude.json,
# .credentials.json, sessions) under ~/.claude, which docker-compose bind-mounts
# to the host. Without this, .claude.json lives at ~/.claude.json (unmounted) and
# is lost on `--rm`, forcing a re-login every run.
ENV CLAUDE_CONFIG_DIR=/home/vscode/.claude
