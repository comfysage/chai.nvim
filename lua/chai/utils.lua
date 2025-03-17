local utils = {}

---@class chai.opts.find_mod
---@field all? boolean return all matches instead of just the first one (defaults to `false`)
---@field rtp? boolean search for modname in the runtime path (defaults to `true`)
---@field paths? string[] extra paths to search for modname (defaults to `{}`)
---@field patterns string[] List of patterns to use when searching for modules. A pattern is a string added to the basename of the Lua module being searched. (defaults to `{"/init.lua", ".lua"}`)

---@param modname string
---@param opts? chai.opts.find_mod
---@return string[] modpaths
function utils.find_mod(modname, opts)
  opts = opts or {}
  opts.rtp = opts.rtp == nil or opts.rtp

  modname = modname:gsub('/', '.')
  local basename = modname:gsub('%.', '/')
  local idx = modname:find('.', 1, true)

  -- NOTE: fix incorrect require statements
  if idx == 1 then
    modname = modname:gsub('^%.+', '')
    basename = modname:gsub('%.', '/')
    idx = modname:find('.', 1, true)
  end

  local topmod = idx and modname:sub(1, idx - 1) or modname
  local patterns = opts.patterns
    or (
      topmod == modname and { '/init.lua', '.lua' } or { '.lua', '/init.lua' }
    )
  patterns = vim
    .iter(ipairs(patterns))
    :map(function(_, pat)
      return '/lua/' .. basename .. pat
    end)
    :totable()

  local paths =
    utils.table_concat((opts.rtp and vim.opt.rtp:get() or {}), opts.paths)

  -- only continue if we haven't found anything yet or we want to find all
  ---@private
  local function continue(results)
    return #results == 0 or opts.all
  end

  return vim.iter(ipairs(paths)):fold({}, function(prev, _, path)
    if not continue(prev) then
      return prev
    end
    local results = vim
      .iter(ipairs(patterns))
      :fold({}, function(inpath, _, pattern)
        if not continue(inpath) then
          return inpath
        end
        local modpath = path .. pattern
        if vim.uv.fs_stat(modpath) then
          table.insert(inpath, modpath)
        end
        return inpath
      end)
    return utils.table_concat(prev, results)
  end)
end

---@generic T
---@vararg T[]
---@return T[]
function utils.table_concat(...)
  local props = { ... }
  return vim.iter(ipairs(props)):fold({}, function(acc, _, t)
    vim.iter(ipairs(t)):each(function(_, v)
      table.insert(acc, v)
    end)
    return acc
  end)
end

return utils
