For Copilot CLI specifically:

- The converter intentionally does not manage Copilot CLI's local
  `~/.copilot/settings.json` or `~/.copilot/mcp-config.json`.
- Do not try to port Claude Code's `statusline.sh`; use Copilot CLI's
  native footer/status settings instead.
- Read `~/.copilot/settings.json` first if it exists. Parse it as JSON
  before changing anything. Merge, do not overwrite unrelated keys. If
  you change it, create `~/.copilot/settings.json.pre-evangelist.bak`
  first unless that backup already exists.
- Read `~/.copilot/mcp-config.json` first if it exists. Merge, do not
  overwrite, and preserve the top-level `mcpServers` object.
- Never hardcode tokens or secrets. If an MCP server needs credentials,
  only reuse values already present in the target file or explicitly
  provided by the user.
- Do not add GitHub's MCP server if the installed Copilot CLI already
  provides it by default.
