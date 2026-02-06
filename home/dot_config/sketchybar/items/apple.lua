local colors = require("colors")
local app_icons = require("helpers.icon_map")

local paw = sbar.add("item", "apple", {
	icon = { drawing = "off" },
	label = {
		align = "center",
		string = app_icons["paw"],
		font = "sketchybar-app-font-bg:Regular:18.0",
		padding_left = 2,
		padding_right = 1,
		color = colors.cmap_1,
	},
	padding_left = 0,
	padding_right = 0,
})

sbar.add("bracket", { paw.name }, {
	background = {
		color = colors.tn_black3,
		border_color = colors.cmap_1,
		height = 24,
		corner_radius = 10,
	},
})

sbar.add("item", { width = 6 })
