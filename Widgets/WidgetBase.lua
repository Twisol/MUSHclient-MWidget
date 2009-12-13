-- Master MWidget package table
MWidget = MWidget or {}

--- A running count of the number of windows created by MWidget.
-- It is used to ensure that window names are unique.
local num_windows = 0

--- A list of all MWidget-owned windows.
-- It is used to resolve hotspot events to the proper handlers.
local windows = setmetatable({}, {__mode = "v"})

--- The methods shared by all WidgetBase instances.
local Instance = {
  -- General window functions
  Show = nil,
  Hide = nil,
  IsShown = nil,
  
  Repaint = nil,
  Clear = nil,
  
  Move = nil,
  Anchor = nil,
  
  BackColor = nil,
  Destroy = nil,
  
  WindowInfo = nil,
  
  
  -- Hotspot-related functions
  AddHotspot = nil,
  DeleteHotspot = nil,
  DeleteAllHotspots = nil,
  
  HotspotTooltip = nil,
  Menu = nil,
  
  HotspotInfo = nil,
  
  
  -- Text/font functions
  Font = nil,
  TextWidth = nil,
  
  FontInfo = nil,
  
  
  -- Graphics functions
  GetPixel = nil,
  SetPixel = nil,
  
  CreateImageFromBitmap = nil,
  CreateImageFromWindow = nil,
  CreateImageFromFile = nil,
  CreateImageFromMemory = nil,
  
  BlendImage = nil,
  DrawImage = nil,
  DrawImageAlpha = nil,
  MergeImageAlpha = nil,
  
  InvertRectangle = nil,
  ApplyFilter = nil,
  
  DrawGradient = nil,
  DrawLine = nil,
  DrawLineList = nil,
  DrawArc = nil,
  DrawBezier = nil,
  DrawPolygon = nil,
  DrawEllipse = nil,
  DrawRectangle = nil,
  DrawRoundedRectangle = nil,
  DrawChord = nil,
  DrawPie = nil,
  DrawText = nil,
  
  SaveAsImage = nil,
  
  ImageInfo = nil,
}

--- The base 'class' table for the WidgetBase widget type.
local WidgetBase = {
  __index = Instance,
  
  hotspot_handlers = nil,
  
  new = nil,
  List = nil,
}
setmetatable(WidgetBase, WidgetBase)

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
WidgetBase.hotspot_handlers = hotspot_handlers


function WidgetBase.new(width, height)
  local o = setmetatable({}, WidgetBase)
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
  WindowCreate(o.name, 0, 0, 1, 1, 0, 0, 0)
  
  windows[o.name] = o
  return o
end

function WidgetBase.List()
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

function Instance:Repaint()
  local flags = (self.position.absolute and 2 or 0)
  
  local shown = WindowInfo(self.name, 5)
  
  -- Recreate the window if it's been resized or re-anchored.
  if self.width ~= WindowInfo(self.name, 3) or
     self.height ~= WindowInfo(self.name, 4) or
     self.position.anchor ~= WindowInfo(self.name, 7) or
     self.backcolor ~= WindowInfo(self.name, 9) then
    WindowCreate(self.name, self.position.x, self.position.y,
      self.width, self.height, self.position.anchor, flags, self.backcolor)
      
    for k,v in pairs(self.hotspots) do
      self:AddHotspot(k, v.left, v.top, v.right, v.bottom, v.cursor)
    end
  else
    WindowRectOp(self.name, 2, 0, 0, 0, 0, self.backcolor)
    WindowPosition(self.name, self.position.x, self.position.y, self.position.anchor, flags)
  end
  
  WindowShow(self.name, shown)
end

function Instance:Clear()
  WindowRectOp(self.name, 2, 0, 0, 0, 0, self.backcolor)
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

function Instance:BackColor(color)
  self.backcolor = color or 0x000000
end

function Instance:Destroy()
  WindowDelete(self.name)
end

function Instance:WindowInfo(infotype)
  return WindowInfo(self.name, infotype)
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
     "MWidget.WidgetBase.hotspot_handlers.mouseover",
     "MWidget.WidgetBase.hotspot_handlers.cancelmouseover",
     "MWidget.WidgetBase.hotspot_handlers.mousedown",
     "MWidget.WidgetBase.hotspot_handlers.cancelmousedown",
     "MWidget.WidgetBase.hotspot_handlers.mouseup",
     nil, cursor or 0, 0)
  WindowDragHandler(self.name, self.name .. "-h" .. id,
     "MWidget.WidgetBase.hotspot_handlers.dragmove",
     "MWidget.WidgetBase.hotspot_handlers.dragrelease",
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

function Instance:HotspotTooltip(id, text)
  return WindowHotspotTooltip(self.name, id, text)
end

function Instance:Menu(x, y, menu)
  return WindowMenu(self.name, x, y, menu)
end


function Instance:Font(font_id, name, size, info_tbl)
  local ok
  if info_tbl then
    ok = WindowFont(self.name, font_id, name, size,
       info_tbl.bold, info_tbl.italic, info_tbl.underline, info_tbl.strikeout,
       info_tbl.charset or 1, info_tbl.pitchandfamily or 0)
  else
    ok = WindowFont(self.name, font_id, name, size, false, false, false, false, 1, 0)
  end
  
  if ok == error_code.eNoSuchWindow then
    return nil, "no such window"
  elseif ok == error_code.eCannotAddFont then
    return nil, "unable to add font"
  else
    self.fonts[font_id] = {
      name = name,
      size = size,
    }
    return true
  end
end

function Instance:TextWidth(font_id, text, unicode)
  return WindowTextWidth(self.name, font_id, text, unicode or false)
end

function Instance:FontInfo(font_id, infotype)
  return WindowFontInfo(self.name, font_id, infotype)
end


function Instance:GetPixel(x, y)
  return WindowGetPixel(self.name, x, y)
end

function Instance:SetPixel(x, y, color)
  return WindowSetPixel(self.name, x, y, color)
end

function Instance:CreateImageFromBitmap(img_id, bitmap)
  return WindowCreateImage(self.name, img_id,
    tonumber(bitmap[8], 2),
    tonumber(bitmap[7], 2),
    tonumber(bitmap[6], 2),
    tonumber(bitmap[5], 2),
    tonumber(bitmap[4], 2),
    tonumber(bitmap[3], 2),
    tonumber(bitmap[2], 2),
    tonumber(bitmap[1], 2))
end

function Instance:CreateImageFromWindow(img_id, window)
  local name
  if type(window) == "table" then
    name = window.name
  else
    name = window
  end
  
  return WindowImageFromWindow(self.name, img_id, name)
end

function Instance:CreateImageFromFile(img_id, filename)
  return WindowLoadImage(self.name, img_id, filename)
end

function Instance:CreateImageFromMemory(img_id, mem_table, swap_blue_alpha)
  return WindowLoadImageMemory(self.name, img_id, mem_table, swap_blue_alpha)
end

function Instance:BlendImage(img_id, dest_rect, src_rect, mode, opacity)
  return WindowBlendImage(self.name, img_id,
     dest_rect[1], dest_rect[2], dest_rect[3], dest_rect[4],
     mode, opacity,
     src_rect[1], src_rect[2], src_rect[3], src_rect[4])
end

function Instance:DrawImage(img_id, dest_rect, src_rect, mode)
  return WindowDrawImage(self.name, img_id,
     dest_rect[1], dest_rect[2], dest_rect[3], dest_rect[4],
     mode,
     src_rect[1], src_rect[2], src_rect[3], src_rect[4])
end

function Instance:DrawImageAlpha(img_id, dest_rect, src_x, src_y, opacity)
  return WindowDrawImageAlpha(self.name, img_id,
     dest_rect[1], dest_rect[2], dest_rect[3], dest_rect[4],
     opacity,
     src_x, src_y)
end

function Instance:MergeImageAlpha(img_id, mask_id, dest_rect, src_rect, mode, opacity)
  return WindowMergeImageAlpha(self.name, img_id, mask_id,
     dest_rect[1], dest_rect[2], dest_rect[3], dest_rect[4],
     mode, opacity,
     src_rect[1], src_rect[2], src_rect[3], src_rect[4])
end

function Instance:InvertRectangle(left, top, right, bottom)
  return WindowRectOp(self.name, 3, left, top, right, bottom)
end

function Instance:ApplyFilter(left, top, right, bottom, operation, options)
  return WindowFilter(self.name, left, top, right, bottom, operation, options)
end

function Instance:DrawGradient(left, top, right, bottom, start_color, end_color, mode)
  return WindowGradient(self.name, left, top, right, bottom, start_color, end_color, mode)
end

function Instance:DrawLine(x1, y1, x2, y2, pen)
  return WindowLine(self.name, x1, y1, x2, y2,
     pen.color, pen.style, pen.width)
end

function Instance:DrawLineList(points, pen, brush, winding)
  return WindowPolygon(self.name, points,
     pen.color, pen.style, pen.width,
     brush.color, brush,style,
     false, winding or false)
end

function Instance:DrawArc(left, top, right, bottom, x1, y1, x2, y2, pen)
  return WindowArc(self.name, left, top, right, bottom, x1, y1, x2, y2,
     pen.color, pen.style, pen.width)
end

function Instance:DrawBezier(points, pen)
  return WindowBezier(self.name, points, pen.color, pen.style, pen.width)
end

function Instance:DrawPolygon(points, pen, brush, winding)
  return WindowPolygon(self.name, points,
     pen.color, pen.style, pen.width,
     brush.color, brush,style,
     true, winding or false)
end

function Instance:DrawEllipse(left, top, right, bottom, pen, brush, image)
  if image then
    return WindowImageOp(self.name, 1, left, top, right, bottom,
       pen.color, pen.style, pen.width,
       brush.color, image)
  else
    WindowCircleOp(self.name, 1, left, top, right, bottom,
       pen.color, pen.style, pen.width,
       brush.color, brush.style)
  end
end

function Instance:DrawRectangle(left, top, right, bottom, pen, brush, image)
  if image then
    return WindowImageOp(self.name, 2, left, top, right, bottom,
       pen.color, pen.style, pen.width,
       brush.color, image)
  else
    return WindowCircleOp(self.name, 2, left, top, right, bottom,
       pen.color, pen.style, pen.width,
       brush.color, brush.style)
  end
end

function Instance:DrawRoundedRectangle(left, top, right, bottom, width, height, pen, brush, image)
  if image then
    return WindowImageOp(self.name, 3, left, top, right, bottom,
       pen.color, pen.style, pen.width,
       brush.color, image,
       width, height)
  else
    return WindowCircleOp(self.name, 3, left, top, right, bottom,
       pen.color, pen.style, pen.width,
       brush.color, brush.style,
       width, height)
  end
end

function Instance:DrawChord(left, top, right, bottom, chord_x1, chord_y1, chord_x2, chord_y2, pen, brush)
  return WindowCircleOp(self.name, 4, left, top, right, bottom,
     pen.color, pen.style, pen.width,
     brush.color, brush.style,
     chord_x1, chord_y1, chord_x2, chord_y2)
end

function Instance:DrawPie(left, top, right, bottom, slice_x1, slice_y1, slice_x2, slice_y2, pen, brush)
  return WindowCircleOp(self.name, 5, left, top, right, bottom,
     pen.color, pen.style, pen.width,
     brush.color, brush.style,
     slice_x1, slice_y1, slice_x2, slice_y2)
end

function Instance:DrawText(font_id, text, left, top, right, bottom, color, unicode)
  return WindowText(self.name, font_id, text,
     left, top, right, bottom,
     color, unicode or false)
end

function Instance:SaveAsImage(filename)
  return WindowWrite(self.name, filename)
end

function Instance:ImageInfo(id, infotype)
  return WindowImageInfo(self.name, id, infotype)
end

-- raw interface to WindowRectOp
-- Needs to be removed/renamed and split/merged into the rest of the API
function Instance:WindowRectOp(action, left, top, right, bottom, color1, color2)
  return WindowRectOp(self.name, action, left, top, right, bottom, color1, color2)
end


MWidget.WidgetBase = WidgetBase
return WidgetBase
