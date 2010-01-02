local MWidget = require("MWidget")

local Instance = {
  GetOwner = nil,
  
  SetHandler = nil,
  ExecuteHandler = nil,
  
  ContainsPoint = nil,
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

function Instance:SetHandler(event_type, func)
  self.handlers[event_type] = func
end

function Instance:ExecuteHandler(event_type, event)
  print(event_type)
  local handler = self.handlers[event_type]
  if not handler then return false end
  
  handler(self, event, event_type)
end

function Instance:ContainsPoint(x, y)
  return (x >= self.left and x < self.right and
          y >= self.top and y < self.bottom)
end

MWidget.Hotspot = Hotspot
return Hotspot
