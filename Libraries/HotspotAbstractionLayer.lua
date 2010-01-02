local hal_list = {}

local Instance = {
}

local HotspotAbstractionLayer = {
  __index = Instance,
  
  handlers = nil,
  
  new = nil,
}
setmetatable(HotspotAbstractionLayer, HotspotAbstractionLayer)

function HotspotAbstractionLayer.new(view)
  local o = hal_list[view.name]
  if not o then
    o = setmetatable({}, HotspotAbstractionLayer)
  end
  
  o.view = view
  o.mouse_record = {
    hotspot = nil,
    view_x = 0, view_y = 0,
    widget_x = 0, widget_y = 0,
  }
  
  check(WindowAddHotspot(view.name, view.name, 0, 0, 0, 0,
     "MWidget.HotspotAbstractionLayer.handlers.mouseover",
     "MWidget.HotspotAbstractionLayer.handlers.cancelmouseover",
     "MWidget.HotspotAbstractionLayer.handlers.mousedown",
     "MWidget.HotspotAbstractionLayer.handlers.cancelmousedown",
     "MWidget.HotspotAbstractionLayer.handlers.mouseup",
     nil, 0, 1)) -- 1: pixel-sensitive
  check(WindowDragHandler(view.name, view.name,
     "MWidget.HotspotAbstractionLayer.handlers.dragmove",
     "MWidget.HotspotAbstractionLayer.handlers.dragrelease",
     0))
  
  hal_list[view.name] = o
  return o
end

local function new_mouse_event(view, x, y, flags)
  local view_x, view_y = WindowInfo(view.name, 14), WindowInfo(view.name, 15)
  return {
    view = view,
    
    widget_x = x,
    widget_y = y,
    output_x = view_x + x,
    output_y = view_y + y,
    
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
      return hotspot, x, y
    end
  end
  
  -- then move on to the children
  for _,record in ipairs(widget.children) do
    local child = record.widget
    local left, top = record.x, record.y
    local right, bottom = record.x + child.width, record.y + child.height
    
    -- cull widgets that don't contain the point
    if left <= x and top <= y and right > x and bottom > y then
      return find_hotspot(record.widget, handler_type, x - left, y - top)
    end
  end
  
  -- no match
  return nil
end

local function base_handler_data(flags, id)
  local hal = hal_list[id]
  local view = hal.view
  local hotspot = hal.mouse_record.hotspot
  
  -- get current mouse position coordinates
  local view_x = WindowInfo(id, 14)
  local view_y = WindowInfo(id, 15)
  local widget_x = view_x - hal.mouse_record.view_x + hal.mouse_record.widget_x
  local widget_y = view_y - hal.mouse_record.view_y + hal.mouse_record.widget_y
  
  -- update the mouse record's data
  hal.mouse_record.widget_x = widget_x
  hal.mouse_record.widget_y = widget_y
  hal.mouse_record.view_x = view_x
  hal.mouse_record.view_y = view_y
  
  return hal, view, hotspot, view_x, view_y, widget_x, widget_y
end

--- Base handlers that forward events through find_hotspot()
--  to the appropriate widget's hotspots
HotspotAbstractionLayer.handlers = {
  -- This handler tracks all mouse movements, providing the base
  -- information that all other handlers rely on.
  -- It also fires mouseover and cancelmouseover events as the mouse
  -- moves over internal hotspot bounds.
  mouseover = function(flags, id)
    local hal, view, record_hotspot,
       view_x, view_y,
       widget_x, widget_y = base_handler_data(flags, id)
    
    -- Locate the hotspot that the mouse is currently over.
    local hotspot, widget_x, widget_y = find_hotspot(view:GetChild(), view_x, view_y)
    
    -- if we've moved into another hotspot
    if hotspot ~= record_hotspot then
      -- first send a cancelmouseover to the old hotspot
      if record_hotspot ~= nil then
        record_hotspot:ExecuteHandler(
           "cancelmouseover",
           new_mouse_event(view, widget_x, widget_y, flags)
        )
      end
      
      -- then send a mouseover to the new hotspot
      if hotspot ~= nil then
        hotspot:ExecuteHandler(
           "mouseover",
           new_mouse_event(view, widget_x, widget_y, flags)
        )
      end
      
      --- Update the mouse record
      hal.mouse_record.hotspot = hotspot
    end
  end,
  
  -- This handler is only called when the mouse leaves the view altogether.
  -- It sends a cancelmouseover to the currently moused over hotspot, then
  -- removes the hotspot from the current mouse record.
  cancelmouseover = function(flags, id)
    local hal, view, hotspot,
       view_x, view_y,
       widget_x, widget_y = base_handler_data(flags, id)
    
    if hotspot ~= nil then
      -- only send the cancelmouseover if it really left the view.
      -- if the event was fired from within the view area, then
      -- a mousedown is likely to follow instead.
      if view_x < 0 or widget_x >= view.width or
         view_y < 0 or widget_y >= view.height then
        hotspot:ExecuteHandler(
           "cancelmouseover",
           new_mouse_event(view, widget_x, widget_y, flags)
        )
        
        -- Update the mouse record
        hal.mouse_record.hotspot = nil
      end
    end
  end,
  
  mousedown = function(flags, id)
    local hal, view, hotspot,
       view_x, view_y,
       widget_x, widget_y = base_handler_data(flags, id)
    
    if hotspot ~= nil then
      hotspot:ExecuteHandler("mousedown", new_mouse_event(view, widget_x, widget_y, flags))
    end
  end,
  
  mouseup = function(flags, id)
    local hal, view, hotspot,
       view_x, view_y,
       widget_x, widget_y = base_handler_data(flags, id)
    
    if hotspot ~= nil then
      -- if the mouse moved out of the hotspot's area, it's a cancelmousedown instead.
      if not hotspot:ContainsPoint(widget_x, widget_y) then
        hotspot:ExecuteHandler("cancelmousedown", new_mouse_event(view, widget_x, widget_y, flags))
      else
        hotspot:ExecuteHandler("mouseup", new_mouse_event(view, widget_x, widget_y, flags))
      end
    end
  end,
  
  cancelmousedown = function(flags, id)
    local hal, view, hotspot,
       view_x, view_y,
       widget_x, widget_y = base_handler_data(flags, id)
    
    if hotspot ~= nil then
      hotspot:ExecuteHandler("cancelmousedown", new_mouse_event(view, widget_x, widget_y, flags))
      hal.mouse_record.hotspot = nil
    end
  end,
  
  dragmove = function(flags, id)
    -- TODO: disabled for now
  end,
  
  dragrelease = function(flags, id)
    -- TODO: disabled for now
  end,
}

MWidget.HotspotAbstractionLayer = HotspotAbstractionLayer
return HotspotAbstractionLayer