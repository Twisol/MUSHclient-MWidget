local MWidget = require("MWidget")
local Canvas = require("MWidget.Libraries.Canvas")
local HAL = require("MWidget.Libraries.HotspotAbstractionlayer")

--- A list of all MWidget-owned views.
-- It is used to resolve hotspot events to the proper handlers.
local views = {}

--- The methods shared by all View instances.
local Instance = {
  __index = Canvas,
  
  Show = nil,
  Hide = nil,
  IsShown = nil,
  
  Move = nil,
  Anchor = nil,
  GetPosition = nil,
  
  GetChild = nil,
  
  Destroy = nil,
}
setmetatable(Instance, Instance)

--- The base 'class' table for the View widget type.
local View = {
  __index = Instance,
  
  new = nil,
  List = nil,
  FromName = nil,
}
setmetatable(View, View)


function View.new(child, x, y)
  local o = Canvas.new(child.width, child.height)
  setmetatable(o, View)
  
  o.child = child
  o.hal = HAL.new(o)
  
  o:Move(x or 0, y or 0)
  o:Refresh()
  o:Hide()
  
  views[o.name] = o
  return o
end

function View.List()
  local list = {}
  for k,v in pairs(views) do
    list[k] = v
  end
  return list
end

function View.FromName(name)
  return views[name]
end

local function resize_view(self, width, height)
  self.width = width
  self.height = height
  
  check(WindowCreate(self.name, self.x, self.y, self.width, self.height,
     self.anchor, (self.anchor == -1) and 2 or 0, 0x000000))
  self.hal = HAL.new(self)
  
  self:DrawImage("view", {0, 0, 0, 0}, {}, 2)
  self:Show()
end


function Instance:Show()
  WindowShow(self.name, true)
end

function Instance:Hide()
  WindowShow(self.name, false)
end

function Instance:IsShown()
  return WindowInfo(self.name, 5)
end

function Instance:Refresh()
  -- * Recursively render child widgets to obtain a final canvas.
  self.child:InternalRender(self.name)
  
  -- * Resize the window if necessary.
  if self.width ~= self.child.width or
     self.height ~= self.child.height then
    resize_view(self, self.child.width, self.child.height)
  end
  
  -- * Draw final canvas to screen.
  self:CreateImageFromWidget("view", self.child)
  self:DrawImage("view", {0, 0, 0, 0}, {}, 2)
  
  -- * Show the view in order to refresh and display it.
  self:Show()
end

function Instance:Move(x, y)
  self.x = x
  self.y = y
  self.anchor = -1
  
  WindowPosition(self.name, x, y, -1, 2)
end

function Instance:Anchor(anchor)
  self.x = -1
  self.y = -1
  self.anchor = anchor
  
  WindowPosition(self.name, -1, -1, anchor, 0)
end

function Instance:GetPosition()
  if self.anchor == -1 then
    return self.x, self.y, self.anchor
  else
    return WindowInfo(self.name, 10), WindowInfo(self.name, 11), self.anchor
  end
end

function Instance:GetChild()
  return self.child
end

function Instance:Destroy()
  Canvas.Destroy(self)
  views[self.name] = nil
end


MWidget.View = View
return View
