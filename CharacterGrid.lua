local base = require("MWidget.Window")

local Instance = {
  __index = base.__index,
  
  HotspotToCell = nil,
  Cell = nil,
  ResetGrid = nil,
  DrawCell = nil,
  Font = nil,
  Resize = nil,
  Repaint = nil,
}
setmetatable(Instance, Instance)

local CharacterGrid = {
  __index = Instance,
  
  new = nil,
}
setmetatable(CharacterGrid, CharacterGrid)


function CharacterGrid.new(columns, rows)
  local o = base.new(0, 0)
  setmetatable(o, CharacterGrid)
  
  o.rows = rows
  o.columns = columns
  
  o:Font(GetInfo(20), 10)
  o:ResetGrid()
  
  return o
end

function Instance:HotspotToCell(hotspot_id)
  local _, _, x, y = string.find(hotspot_id, "%((%d+),(%d+)%)")
  x, y = tonumber(x), tonumber(y)
  
  return grid:Cell(x, y), x, y
end

function Instance:Cell(x, y)
  if x <= self.columns and y <= self.rows and
     x >= 1 and y >= 1 then
    return self.grid[y][x]
  else
    return nil, "invalid coordinate"
  end
end

function Instance:ResetGrid()
  local grid = {}
  
  self:DeleteAllHotspots()
  
  for y = 1, self.rows do
    local row = {}
    for x = 1, self.columns do
      local left = self.fonts["f"].width*(x-1)
      local top = self.fonts["f"].height*(y-1)
      
      row[#row+1] = {
        char = " ",
        backcolor = self.backcolor,
        forecolor = 0xFFFFFF,
        hotspot = self:AddHotspot("(" .. x .. "," .. y .. ")",
               left, top,
               left+self.fonts["f"].width, top+self.fonts["f"].height)
      }
    end
    grid[#grid+1] = row
  end

  self.grid = grid
end

function Instance:DrawCell(x, y)
  -- Index into the appropriate cell
  local left = self.fonts["f"].width*(x-1)
  local top = self.fonts["f"].height*(y-1)
  local right = left+self.fonts["f"].width
  local bottom = top+self.fonts["f"].height
  
  local cell = self:Cell(x, y)
  if cell == nil then
    return nil, "Invalid cell index."
  end
  
  self:WindowRectOp(2, left, top, right, bottom, cell.backcolor)
  self:DrawText("f", cell.char, left, top, 0, 0, cell.forecolor)
  
  return true
end

function Instance:Font(...)
  -- Only needs one font, so don't confuse users with ids.
  local ok, err = base.Font(self, "f", ...)
  if ok then
    self.fonts["f"].width = self:TextWidth("f", "#")
    self.fonts["f"].height = self:FontInfo("f",  1)
    
    self.width = self.fonts["f"].width * self.columns;
    self.height = self.fonts["f"].height * self.rows;
  end
  return ok, err
end

function Instance:Resize(columns, rows)
  if columns < 1 or rows < 1 then
    return nil, "Invalid dimensions."
  end
  
  local oldgrid = self.grid
  local oldrows = self.rows
  local oldcolumns = self.columns
  
  self.columns = columns
  self.rows = rows
  self:ResetGrid()
  
  for y = 1, math.min(rows, oldrows) do
    for x = 1, math.min(columns, oldcolumns) do
      self.grid[y][x] = oldgrid[y][x]
    end
  end
  
  self.width = self.fonts["f"].width * self.columns;
  self.height = self.fonts["f"].height * self.rows;
  
  return true
end

function Instance:Repaint()
  base.Repaint(self)
  
  for y = 1, math.min(#self.grid, self.rows) do
    local row = self.grid[y]
    for x = 1, math.min(#row, self.columns) do
      self:DrawCell(x, y)
    end
  end
end

MWidget.CharacterGrid = CharacterGrid
return CharacterGrid
