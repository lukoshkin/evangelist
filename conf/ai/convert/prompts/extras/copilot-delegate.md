For Copilot CLI specifically:

- Do not try to reuse Claude Code's `statusline.sh` or Claude
  `settings.json`. Copilot CLI uses its own native footer/status settings
  in `~/.copilot/settings.json`.
- Read `~/.copilot/settings.json` first if it exists. Parse it as JSON
  before changing anything. Merge, do not overwrite unrelated keys. If
  you change it, create `~/.copilot/settings.json.pre-evangelist.bak`
  first unless that backup already exists.
- Configure Copilot CLI's footer/status display in its native format
  after checking the installed version's current schema. Prefer
  preserving existing user choices; only add the missing footer/status
  block if it is absent.
- Read `~/.copilot/mcp-config.json` first if it exists. Merge, do not
  overwrite, and preserve the top-level `mcpServers` object.
- Never hardcode tokens or secrets. If an MCP server needs credentials,
  only reuse values already present in the target file or explicitly
  provided by the user.
- Do not add GitHub's MCP server if the installed Copilot CLI already
  provides it by default.
