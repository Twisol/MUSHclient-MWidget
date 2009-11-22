local MWidget = {
  CheckType = function(self, type)
    local self_type = getmetatable(self).__index
    local meta = type.__index
    while self_type ~= nil do
      if meta == self_type then
        return true
      end
      self_type = self_type.__index
    end
    return false
  end
}

return MWidget