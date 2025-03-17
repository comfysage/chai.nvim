---@class chai.config
---@field custom_module 'custom'|string
---@field log_level vim.log.levels

---@class chai.module.spec
---@field [1] string
---@field name? string
---@field enabled? boolean
---@field event? string
---@field opts? table

---@class chai.module
---@field name string
---@field enabled boolean
---@field event string
---@field opts table
---@field loaded boolean
