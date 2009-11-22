local base = require("MWidget\\Window")

local Instance = {
  __index = base.__index,
  
  Cell = function(self, x, y)
    if x <= self.mapwidth and y <= self.mapheight and
	   x >= 1 and y >= 1 then
      return self.grid[y][x]
	else
	  return nil
	end
  end,
  
  ResetGrid = function(self)
    local grid = {}
	
	for i = 1, self.mapheight do
	  local line = {}
	  for j = 1, self.mapwidth do
	    line[#line+1] = {
		  char = " ",
		  forecolor = 0xFFFFFF,
		  backcolor = 0x000000,
		  hotspot = nil,
		}
	  end
	  grid[#grid+1] = line
	end
	
	self.grid = grid
  end,
  
  DrawCell = function(self, x, y)
    -- Index into the appropriate cell
    local left = self.font.width*(x-1)
    local top = self.font.height*(y-1)
    
    local cell = self:Cell(x, y)
    if cell == nil then
      return nil, "Invalid cell index."
    end
    
    if cell.backcolor ~= 0x000000 then
      WindowRectOp(self.name, 2, left, top,
         left+self.font+width, top+self.font.height, cell.backcolor)
    end
    
    WindowText(self.name, self.font.id, cell.char, left, top, 0, 0, cell.forecolor, false)
    if cell.hotspot then
      WindowAddHotspot(self.name, self.name .. "-h(" .. x .. "," .. y .. ")",
         left, top, left+self.font.width, top+self.font.height,
         cell.hotspot.mouseover, cell.hotspot.cancelmouseover,
         cell.hotspot.mousedown, cell.hotspot.camcelmousedown,
         cell.hotspot.mouseup, cell.hotspot.tooltip,
         cell.hotspot.cursor, 0)
    end
    
    return true
  end,
  
  Draw = function(self)
    self.font.id = self:SelectFont(self.font.name, self.font.size)
    
    self.font.width = WindowTextWidth(self.name, self.font.id, "#")
    self.font.height = WindowFontInfo(self.name, self.font.id,  1)
    
    self.width = self.font.width * self.mapwidth;
    self.height = self.font.height * self.mapheight;
    
    base.Draw(self)
	
    for y = 1, math.min(#self.grid, self.mapheight) do
	    local row = self.grid[y]
      for x = 1, math.min(#row, self.mapwidth) do
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

CharacterGrid.new = function(width, height, font, px)
  local o = base.new()
  setmetatable(o, CharacterGrid)
  
  o.mapwidth = width
  o.mapheight = height
  
  o.font = {
    name = font or "fixedsys",
    size = px or 10,
    width = 1,
    height = 1,
  }
  
  o:ResetGrid()
  
  o.font.id = o:SelectFont(o.font.name, o.font.size)
  
  return o
end

return CharacterGrid