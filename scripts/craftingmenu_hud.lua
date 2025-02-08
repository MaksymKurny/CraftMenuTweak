local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Grid = require "widgets/grid"
local UIAnim = require "widgets/uianim"

local CraftingMenuDetails = require "widgets/redux/craftingmenu_details"
local CraftingMenuWidget = require "widgets/redux/craftingmenu_widget"
local CraftingMenuPinBar = require "widgets/redux/craftingmenu_pinbar"

local AddClassPostConstruct = AddClassPostConstruct
local GetModConfigData = GetModConfigData

local HEIGHT = 650
local SCALE = 0.75
local SEARCH_BOX_HEIGHT = 40

GLOBAL.setfenv(1, GLOBAL)

AddClassPostConstruct("widgets/redux/craftingmenu_skinselector", function(self, recipe, owner, skin_name)
	self:SetScale(SCALE)
end)
AddClassPostConstruct("widgets/redux/craftingmenu_widget", function(self, owner, crafting_hud, height)
	self.UpdateEventButtonLayout = function(self)
		local is_event_layout = self.event_layout
		self.event_layout = self.special_event_filter.num_can_build ~= nil and self.special_event_filter.num_can_build > 0 or
		self.special_event_filter.has_unlocked or false

		if is_event_layout ~= self.event_layout then
			if self.event_layout then
				self.special_event_filter:Show()
				self.special_event_filter:SetHoverText(GetActiveSpecialEventCount() == 1 and
				STRINGS.UI.SPECIAL_EVENT_NAMES[string.upper(GetFirstActiveSpecialEvent())] or
				STRINGS.UI.SPECIAL_EVENT_NAMES.MULTIPLE_EVENTS)

				local pt = self.crafting_station_filter:GetPosition()
				self.crafting_station_filter:SetPosition(
				self.grid_left + self.grid_button_space + (self.event_layout and self.grid_button_space or 0), pt.y)

				self.search_box.textbox_root.textbox_bg:ScaleToSize(self.grid_button_space * 3.5, SEARCH_BOX_HEIGHT)
				self.search_box.textbox_root.textbox:SetRegionSize(self.grid_button_space * 3.5 - 30, SEARCH_BOX_HEIGHT)
			else
				self.special_event_filter:Hide()

				local pt = self.crafting_station_filter:GetPosition()
				self.crafting_station_filter:SetPosition(self.grid_left + self.grid_button_space, pt.y)

				self.search_box.textbox_root.textbox_bg:ScaleToSize(self.grid_button_space * 4, SEARCH_BOX_HEIGHT)
				self.search_box.textbox_root.textbox:SetRegionSize(self.grid_button_space * 4 - 30, SEARCH_BOX_HEIGHT)
			end
		end
	end

	local _RefreshCraftingHelpText = self.RefreshCraftingHelpText
	self.RefreshCraftingHelpText = function(self, controller_id)
		if self.filter_panel.focus then
			return TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT) ..
			" " ..
			STRINGS.UI.HUD.SELECT ..
			" " .. TheInput:GetLocalizedControl(controller_id, CONTROL_MENU_MISC_1) .. " " .. STRINGS.UI.CRAFTING_MENU.PIN
		end
		return _RefreshCraftingHelpText(self, controller_id)
	end

	self.MakeFrame = function(self, width, height)
		local w = Widget("crafting_menu_frame")

		local atlas = resolvefilepath(CRAFTING_ATLAS)

		self.filter_panel = w:AddChild(self:MakeFilterPanel(width + 17))
		local filters_height = self.filter_panel.panel_height --147

		height = height + math.max(filters_height - 147, 0)

		local fill = w:AddChild(Image(atlas, "backing.tex"))
		fill:ScaleToSize(width + 10, height + 12, 6)
		fill:SetTint(1, 1, 1, 0.5)

		local left = w:AddChild(Image(atlas, "side.tex"))
		left:SetPosition(-width / 2 - 8, 1)
		left:ScaleToSize(-26, -(height - 20))

		local right = w:AddChild(Image(atlas, "side.tex"))
		right:SetPosition(width / 2 + 8, 1)
		right:ScaleToSize(26, height - 20)
		right:SetClickable(false)

		local top = w:AddChild(Image(atlas, "top.tex"))
		top:SetPosition(0, height / 2 + 10)
		top:ScaleToSize(375, 38)

		local bottom = w:AddChild(Image(atlas, "bottom.tex"))
		bottom:SetPosition(0, -height / 2 - 8)
		bottom:ScaleToSize(375, 38)
		bottom:SetClickable(false)

		----------------
		self.filter_panel:SetPosition(0, height / 2 - 20)
		self.filter_panel:MoveToFront()

		self.recipe_grid = w:AddChild(self:MakeRecipeList(width, height - filters_height))
		local grid_w, grid_h = self.recipe_grid:GetScrollRegionSize()
		self.recipe_grid:SetPosition(-2, height / 2 - filters_height - grid_h / 2)

		self.no_recipes_msg = w:AddChild(Text(UIFONT, 30, STRINGS.UI.CRAFTING_MENU.NO_ITEMS, UICOLOURS.GOLD_UNIMPORTANT))
		self.no_recipes_msg:SetPosition(-2, height / 2 - filters_height - grid_h / 2)
		self.no_recipes_msg:Hide()

		----------------

		self.itemlist_split = w:AddChild(Image(atlas, "horizontal_bar.tex"))
		self.itemlist_split:SetPosition(0, height / 2 - filters_height)
		self.itemlist_split:ScaleToSize(351, 15)

		self.itemlist_split2 = w:AddChild(Image(atlas, "horizontal_bar.tex"))
		self.itemlist_split2:SetPosition(0, height / 2 - filters_height - grid_h - 2)
		self.itemlist_split2:ScaleToSize(351, 15)

		----------------

		self.details_root = w:AddChild(CraftingMenuDetails(self.owner, self, width - 20 * 2, height - 20 * 2))
		self.details_root:SetPosition(0, height / 2 - filters_height - grid_h - 10)

		self.nav_hint = w:AddChild(Text(BODYTEXTFONT, 26))
		self.nav_hint:SetPosition(0, -height / 2 - 30)

		----------------

		self.recipe_grid:MoveToBack()

		fill:MoveToBack()
		return w
	end

	self.MakeFilterPanel = function(self, width)
		width = width - 40
		local button_size = 38
		local grid_button_space = button_size + 5
		local grid_buttons_wide = math.floor(width / (button_size + 1))
		local grid_left = -grid_button_space * grid_buttons_wide / 2 + grid_button_space / 2

		self.grid_button_space = grid_button_space
		self.grid_left = grid_left

		local w = Widget("FilterPanel")

		self.top_row_widgets = {}

		local y = -2

		-- favorites filter button
		local favorites_filter = w:AddChild(self:MakeFilterButton(CRAFTING_FILTERS.FAVORITES, button_size))
		favorites_filter:SetPosition(grid_left, y)
		self.filter_buttons[CRAFTING_FILTERS.FAVORITES.name] = favorites_filter
		self.favorites_filter = favorites_filter
		table.insert(self.top_row_widgets, favorites_filter)

		self.event_layout = IsAnySpecialEventActive()

		-- special_event_filter
		local special_event_filter = w:AddChild(self:MakeFilterButton(CRAFTING_FILTERS.SPECIAL_EVENT, button_size))
		special_event_filter:SetPosition(grid_left + grid_button_space, y)
		self.filter_buttons[CRAFTING_FILTERS.SPECIAL_EVENT.name] = special_event_filter
		special_event_filter:Hide()
		self.special_event_filter = special_event_filter
		table.insert(self.top_row_widgets, special_event_filter)

		-- station filter button
		local filter_station = w:AddChild(self:MakeFilterButton(CRAFTING_FILTERS.CRAFTING_STATION, button_size))
		filter_station:SetPosition(grid_left + grid_button_space, y)
		self.filter_buttons[CRAFTING_FILTERS.CRAFTING_STATION.name] = filter_station
		self.crafting_station_filter = filter_station
		table.insert(self.top_row_widgets, filter_station)

		-- search bar
		self.search_box = w:AddChild(self:MakeSearchBox(grid_button_space * 4, SEARCH_BOX_HEIGHT))
		self.search_box:SetPosition(0, y)
		table.insert(self.top_row_widgets, self.search_box)

		-- modded items filter button
		local filter_mods = w:AddChild(self:MakeFilterButton(CRAFTING_FILTERS.MODS, button_size))
		filter_mods:SetPosition(grid_left + grid_button_space * 6, y)
		self.filter_buttons[CRAFTING_FILTERS.MODS.name] = filter_mods
		self.mods_filter = filter_mods
		table.insert(self.top_row_widgets, filter_mods)

		-- sort button
		self.sort_button = w:AddChild(self:AddSorter())
		self.sort_button:SetPosition(grid_left + grid_button_space * 7, y)
		table.insert(self.top_row_widgets, self.sort_button)

		y = y - button_size / 2

		self:UpdateEventButtonLayout()

		-- Divider
		y = y - 5
		local line_height = 4
		local line = w:AddChild(Image("images/ui.xml", "line_horizontal_white.tex"))
		line:SetPosition(0, y - line_height / 2)
		line:SetTint(unpack(BROWN))
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

				w.button.OnControl = function(_self, control, down)
					if ImageButton.OnControl(_self, control, down) then return true end

					if not _self.focus then
						return false
					end

					if down and not _self.down then
						if control == CONTROL_MENU_MISC_1 then
							if self.crafting_hud.pinbar ~= nil then
								local slot = self.crafting_hud.pinbar:FindFirstUnpinnedSlot()
								if slot ~= nil then
									slot:SetFocus()
									slot.craft_button:OnControl(control, down)
									return true
								else
									slot = self.crafting_hud.pinbar:GetFirstButton()
									if slot ~= nil then
										TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
										slot:SetFocus()
										return true
									end
								end
							end
						end
					end
				end
				self.filter_buttons[filter_def.name] = w
				table.insert(widgets, w)
			end
		end
		filter_grid:FillGrid(grid_buttons_wide, grid_button_space, grid_button_space, widgets)
		filter_grid:SetPosition(grid_left, y)

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
	self.frame = self.root:AddChild(self:MakeFrame(350, height))

	self.focus_forward = self.filter_panel.filter_grid
end)

AddClassPostConstruct("widgets/redux/craftingmenu_hud", function(self, owner, is_left_aligned)
	if GetModConfigData("FIX_PINBAR") then
		self.closed_pos = Vector3(0, 0, 0)
		self.opened_pos = Vector3(450, 0, 0)
	elseif is_left_aligned then
		self.closed_pos = Vector3(0, 0, 0)
		self.opened_pos = Vector3(370, 0, 0) --370
	else
		self.closed_pos = Vector3(0, 0, 0)
		self.opened_pos = Vector3(-370, 0, 0)
	end
	self.craftingmenu:Kill()
	self.craftingmenu = self.ui_root:AddChild(CraftingMenuWidget(owner, self, HEIGHT))
	self.craftingmenu:SetPosition(is_left_aligned and -180 or 180, 20)
	self.craftingmenu:Disable()

	self.nav_hint = self.craftingmenu.nav_hint

	if GetModConfigData("FIX_PINBAR") then
		self.pb_root = self:AddChild(Widget("craftingmenu_root"))
		self.pinbar:KillAllChildren()
		self.pinbar = self.pb_root:AddChild(CraftingMenuPinBar(owner, self, HEIGHT))
		self.pinbar:SetPosition(0, 0)
		self.pinbar:MoveToBack()
	end

	self:RefreshControllers(TheInput:ControllerAttached())
	self.craftingmenu:DoFocusHookups()
end)
