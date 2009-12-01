local base = require("MWidget.Window")

local Instance = {
  __index = base.__index,
  
  Draw = nil,
  SetEffect = nil,
  Value = nil,
}
setmetatable(Instance, Instance)

local Gauge = {
  __index = Instance,
  
  new = nil,
  effects = {}
}
setmetatable(Gauge, Gauge)

function Gauge.effects.solid(color)
  return function(gauge)
    local right = gauge.width * gauge.value/100
    
    WindowRectOp(gauge.name, 2, 0, 0, right, gauge.height, color)
  end
end

function Gauge.effects.scaledgrad(leftcolor, rightcolor)
  return function(gauge)
    local right = gauge.width * gauge.value/100
    
    WindowGradient(gauge.name, 0, 0, right, gauge.height, leftcolor, rightcolor, 1)
  end
end

function Gauge.effects.meter(leftcolor, rightcolor)
  return function(gauge)
    local val_pixel = gauge.width * gauge.value/100
    
    WindowRectOp(gauge.name, 2, 0, 0, val_pixel-1, gauge.height, leftcolor)
    WindowRectOp(gauge.name, 2, val_pixel+1, 0, gauge.width, gauge.height, rightcolor)
  end
end

function Gauge.new(width, height)
  local o = base.new(width, height)
  setmetatable(o, Gauge)
  
  o.value = 100
  
  o:SetEffect(Gauge.effects.solid, 0xFF0000)
  
  return o
end

function Instance:Draw()
  base.Draw(self)
  if self.value > 0 and self.effect then
	  self.effect(self)
  end
end

function Instance:SetEffect(effect, ...)
  self.effect = effect(...)
end

function Instance:Value(value)
  if value > 100 then
    value = 100
  elseif value < 0 then
    value = 0
  end
  
  self.value = value
end

MWidget.Gauge = Gauge
return Gauge