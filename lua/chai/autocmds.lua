local log = require 'chai.log'

---@class chai.params.handle
---@field event string|':custom' ':CustomEvent' -> User CustomEvent
---@field fn fun(ev: vim.api.keyset.create_autocmd.callback_args)
---@field priority? integer
---@field desc? string

local autocmds = {}

---@alias ch.types.global.handle table<string, chai.params.handle[][]>
---@type ch.types.global.handle
autocmds.handles = {}
autocmds.augroup =
  vim.api.nvim_create_augroup('chai.autocmds', { clear = false })

---@param event string ':CustomEvent' -> User CustomEvent
function autocmds.setup(event)
  autocmds.handles[event] = autocmds.handles[event] or {}
  local tag = nil
  if event:sub(1,1) == ':' then
    tag = event:sub(2, -1)
  end
  vim.api.nvim_create_autocmd(tag and 'User' or event, {
    group = autocmds.augroup,
    desc = ('(%s) chai handle'):format(event),
    pattern = tag,
    callback = function(opts)
      -- loop over priorities of current event
      vim
        .iter(pairs(autocmds.handles[event]))
        :each(function(priority_i, priority_t)
          log.debug(
            ('(autocmds.callback) %s with priority: %d'):format(event, priority_i)
          )
          -- loop over handles of current priority
          vim.iter(ipairs(priority_t)):each(function(_, handle)
            handle.fn(opts)
          end)
        end)
    end,
  })
end

--- ```lua
--- autocmds.create {
---   event = 'ColorScheme', priority = 0,
---   fn = function() ch.log 'hi' end,
--- }
--- autocmds.create {
---   event = ':Custom', priority = 0,
---   fn = function() ch.log 'hi' end,
--- }
--- ```
---@param props chai.params.handle
function autocmds.create(props)
  if not props.event or not props.fn then
    return
  end

  local priority = props.priority or 50

  if not autocmds.handles[props.event] then
    autocmds.setup(props.event)
  end

  autocmds.add(props.event, priority, props)
end

---@param event string
---@param priority integer
---@param props chai.params.handle
function autocmds.add(event, priority, props)
  autocmds.handles[event][priority] = autocmds.handles[event][priority] or {}
  local next = #autocmds.handles[event][priority] + 1
  autocmds.handles[event][priority][next] = props
end

-- start custom User event with event
function autocmds.start(event)
  log.debug(string.format('(autocmds) start %s', event))
  vim.api.nvim_exec_autocmds('User', { pattern = event })
end

return autocmds
