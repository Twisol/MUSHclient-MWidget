local Core = {
  CheckType = function(widget, class)
    local widget_type = getmetatable(widget).__index
    local meta = class.__index
    while widget_type ~= nil do
      if meta == widget_type then
        return true
      end
      widget_type = widget_type.__index
    end
    return false
  end,
}

return Core
