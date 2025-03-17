local log = require 'chai.log'
local utils = require 'chai.utils'
local config = require 'chai.config'
local autocmds = require 'chai.autocmds'

---@class chai.parts
---@field modules table<chai.module>

---@class chai.proto.parts
---@field __index chai.proto.parts
---@field value chai.parts
---@field specs table<chai.module.spec>
---@field augroup integer

---@type chai.proto.parts
---@diagnostic disable-next-line: missing-fields
local parts = {}
parts.__index = parts

---@class chai.proto.parts
---@field new fun(self, cfg: table<chai.module.spec>): chai.proto.parts
function parts:new(cfg)
  return setmetatable({
    value = {},
    specs = cfg or {},
    augroup = vim.api.nvim_create_augroup('chai.parts', { clear = true }),
  }, self)
end

---@class chai.proto.parts
---@field setup fun(self)
function parts:setup()
  self:load_config()

  vim.schedule(function()
    autocmds.start 'ChaiLazy'
    autocmds.start 'ChaiLoad'
  end)

  vim.iter(pairs(self.value.modules)):each(function(_, mod)
    autocmds.create {
      event = ':ChaiLazy',
      priority = mod.priority or nil,
      desc = ('chailazy:%s'):format(mod.name),
      fn = function()
        self:lazy_load(mod)
      end,
    }
  end)
end

---@class chai.proto.parts
---@field parsemodulespec fun(self, spec: chai.module.spec): chai.module
function parts:parsemodulespec(spec)
  spec.name = spec.name or spec[1]
  log.debug('(chai.parts) configurating ' .. spec.name .. ' module.')
  if spec.opts and type(spec.opts) == 'string' then
    ---@diagnostic disable-next-line: param-type-mismatch
    spec.opts = require(spec.opts)
  end
  spec.opts = require('chai.options').setup(spec) or {}
  spec.event = spec.event or ':ChaiLoad'

  return spec
end

---@class chai.proto.parts
---@field load_config fun(self)
function parts:load_config()
  self.value.modules = vim
    .iter(ipairs(self.specs))
    :map(function(_, spec)
      return self:parsemodulespec(spec)
    end)
    :totable()
end

---@class chai.proto.parts
---@field lazy_load fun(self, mod: chai.module)
function parts:lazy_load(mod)
  self:load(mod)
  self:create_reload(mod)
end

---@class chai.proto.parts
---@field create_reload fun(self, mod: chai.module)
function parts:create_reload(mod)
  local filepath = utils.find_mod(mod.name)
  if not filepath then
    return log.error(('could not find filepath for %s'):format(mod.name))
  end
  vim.api.nvim_create_autocmd('BufWritePost', {
    callback = function(props)
      log.debug(('reloading module (%s) from %s'):format(mod.name, props.file))
      package.loaded[mod.name] = nil
      self:load(mod)
    end,
    group = autocmds.augroup,
    pattern = filepath,
    desc = 'config:reload:' .. mod.name,
  })
end

---@class chai.proto.parts
---@field load fun(self, mod: chai.module)
function parts:load(mod)
  if mod.enabled == false then
    return log.debug(
      '(chai.parts) skipping loading disabled module: ' .. mod.name
    )
  end

  autocmds.create {
    event = mod.event,
    desc = ('trigger setup for %s'):format(mod.name),
    fn = function()
      local status, result = pcall(require, mod.name)
      if not status then
        log.error(
          '(chai.parts) failed to load ' .. mod.name .. '\n\t' .. result
        )
      end
      if type(result) ~= 'table' or not result.setup then
        return
      end
      if not type(mod.opts) == 'table' then
        return
      end
      result.setup(mod.opts)
    end,
  }
end

---@class chai.proto.parts
---@field platform fun(self)
function parts:platform()
  local is_mac = vim.fn.has 'mac' == 1
  local is_win = vim.fn.has 'win32' == 1
  local is_neovide = vim.g.neovide ~= nil

  local custom_module = config.get().custom_module

  local modname = nil

  if is_mac then
    modname = custom_module .. '.macos'
  elseif is_win then
    modname = custom_module .. '.win'
  end
  if is_neovide then
    modname = custom_module .. '.neovide'
  end

  if not modname then
    return
  end

  local ok, result = pcall(require, modname)
  if not ok then
    log.warn(('error while loading module `%s`:\n\t%s'):format(modname, result))
  end
end

return parts
