local log = require "plenary.log"
local registry = require "mason-registry"
local M = {}

-- @param file_path string: path with mason packages to install
-- @return nil
local function install_from_file(file_path)
  local file = io.open(file_path, "r")
  if not file then
    log.error("File not found: " .. file_path)
    return
  end

  for line in file:lines() do
    local package_name = vim.trim(line)
    if package_name ~= "" then
      local ok, pkg = pcall(registry.get_package, package_name)
      if ok and pkg then
        if not pkg:is_installed() then
          log.info("Installing " .. package_name)
          pkg:install { force = true }
        end
      end
      if not ok then
        log.error("<" .. package_name .. "> does not exist")
      end
    end
  end

  file:close()
end

function M.evn_force_reinstall()
  local file_path = os.getenv "EVANGELIST" .. "/mason-packages.txt"
  install_from_file(file_path)
end

local function external_evn_force_reinstall()
  require("mason").setup()
  M.evn_force_reinstall()
end

return M
