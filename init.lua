local Methods = {
  Load = nil,
}

-- Global MWidget table - do not rename!
MWidget = {
  Widgets = {}
}
setmetatable(MWidget, {__index = Methods})

function Methods.Load(name)
  local widget = require("MWidget.Widgets." .. name)
  MWidget.Widgets[name] = widget
  return widget
end

return MWidget
