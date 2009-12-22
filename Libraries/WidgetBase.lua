local MWidget = require("MWidget")
local Canvas = require("MWidget.Libraries.Canvas")
local Hotspot = require("MWidget.Libraries.Hotspot")
local View = require("MWidget.Libraries.View")

local Instance = {
  AddHotspot = nil,
  
  Invalidate = nil,
  Refresh = nil,
  GetView = nil,
  
  Destroy = nil,
}

local WidgetBase = {
  __index = Instance,
  
  new = nil,
}
setmetatable(WidgetBase, WidgetBase)

function WidgetBase.new(width, height)
  o = setmetatable({}, WidgetBase)
  
  o.width = width or 1
  o.height = height or 1
  o.canvas = Canvas.new(o.width, o.height)
  o.invalidated = true
  
  o.children = {}
  o.hotspots = {}
  
  return o
end

function Instance:AddChild(widget, x, y, name)
  table.insert(self.children, {
    widget = widget,
    x = x,
    y = y,
  })
end

function Instance:AddHotspot(name, left, top, right, bottom)
  local hotspot = self.hotspots[name]
  
  if not hotspot then
    hotspot = Hotspot.new(name, left, top, right, bottom)
    
    table.insert(self.hotspots, hotspot)
    self.hotspots[name] = hotspot
  else
    hotspot.left = left
    hotspot.top = top
    hotspot.right = right
    hotspot.bottom = bottom
  end
  
  return hotspot
end

function Instance:GetHotspot(name)
  return self.hotspots[name]
end

function Instance:Invalidate()
  self.invalidated = true
end

function Instance:InternalRender()
  -- track whether this widget was updated
  local updated = self.invalidated
  
  -- run through each child to ensure it is up to date.
  for _,record in ipairs(self.children) do
    updated = updated or record.widget:InternalRender()
  end
  
  if updated then
    self:OnPaint()
    self.invalidated = false
  end
  
  return updated
end

function Instance:OnPaint()
  -- Override this in derived widgets.
end

function Instance:GetView(x, y)
  return View.new(self, x or 0, y or 0)
end

function Instance:Destroy()
  return self.canvas:Destroy()
end

MWidget.WidgetBase = WidgetBase
return WidgetBase