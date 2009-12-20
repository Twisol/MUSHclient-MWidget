local MWidget = require("MWidget")

local Instance = {
  SetHandler = nil,
  ExecuteHandler = nil,
}

local Hotspot = {
  __index = Instance,
  
  base_handlers = nil,
  
  new = nil,
}
setmetatable(Hotspot, Hotspot)

function Hotspot.new(name)
  local o = setmetatable({}, Hotspot)
  
  o.name = name
  o.handlers = {}
  
  return o
end

function Instance:SetHandler(handler_type, func)
  self.handlers[handler_type] = func
end

function Instance:ExecuteHandler(view, widget, handler_type, flags)
  local handler = self.handlers[handler_type]
  if not handler then return false end
  
  handler(view, widget, self, flags or 0)
  return true
end

MWidget.Hotspot = Hotspot
return Hotspot
