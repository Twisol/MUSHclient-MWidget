local MWidget = require("MWidget")

--- The methods shared by all View instances.
local Instance = {
  -- General window functions
  Show = nil,
  Hide = nil,
  IsShown = nil,
  
  Move = nil,
  Anchor = nil,
  GetPosition = nil,
  
  Destroy = nil,
}

--- The base 'class' table for the View widget type.
local View = {
  __index = Instance,
  
  hotspot_handlers = nil,
  
  new = nil,
  List = nil,
}
setmetatable(View, View)

function View.new(child, x, y)
  local o = setmetatable({}, View)
  
  o.name = MWidget.GetUniqueName()
  o.x = x
  o.y = y
  o.width = child.width
  o.height = child.height
  o.child = child
  
  o.position = {}
  
  o:Refresh(false)
  
  MWidget.RegisterWindow(o.name, o)
  return o
end

function View.List()
  return WindowList()
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

function Instance:Refresh(show)
  -- * Recursively render child widgets to obtain a final canvas.
  self.child:InternalRender()
  
  -- TODO:
  -- * Recreate window if the final canvas has been resized, or
  --   if the view has been re-anchored.
  check(WindowCreate(self.name, self.x, self.y, self.width, self.height, 0, 2, 0x000000))
  
  -- * Draw final canvas to screen.
  check(WindowImageFromWindow(self.name, "view", self.child.canvas.name))
  check(WindowDrawImage(self.name, "view", 0, 0, 0, 0, 1))
  check(WindowLoadImage(self.name, "view", ""))
  
  -- * Show the view in order to refresh and display it.
  if show ~= false then
    check(WindowShow(self.name))
  end
end

function Instance:Move(x, y)
  self.position.x = x
  self.position.y = y
  self.position.anchor = -1
  self.position.absolute = true
end

function Instance:Anchor(anchor)
  self.position.x = -1
  self.position.y = -1
  self.position.anchor = anchor
  self.position.absolute = false
end

function Instance:GetPosition()
  if self.position.anchor == -1 then
    return "absolute", self.position.x, self.position.y
  else
    return "anchored", WindowInfo(self.name, 10), WindowInfo(self.name, 11), self.position.anchor
  end
end

function Instance:Destroy()
  MWidget.UnregisterWindow(self.name)
  WindowDelete(self.name)
end

--[[
function Instance:AddHotspot(id, left, top, right, bottom, cursor)
  local hotspot = self.hotspots[id]
  
  -- reuse table and handlers if possible
  if hotspot then
    hotspot.cursor = cursor
    hotspot.left = left
    hotspot.top = top
    hotspot.right = right
    hotspot.bottom = bottom
  else
    hotspot = {
      id = id,
      cursor = cursor,
      left = left,
      top = top,
      right = right,
      bottom = bottom,
    }
  end
  
  WindowAddHotspot(self.name, self.name .. "-h" .. id, left, top, right, bottom,
     "MWidget.Core.hotspot_handlers.mouseover",
     "MWidget.Core.hotspot_handlers.cancelmouseover",
     "MWidget.Core.hotspot_handlers.mousedown",
     "MWidget.Core.hotspot_handlers.cancelmousedown",
     "MWidget.Core.hotspot_handlers.mouseup",
     nil, cursor or 0, 0)
  WindowDragHandler(self.name, self.name .. "-h" .. id,
     "MWidget.Core.hotspot_handlers.dragmove",
     "MWidget.Core.hotspot_handlers.dragrelease",
     0)
  
  self.hotspots[id] = hotspot
  return hotspot
end

function Instance:DeleteHotspot(id)
  self.hotspots[name] = nil
  return WindowDeleteHotspot(self.name, id)
end

function Instance:DeleteAllHotspots()
  return WindowDeleteAllHotspots(self.name)
end
--]]


-- TODO: may need to use > for right/bottom instead of >=
local function find_hotspot(widget, handler_type, x, y)
  -- first look for matches in this widget
  for _,record in ipairs(widget.hotspots) do
    -- cull hotspots that don't contain the point
    if record.left <= x and record.top <= y and
       record.right >= x and record.bottom >= y and
       record.hotspot.handlers[handler_type] ~= nil then
      return widget, record.hotspot
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
  local view = MWidget:GetWindowByName(view_name)
  x, y = tonumber(x), tonumber(y)
  
  -- * Recurse through child widgets until a hotspot with the right handler
  --   has been found.
  local widget, hotspot = find_hotspot(view.child, handler_type, x, y)
  
  -- * Execute the handler.
  return hotspot:ExecuteHandler(view, widget, handler_type, flags)
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
