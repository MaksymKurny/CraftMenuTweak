local qcmode = GetModConfigData("FAST_CRAFT")
local ThreeSlice = require "widgets/threeslice"
local TEMPLATES = require "widgets/redux/templates"
local dataset = require("screens/redux/scrapbookdata")
local Text = require("widgets/text")
local Image = require "widgets/image"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"

local AddClassPostConstruct = AddClassPostConstruct
local GetModConfigData = GetModConfigData

local F_KEYS = F_KEYS

GLOBAL.setfenv(1, GLOBAL)

AddClassPostConstruct("widgets/redux/craftingmenu_details", function(self, owner, parent_widget, panel_width, panel_height)
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
		local root_left = self:AddChild(Widget("left_root"))
		
		-- Wiki Button
		local is_viewed = data and TheScrapbookPartitions:WasViewedInScrapbook(data.recipe.name) or false
		local scrap_button = self:AddChild(Widget("left_root")):AddChild(ImageButton(atlas, is_viewed and "unlocked_over.tex" or "question_over.tex", 
																   is_viewed and "unlocked_over.tex" or "question_over.tex", nil, 
																   is_viewed and "unlocked_over.tex" or "question_over.tex", nil, {.7, .7}, {0, 0}))
		scrap_button:SetPosition(-self.panel_width/2 + 2, self.build_button_root:GetLocalPosition().y - 2)
		scrap_button.focus_scale = {.8, .8}
		scrap_button.normal_scale = {.7, .7}
		
		if is_viewed then 	scrap_button:Enable()
		else 				scrap_button:Disable()
		end
		scrap_button:SetOnClick(function()
			TheScrapbookPartitions:TryToTeachScrapbookData_Note(data.recipe.name)		
		end)
		self.scrap_button = scrap_button
	end
end)

local function Modded(self, w)
	if TheInput:IsKeyDown(F_KEYS) and self.current_filter_name == "FAVORITES" then 
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
			local filter_recipes = (current_filter ~= nil and CRAFTING_FILTERS[current_filter] ~= nil) and FunctionOrValue(CRAFTING_FILTERS[current_filter].default_sort_values) or nil

			local show_hidden = current_filter == CRAFTING_FILTERS.EVERYTHING.name or current_filter == CRAFTING_FILTERS.FAVORITES.name

			for i, recipe_name in metaipairs(self.sort_class) do
				local data = self.crafting_hud.valid_recipes[recipe_name]
				if data and (show_hidden or data.meta.build_state ~= "hide") and IsRecipeValidForFilter(self, recipe_name, filter_recipes) and IsRecipeValidForStation(self, data.recipe, station, current_filter) then
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
			local w = Widget("recipe-cell-".. index)

			w:SetScale(0.475)

			--------------
			w.cell_root = w:AddChild(ImageButton(atlas, "slot_frame.tex", "slot_frame_highlight.tex"))

			w.focus_forward = w.cell_root
			w.cell_root.ongainfocusfn = function() 
				self.recipe_grid:OnWidgetFocus(w)
				w.cell_root.recipe_held = false
				w.cell_root.last_recipe_click = nil

				if TheInput:ControllerAttached() then
					self.details_root:PopulateRecipeDetailPanel(w.data, w.data ~= nil and Profile:GetLastUsedSkinForItem(w.data.recipe.name) or nil)
				end	
----------- Edit -----------
				if GetModConfigData("SUB_INGR") then
					local CraftingMenuIngredients = require "widgets/redux/craftingmenu_ingredients"

					w.cell_root.sub_ingredients = w.cell_root.parent:AddChild(Widget("sub_ingredients"))
					w.cell_root.sub_ingredients:MoveToBack()
					w.cell_root.background = w.cell_root.sub_ingredients:AddChild(ThreeSlice(resolvefilepath("images/crafting_menu.xml"), "popup_end.tex", "popup_short.tex"))
					if w.data and w.data.recipe then
						w.cell_root.ingredients = w.cell_root.sub_ingredients:AddChild(CraftingMenuIngredients(self.owner, 4, w.data.recipe, 1.5))
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
					local stay_open, error_msg = DoRecipeClick(self.owner, w.data.recipe, self.details_root.skins_spinner:GetItem())
					if not stay_open then
						self.owner:PushEvent("refreshcrafting")  -- this is only really neede for free crafting

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
				w.numtogive:SetPosition(25,-25)
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
					skin_name = Profile:GetLastUsedSkinForItem(recipe.name)..".tex"
				end
				
				if GetModConfigData("CRAFT_COUNT") then 
					if data.recipe.numtogive ~= nil and data.recipe.numtogive > 1 then
						widget.numtogive:SetString("x"..data.recipe.numtogive)
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
		
		local size = GetModConfigData("COMP_CM") and { 0.25, 4, 5} or { 0.5, 3, 7}
		
		local grid = TEMPLATES.ScrollingGrid(
				{},
				{
					context = {},
					widget_width  = row_w+row_spacing,
					widget_height = row_h+row_spacing,
					peek_percent     = size[1],
					num_visible_rows = size[2],
					num_columns      = size[3],
					item_ctor_fn = ScrollWidgetsCtor,
					apply_fn     = ScrollWidgetSetData,
					scrollbar_offset = 7,
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