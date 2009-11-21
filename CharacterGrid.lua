local base = require("MWidget\\Window")

local Instance = {
  __index = base.__index,
  
  DrawCell = function(self, cell, x, y)
    -- Index into the appropriate cell
    local x = self.font.width*x
    local y = self.font.height*y
    
    WindowText(self.name, self.font.id, cell.char, x, y, 0, 0, cell.style, false)
    if cell.hotspot then
      WindowAddHotspot(self.name, self.name .. "-h" .. x .. y,
         x, y, x+self.font.width, y+self.font.height,
         cell.hotspot.mouseover, cell.hotspot.cancelmouseover,
         cell.hotspot.mousedown, cell.hotspot.camcelmousedown,
         cell.hotspot.mouseup, cell.hotspot.tooltip,
         cell.hotspot.cursor, 0)
    end
  end,
      
  DrawRow = function(self, line, row)
    for i = 1, math.min(table.getn(line), self.mapwidth) do
      self:DrawCell(line[i], i-1, row)
    end
  end,
  
  DrawGrid = function(self)
    for i = 1, math.min(table.getn(self), self.mapheight) do
      self:DrawRow(self[i], i-1)
    end
  end,
  
  ResetGrid = function(self)
    if #self < self.mapheight then
      for i = #self+1, self.mapwidth do
        local line = {}
        for i = 1, self.mapwidth do
          line[i] = {char = " ", style = 0x000000, hotspot = nil}
        end
        table.insert(self, line)
      end
    end
    
    for k,v in ipairs(self) do
      for k,v in ipairs(v) do
        v.char = " "
        v.style = 0x000000
      end
    end
  end,
  
  Draw = function(self)
    self.font.id = self:SelectFont(self.font.name, self.font.size)
    
    self.font.width = WindowTextWidth(self.name, self.font.id, "#")
    self.font.height = WindowFontInfo(self.name, self.font.id,  1)
    
    self.width = self.font.width * self.mapwidth;
    self.height = self.font.height * self.mapheight;
    
    base.Draw(self, 6, 2, 0x000000)
    self:DrawGrid()
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