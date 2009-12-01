-- Master MWidget package table
MWidget = MWidget or {}

--- A running count of the number of windows created by MWidget.
-- It is used to ensure that window names are unique.
local num_windows = 0
--- A list of all MWidget-owned windows.
-- 
local windows = setmetatable({}, {__mode = "v"})

--- The methods shared by all Window instances.
local Instance = {
  Show = nil,
  Hide = nil,
  IsShown = nil,
  
  Font = nil,
  BackColor = nil,
  
  Move = nil,
  Anchor = nil,
  
  Draw = nil,
  Clear = nil,
  
  Destroy = nil,
  
  AddHotspot = nil,
  DeleteHotspot = nil,
  DeleteAllHotspots = nil,
}

--- The base 'class' table for the Window widget type.
local Window = {
  __index = Instance,
  
  hotspot_handlers = nil,
  
  new = nil,
}
setmetatable(Window, Window)

--- Resolves hotspot identifiers and executes the appropriate handler.
-- @param flags The flags to pass to the handler.
-- @param id The hotspot ID to be resolved into a window identifier.
-- @param handler_type The type of hotspot handler to execute.
local execute_handler = function(flags, id, handler_type)
  local _, _, win_name, hotspot_name = id:find("(w%d+_%w+)-h(.*)")
  if win_name == nil then
    return
  end
  
  local win = windows[win_name]
  if win == nil then
    return
  end
  
  local handler = win.hotspots[hotspot_name][handler_type]
  if handler == nil then
    return
  end
  
  return handler(win, flags, hotspot_name)
end

--- Base handlers automatically registered to every MWidget hotspot.
-- They forward requests to the appropriate user-provided handler
-- through execute_handler().
local hotspot_handlers = {
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
  end
}
Window.hotspot_handlers = hotspot_handlers


function Window.new(width, height)
  local o = setmetatable({}, Window)
  num_windows = num_windows + 1
  
  o.name = "w" .. num_windows .. "_" .. GetPluginID()
  o.width = width or 0
  o.height = height or 0
  o.backcolor = 0x000000
  o.position = {}
  o.fonts = {}
  o.hotspots = {}
  
  o:Move(0, 0)
  
  -- Dummy window.
  WindowCreate(o.name, 0, 0, 0, 0, 0, 0, 0)
  
  windows[o.name] = o
  return o
end

function Instance:Clear(color)
  WindowRectOp(self.name, 2, 0, 0, 0, 0, color or 0x000000)
end

function Instance:Show()
  WindowShow(self.name, true)
end

function Instance:IsShown()
  return WindowInfo(self.name, 5)
end

function Instance:Hide()
  WindowShow(self.name, false)
end

function Instance:Move(x, y)
  if self.position == nil then
    self.position = {}
  end
  
  self.position.x = x
  self.position.y = y
  self.position.anchor = -1
  self.position.absolute = true
end

function Instance:Anchor(anchor)
  if self.position == nil then
    self.position = {}
  end
  
  self.position.x = -1
  self.position.y = -1
  self.position.anchor = anchor
  self.position.absolute = false
end

function Instance:Font(id, name, size, info_tbl)
  local ok
  if info_tbl then
    ok = WindowFont(self.name, id, name, size,
       info_tbl.bold, info_tbl.italic, info_tbl.underline, info_tbl.strikeout,
       info_tbl.charset or 1, info_tbl.pitchandfamily or 0)
  else
    ok = WindowFont(self.name, id, name, size, false, false, false, false, 1, 0)
  end
  
  if ok == error_code.eNoSuchWindow then
    return nil, "no such window"
  elseif ok == error_code.eCannotAddFont then
    return nil, "unable to add font"
  else
    self.fonts[id] = {
      name = name,
      size = size,
    }
    return true
  end
end

function Instance:BackColor(color)
  self.backcolor = color or 0x000000
end

function Instance:Draw()
  local flags = (self.position.absolute and 2 or 0)
  
  -- Recreate the window if it's been resized or re-anchored.
  if self.width ~= WindowInfo(self.name, 3) or
     self.height ~= WindowInfo(self.name, 4) or
     self.position.anchor ~= WindowInfo(self.name, 7) then
    local shown = WindowInfo(self.name, 5)
    WindowCreate(self.name, self.position.x, self.position.y,
      self.width, self.height, self.position.anchor, flags, self.backcolor)
      
    for k,v in pairs(self.hotspots) do
      self:AddHotspot(k, v.left, v.top, v.right, v.bottom, v.cursor)
    end
    
    if shown then
      self:Show()
    else
      self:Hide()
    end
  else
    WindowRectOp(self.name, 2, 0, 0, self.width, self.height, self.backcolor)
    WindowPosition(self.name, self.position.x, self.position.y, self.position.anchor, flags)
  end
  
  if show then
    WindowShow(self.name, true)
  end
end

function Instance:Destroy()
  WindowDelete(self.name)
end

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
     "MWidget.Window.hotspot_handlers.mouseover",
     "MWidget.Window.hotspot_handlers.cancelmouseover",
     "MWidget.Window.hotspot_handlers.mousedown",
     "MWidget.Window.hotspot_handlers.cancelmousedown",
     "MWidget.Window.hotspot_handlers.mouseup",
     nil, cursor or 0, 0)
  WindowDragHandler(self.name, self.name .. "-h" .. id,
     "MWidget.Window.hotspot_handlers.dragmove",
     "MWidget.Window.hotspot_handlers.dragrelease",
     0)
  
  self.hotspots[id] = hotspot
  return hotspot
end

function Instance:DeleteHotspot(id)
  WindowDeleteHotspot(self.name, id)
  self.hotspots[name] = nil
end

function Instance:DeleteAllHotspots()
  WindowDeleteAllHotspots(self.name)
end

MWidget.Window = Window
return Window
