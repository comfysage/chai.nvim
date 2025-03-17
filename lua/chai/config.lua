local M = {}

---@type chai.config
M.default = {
  custom_module = 'custom',
  log_level = vim.log.levels.INFO,
}

---@type chai.config
---@diagnostic disable-next-line: missing-fields
M.config = {}

---@return chai.config
function M.get()
  return vim.tbl_deep_extend('force', M.default, M.config)
end

---@param cfg chai.config
---@return chai.config
function M.override(cfg)
  return vim.tbl_deep_extend('force', M.default, cfg)
end

---@param cfg chai.config
function M.set(cfg)
  M.config = cfg
end

return M
