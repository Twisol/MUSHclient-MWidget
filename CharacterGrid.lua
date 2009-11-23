local base = require("MWidget\\Window")

local Instance = {
  __index = base.__index,
  
  Cell = function(self, x, y)
    if x <= self.columns and y <= self.rows and
       x >= 1 and y >= 1 then
      return self.grid[y][x]
    else
      return nil
    end
  end,
  
  ResetGrid = function(self)
    local grid = {}
    
    for i = 1, self.rows do
      local row = {}
      for j = 1, self.columns do
        row[#row+1] = {
          char = " ",
          forecolor = 0xFFFFFF,
          backcolor = 0x000000,
          hotspot = nil,
        }
      end
      grid[#grid+1] = row
    end
  
    self.grid = grid
  end,
  
  DrawCell = function(self, x, y)
    -- Index into the appropriate cell
    local left = self.fonts["f"].width*(x-1)
    local top = self.fonts["f"].height*(y-1)
    local right = left+self.fonts["f"].width
    local bottom = top+self.fonts["f"].height
    
    local cell = self:Cell(x, y)
    if cell == nil then
      return nil, "Invalid cell index."
    end
    
    if cell.backcolor ~= 0x000000 then
      WindowRectOp(self.name, 2, left, top, right, bottom, cell.backcolor)
    end
    
    WindowText(self.name, "f", cell.char, left, top, 0, 0, cell.forecolor, false)
    if cell.hotspot then
      WindowAddHotspot(self.name, self.name .. "-h(" .. x .. "," .. y .. ")",
         left, top, left+self.fonts["f"].width, top+self.fonts["f"].height,
         cell.hotspot.mouseover, cell.hotspot.cancelmouseover,
         cell.hotspot.mousedown, cell.hotspot.camcelmousedown,
         cell.hotspot.mouseup, cell.hotspot.tooltip,
         cell.hotspot.cursor, 0)
    end
    
    return true
  end,
  
  Font = function(self, ...)
    -- Only needs one font, so don't confuse users with ids.
    local ok, err = base.Font(self, "f", ...)
    if ok then
      self.fonts["f"].width = WindowTextWidth(self.name, "f", "#")
      self.fonts["f"].height = WindowFontInfo(self.name, "f",  1)
      
      self.width = self.fonts["f"].width * self.columns;
      self.height = self.fonts["f"].height * self.rows;
    end
    return ok, err
  end,
  
  Draw = function(self, show)
    base.Draw(self, show)
    
    for y = 1, math.min(#self.grid, self.rows) do
      local row = self.grid[y]
      for x = 1, math.min(#row, self.columns) do
        self:DrawCell(x, y)
      end
    end
  end,
}
setmetatable(Instance, Instance)

local CharacterGrid = {
  __index = Instance,
  
  new = nil,
}
setmetatable(CharacterGrid, CharacterGrid)

CharacterGrid.new = function(columns, rows)
  local o = base.new(0, 0)
  setmetatable(o, CharacterGrid)
  
  o.rows = rows
  o.columns = columns
  
  o:Font("fixedsys", 10)
  o:ResetGrid()
  
  return o
end

return CharacterGrid