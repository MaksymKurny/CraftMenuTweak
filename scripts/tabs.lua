local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local AddClassPostConstruct = AddClassPostConstruct
local GetModConfigData = GetModConfigData

local F_KEYS = F_KEYS

GLOBAL.setfenv(1, GLOBAL)

-- Add click and open --
AddClassPostConstruct("widgets/redux/craftingmenu_pinslot", function(self, owner, craftingmenu, slot_num, pin_data)
	if GetModConfigData("CRAFT_COUNT") then
		self.item_img.numtogive = self.item_img:AddChild(Text(UIFONT, 35, "", UICOLOURS.GOLD_UNIMPORTANT))
		self.item_img.numtogive:SetPosition(25,-25)
		self.item_img.numtogive:Hide()
	end

	local _OnClick = self.craft_button.onclick
	self.craft_button:SetOnClick(function()
		if self.recipe_name ~= nil and string.find(self.recipe_name, "filter_") and not self.unpin_button.focus then
			self.owner.HUD:OpenCrafting()
			self.craftingmenu.craftingmenu:SelectFilter(string.sub(self.recipe_name, 8), true)
			local data = self.craftingmenu.craftingmenu.filtered_recipes[1]
			self.craftingmenu.craftingmenu:PopulateRecipeDetailPanel(data, data ~= nil and Profile:GetLastUsedSkinForItem(data.recipe.name) or nil)
			self.craft_button:SetHelpTextMessage(STRINGS.ACTIONS.RUMMAGE.GENERIC)
			return
		end

		if self.craftingmenu:IsCraftingOpen() and not self.unpin_button.focus and self.recipe_name == nil and TheInput:IsKeyDown(F_KEYS) then
			local curr_filter = "filter_"..self.craftingmenu.craftingmenu.current_filter_name
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
				local curr_filter = "filter_"..self.craftingmenu.craftingmenu.current_filter_name
				self:SetRecipe(curr_filter, nil)
				return true
			end
		end
	end

	local _RefreshCraftingHelpText = self.RefreshCraftingHelpText
	self.RefreshCraftingHelpText = function(self, controller_id)
		if self.recipe_name ~= nil and string.find(self.recipe_name, "filter_") then
			return TheInput:GetLocalizedControl(controller_id, CONTROL_ACCEPT).." "..STRINGS.ACTIONS.RUMMAGE.GENERIC
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

				self.craft_button:SetTextures(atlas, has_buffered and "pinslot_bg_buffered.tex" or num_can_build > 0 and "pinslot_bg_prototype.tex" or "pinslot_bg_missing_mats.tex",
									  nil, nil, nil, has_buffered and "pinslot_bg_buffered.tex" or num_can_build > 0 and "pinslot_bg_prototype.tex" or "pinslot_bg_missing_mats.tex")

				if has_prototypeable then
					self.fg:SetTexture(atlas, "pinslot_fg_prototype.tex")
					self.fg:Show()
				else self.fg:Hide() end
			end
			self.craft_button:SetHelpTextMessage(STRINGS.ACTIONS.RUMMAGE.GENERIC)

			self:Show()
		else
			_Refresh(self)
		end

		if GetModConfigData("CRAFT_COUNT") then
			if data ~= nil and data.recipe ~= nil and data.meta ~= nil then
				if data.recipe.numtogive ~= nil and data.recipe.numtogive > 1 then
					self.item_img.numtogive:SetString("x"..data.recipe.numtogive)
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
