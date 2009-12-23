local MWidget = require("MWidget")
local Canvas = require("MWidget.Libraries.Canvas")
local Hotspot = require("MWidget.Libraries.Hotspot")
local View = require("MWidget.Libraries.View")

local Instance = {
  GetCanvasID = nil,
  GetView = nil,
  
  AddHotspot = nil,
  
  Invalidate = nil,
  Refresh = nil,
  
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
  o.invalidated = {}
  
  o.children = {}
  o.hotspots = {}
  
  return o
end

function Instance:GetCanvasID()
  return self.canvas.name
end

function Instance:GetView(x, y)
  return View.new(self, x or 0, y or 0)
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
  for k,_ in pairs(self.invalidated) do
    self.invalidated[k] = true
  end
end

function Instance:InternalRender(view_id)
  -- track whether this widget was invalidated
  local updated = self.invalidated[view_id] or true
  
  -- run through each child to ensure it is up to date.
  for _,record in ipairs(self.children) do
    local child_updated = WidgetBase.InternalRender(record.widget)
    
    -- if this child was updated, save its image
    if child_updated then
      self.canvas:CreateImageFromWidget(record.widget:GetCanvasID(), record.widget)
    end
    
    -- keep track of whether any children were updated at all
    updated = updated or child_updated
  end
  
  -- if this widget or any of its children was updated, repaint the canvas
  if updated then
    self:OnPaint()
    self.invalidated[view_id] = false
  end
  
  return updated
end

function Instance:OnPaint()
  -- Override this in derived widgets.
end

function Instance:Destroy()
  return self.canvas:Destroy()
end

MWidget.WidgetBase = WidgetBase
return WidgetBase