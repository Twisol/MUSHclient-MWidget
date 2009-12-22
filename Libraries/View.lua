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
  Resize = nil,
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
  -- Takes around 2 seconds to execute this loop.
  --
  -- TODO: Hopefully, WindowAddHotspot will eventually add a
  -- 'pixel-sensitive' flag so that only one hotspot would be
  -- needed to cover the view. Unfortunately, that's not an
  -- option at this time.
  for y = 0, self.height do
    for x = 0, self.width do
      local id = self.name .. "-h(" .. x .. "," .. y .. ")"
      check(WindowAddHotspot(self.name, id, x, y, x+1, y+1,
         "MWidget.View.hotspot_handlers.mouseover",
         "MWidget.View.hotspot_handlers.cancelmouseover",
         "MWidget.View.hotspot_handlers.mousedown",
         "MWidget.View.hotspot_handlers.cancelmousedown",
         "MWidget.View.hotspot_handlers.mouseup",
         nil, 0, 0))
      check(WindowDragHandler(self.name, id,
         "MWidget.View.hotspot_handlers.dragmove",
         "MWidget.View.hotspot_handlers.dragrelease",
         0))
    end
  end
end


function View.new(child, x, y)
  local o = Canvas.new(child.width, child.height)
  setmetatable(o, View)
  
  o.child = child
  o.autosize = true
  
  init_hotspots(o)
  
  o:Move(x, y)
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
  self.child:InternalRender()
  
  -- * Resize the window if necessary.
  if self.autosize and
     (self.width ~= self.child.width or
      self.height ~= self.child.height) then
    self:Resize(self.child.width, self.child.height)
    self.autosize = true
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

function Instance:Resize(width, height, autosize)
  self.width = width
  self.height = height
  self.autosize = false
  
  check(WindowCreate(self.name, self.x, self.y, self.width, self.height,
     self.anchor, (self.anchor == -1) and 2 or 0, 0x000000))
  init_hotspots(self)
  
  self:DrawImage("view", {0, 0, 0, 0}, {}, 2)
  self:Show()
end

function Instance:ResetSize()
  self:Resize(self.child.width, self.child.height)
  self.autosize = true
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

-- TODO: may need to use > for right/bottom instead of >=
local function find_hotspot(widget, handler_type, x, y)
  -- first look for matches in this widget
  for _,hotspot in ipairs(widget.hotspots) do
    -- cull hotspots that don't contain the point
    if hotspot.left <= x and hotspot.top <= y and
       hotspot.right >= x and hotspot.bottom >= y and
       hotspot.handlers[handler_type] ~= nil then
      return widget, hotspot
    end
  end
  
  -- then move on to the children
  for _,record in ipairs(widget.children) do
    local child = record.widget
    local left, top = record.x, record.y
    local right, bottom = record.x + child.width, record.y + child.height
    
    -- cull widgets that don't contain the point
    if left <= x and top <= y and right >= x and bottom >= y then
      local widget, hotspot = find_hotspot(record.widget, handler_type, x - left, y - top)
      if hotspot then
        return widget, hotspot
      end
    end
  end
  
  -- no match
  return nil
end

--- Resolves hotspot identifiers and executes the appropriate handler.
-- @param flags The flags to pass to the handler.
-- @param id The hotspot ID to be resolved into a window identifier.
-- @param handler_type The type of hotspot handler to execute.
local execute_handler = function(flags, name, handler_type)
  -- * Get view object from hotspot name
  local _, _, view_name, x, y = name:find("(w%d+_%w+)-h%((%d+),(%d+)%)")
  local view = views[view_name]
  x, y = tonumber(x), tonumber(y)
  
  -- * Recurse through child widgets until a hotspot with the right handler
  --   has been found.
  local widget, hotspot = find_hotspot(view.child, handler_type, x, y)
  
  -- * Execute the handler.
  if hotspot then
    return hotspot:ExecuteHandler(view, widget, handler_type, flags)
  end
end

--- Base handlers that forward events through execute_handler()
-- to the appropriate widget's hotspots
View.hotspot_handlers = {
  mouseover = function(flags, id)
    return execute_handler(flags, id, "mouseover")
  end,
  cancelmouseover = function(flags, id)
    return execute_handler(flags, id, "cancelmouseover")
  end,
  mousedown = function(flags, id)
    return execute_handler(flags, id, "mousedown")
  end,
  cancelmousedown = function(flags, id)
    return execute_handler(flags, id, "cancelmousedown")
  end,
  mouseup = function(flags, id)
    return execute_handler(flags, id, "mouseup")
  end,
  dragmove = function(flags, id)
    return execute_handler(flags, id, "dragmove")
  end,
  dragrelease = function(flags, id)
    return execute_handler(flags, id, "dragrelease")
  end,
}


MWidget.View = View
return View
