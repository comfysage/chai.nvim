local config = require 'chai.config'

local M = {}

---@param cfg? chai.config
function M.setup(cfg)
  cfg = cfg or {}

  config.set(config.override(cfg))
end

return M
