local MWidget = require("MWidget")

local Methods = {
  -- General canvas functions
  Clear = nil,
  BackColor = nil,
  
  Resize = nil,
  Destroy = nil,
  
  
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

local Canvas = {
  __index = Methods,
  
  new = nil,
}
setmetatable(Canvas, Canvas)

function Canvas.new(width, height)
  local o = setmetatable({}, Canvas)
  
  o.name = MWidget.GetUniqueName() .. "-canvas"
  o.width = width or 1
  o.height = height or 1
  o.backcolor = 0x000000
  
  o.fonts = {}
  
  WindowCreate(o.name, 0, 0, o.width, o.height, 0, 2, o.backcolor)
  return o
end

function Methods:Clear()
  return WindowRectOp(self.name, 2, 0, 0, 0, 0, self.backcolor)
end

function Methods:BackColor(color)
  self.backcolor = color or 0x000000
end

function Methods:Resize(width, height)
  -- resize while keeping contents
  WindowImageFromWindow(self.name, "temp", self.name)
  WindowCreate(self.name, 0, 0, width, height, 0, 2, self.backcolor)
  WindowDrawImage(self.name, "temp", 0, 0, 0, 0, 1)
  
  -- unload temporary image
  WindowLoadImage(self.name, "temp", "")
  
  self.width, self.height = width, height
end

function Methods:Destroy()
  return WindowDelete(self.name)
end

function Methods:Font(font_id, name, size, info_tbl)
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
    return self.fonts[font_id]
  end
end

function Methods:TextWidth(font_id, text, unicode)
  return WindowTextWidth(self.name, font_id, text, unicode or false)
end

function Methods:FontInfo(font_id, infotype)
  return WindowFontInfo(self.name, font_id, infotype)
end

-- Get a single pixel's RGB value.
function Methods:GetPixel(x, y)
  return WindowGetPixel(self.name, x, y)
end

-- Set a single pixel's RGB value directly.
function Methods:SetPixel(x, y, color)
  return WindowSetPixel(self.name, x, y, color)
end

function Methods:CreateImageFromBitmap(img_id, bitmap)
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

function Methods:CreateImageFromWindow(img_id, window)
  local name
  if type(window) == "table" then
    name = window.name
  else
    name = window
  end
  
  return WindowImageFromWindow(self.name, img_id, name)
end

function Methods:CreateImageFromFile(img_id, filename)
  return WindowLoadImage(self.name, img_id, filename)
end

--- Loads a BMP image from memory.
-- swap_blue_alpha defaults to false.
function Methods:CreateImageFromMemory(img_id, mem_table, swap_blue_alpha)
  return WindowLoadImageMemory(self.name, img_id, mem_table, swap_blue_alpha)
end

function Methods:DeleteImage(img_id)
  return WindowLoadImage(self.name, img_id, "")
end

function Methods:BlendImage(img_id, dest_rect, src_rect, mode, opacity)
  return WindowBlendImage(self.name, img_id,
     dest_rect[1], dest_rect[2], dest_rect[3], dest_rect[4],
     mode, opacity,
     src_rect[1], src_rect[2], src_rect[3], src_rect[4])
end

function Methods:DrawImage(img_id, dest_rect, src_rect, mode)
  return WindowDrawImage(self.name, img_id,
     dest_rect[1], dest_rect[2], dest_rect[3], dest_rect[4],
     mode or 1,
     src_rect[1], src_rect[2], src_rect[3], src_rect[4])
end

function Methods:DrawImageAlpha(img_id, dest_rect, src_x, src_y, opacity)
  return WindowDrawImageAlpha(self.name, img_id,
     dest_rect[1], dest_rect[2], dest_rect[3], dest_rect[4],
     opacity,
     src_x, src_y)
end

function Methods:MergeImageAlpha(img_id, mask_id, dest_rect, src_rect, mode, opacity)
  return WindowMergeImageAlpha(self.name, img_id, mask_id,
     dest_rect[1], dest_rect[2], dest_rect[3], dest_rect[4],
     mode, opacity,
     src_rect[1], src_rect[2], src_rect[3], src_rect[4])
end

function Methods:InvertRectangle(left, top, right, bottom)
  return WindowRectOp(self.name, 3, left, top, right, bottom)
end

function Methods:ApplyFilter(left, top, right, bottom, operation, options)
  return WindowFilter(self.name, left, top, right, bottom, operation, options)
end

function Methods:DrawGradient(left, top, right, bottom, start_color, end_color, mode)
  return WindowGradient(self.name, left, top, right, bottom, start_color, end_color, mode)
end

function Methods:DrawLine(x1, y1, x2, y2, pen)
  return WindowLine(self.name, x1, y1, x2, y2,
     pen.color, pen.style, pen.width)
end

function Methods:DrawLineList(points, pen, brush, winding)
  return WindowPolygon(self.name, points,
     pen.color, pen.style, pen.width,
     brush.color, brush,style,
     false, winding or false)
end

function Methods:DrawArc(left, top, right, bottom, x1, y1, x2, y2, pen)
  return WindowArc(self.name, left, top, right, bottom, x1, y1, x2, y2,
     pen.color, pen.style, pen.width)
end

function Methods:DrawBezier(points, pen)
  return WindowBezier(self.name, points, pen.color, pen.style, pen.width)
end

function Methods:DrawPolygon(points, pen, brush, winding)
  return WindowPolygon(self.name, points,
     pen.color, pen.style, pen.width,
     brush.color, brush,style,
     true, winding or false)
end

function Methods:DrawEllipse(left, top, right, bottom, pen, brush, image)
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

function Methods:DrawRectangle(left, top, right, bottom, pen, brush, image)
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

function Methods:DrawRoundedRectangle(left, top, right, bottom, width, height, pen, brush, image)
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

function Methods:DrawChord(left, top, right, bottom, chord_x1, chord_y1, chord_x2, chord_y2, pen, brush)
  return WindowCircleOp(self.name, 4, left, top, right, bottom,
     pen.color, pen.style, pen.width,
     brush.color, brush.style,
     chord_x1, chord_y1, chord_x2, chord_y2)
end

function Methods:DrawPie(left, top, right, bottom, slice_x1, slice_y1, slice_x2, slice_y2, pen, brush)
  return WindowCircleOp(self.name, 5, left, top, right, bottom,
     pen.color, pen.style, pen.width,
     brush.color, brush.style,
     slice_x1, slice_y1, slice_x2, slice_y2)
end

function Methods:DrawText(font_id, text, left, top, right, bottom, color, unicode)
  return WindowText(self.name, font_id, text,
     left, top, right, bottom,
     color, unicode or false)
end

function Methods:SaveAsImage(filename)
  return WindowWrite(self.name, filename)
end

function Methods:ImageInfo(id, infotype)
  return WindowImageInfo(self.name, id, infotype)
end

-- raw interface to WindowRectOp
-- Needs to be removed/renamed and split/merged into the rest of the API
function Methods:WindowRectOp(action, left, top, right, bottom, color1, color2)
  return WindowRectOp(self.name, action, left, top, right, bottom, color1, color2)
end

-- Ease-of-use function that wraps the process of deriving an image from a window and drawing it.
function Methods:BlitCanvas(canvas, x, y)
  self:ImageFromWindow("blitcanvas", canvas)
  self:DrawImage("blitcanvas", {x, y}, {}, 1)
  self:DeleteImage("blitcanvas")
end

MWidget.Canvas = Canvas
return Canvas
