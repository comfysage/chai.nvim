local log = require 'chai.log'

local options = {}

---@class chai.option
---@field _type 'option'
---@field default any default value
---@field description string description
---@field validate type|fun(v?: any): boolean validator passed to vim.validate
---@field optional boolean

---@class chai.option.spec
---@field default any default value
---@field description string description
---@field validate type|fun(v?: any): boolean validator passed to vim.validate
---@field optional? boolean

---@class chai.option.params
---@field [1] any default value
---@field [2] string description
---@field [3] type|fun(v?: any): boolean validator passed to vim.validate

---@param opt chai.option.params|chai.option.spec
---@return chai.option
function options.makeopt(opt)
  if vim.islist(opt) then
    if #opt ~= 3 then
      log.error 'invalid option'
      return {}
    end

    return options.makeopt {
      default = opt[1],
      description = opt[2],
      validate = opt[3],
    }
  end

  if type(opt) ~= 'table' then
    log.error 'invalid option'
    return {}
  end

  vim.validate('description', opt.description, 'string')
  vim.validate('validator', opt.validate, { 'string', 'callable' })
  vim.validate('optional', opt.optional, 'boolean', true)
  vim.validate('default', opt.default, function(v)
    if opt.optional then
      return true
    end
    return v ~= nil
  end)

  return vim.tbl_extend('keep', {
    _type = 'option',
  }, vim.tbl_extend('keep', opt, { optional = false }))
end

---@param name string
---@param opt chai.option
---@param value any
function options.validate(name, opt, value)
  vim.validate(
    name,
    value,
    opt.validate,
    opt.optional,
    ('(%s) invalid config option: %s'):format(name, vim.inspect(value))
  )
  return value
end

---@param opt chai.option
---@param value any
function options.parseoptionvalue(opt, value)
  if value ~= nil then
    return value
  end

  if opt.optional then
    return value
  end

  return opt.default
end

---@param name string
---@param opt chai.option|table
---@param value any
---@return any
function options.parseoptleaf(name, opt, value)
  vim.validate('option', opt, 'table')

  if opt._type and opt._type == 'option' then
    value = options.parseoptionvalue(opt, value)
    return options.validate(name, opt, value)
  end

  return options.parseoptions(name, opt, value)
end

---@param opts table options defined by the module
---@param attrs table values set by the user
---@return table returns table of parsed options
function options.parseoptions(name, opts, attrs)
  attrs = attrs or {}
  return vim.iter(pairs(opts)):fold({}, function(config, k, opt)
    config[k] =
      options.parseoptleaf(options.concatnames(name, k), opt, attrs[k])
    return config
  end)
end

---@param spec chai.module
---@return table?
function options.setup(spec)
  local opts = options.get_options(spec.name)
  if not opts then
    log.error(('(%s) could not get options for module'):format(spec.name))
    return
  end

  return options.parseoptions(spec.name, opts, spec.opts or {})
end

---@param modname string
---@return table?
function options.get_options(modname)
  local ok, result = pcall(require, modname)
  if not ok then
    log.error(('(%s) could not load module\n\t%s'):format(modname, result))
    return
  end

  if type(result) == 'table' then
    return result.options or {}
  end

  return {}
end

---@param ... string
function options.concatnames(...)
  return table.concat({ ... }, '.')
end

return options
