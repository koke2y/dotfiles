local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.icon_map")

local spaces = {}

local colors_spaces = {
	["1"] = colors.cmap_1,
	["2"] = colors.cmap_2,
	["3"] = colors.cmap_3,
	["4"] = colors.cmap_4,
	["5"] = colors.cmap_5,
	["6"] = colors.cmap_6,
	["7"] = colors.cmap_7,
	["8"] = colors.cmap_8,
	["9"] = colors.cmap_9,
	["S"] = colors.cmap_10,
	["O"] = colors.cmap_10,
}

-- Query monitor/workspace mapping from AeroSpace (synchronous at init time)
-- AeroSpace and SketchyBar use reversed monitor numbering
local function get_monitor_workspace_map()
	local monitor_count = 0
	local aero_monitors = {}

	local handle = io.popen("aerospace list-monitors 2>/dev/null")
	if handle then
		for line in handle:lines() do
			local mid = line:match("^(%d+)")
			if mid then
				monitor_count = monitor_count + 1
				table.insert(aero_monitors, tonumber(mid))
			end
		end
		handle:close()
	end

	local ws_display = {}
	local all_workspace_ids = {}

	for _, mid in ipairs(aero_monitors) do
		local sketchybar_display = monitor_count - mid + 1
		local ws_handle = io.popen("aerospace list-workspaces --monitor " .. mid .. " 2>/dev/null")
		if ws_handle then
			for ws_id in ws_handle:lines() do
				ws_id = ws_id:match("^%s*(.-)%s*$")
				if ws_id and ws_id ~= "" then
					ws_display[ws_id] = sketchybar_display
					table.insert(all_workspace_ids, ws_id)
				end
			end
			ws_handle:close()
		end
	end

	return ws_display, all_workspace_ids
end

local ws_display_map, workspace_ids = get_monitor_workspace_map()

if #workspace_ids == 0 then
	workspace_ids = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "S", "O" }
end

-- Get windows for a specific workspace and update icon label
local function update_workspace_icons(ws_id, space_item)
	sbar.exec("aerospace list-windows --workspace " .. ws_id .. " --format '%{app-name}'", function(result)
		local icon_line = ""
		local no_app = true
		for app in result:gmatch("[^\r\n]+") do
			no_app = false
			local lookup = app_icons[app]
			local icon = ((lookup == nil) and app_icons["default"] or lookup)
			icon_line = icon_line .. utf8.char(0x202F) .. icon
		end

		if no_app then
			icon_line = "—"
		end
		sbar.animate("tanh", 10, function()
			space_item:set({ label = icon_line })
		end)
	end)
end

for _, ws_id in ipairs(workspace_ids) do
	local color = colors_spaces[ws_id] or colors.grey
	local display = ws_display_map[ws_id]

	local space = sbar.add("item", "space." .. ws_id, {
		display = display,
		icon = {
			font = {
				family = settings.font.numbers,
				size = 14,
			},
			string = ws_id,
			padding_left = 5,
			padding_right = 0,
			color = color,
			highlight_color = colors.tn_black3,
		},
		label = {
			padding_right = 10,
			padding_left = 3,
			color = color,
			font = "sketchybar-app-font-bg:Regular:21.0",
			y_offset = -2,
		},
		padding_right = 4,
		padding_left = 4,
		background = {
			color = colors.transparent,
			height = 22,
			border_width = 0,
			border_color = colors.transparent,
		},
		popup = { background = { border_width = 5, border_color = colors.black } },
	})

	spaces[ws_id] = space

	-- Padding space
	sbar.add("item", "space.padding." .. ws_id, {
		display = display,
		script = "",
		width = settings.group_paddings,
	})

	local space_popup = sbar.add("item", {
		position = "popup." .. space.name,
		padding_left = 0,
		padding_right = 0,
		background = {
			drawing = true,
			image = {
				corner_radius = 6,
				scale = 0.2,
			},
		},
	})

	space:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "other" then
			space_popup:set({ background = { image = "space." .. ws_id } })
			space:set({ popup = { drawing = "toggle" } })
		else
			sbar.exec("aerospace workspace " .. ws_id)
		end
	end)

	space:subscribe("mouse.exited", function(_)
		space:set({ popup = { drawing = false } })
	end)
end

-- Group workspace items into brackets per display
local display_spaces = {}
for _, ws_id in ipairs(workspace_ids) do
	local d = ws_display_map[ws_id] or 1
	if not display_spaces[d] then
		display_spaces[d] = {}
	end
	table.insert(display_spaces[d], spaces[ws_id].name)
end

for _, names in pairs(display_spaces) do
	sbar.add("bracket", names, {
		background = {
			color = colors.background,
			border_color = colors.accent3,
			border_width = 2,
		},
	})
end

sbar.add("event", "aerospace_mode_change")

local space_window_observer = sbar.add("item", {
	drawing = false,
	updates = true,
})

sbar.add("item", { width = 6 })

local spaces_indicator = sbar.add("item", {
	background = {
		color = colors.with_alpha(colors.grey, 0.0),
		border_color = colors.with_alpha(colors.bg1, 0.0),
		border_width = 0,
		corner_radius = 6,
		height = 24,
		padding_left = 6,
		padding_right = 6,
	},
	icon = {
		font = {
			family = settings.font.text,
			style = settings.font.style_map["Bold"],
			size = 14.0,
		},
		padding_left = 6,
		padding_right = 9,
		color = colors.accent1,
		string = icons.switch.on,
	},
	label = {
		drawing = "off",
		padding_left = 0,
		padding_right = 0,
	},
})

-- Subscribe to aerospace_workspace_change instead of space_change / space_windows_change
space_window_observer:subscribe("aerospace_workspace_change", function(env)
	local focused = env.FOCUSED_WORKSPACE

	-- Highlight focused workspace
	for _, ws_id in ipairs(workspace_ids) do
		local selected = (ws_id == focused)
		local color = colors_spaces[ws_id] or colors.grey
		sbar.animate("tanh", 10, function()
			spaces[ws_id]:set({
				icon = { highlight = selected },
				label = { highlight = selected },
				background = {
					height = 25,
					border_color = selected and color,
					color = selected and color,
					corner_radius = selected and 6,
				},
			})
		end)
	end

	-- Update app icons for all workspaces
	for _, ws_id in ipairs(workspace_ids) do
		update_workspace_icons(ws_id, spaces[ws_id])
	end
end)

-- Also update icons on app focus change
space_window_observer:subscribe("front_app_switched", function(env)
	for _, ws_id in ipairs(workspace_ids) do
		update_workspace_icons(ws_id, spaces[ws_id])
	end
end)

-- Initial state
sbar.exec("aerospace list-workspaces --focused", function(result)
	local focused = result:gsub("%s+", "")
	for _, ws_id in ipairs(workspace_ids) do
		local selected = (ws_id == focused)
		local color = colors_spaces[ws_id] or colors.grey
		spaces[ws_id]:set({
			icon = { highlight = selected },
			label = { highlight = selected },
			background = {
				height = 25,
				border_color = selected and color,
				color = selected and color,
				corner_radius = selected and 6,
			},
		})
		update_workspace_icons(ws_id, spaces[ws_id])
	end
end)

spaces_indicator:subscribe("swap_menus_and_spaces", function(env)
	local currently_on = spaces_indicator:query().icon.value == icons.switch.on
	spaces_indicator:set({
		icon = currently_on and icons.switch.off or icons.switch.on,
	})
end)

spaces_indicator:subscribe("mouse.entered", function(env)
	sbar.animate("tanh", 30, function()
		spaces_indicator:set({
			background = {
				color = colors.tn_black1,
				border_color = { alpha = 1.0 },
				padding_left = 6,
				padding_right = 6,
			},
			icon = {
				color = colors.accent1,
				padding_left = 6,
				padding_right = 9,
			},
			label = { drawing = "off" },
			padding_left = 6,
			padding_right = 6,
		})
	end)
end)

spaces_indicator:subscribe("mouse.exited", function(env)
	sbar.animate("tanh", 30, function()
		spaces_indicator:set({
			background = {
				color = { alpha = 0.0 },
				border_color = { alpha = 0.0 },
			},
			icon = { color = colors.accent1 },
			label = { width = 0 },
		})
	end)
end)

spaces_indicator:subscribe("mouse.clicked", function(env)
	sbar.trigger("swap_menus_and_spaces")
end)

local front_app_icon = sbar.add("item", "front_app_icon", {
	display = "active",
	icon = { drawing = false },
	label = {
		font = "sketchybar-app-font-bg:Regular:21.0",
	},
	updates = true,
	padding_right = 0,
	padding_left = -10,
})

front_app_icon:subscribe("front_app_switched", function(env)
	local icon_name = env.INFO
	local lookup = app_icons[icon_name]
	local icon = ((lookup == nil) and app_icons["default"] or lookup)
	front_app_icon:set({ label = { string = icon, color = colors.accent1 } })
end)

sbar.add("bracket", {
	spaces_indicator.name,
	front_app_icon.name,
}, {
	background = {
		color = colors.tn_black3,
		border_color = colors.accent1,
		border_width = 2,
	},
})
