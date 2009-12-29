local MWidget = require("MWidget")
local Canvas = require("MWidget.Libraries.Canvas")

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
  
  hotspot_handlers = nil,
  
  new = nil,
  List = nil,
  FromName = nil,
}
setmetatable(View, View)


local function init_hotspots(self)
  check(WindowAddHotspot(self.name, self.name, 0, 0, 0, 0,
     "MWidget.View.hotspot_handlers.mouseover",
     "MWidget.View.hotspot_handlers.cancelmouseover",
     "MWidget.View.hotspot_handlers.mousedown",
     "MWidget.View.hotspot_handlers.cancelmousedown",
     "MWidget.View.hotspot_handlers.mouseup",
     nil, 0, 1)) -- pixel-sensitive
  check(WindowDragHandler(self.name, self.name,
     "MWidget.View.hotspot_handlers.dragmove",
     "MWidget.View.hotspot_handlers.dragrelease",
     0))
end


function View.new(child, x, y)
  local o = Canvas.new(child.width, child.height)
  setmetatable(o, View)
  
  o.child = child
  
  init_hotspots(o)
  
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
    self:Resize(self.child.width, self.child.height)
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
  if self.position.anchor == -1 then
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


local function new_mouse_event(view, x, y, flags)
  return {
    view = view,
    
    widget_x = x,
    widget_y = y,
    output_x = view.x + x,
    output_y = view.y + y,
    
    shift_key = bit.band(flags, 0x01) ~= 0,
    ctrl_key = bit.band(flags, 0x02) ~= 0,
    alt_key = bit.band(flags, 0x04) ~= 0,
    lh_mouse = bit.band(flags, 0x10) ~= 0,
    rh_mouse = bit.band(flags, 0x20) ~= 0,
    
    -- possibly abstract into its own event
    doubleclick = bit.band(flags, 0x40) ~= 0,
  }
end

local function find_hotspot(widget, x, y)
  -- first look for matches in this widget
  for _,hotspot in ipairs(widget.hotspots) do
    -- cull hotspots that don't contain the point
    if hotspot.left <= x and hotspot.top <= y and
       hotspot.right > x and hotspot.bottom > y then
      return hotspot
    end
  end
  
  -- then move on to the children
  for _,record in ipairs(widget.children) do
    local child = record.widget
    local left, top = record.x, record.y
    local right, bottom = record.x + child.width, record.y + child.height
    
    -- cull widgets that don't contain the point
    if left <= x and top <= y and right > x and bottom > y then
      local hotspot = find_hotspot(record.widget, handler_type, x - left, y - top)
      if hotspot then
        return hotspot
      end
    end
  end
  
  -- no match
  return nil
end

--- Resolves mouse events to a matching hotspot
-- name: The hotspot's ID, which should match the name of a view.
-- x, y: The coordinates the mouse event originated from.
local function resolve_hotspot(name, x, y)
  -- * Get view object from hotspot name.
  local view = views[name]
  
  -- * Recurse through child widgets until a hotspot has been found.
  return find_hotspot(view.child, x, y)
end

--- Base handlers that forward events through execute_handler()
--  to the appropriate widget's hotspots
View.hotspot_handlers = {
  mouseover = function(flags, id)
    local view = views[id]
    
    local x, y = WindowInfo(id, 14), WindowInfo(id, 15)
    local hotspot = resolve_hotspot(id, x, y)
    
    if hotspot ~= view.hotspot_over then
      -- first send a cancelmouseover to the old hotspot
      if view.hotspot_over ~= nil then
        view.hotspot_over:ExecuteHandler("cancelmouseover", new_mouse_event(view, x, y, flags))
      end
      
      -- then send a mouseover to the new hotspot
      if hotspot ~= nil then
        hotspot:ExecuteHandler("mouseover", new_mouse_event(view, x, y, flags))
      end
      
      view.hotspot_over = hotspot
    end
  end,
  cancelmouseover = function(flags, id)
    local view = views[id]
    
    if view.hotspot_over ~= nil then
      local x, y = WindowInfo(id, 14), WindowInfo(id, 15)
      
      view.hotspot_over:ExecuteHandler("cancelmouseover", new_mouse_event(view, x, y, flags))
      
      view.hotspot_over = nil
    end
  end,
  mousedown = function(flags, id)
    local view = views[id]
    
    local x, y = WindowInfo(id, 14), WindowInfo(id, 15)
    local hotspot = resolve_hotspot(id, x, y)
    if hotspot ~= nil then
      hotspot:ExecuteHandler("mousedown", new_mouse_event(view, x, y, flags))
      
      view.hotspot_down = hotspot
    end
  end,
  cancelmousedown = function(flags, id)
    local view = views[id]
    
    local hotspot = view.hotspot_down
    if hotspot ~= nil then
      local x, y = WindowInfo(id, 14), WindowInfo(id, 15)
      
      hotspot:ExecuteHandler("cancelmousedown", new_mouse_event(view, x, y, flags))
      
      view.hotspot_down = nil
    end
  end,
  mouseup = function(flags, id)
    local view = views[id]
    
    local hotspot = view.hotspot_down
    if hotspot ~= nil then
      local x, y = WindowInfo(id, 14), WindowInfo(id, 15)
      
      hotspot:ExecuteHandler("mouseup", new_mouse_event(view, x, y, flags))
      
      view.hotspot_down = nil
    end
  end,
  dragmove = function(flags, id)
    -- TODO: disabled for now
  end,
  dragrelease = function(flags, id)
    -- TODO: disabled for now
  end,
}


MWidget.View = View
return View
