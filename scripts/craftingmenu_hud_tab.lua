local CraftingMenuDetails = require "widgets/redux/craftingmenu_details"
local CraftingMenuWidget = require "widgets/redux/craftingmenu_widget"
local UIAnim = require "widgets/uianim"
local HEIGHT = 650
local CRAFTING_FILTERS = _G.CRAFTING_FILTERS
local Vector3 = _G.Vector3
local CRAFTING_ATLAS = _G.CRAFTING_ATLAS
local CRAFTING_FILTER_DEFS = _G.CRAFTING_FILTER_DEFS
local STRINGS = _G.STRINGS
local SCALE = 0.75

AddClassPostConstruct("widgets/redux/craftingmenu_skinselector", function(self, recipe, owner, skin_name)
	self:SetScale(SCALE)
end)
AddClassPostConstruct("widgets/redux/craftingmenu_widget", function(self, owner, crafting_hud, height)
self.MakeFrame = function(self, width, height)
	local w = Widget("crafting_menu_frame")

	local atlas = resolvefilepath(CRAFTING_ATLAS)

	self.filter_panel = w:AddChild(self:MakeFilterPanel(width)) -- +17
	local filters_height = 50 --147

	height = height + math.max(filters_height - 147, 0)

	local fill = w:AddChild(Image(atlas, "backing.tex"))
	fill:ScaleToSize(width + 10, height + 18)
	fill:SetTint(1, 1, 1, 0.5)

	local left = w:AddChild(Image(atlas, "side.tex"))
	left:SetPosition(-width/2 - 8, 1)
	left:ScaleToSize(-26, -(height - 20))

	local right = w:AddChild(Image(atlas, "side.tex"))
	right:SetPosition(width/2 + 8, 1)
	right:ScaleToSize(26, height - 20)
	right:SetClickable(false)

	local top = w:AddChild(Image(atlas, "top.tex"))
	top:SetPosition(0, height/2 + 10)
	top:ScaleToSize(434, 38)	--534

	local bottom = w:AddChild(Image(atlas, "bottom.tex"))
	bottom:SetPosition(0, -height/2 - 8)
	bottom:ScaleToSize(434, 38)	--534
	bottom:SetClickable(false)

	----------------
	self.filter_panel:SetPosition(0, height/2 - 20)
	self.filter_panel:MoveToFront()

	self.recipe_grid = w:AddChild(self:MakeRecipeList(width, height - filters_height))
	local grid_w, grid_h = self.recipe_grid:GetScrollRegionSize() -- 231
	self.recipe_grid:SetPosition(-30, height/2 - filters_height - grid_h/2)
	
	self.no_recipes_msg = w:AddChild(Text(_G.UIFONT, 30, STRINGS.UI.CRAFTING_MENU.NO_ITEMS, _G.UICOLOURS.GOLD_UNIMPORTANT))
	self.no_recipes_msg:SetPosition(-2, height/2 - filters_height - grid_h/2)
	self.no_recipes_msg:Hide()

	----------------

	-- self.itemlist_split = w:AddChild(Image(atlas, "horizontal_bar.tex"))
	-- self.itemlist_split:SetPosition(0, height/2 - filters_height)
	-- self.itemlist_split:ScaleToSize(402, 15)
	
	self.itemlist_split = w:AddChild(Image(atlas, "side.tex"))
	self.itemlist_split:SetPosition(width/3+13, height/2 - filters_height - grid_h - 115)
	self.itemlist_split:ScaleToSize(20,  height/3 + 5)
	
	self.itemlist_split2 = w:AddChild(Image(atlas, "horizontal_bar.tex"))
	self.itemlist_split2:SetPosition(-27, height/2 - filters_height - grid_h - 2)
	self.itemlist_split2:ScaleToSize(345, 15)

	----------------

	self.details_root = w:AddChild(CraftingMenuDetails(self.owner, self, width - 20 * 2 - 50, height - 20 * 2))
	self.details_root:SetPosition(-30, height/2 - filters_height - grid_h - 10)
	
	----------------

	self.recipe_grid:MoveToBack()

	fill:MoveToBack()
	return w
end

self.MakeFilterPanel = function(self, width)
	width = width - 40
	local button_size = 38
	local grid_button_space = button_size + 5
	local grid_buttons_wide = math.floor(width/(button_size + 1))
	local grid_left = -grid_button_space * grid_buttons_wide/2 + grid_button_space/2
	local grid_right = grid_button_space * grid_buttons_wide/2 - grid_button_space/2 + 5

    local w = Widget("FilterPanel")

	self.top_row_widgets = {}

	local y = -2

	-- favorites filter button
	local favorites_filter = w:AddChild(self:MakeFilterButton(CRAFTING_FILTERS.FAVORITES, button_size))
	favorites_filter:SetPosition(grid_left, y)
	self.filter_buttons[CRAFTING_FILTERS.FAVORITES.name] = favorites_filter
	self.favorites_filter = favorites_filter
	table.insert(self.top_row_widgets, favorites_filter)

	-- special_event_filter
	local event_layout = _G.IsAnySpecialEventActive()
	if event_layout then
		local special_event_filter = w:AddChild(self:MakeFilterButton(CRAFTING_FILTERS.SPECIAL_EVENT, button_size))
		special_event_filter:SetPosition(grid_left + grid_button_space, y)
		self.filter_buttons[CRAFTING_FILTERS.SPECIAL_EVENT.name] = special_event_filter

		local event_name
		if _G.GetActiveSpecialEventCount() == 1 then
			event_name = STRINGS.UI.SPECIAL_EVENT_NAMES[string.upper(_G.GetFirstActiveSpecialEvent())]
		else
			event_name = STRINGS.UI.SPECIAL_EVENT_NAMES.MULTIPLE_EVENTS
		end
		special_event_filter:SetHoverText(event_name or "")
		--special_event_filter.filter_img:SetTexture(crafting_station_def.filter_atlas, crafting_station_def.filter_image)
		--special_event_filter.filter_img:ScaleToSize(54, 54)

		self.special_event_filter = special_event_filter
		table.insert(self.top_row_widgets, special_event_filter)
	end

	-- favorites filter button
	local filter_station = w:AddChild(self:MakeFilterButton(CRAFTING_FILTERS.CRAFTING_STATION, button_size))
	filter_station:SetPosition(grid_left + grid_button_space + (event_layout and grid_button_space or 0), y)
	self.filter_buttons[CRAFTING_FILTERS.CRAFTING_STATION.name] = filter_station
	self.crafting_station_filter = filter_station
	table.insert(self.top_row_widgets, filter_station)

	-- search bar
    self.search_box = w:AddChild(self:MakeSearchBox(grid_button_space * (event_layout and 5 or 6.5)* 0.7, 40))
	self.search_box:SetPosition(0, y)
	table.insert(self.top_row_widgets, self.search_box)

	-- modded items filter button
	local filter_mods = w:AddChild(self:MakeFilterButton(CRAFTING_FILTERS.MODS, button_size))
	filter_mods:SetPosition(grid_left + grid_button_space * 7, y)
	self.filter_buttons[CRAFTING_FILTERS.MODS.name] = filter_mods
	self.mods_filter = filter_mods
	table.insert(self.top_row_widgets, filter_mods)

	-- sort button
	self.sort_button = w:AddChild(self:AddSorter())
	self.sort_button:SetPosition(grid_left + grid_button_space * 8, y)
	table.insert(self.top_row_widgets, self.sort_button)

	y = y - button_size / 2

	-- Divider
	y = y - 5
	local line_height = 4
	local line = w:AddChild(Image("images/ui.xml", "line_horizontal_white.tex"))
	line:SetPosition(0, y - line_height/2)
    line:SetTint(_G.unpack(_G.BROWN))
	line:ScaleToSize(width, line_height)
	line:MoveToBack()
	y = y - line_height

	-- grid
	y = y - 8 - 17
	local filter_grid = w:AddChild(Grid())
    filter_grid:SetLooping(false, false)

	local widgets = {}
	for i, filter_def in ipairs(CRAFTING_FILTER_DEFS) do
		if not filter_def.custom_pos and (filter_def ~= CRAFTING_FILTERS.MODS or #filter_def.recipes > 0) then
			local w = self:MakeFilterButton(filter_def, button_size)
			self.filter_buttons[filter_def.name] = w
			table.insert(widgets, w)
		end
	end
	filter_grid:FillGrid(1, grid_button_space, button_size+1, widgets) --grid_buttons_wide
	filter_grid:SetPosition(grid_right, y)

	y = y - grid_button_space * filter_grid.num_rows - 6

	w.filter_grid = filter_grid
	w.focus_forward = filter_grid

	w:SetOnGainFocus(function()
		if TheInput:ControllerAttached() then
			self:PopulateRecipeDetailPanel(nil, nil)
		end
	end)

	w.panel_height = math.abs(y)

	return w
end

self.frame:KillAllChildren()
self.frame = self.root:AddChild(self:MakeFrame(400, height))
end)

AddClassPostConstruct("widgets/redux/craftingmenu_hud", function(self, owner, is_left_aligned)
	local y_offset = _G.IsSplitScreen() and -50 or 0
	if is_left_aligned then
		self.closed_pos = Vector3(0, y_offset, 0)
		self.opened_pos = Vector3(370, y_offset, 0)
	else
		self.closed_pos = Vector3(0, y_offset, 0)
		self.opened_pos = Vector3(-370, y_offset, 0)
	end
	self.craftingmenu:Kill()
	self.craftingmenu = self.ui_root:AddChild(CraftingMenuWidget(owner, self, HEIGHT))
	self.craftingmenu:SetPosition(is_left_aligned and -155 or 155, 20) -- 180
	self.craftingmenu:Disable()
	
	self.pinbar:SetPosition(50, 0)
end)