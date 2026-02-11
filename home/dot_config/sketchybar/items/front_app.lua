local colors = require("colors")
local settings = require("settings")

local front_app = sbar.add("item", "front_app", {
  display = "active",
  icon = { drawing = false },
  label = {
    font = {
      style = settings.font.style_map["Black"],
      size = 12.0,
    },
  },
  updates = true,
})

front_app:subscribe("front_app_switched", function(env)
  front_app:set({ label = { string = env.INFO } })
end)

front_app:subscribe("mouse.clicked", function(env)
  sbar.trigger("swap_menus_and_spaces")
end)

local mode_indicator = sbar.add("item", "mode_indicator", {
  display = "active",
  icon = { drawing = false },
  label = {
    font = {
      family = settings.font.text,
      style = settings.font.style_map["Bold"],
      size = 12.0,
    },
    string = "",
    color = colors.tn_black4,
    padding_left = 6,
    padding_right = 6,
  },
  background = {
    color = colors.tn_orange,
    corner_radius = 6,
    height = 20,
  },
  drawing = false,
})

mode_indicator:subscribe("aerospace_mode_change", function(env)
  if env.MODE == "service" then
    mode_indicator:set({ drawing = true, label = { string = "SERVICE" } })
  else
    mode_indicator:set({ drawing = false })
  end
end)
