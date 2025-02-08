local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local Text = require "widgets/text"
local Grid = require "widgets/grid"
local ThreeSlice = require "widgets/threeslice"
local qcmode = GetModConfigData("FAST_CRAFT")
local TEMPLATES = require "widgets/redux/templates"
local CraftingMenuIngredients = require "widgets/redux/craftingmenu_ingredients"

Assets = {
	Asset("IMAGE", "images/crafting_menu_avatars_o.tex"),
	Asset("ATLAS", "images/crafting_menu_avatars_o.xml"),
}

local Assets = Assets
local env = env
local modimport = modimport
local AddClassPostConstruct = AddClassPostConstruct
local GetModConfigData = GetModConfigData


-- Functional key --
local FN_KEYS = GetModConfigData("FUN_KEY")
if type(FN_KEYS) == "string" and GLOBAL:rawget(FN_KEYS) then FN_KEYS = GLOBAL[FN_KEYS] end

GLOBAL.setfenv(1, GLOBAL)


--- Icons ---
if GetModConfigData("ICON_PACK") == 1 then
	table.insert(Assets, Asset("IMAGE", "images/old/crafting_menu_icons.tex"))
	table.insert(Assets, Asset("ATLAS", "images/old/crafting_menu_icons.xml"))
	CRAFTING_ICONS_ATLAS = "images/old/crafting_menu_icons.xml"
elseif GetModConfigData("ICON_PACK") == 2 then
	table.insert(Assets, Asset("IMAGE", "images/blk/crafting_menu_icons.tex"))
	table.insert(Assets, Asset("ATLAS", "images/blk/crafting_menu_icons.xml"))
	CRAFTING_ICONS_ATLAS = "images/blk/crafting_menu_icons.xml"
end

-- Icons and old/new mode --
modimport("scripts/recipes_filter")

-- Scrapbook Button --
AddClassPostConstruct("widgets/redux/craftingmenu_details",
	function(self, owner, parent_widget, panel_width, panel_height)
		local _PopulateRecipeDetailPanel = self.PopulateRecipeDetailPanel
		self.PopulateRecipeDetailPanel = function(self, data, skin_name)
			_PopulateRecipeDetailPanel(self, data, skin_name)
			if data == nil then
				self.scrap_button = nil
				self:KillAllChildren()
				return
			end
			if not GetModConfigData("SCRAP_BOOK") then return end

			local atlas = resolvefilepath("images/skilltree.xml")

			-- Scrapbook Button
			local is_viewed = data and TheScrapbookPartitions:WasViewedInScrapbook(data.recipe.name) or false
			local scrap_button = self:AddChild(Widget("left_root")):AddChild(ImageButton(atlas,
				is_viewed and "unlocked_over.tex" or "question_over.tex",
				is_viewed and "unlocked_over.tex" or "question_over.tex", nil,
				is_viewed and "unlocked_over.tex" or "question_over.tex", nil, { .7, .7 }, { 0, 0 }))
			scrap_button:SetPosition(-self.panel_width / 2 + 2, self.build_button_root:GetLocalPosition().y - 2)
			scrap_button.focus_scale = { .8, .8 }
			scrap_button.normal_scale = { .7, .7 }

			if is_viewed then
				scrap_button:Enable()
			else
				scrap_button:Disable()
			end
			scrap_button:SetOnClick(function()
				TheScrapbookPartitions:TryToTeachScrapbookData_Note(data.recipe.name)
			end)
			self.scrap_button = scrap_button
		end
	end)

-- Craft 1 click and favorite sort craft count --
local function Modded(self, w)
	if TheInput:IsKeyDown(FN_KEYS) and self.current_filter_name == "FAVORITES" then
		TheCraftingMenuProfile:RemoveFavorite(w.data.recipe.name)
		TheCraftingMenuProfile:AddFavorite(w.data.recipe.name)
		self:OnFavoriteChanged(w.data.recipe.name)
		self.owner:PushEvent("refreshcrafting")
		return
	end
	if w.data.meta.can_build and not (w.data == self.details_root.data) and ((TheInput:IsMouseDown(MOUSEBUTTON_RIGHT) and qcmode == 1) or (TheInput:IsKeyDown(KEY_CTRL) and qcmode == 2) or (not TheInput:IsMouseDown(MOUSEBUTTON_RIGHT) and qcmode == 0)) then
		self.details_root:PopulateRecipeDetailPanel(w.data, Profile:GetLastUsedSkinForItem(w.data.recipe.name))
		w.cell_root.last_recipe_click = GetTime()
	end
end

AddClassPostConstruct("widgets/redux/craftingmenu_widget", function(self, owner, crafting_hud, height)
	-- Init in fav filter --
	self.Initialize = function()
		self:UpdateFilterButtons()

		self:SelectFilter(CRAFTING_FILTERS.FAVORITES.name, true)
		local data = self.filtered_recipes[1]
		self:PopulateRecipeDetailPanel(data, data ~= nil and Profile:GetLastUsedSkinForItem(data.recipe.name) or nil)

		self:Refresh()
	end

	if GetModConfigData("FAV_SHOW_ALL") then
		local function IsRecipeValidForFilter(self, recipename, filter_recipes)
			if filter_recipes then
				return filter_recipes[recipename] ~= nil
			end
			return self:IsRecipeValidForSearch(recipename)
		end

		local function IsRecipeValidForStation(self, recipe, station, current_filter)
			if current_filter ~= "CRAFTING_STATION" then
				return true -- Only care about CRAFTING_STATION filter tab for this function.
			end

			if recipe == nil or station == nil then
				return true -- NOTES(JBK): This is here to not change old filtering before this function was added.
			end

			if recipe.station_tag == nil then
				return true
			end

			return station:HasTag(recipe.station_tag)
		end

		self.ApplyFilters = function()
			self.filtered_recipes = {}

			local builder = self.owner ~= nil and self.owner.replica.builder or nil
			local station = builder and builder:GetCurrentPrototyper() or nil

			local current_filter = self.current_filter_name
			local filter_recipes = (current_filter ~= nil and CRAFTING_FILTERS[current_filter] ~= nil) and
					FunctionOrValue(CRAFTING_FILTERS[current_filter].default_sort_values) or nil

			local show_hidden = current_filter == CRAFTING_FILTERS.EVERYTHING.name or
					current_filter == CRAFTING_FILTERS.FAVORITES.name -- FAV_SHOW_ALL edit

			--Forced hints are mainly used for hinting character skilltree recipe unlocks that also require
			--a crafting station, so we should make sure they do not show up on the wrong crafting station.
			local show_forced_hints = current_filter ~= CRAFTING_FILTERS.CRAFTING_STATION.name

			for i, recipe_name in metaipairs(self.sort_class) do
				local data = self.crafting_hud.valid_recipes[recipe_name]
				if data and
						(show_hidden or data.meta.build_state ~= "hide") and
						(show_forced_hints or data.meta.build_state ~= "hint" or not data.recipe.force_hint) and
						IsRecipeValidForFilter(self, recipe_name, filter_recipes) and
						IsRecipeValidForStation(self, data.recipe, station, current_filter)
				then
					table.insert(self.filtered_recipes, data)
				end
			end

			if self.crafting_hud:IsCraftingOpen() then
				self:UpdateRecipeGrid(self.focus and not TheFrontEnd.tracking_mouse)
				--self.recipe_grid:ResetScroll()
				--self.recipe_grid:SetItemsData(self.filtered_recipes)
			else
				self.recipe_grid.dirty = true
			end
		end
	end

	self.MakeRecipeList = function(self, width, height)
		local cell_size = 60
		local row_w = cell_size
		local row_h = cell_size
		local row_spacing = 6
		local item_size = 94
		local atlas = resolvefilepath(CRAFTING_ATLAS)

		local function ScrollWidgetsCtor(context, index)
			local w = Widget("recipe-cell-" .. index)

			w:SetScale(0.475)

			--------------
			w.cell_root = w:AddChild(ImageButton(atlas, "slot_frame.tex", "slot_frame_highlight.tex"))

			w.focus_forward = w.cell_root
			w.cell_root.ongainfocusfn = function()
				self.recipe_grid:OnWidgetFocus(w)
				w.cell_root.recipe_held = false
				w.cell_root.last_recipe_click = nil

				if TheInput:ControllerAttached() then
					self.details_root:PopulateRecipeDetailPanel(w.data,
						w.data ~= nil and Profile:GetLastUsedSkinForItem(w.data.recipe.name) or nil)
				end
				----------- Edit -----------
				if GetModConfigData("SUB_INGR") then
					w.cell_root.sub_ingredients = w.cell_root.parent:AddChild(Widget("sub_ingredients"))
					w.cell_root.sub_ingredients:MoveToFront()
					w.cell_root.background = w.cell_root.sub_ingredients:AddChild(ThreeSlice(
						resolvefilepath("images/crafting_menu.xml"), "popup_end.tex", "popup_short.tex"))
					if w.data and w.data.recipe then
						w.cell_root.ingredients = w.cell_root.sub_ingredients:AddChild(CraftingMenuIngredients(self.owner, 4,
							w.data.recipe, 1.5))
					end
					w.cell_root.background:ManualFlow(math.min(5, w.cell_root.ingredients.num_items), true)

					local x = w.cell_root.background.startcap:GetPositionXYZ()
					w.cell_root.sub_ingredients:SetPosition(0, -105)
					w.cell_root.sub_ingredients:SetScale(1.25)
					--self:Refresh()
				end
			end
			w.cell_root.onlosefocus = function()
				if w.cell_root.sub_ingredients ~= nil then
					w.cell_root.sub_ingredients:Kill()
					w.cell_root.sub_ingredients = nil
				end
			end
			----------------------
			w.cell_root:SetWhileDown(function()
				if w.cell_root.recipe_held then
					DoRecipeClick(self.owner, w.data.recipe, self.details_root.skins_spinner:GetItem())
				end
			end)
			w.cell_root:SetOnDown(function()
				if w.cell_root.last_recipe_click and (GetTime() - w.cell_root.last_recipe_click) < 1 then
					w.cell_root.recipe_held = true
					w.cell_root.last_recipe_click = nil
				end
			end)
			----------- Edit -----------
			w.cell_root:SetOnClick(function()
				Modded(self, w) -- Need add --
				local is_current = w.data == self.details_root.data
				if is_current then -- clicking the item when it is already selected will trigger a build
					local already_buffered = self.owner.replica.builder:IsBuildBuffered(w.data.recipe.name)
					if not w.cell_root.recipe_held or already_buffered then
						local stay_open, error_msg = DoRecipeClick(self.owner, w.data.recipe,
							self.details_root.skins_spinner:GetItem())
						if not stay_open then
							self.owner:PushEvent("refreshcrafting") -- this is only really neede for free crafting

							if already_buffered or Profile:GetCraftingMenuBufferedBuildAutoClose() then
								self.owner.HUD:CloseCrafting()
								return
							end
						end
						if error_msg and not TheNet:IsServerPaused() then
							SendRPCToServer(RPC.CannotBuild, error_msg)
						end

						if stay_open and not already_buffered then
							w.cell_root.last_recipe_click = GetTime()
						end
					end
				else
					self.details_root:PopulateRecipeDetailPanel(w.data, Profile:GetLastUsedSkinForItem(w.data.recipe.name))
					w.cell_root.last_recipe_click = GetTime()
				end

				w.cell_root.recipe_held = false
			end)
			w.cell_root.OnControl = function(_self, control, down)
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
					elseif control == CONTROL_MENU_MISC_2 then
						local fav_button = self.details_root.fav_button
						if fav_button ~= nil and fav_button.onclick ~= nil then
							TheFrontEnd:GetSound():PlaySound("dontstarve/HUD/click_move")
							fav_button.onclick()
							return true
						end
					end
				end
			end

			----------------
			w.bg = w.cell_root:AddChild(Image(atlas, "slot_bg.tex"))
			w.item_img = w.bg:AddChild(Image("images/global.xml", "square.tex"))
			w.fg = w.bg:AddChild(Image("images/global.xml", "square.tex"))
			w.bg:MoveToBack()

			if GetModConfigData("CRAFT_COUNT") then
				w.numtogive = w.bg:AddChild(Text(UIFONT, 45, "", UICOLOURS.GOLD_UNIMPORTANT))
				w.numtogive:SetPosition(25, -25)
				w.numtogive:Hide()
			end

			return w
		end

		local function ScrollWidgetSetData(context, widget, data, index)
			if data ~= nil and data.recipe ~= nil and data.meta ~= nil then
				if widget.data ~= nil then
					if widget.data.recipe ~= data.recipe then
						widget.cell_root.recipe_held = false
						widget.cell_root.last_recipe_click = nil
					end
				end

				local recipe = data.recipe
				local meta = data.meta

				widget.cell_root:Show()
				----------- Edit -----------
				local skin_name
				if Profile:GetLastUsedSkinForItem(recipe.name) ~= nil and GetModConfigData("CRAFT_SKIN") then
					skin_name = Profile:GetLastUsedSkinForItem(recipe.name) .. ".tex"
				end

				if GetModConfigData("CRAFT_COUNT") then
					if data.recipe.numtogive ~= nil and data.recipe.numtogive > 1 then
						widget.numtogive:SetString("x" .. data.recipe.numtogive)
						widget.numtogive:Show()
					else
						widget.numtogive:SetString("")
						widget.numtogive:Hide()
					end
				end
				----------------------------
				local image = skin_name or (recipe.imagefn ~= nil and recipe.imagefn() or recipe.image)

				widget.item_img:SetTexture(recipe:GetAtlas(), image, image ~= recipe.image and recipe.image or nil)
				widget.item_img:ScaleToSize(item_size, item_size)

				widget.item_img:SetTint(1, 1, 1, 1)

				if meta.build_state == "buffered" then
					widget.bg:SetTexture(atlas, "slot_bg_buffered.tex")
					widget.fg:Hide()
				elseif meta.build_state == "prototype" and meta.can_build then
					widget.bg:SetTexture(atlas, "slot_bg_prototype.tex")
					widget.fg:SetTexture(atlas, "slot_fg_prototype.tex")
					widget.fg:Show()
				elseif meta.can_build then
					widget.bg:SetTexture(atlas, "slot_bg.tex")
					widget.fg:Hide()
				elseif meta.build_state == "hint" then
					widget.bg:SetTexture(atlas, "slot_bg_missing_mats.tex")
					widget.item_img:SetTint(0.7, 0.7, 0.7, 1)
					widget.fg:SetTexture(atlas, "slot_fg_lock.tex")
					widget.fg:Show()
				elseif meta.build_state == "no_ingredients" or meta.build_state == "prototype" then
					widget.bg:SetTexture(atlas, "slot_bg_missing_mats.tex")
					widget.item_img:SetTint(0.7, 0.7, 0.7, 1)
					widget.fg:Hide()
				else
					widget.bg:SetTexture(atlas, "slot_bg_missing_mats.tex")
					widget.item_img:SetTint(0.7, 0.7, 0.7, 1)
					widget.fg:SetTexture(atlas, "slot_fg_lock.tex")
					widget.fg:Show()
				end

				widget:Enable()
			else
				widget:Disable()
				widget.cell_root:Hide()
			end

			widget.data = data
		end

		local size = GetModConfigData("COMP_CM") and { 0.25, 4, 5 } or { 0.5, 3, 7 }

		local grid = TEMPLATES.ScrollingGrid(
			{},
			{
				context                 = {},
				widget_width            = row_w + row_spacing,
				widget_height           = row_h + row_spacing,
				peek_percent            = size[1],
				num_visible_rows        = size[2],
				num_columns             = size[3],
				item_ctor_fn            = ScrollWidgetsCtor,
				apply_fn                = ScrollWidgetSetData,
				scrollbar_offset        = 7,
				scrollbar_height_offset = -50
			})


		grid.up_button:SetTextures(atlas, "scrollbar_arrow_up.tex", "scrollbar_arrow_up_hl.tex")
		grid.up_button:SetScale(0.4)

		grid.down_button:SetTextures(atlas, "scrollbar_arrow_down.tex", "scrollbar_arrow_down_hl.tex")
		grid.down_button:SetScale(0.4)

		grid.scroll_bar_line:SetTexture(atlas, "scrollbar_bar.tex")
		grid.scroll_bar_line:ScaleToSize(11, grid.scrollbar_height - 15)

		grid.position_marker:SetTextures(atlas, "scrollbar_handle.tex")
		grid.position_marker.image:SetTexture(atlas, "scrollbar_handle.tex")
		grid.position_marker:SetScale(.3)

		grid.custom_focus_check = function() return self.focus end

		return grid
	end
	if not GetModConfigData("COMP_CM") then
		self.frame:KillAllChildren()
		self.frame = self.root:AddChild(self:MakeFrame(500, height))
	end
end)

--- Ing quick craft ---
--- Thanks a lot for the first base code Zaptrap --
if GetModConfigData("CRAFT_ING") then
	AddClassPostConstruct("widgets/ingredientui",
		function(self, atlas, image, quantity, on_hand, has_enough, name, owner, recipe_type, quant_text_scale,
						 ingredient_recipe)
			self:Kill()
			ImageButton._ctor(self, resolvefilepath("images/hud.xml"), has_enough and "inv_slot.tex" or "resource_needed.tex")

			local hud_atlas = resolvefilepath("images/hud.xml")
			local crafting_atlas = resolvefilepath("images/crafting_menu.xml")

			self:SetFocusScale(1.1)

			local skin_name
			if Profile:GetLastUsedSkinForItem(recipe_type) ~= nil then
				skin_name = Profile:GetLastUsedSkinForItem(recipe_type) .. ".tex"
			end
			self.ing = self.image:AddChild(Image(atlas, skin_name or image))

			if recipe_type ~= nil and AllRecipes[recipe_type] then
				self:Enable()
			else
				self:Disable()
			end

			if quantity ~= nil then
				self.quant = self.image:AddChild(Text(SMALLNUMBERFONT, JapaneseOnPS4() and 30 or 24))
				self.quant:SetPosition(7, -32, 0)
				if quant_text_scale ~= nil then
					self.quant:SetScale(quant_text_scale, quant_text_scale)
				end
				if not IsCharacterIngredient(recipe_type) then
					local builder = owner ~= nil and owner.replica.builder or nil
					if builder ~= nil then
						quantity = RoundBiasedUp(quantity * builder:IngredientMod())
					end
					self.quant:SetString(string.format("%d/%d", on_hand, quantity))
				elseif recipe_type == CHARACTER_INGREDIENT.MAX_HEALTH
						or recipe_type == CHARACTER_INGREDIENT.MAX_SANITY then
					self.quant:SetString(string.format("-%2.0f%%", quantity * 100))
				else
					self.quant:SetString(string.format("-%d", quantity))
				end
				if not has_enough then
					self.quant:SetColour(255 / 255, 155 / 255, 155 / 255, 1)
				end
			end

			self.recipe_type = recipe_type
			self.has_enough = has_enough
			self.owner = owner

			local tooltip = name

			local meta = ingredient_recipe ~= nil and ingredient_recipe.meta or nil

			if meta and (not has_enough or quantity == nil) then
				if meta.build_state == "hint" or meta.build_state == "hide" then
					self.fg = self.image:AddChild(Image(crafting_atlas, "ingredient_lock.tex"))
					self.fg:ScaleToSize(self.ing:GetSize())
				elseif meta.can_build then
					self.ingredient_recipe = ingredient_recipe
					if meta.build_state == "buffered" then
						self:SetTextures(hud_atlas, "inv_slot.tex", "inv_slot.tex")
						tooltip = tooltip ..
								"\n" ..
								TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_PRIMARY) ..
								": " ..
								(ingredient_recipe.recipe.actionstr ~= nil and STRINGS.UI.CRAFTING.RECIPEACTION[ingredient_recipe.recipe.actionstr] or STRINGS.UI.CRAFTING.PLACE)
						--self.fg = self.image:AddChild(Image(crafting_atlas, "ingredient_craft.tex"))
						--self.fg:SetTint(0.2, 0.6, 0.7, 1)
					elseif meta.build_state == "prototype" then
						self.fg = self.image:AddChild(Image(crafting_atlas, "ingredient_prototype.tex"))
						tooltip = tooltip ..
								"\n" ..
								TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_PRIMARY) ..
								": " .. STRINGS.UI.CRAFTING.PROTOTYPE
					else
						self.fg = self.image:AddChild(Image(crafting_atlas, "ingredient_craft.tex"))
						tooltip = tooltip ..
								"\n" ..
								TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_PRIMARY) ..
								": " ..
								(ingredient_recipe.recipe.actionstr ~= nil and STRINGS.UI.CRAFTING.RECIPEACTION[ingredient_recipe.recipe.actionstr] or STRINGS.UI.CRAFTING.BUILD)
					end
					self.fg:ScaleToSize(self.ing:GetSize())

					self.onclick = function()
						if self.ingredient_recipe ~= nil and meta.can_build then
							DoRecipeClick(self.owner, self.ingredient_recipe.recipe, Profile:GetLastUsedSkinForItem(self.recipe_type))
						end
					end
				end
				self.ongainfocus = function()
					self.sub_ingredients = self.parent:AddChild(Widget("sub_ingredients"))
					self.sub_ingredients:MoveToBack()
					self.background = self.sub_ingredients:AddChild(ThreeSlice(crafting_atlas, "popup_end.tex", "popup_short.tex"))

					self.ingredients = self.sub_ingredients:AddChild(CraftingMenuIngredients(self.owner, 4,
						ingredient_recipe.recipe, 1.5))

					self._scale = 1.0

					self.background:ManualFlow(math.min(5, self.ingredients.num_items), true)

					local x = self.background.startcap:GetPositionXYZ()

					self.sub_ingredients:SetPosition(0, -75)
					self.sub_ingredients:SetScale(self._scale)
				end

				self.onlosefocus = function()
					if self.sub_ingredients ~= nil then
						self.sub_ingredients:Kill()
						self.sub_ingredients = nil
					end
				end
			end

			if not self.ingredient_recipe then
				self:Select() -- a disable that blocks focus highlighting
			end

			self:SetTooltip(tooltip)
		end)
end

--- Compact pinn bar ---
if GetModConfigData("COMP_PINBAR") then
	TUNING.MAX_PINNED_RECIPES = 12
end
AddClassPostConstruct("widgets/redux/craftingmenu_pinbar", function(self, owner, crafting_hud, height)
	if GetModConfigData("COMP_PINBAR") then
		local PinSlot = require "widgets/redux/craftingmenu_pinslot"
		local buttonsize = 60 -- 64
		local y = 241       -- 378 -76 -61
		self.pin_slots = {}
		local pinned_recipes = TheCraftingMenuProfile:GetPinnedRecipes()

		local function FindPinUp(_pin)
			for i = _pin.slot_num - 1, 1, -1 do
				if self.pin_slots[i]:IsVisible() then
					return self.pin_slots[i]
				end
			end

			if self.crafting_hud:IsCraftingOpen() and TheInput:ControllerAttached() then
				return self.page_spinner
			end
		end

		local function FindPinDown(_pin)
			for i = (_pin.slot_num or 0) + 1, TUNING.MAX_PINNED_RECIPES do
				if self.pin_slots[i]:IsVisible() then
					return self.pin_slots[i]
				end
			end
		end

		for i = 1, TUNING.MAX_PINNED_RECIPES do
			local pin_slot = self.root:AddChild(PinSlot(self.owner, crafting_hud, i, pinned_recipes[i]))
			pin_slot:SetPosition(0, y)
			pin_slot.FindPinUp = FindPinUp
			pin_slot.FindPinDown = FindPinDown
			pin_slot.hide_cursor = true
			pin_slot.in_pinbar = true
			table.insert(self.pin_slots, pin_slot)

			y = y - buttonsize - 3 -- 13
		end

		self.focus_forward = self.pin_slots[1]
	end

	if GetModConfigData("CHR_PINBAR") then
		local _RefreshPinnedRecipes = self.RefreshPinnedRecipes
		self.RefreshPinnedRecipes = function(self)
			_RefreshPinnedRecipes(self)
			local currentPage = TheCraftingMenuProfile:GetCurrentPage()
			self.page_spinner.page_text:SetString(tostring(currentPage <= 9 and currentPage or "C"))
		end

		local _Refresh = self.Refresh
		self.Refresh = function(self)
			_Refresh(self)
			local currentPage = TheCraftingMenuProfile:GetCurrentPage()
			self.page_spinner.page_text:SetString(tostring(currentPage <= 9 and currentPage or "C"))
		end
	end
end)

-- Tabs client_only port --
if GetModConfigData("TAB_SUPPORT") then
	AddClassPostConstruct("widgets/redux/craftingmenu_pinslot", function(self, owner, craftingmenu, slot_num, pin_data)
		if GetModConfigData("CRAFT_COUNT") then
			self.item_img.numtogive = self.item_img:AddChild(Text(UIFONT, 35, "", UICOLOURS.GOLD_UNIMPORTANT))
			self.item_img.numtogive:SetPosition(25, -25)
			self.item_img.numtogive:Hide()
		end

		local _OnClick = self.craft_button.onclick
		self.craft_button:SetOnClick(function()
			if self.recipe_name ~= nil and string.find(self.recipe_name, "filter_") and not self.unpin_button.focus then
				self.owner.HUD:OpenCrafting()
				self.craftingmenu.craftingmenu:SelectFilter(string.sub(self.recipe_name, 8), true)
				local data = self.craftingmenu.craftingmenu.filtered_recipes[1]
				self.craftingmenu.craftingmenu:PopulateRecipeDetailPanel(data,
					data ~= nil and Profile:GetLastUsedSkinForItem(data.recipe.name) or nil)
				self.craft_button:SetHelpTextMessage(STRINGS.ACTIONS.RUMMAGE.GENERIC)
				return
			end

			if self.craftingmenu:IsCraftingOpen() and not self.unpin_button.focus and self.recipe_name == nil and TheInput:IsKeyDown(FN_KEYS) then
				local curr_filter = "filter_" .. self.craftingmenu.craftingmenu.current_filter_name
				self:SetRecipe(curr_filter, nil)
				return
			end

			_OnClick()
		end)

		local _OnControl = self.craft_button.OnControl
		self.craft_button.OnControl = function(_self, control, down)
			if ImageButton.OnControl(_self, control, down) then return true end
			if self.focus and down and not _self.down then
				if not TheInput:ControllerAttached() or not self.craftingmenu:IsCraftingOpen() or not control == CONTROL_MENU_MISC_1 or self.recipe_name ~= nil then
					return _OnControl(_self, control, down)
				end

				local recipe_name, skin_name = self.craftingmenu:GetCurrentRecipeName()
				if recipe_name ~= nil then
					return _OnControl(_self, control, down)
				elseif control == CONTROL_MENU_MISC_1 then
					local curr_filter = "filter_" .. self.craftingmenu.craftingmenu.current_filter_name
					self:SetRecipe(curr_filter, nil)
					return true
				end
			end
		end

		local _RefreshCraftingHelpText = self.RefreshCraftingHelpText
		self.RefreshCraftingHelpText = function(self, controller_id)
			if self.recipe_name ~= nil and string.find(self.recipe_name, "filter_") then
				return TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT) .. " " .. STRINGS.ACTIONS.RUMMAGE.GENERIC
			end

			return _RefreshCraftingHelpText(self, controller_id)
		end

		local _Refresh = self.Refresh
		self.Refresh = function(self)
			local data = self.craftingmenu:GetRecipeState(self.recipe_name)
			local is_left = self.craftingmenu.is_left_aligned
			local item_size = 80
			local atlas = resolvefilepath(CRAFTING_ATLAS)
			local craftmenu = self.craftingmenu.craftingmenu

			------ Add this  -----------
			if data == nil and self.recipe_name ~= nil and string.find(self.recipe_name, "filter_") and craftmenu.filter_buttons[string.sub(self.recipe_name, 8)] then
				local button = craftmenu.filter_buttons[string.sub(self.recipe_name, 8)]
				local can_prototype = false
				local new_recipe_available = false
				local inv_atlas = button.filter_img.atlas
				local inv_image = button.filter_img.texture

				self.item_img:SetTexture(inv_atlas, inv_image or "default.tex", "default.tex")
				self.item_img:ScaleToSize(is_left and item_size or -item_size, item_size)
				self.item_img:SetTint(1, 1, 1, 1)

				if button ~= nil and button.filter_def.recipes ~= nil then
					local has_buffered = false
					local has_prototypeable = false
					local num_can_build = 0
					for _, recipe_name in pairs(FunctionOrValue(button.filter_def.recipes)) do
						local data_recipes = craftmenu.crafting_hud.valid_recipes[recipe_name]
						if data_recipes ~= nil then
							if data_recipes.meta.can_build then
								num_can_build = num_can_build + 1
								if data_recipes.meta.build_state == "prototype" then
									has_prototypeable = true
									can_prototype = true
								elseif data_recipes.meta.build_state == "buffered" then
									has_buffered = true
								end
							end
						end
					end

					self.craft_button:SetTextures(atlas,
						has_buffered and "pinslot_bg_buffered.tex" or num_can_build > 0 and "pinslot_bg_prototype.tex" or
						"pinslot_bg_missing_mats.tex",
						nil, nil, nil,
						has_buffered and "pinslot_bg_buffered.tex" or num_can_build > 0 and "pinslot_bg_prototype.tex" or
						"pinslot_bg_missing_mats.tex")

					if has_prototypeable then
						self.fg:SetTexture(atlas, "pinslot_fg_prototype.tex")
						self.fg:Show()
					else
						self.fg:Hide()
					end
				end
				self.craft_button:SetHelpTextMessage(STRINGS.ACTIONS.RUMMAGE.GENERIC)

				self:Show()
			else
				_Refresh(self)
			end

			if GetModConfigData("CRAFT_COUNT") then
				if data ~= nil and data.recipe ~= nil and data.meta ~= nil then
					if data.recipe.numtogive ~= nil and data.recipe.numtogive > 1 then
						self.item_img.numtogive:SetString("x" .. data.recipe.numtogive)
						self.item_img.numtogive:Show()
					else
						self.item_img.numtogive:SetString("")
						self.item_img.numtogive:Hide()
					end
				else
					self.item_img.numtogive:SetString("")
					self.item_img.numtogive:Hide()
				end
			end
		end
	end)
end

-- Compact menu --
if GetModConfigData("COMP_CM") then
	local CraftingMenuDetails = require "widgets/redux/craftingmenu_details"
	local CraftingMenuWidget = require "widgets/redux/craftingmenu_widget"
	local CraftingMenuPinBar = require "widgets/redux/craftingmenu_pinbar"

	local HEIGHT = 650
	local SCALE = 0.75
	local SEARCH_BOX_HEIGHT = 40

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
						" " ..
						TheInput:GetLocalizedControl(controller_id, CONTROL_MENU_MISC_1) .. " " .. STRINGS.UI.CRAFTING_MENU.PIN
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

			self.recipe_grid:MoveToFront()

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
			self.pb_root:MoveToBack()
		end

		if GetModConfigData("COMP_CM") then
			self.pinbar:SetPosition(0, 40)
			local y_offset = IsSplitScreen() and -50 or 0
			self.openhint:SetPosition(is_left_aligned and 28 or -28, 34 + HEIGHT / 2 + y_offset + 40)
		end

		self:RefreshControllers(TheInput:ControllerAttached())
		self.craftingmenu:DoFocusHookups()
	end)
end

if GetModConfigData("CHR_PINBAR") then
	AddClassPostConstruct("craftingmenuprofile", function(self)
		local function findIndex(tbl, value)
			for index, v in ipairs(tbl) do
				if v == value then
					return index
				end
			end
			return 99
		end
		function self:NextPage()
			local next_page = self.pinned_page + 1
			if next_page == Profile:GetCraftingNumPinnedPages() + 1 and table.contains(env.CHARACTERLIST, ThePlayer.prefab) then
				self:SetCurrentPage(9 + findIndex(env.CHARACTERLIST, ThePlayer.prefab))
			else
				self:SetCurrentPage(next_page <= Profile:GetCraftingNumPinnedPages() and next_page or 1)
			end
		end

		function self:PrevPage()
			local prev_page = self.pinned_page - 1
			if prev_page > Profile:GetCraftingNumPinnedPages() then
				prev_page = Profile:GetCraftingNumPinnedPages()
			end
			if prev_page == 0 and table.contains(env.CHARACTERLIST, ThePlayer.prefab) then
				self:SetCurrentPage(9 + findIndex(env.CHARACTERLIST, ThePlayer.prefab))
			else
				self:SetCurrentPage(prev_page >= 1 and prev_page or Profile:GetCraftingNumPinnedPages())
			end
		end
	end)
end
