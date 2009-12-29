local MWidget = require("MWidget")

local Instance = {
  GetOwner = nil,
  
  SetHandler = nil,
  ExecuteHandler = nil,
}

local Hotspot = {
  __index = Instance,
  
  base_handlers = nil,
  
  new = nil,
}
setmetatable(Hotspot, Hotspot)

function Hotspot.new(name, owner, left, top, right, bottom)
  local o = setmetatable({}, Hotspot)
  
  o.name = name
  o.owner = owner
  
  o.left = left
  o.top = top
  o.right = right
  o.bottom = bottom
  
  o.handlers = {}
  
  return o
end

function Instance:GetOwner()
  return self.owner
end

function Instance:SetHandler(handler_type, func)
  self.handlers[handler_type] = func
end

function Instance:ExecuteHandler(handler_type, event)
  local handler = self.handlers[handler_type]
  if not handler then return false end
  
  handler(self, event, event_type)
  return true
end

MWidget.Hotspot = Hotspot
return Hotspot
