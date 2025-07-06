-- JK's NvChad Configuration
-- Based on NvChad 2.5+ starter configuration
-- Optimized for development workflow

vim.g.base46_cache = vim.fn.stdpath "data" .. "/nvchad/base46/"
vim.g.mapleader = " "

-- Bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- Load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    priority = 1000,
    branch = "v2.5",
    import = "nvchad.plugins",
    config = function()
      require "nvchad"
    end,
  },

  { import = "plugins" },
}, lazy_config)

-- Load NvChad core (with safety checks)
local function safe_dofile(file)
  if vim.fn.filereadable(file) == 1 then
    dofile(file)
  end
end

safe_dofile(vim.g.base46_cache .. "defaults")
safe_dofile(vim.g.base46_cache .. "statusline")

-- Load custom chadrc configuration
require "chadrc"

-- ============================================================================
-- AUTO-RELOAD CONFIGURATION (Live File Updates)
-- ============================================================================

-- Enable automatic reading of files when they change externally
vim.o.autoread = true

-- Set shorter update time for more responsive file checking (default is 4000ms)
vim.o.updatetime = 1000

-- Create autocommands for automatic file reloading
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
  desc = "Auto-reload files when focus gained or buffer entered",
  command = "checktime",
  pattern = "*",
})

-- Optional: Also check on cursor hold for more frequent updates
vim.api.nvim_create_autocmd("CursorHold", {
  desc = "Auto-reload files on cursor hold",
  command = "checktime",
  pattern = "*",
})