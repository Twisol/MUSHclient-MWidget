local base = require("MWidget\\Window")

local Instance = {
  __index = base.__index,
  
  Draw = function(self)
    base.Draw(self, 0, 6, self.backcolor)
	WindowRectOp (self.name, 2, 1,  1,
	   (self.width*self.value/100)-1, self.height-1,
	   self.forecolor)
  end,
}
setmetatable(Instance, Instance)

local Gauge = {
  __index = Instance,
  
  new = nil,
}
setmetatable(Gauge, Gauge)

Gauge.new = function(width, height)
  o = base.new()
  setmetatable(o, Gauge)
  
  o.width = width
  o.height = height
  
  o.backcolor = 0x0000FF
  o.forecolor = 0xFF0000
  
  o.value = 50
  
  return o
end

return Gauge