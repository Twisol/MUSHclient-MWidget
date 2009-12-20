--- A running count of the number of miniwindows created by MWidget.
-- It is used to ensure that window names are unique.
local num_windows = 0

--- A list of all MWidget-owned canvases.
-- It is used to resolve hotspot events to the proper handlers.
local windows = {}

local Methods = {
  --[[
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
  --]]
  
  RegisterWindow = nil,
  UnregisterWindow = nil,
  
  GetUniqueName = nil,
  GetWindowByName = nil,
  
  Load = nil,
}

-- Global MWidget table - do not rename!
MWidget = {
  Widgets = {}
}
setmetatable(MWidget, {__index = Methods})


function Methods.GetUniqueName()
  num_windows = num_windows + 1
  return "w" .. num_windows .. "_" .. GetPluginID()
end

function Methods.RegisterWindow(name, window)
  windows[name] = window
end

function Methods.UnregisterWindow(name)
  windows[name] = nil
end

function Methods.GetWindowByName(name)
  return windows[name]
end

function Methods.Load(name)
  local widget = require("MWidget.Widgets." .. name)
  MWidget.Widgets[name] = widget
  return widget
end

return MWidget
