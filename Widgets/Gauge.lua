local base = require("MWidget.Libraries.WidgetBase")

local Instance = {
  __index = base.__index,
  
  OnPaint = nil,
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
    
    gauge.canvas:WindowRectOp(2, 0, 0, right, gauge.height, color)
  end
end

function Gauge.effects.scaledgrad(leftcolor, rightcolor)
  return function(gauge)
    local right = gauge.width * gauge.value/100
    
    gauge.canvas:DrawGradient(0, 0, right, gauge.height, leftcolor, rightcolor, 1)
  end
end

function Gauge.effects.meter(leftcolor, rightcolor)
  return function(gauge)
    local val_pixel = gauge.width * gauge.value/100
    
    gauge.canvas:WindowRectOp(2, 0, 0, val_pixel-1, gauge.height, leftcolor)
    gauge.canvas:WindowRectOp(2, val_pixel+1, 0, gauge.width, gauge.height, rightcolor)
  end
end

function Gauge.new(width, height)
  local o = base.new(width, height)
  setmetatable(o, Gauge)
  
  o:Value(100)
  o:SetEffect(Gauge.effects.solid, 0xFF0000)
  
  return o
end

function Instance:OnPaint()
  self.canvas:Clear()
  if self.value > 0 and self.effect then
    self.effect(self)
  end
end

function Instance:SetEffect(effect, ...)
  self.effect = effect(...)
  
  self:Invalidate()
end

function Instance:Value(value)
  if value > 100 then
    value = 100
  elseif value < 0 then
    value = 0
  end
  
  self.value = value
  
  self:Invalidate()
end

MWidget.Gauge = Gauge
return Gauge