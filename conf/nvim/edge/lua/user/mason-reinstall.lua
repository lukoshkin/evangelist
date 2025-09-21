local log = require "plenary.log"
local registry = require "mason-registry"
local M = {}

local function packages_failed_due_to_lock()
  local log_path = vim.fn.stdpath "state" .. "/mason.log"
  local ok, log_lines = pcall(vim.fn.readfile, log_path)
  log_lines = ok and log_lines or {}

  local failed = {}
  for _, line in ipairs(log_lines) do
    if line:find "Lockfile exists" or line:find "Lockfile already exists" then
      local name = line:match "Package%(name=([%w%._%-%+]+)%)"
      local lock_path = ("%s/mason/staging/%s.lock"):format(
        vim.fn.stdpath "data",
        name
      )
      if vim.uv.fs_stat(lock_path) then
        failed[name] = true
      end
    end
  end
  return failed
end

function M.install_from_file(file_path)
  local ok, lines = pcall(vim.fn.readfile, file_path)
  if not ok then
    log.error("Could not read file: " .. file_path)
    return
  end

  for line in lines do
    local package_name = vim.trim(line)
    if package_name ~= "" then
      local ok, pkg = pcall(registry.get_package, package_name)
      if ok and pkg then
        pkg:install { force = true }
      end
      if not ok then
        log.error("<" .. package_name .. "> does not exist")
      end
    end
  end
end

function M.reinstall_from_logfile()
  local failed_pkgs = packages_failed_due_to_lock()
  if vim.tbl_isempty(failed_pkgs) then
    log.info "No packages to reinstall"
    return
  end

  for name, _ in pairs(failed_pkgs) do
    local ok, pkg = pcall(registry.get_package, name)
    if ok and pkg then
      pkg:install { force = true }
    end
    if not ok then
      log.error("<" .. name .. "> does not exist")
    end
  end
end

function M.reinstall_from_evnfile()
  local file_path = os.getenv "EVANGELIST" .. "/mason-packages.txt"
  M.install_from_file(file_path)
end

return M
