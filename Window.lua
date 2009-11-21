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
  
  Draw = function(self, position, flags, background)
    WindowCreate(self.name, self.x, self.y,
	   self.width, self.height, position, flags, background)
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

Window.new = function(name, width, height)
  local o = setmetatable({}, Window)
  
  o.name = GetPluginID() .. ":w" .. #window_list+1
  o.x = 0
  o.y = 0
  o.width = width
  o.height = height
  
  -- Dummy window.
  WindowCreate(o.name, 0, 0, 0, 0, 0, 0, 0)
  WindowShow(o.name, false)
  
  return o
end

return Window