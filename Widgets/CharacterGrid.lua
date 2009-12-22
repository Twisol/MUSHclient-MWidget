local base = require("MWidget.Libraries.WidgetBase")

local Instance = {
  __index = base.__index,
  
  OnPaint = nil,
  
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
  o:Resize(columns, rows)
  
  return o
end


local DrawCell = function(self, cell, x, y)
  -- Index into the appropriate cell
  local left = self.font.width*(x-1)
  local top = self.font.height*(y-1)
  local right = left+self.font.width
  local bottom = top+self.font.height
  
  self.canvas:DrawRectangle(left, top, right, bottom,
     {color = cell.backcolor or self.canvas.backcolor,
      style = 0,
      width = 1},
     {color = cell.backcolor or self.canvas.backcolor,
      style = 0})
  
  self.canvas:DrawText("f", cell.char, left, top, 0, 0, cell.forecolor)
  
  return true
end

function Instance:Cell(x, y)
  if x > self.columns or y > self.rows then
    return nil, "Invalid cell index."
  end
  
  return self.grid[y][x]
end

function Instance:HotspotToCell(hotspot)
  local _, _, x, y = string.find(hotspot.name, "%((%d+),(%d+)%)")
  x, y = tonumber(x), tonumber(y)
  
  return self:Cell(x, y), x, y
end

function Instance:Font(name, size)
  -- Only needs one font, so don't confuse users with ids.
  self.font = assert(self.canvas:Font("f", name, size))
  
  -- Record some extra information for later.
  self.font.width = self.canvas:TextWidth("f", "#")
  self.font.height = self.canvas:FontInfo("f",  1)
  self.width = self.font.width * self.columns
  self.height = self.font.height * self.rows
  
  self:Invalidate()
  self.canvas:Resize(self.width, self.height)
end

function Instance:ResetGrid()
  local grid = {}
  
  for y = 1, self.rows do
    local row = {}
    for x = 1, self.columns do
      local left = self.font.width*(x-1)
      local top = self.font.height*(y-1)
      
      local hotspot = self:AddHotspot("(" .. x .. "," .. y .. ")",
         left, top, left + self.font.width, top + self.font.height)
      
      row[#row+1] = {
        char = " ",
        forecolor = 0xFFFFFF,
        hotspot = hotspot,
      }
    end
    grid[#grid+1] = row
  end
 
  self.grid = grid
end

function Instance:Resize(columns, rows)
  if columns < 1 or rows < 1 then
    return nil, "Invalid dimensions."
  end
  
  self.columns = columns
  self.rows = rows
  self.width = self.font.width * self.columns
  self.height = self.font.height * self.rows
  
  -- Start with a blank slate
  self:ResetGrid()
  
  self:Invalidate()
  return self.canvas:Resize(self.width, self.height)
end

function Instance:OnPaint()
  self.canvas:Clear()
  for y = 1, self.rows do
    for x = 1, self.columns do
      DrawCell(self, self:Cell(x,y), x, y)
    end
  end
end

MWidget.CharacterGrid = CharacterGrid
return CharacterGrid
