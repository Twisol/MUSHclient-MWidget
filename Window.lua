local window_list = setmetatable({}, {__mode = "v"})

local Instance = {
  Clear = function(self, color)
    WindowRectOp(self.name, 2, 0, 0, 0, 0, color or 0x000000)
  end,
  
  Show = function(self)
    WindowShow(self.name, true)
  end,
  
  IsShown = function(self)
    return WindowInfo(self.name, 5)
  end,
  
  Hide = function(self)
    WindowShow(self.name, false)
  end,
  
  Move = function(self, x, y)
    if self.position == nil then
      self.position = {}
    end
    
    self.position.x = x
    self.position.y = y
    self.position.anchor = -1
    self.position.absolute = true
  end,
  
  Anchor = function(self, anchor)
    if self.position == nil then
      self.position = {}
    end
    
    self.position.x = -1
    self.position.y = -1
    self.position.anchor = anchor
    self.position.absolute = false
  end,
  
  SelectFont = function(self, fontname, fontsize)
    local fid = nil
    local fontlist = WindowFontList(self.name)
    
    if fontlist then
      for _,v in ipairs(fontlist) do
        if WindowFontInfo(self.name, v, 21) == fontname and
           WindowFontInfo(self.name, v, 8) == fontsize then
          break
        end
      end
    end
    
    if not fid then
      local numfonts = fontlist and #fontlist or 0
      fid = self.name .. "-f" .. numfonts+1
      WindowFont(self.name, fid, fontname, fontsize, false, false, false, false, 1, 0)
    end
    
    return fid
  end,
  
  Draw = function(self)
    local flags = self.flags or 0
    if self.position.absolute then
      flags = bit.bor(flags, 2)
    end
    
    WindowDelete(self.name)
    WindowCreate(self.name, self.position.x, self.position.y,
	     self.width, self.height, self.position.anchor, flags, self.backcolor)
  end,
  
  Destroy = function(self)
    WindowDelete(self.name)
  end,
}

local Window = {
  __index = Instance,
  
  new = nil,
}
setmetatable(Window, Window)

Window.new = function(width, height)
  local o = setmetatable({}, Window)
  window_list[#window_list+1] = o
  
  o.name = GetPluginID() .. ":w" .. #window_list
  o.width = width or 0
  o.height = height or 0
  o.backcolor = 0x000000
  o.flags = 0
  o.position = {}
  
  o:Move(0, 0)
  
  -- Dummy window.
  WindowCreate(o.name, 0, 0, 0, 0, 0, 0, 0)
  WindowShow(o.name, false)
  
  return o
end

return Window