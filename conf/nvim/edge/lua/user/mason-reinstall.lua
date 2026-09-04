local log = require "plenary.log"
local registry_ok, registry = pcall(require, "mason-registry")
local M = {}

local function warn_unavailable()
  vim.notify(
    "mason-registry is not available (mason.nvim isn't loaded"
      .. (vim.g.nvim_minimal and "; NVIM_MINIMAL=1 is set" or "")
      .. ")",
    vim.log.levels.WARN,
    { title = "mason-reinstall" }
  )
end

local function packages_failed_from_log()
  local log_path = vim.fn.stdpath "state" .. "/mason.log"
  local ok, log_lines = pcall(vim.fn.readfile, log_path)
  log_lines = ok and log_lines or {}

  local failed = {}
  for _, line in ipairs(log_lines) do
    if
      line:find "Installation failed for"
      or line:find "Lockfile exists"
      or line:find "Lockfile already exists"
    then
      local name = line:match "Package%(name=([%w%._%-%+]+)%)"
      if name then
        failed[name] = true
      end
    end
  end
  return failed
end

--- @param pkg mason-core.Package
--- @param name string
--- @param on_done fun(status: "installed"|"failed")
local function try_install(pkg, name, on_done)
  local install_ok, err = pcall(function()
    pkg:install({ force = true }, function(success, result)
      if success then
        on_done "installed"
      else
        log.error("Failed to install <" .. name .. ">: " .. tostring(result))
        on_done "failed"
      end
    end)
  end)
  if not install_ok then
    log.error("Failed to start install for <" .. name .. ">: " .. tostring(err))
    on_done "failed"
  end
end

--- @param name string
--- @param skip_if_installed boolean
--- @param on_done fun(status: "installed"|"skipped"|"failed"|"missing")
local function install_package(name, skip_if_installed, on_done)
  local ok, pkg = pcall(registry.get_package, name)
  if not ok or not pkg then
    log.error("<" .. name .. "> does not exist")
    on_done "missing"
    return
  end
  if skip_if_installed and pkg:is_installed() then
    on_done "skipped"
    return
  end
  try_install(pkg, name, on_done)
end

--- @param names string[]
--- @param skip_if_installed boolean
--- @param callback? fun(summary: table)
--- @return table summary
local function install_names(names, skip_if_installed, callback)
  local summary = { total = #names, installed = 0, skipped = 0, failed = 0, missing = 0 }
  if not registry_ok then
    warn_unavailable()
    summary.missing = #names
    if callback then
      callback(summary)
    end
    return summary
  end
  if #names == 0 then
    if callback then
      callback(summary)
    end
    return summary
  end

  local remaining = #names
  local function on_done(status)
    summary[status] = summary[status] + 1
    remaining = remaining - 1
    if remaining == 0 and callback then
      callback(summary)
    end
  end

  for _, name in ipairs(names) do
    install_package(name, skip_if_installed, on_done)
  end
  return summary
end

--- Installs (skipping already-installed) packages listed one per line in
--- `file_path`. Blank lines and lines starting with `#` are ignored; only
--- the first whitespace-separated token on a line is used as the package
--- name (a trailing token is treated as a human-readable alias and dropped).
--- @param file_path string
--- @param callback? fun(summary: table)
--- @return table summary
function M.install_from_file(file_path, callback)
  local ok, lines = pcall(vim.fn.readfile, file_path)
  if not ok then
    log.error("Could not read file: " .. file_path)
    local summary = { total = 0, installed = 0, skipped = 0, failed = 0, missing = 0 }
    if callback then
      callback(summary)
    end
    return summary
  end

  local names = {}
  for _, line in ipairs(lines) do
    local trimmed = vim.trim(line)
    if trimmed ~= "" and not vim.startswith(trimmed, "#") then
      table.insert(names, trimmed:match "^(%S+)")
    end
  end

  return install_names(names, true, callback)
end

--- Reinstalls only the packages that mason.log recorded as having failed
--- (a generic install failure or a lockfile conflict) and that are still
--- not installed now. Bound to :MasonReinstall.
--- @param callback? fun(summary: table)
--- @return table summary
function M.reinstall_from_logfile(callback)
  local failed_pkgs = packages_failed_from_log()
  local names = vim.tbl_keys(failed_pkgs)
  return install_names(names, true, function(summary)
    if summary.installed == 0 then
      log.info "No packages to reinstall"
    end
    if callback then
      callback(summary)
    end
  end)
end

--- Installs whatever from $EVANGELIST/mason-packages.txt isn't installed
--- yet. Already-installed packages are left alone.
--- @param callback? fun(summary: table)
--- @return table summary
function M.reinstall_from_evnfile(callback)
  local file_path = os.getenv "EVANGELIST" .. "/mason-packages.txt"
  return M.install_from_file(file_path, callback)
end

--- Force reinstalls one named package regardless of its current state.
--- @param name string
--- @param callback? fun(summary: table)
--- @return table summary
function M.force_reinstall_package(name, callback)
  return install_names({ name }, false, callback)
end

return M
