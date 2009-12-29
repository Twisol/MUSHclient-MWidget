--- Semantic versioning: http://semver.org/
local V_MAJOR = 0 -- Major changes to the API - think first!
local V_MINOR = 1 -- Backwards-compatible features/changes
local V_PATCH = 0 -- Outwardly-visible bugfixes and the like.
local VERSION = string.format("v%d.%d.%d", V_MAJOR, V_MINOR, V_PATCH)

local Methods = {
  Load = nil,
}

-- Global MWidget table - do not rename!
MWidget = {
  Widgets = {},
  
  __V = VERSION,
  __V_MAJOR = V_MAJOR,
  __V_MINOR = V_MINOR,
  __V_PATCH = V_PATCH,
}
setmetatable(MWidget, {__index = Methods})

function Methods.Load(name)
  local widget = require("MWidget.Widgets." .. name)
  MWidget.Widgets[name] = widget
  return widget
end

return MWidget
