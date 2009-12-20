local base = require("MWidget.Libraries.Canvas")

local Instance = {
  __index = base.__index,
  
  HotspotToCell = nil,
  DrawCell = nil,
  Font = nil,
  Resize = nil,
}
setmetatable(Instance, Instance)

local CharacterGrid = {
  __index = Instance,
  
  new = nil,
}
setmetatable(CharacterGrid, CharacterGrid)


function CharacterGrid.new(columns, rows)
  local o = base.new()
  setmetatable(o, CharacterGrid)
  
  o.columns = columns
  o.rows = rows
  
  o:Font(GetInfo(20), 10)
  
  return o
end

function Instance:HotspotToCell(hotspot_id)
  local _, _, x, y = string.find(hotspot_id, "%((%d+),(%d+)%)")
  
  return tonumber(x), tonumber(y)
end

function Instance:DrawCell(x, y, char, forecolor, backcolor)
  if x > self.columns or y > self.rows then
    return nil, "Invalid cell index."
  end
  
  -- Index into the appropriate cell
  local left = self.fonts["f"].width*(x-1)
  local top = self.fonts["f"].height*(y-1)
  local right = left+self.fonts["f"].width
  local bottom = top+self.fonts["f"].height
  
  self:DrawRectangle(left, top, right, bottom,
     {color = backcolor or self.backcolor,
      style = 0,
      width = 1},
     {color = backcolor or self.backcolor,
      style = 0})
  
  if char then
    self:DrawText("f", char, left, top, 0, 0, forecolor)
  end
  
  return true
end

function Instance:Font(...)
  -- Only needs one font, so don't confuse users with ids.
  local ok, err = base.Font(self, "f", ...)
  if ok then
    self.fonts["f"].width = self:TextWidth("f", "#")
    self.fonts["f"].height = self:FontInfo("f",  1)
    
    self:Resize(self.columns, self.rows)
  end
  return ok, err
end

function Instance:Resize(columns, rows)
  if columns < 1 or rows < 1 then
    return nil, "Invalid dimensions."
  end
  
  self.columns = columns
  self.rows = rows
  
  return base.Resize(self, self.fonts["f"].width * self.columns, self.fonts["f"].height * self.rows)
end

MWidget.CharacterGrid = CharacterGrid
return CharacterGrid
