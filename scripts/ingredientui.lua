local ThreeSlice = require "widgets/threeslice"
local Image = require "widgets/image"
local Text = require "widgets/text"
local ImageButton = require "widgets/imagebutton"
local Widget = require "widgets/widget"
local CraftingMenuIngredients = require "widgets/redux/craftingmenu_ingredients"

local AddClassPostConstruct = AddClassPostConstruct
local GetModConfigData = GetModConfigData

GLOBAL.setfenv(1, GLOBAL)

AddClassPostConstruct("widgets/ingredientui", function(self, atlas, image, quantity, on_hand, has_enough, name, owner, recipe_type, quant_text_scale, ingredient_recipe)		
	self:Kill()
	ImageButton._ctor(self, resolvefilepath("images/hud.xml"), has_enough and "inv_slot.tex" or "resource_needed.tex")

	local hud_atlas = resolvefilepath("images/hud.xml")
	local crafting_atlas = resolvefilepath("images/crafting_menu.xml")

	self:SetFocusScale(1.1)
	
	local skin_name
	if Profile:GetLastUsedSkinForItem(recipe_type) ~= nil then
		skin_name = Profile:GetLastUsedSkinForItem(recipe_type)..".tex"
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
			self.quant:SetColour(255/255, 155/255, 155/255, 1)
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
				self:SetTextures(hud_atlas, "inv_slot.tex","inv_slot.tex")
				tooltip = tooltip.."\n".. TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_PRIMARY)..": "..(ingredient_recipe.recipe.actionstr ~= nil and STRINGS.UI.CRAFTING.RECIPEACTION[ingredient_recipe.recipe.actionstr] or STRINGS.UI.CRAFTING.PLACE)
				--self.fg = self.image:AddChild(Image(crafting_atlas, "ingredient_craft.tex"))
				--self.fg:SetTint(0.2, 0.6, 0.7, 1)
			elseif meta.build_state == "prototype" then
				self.fg = self.image:AddChild(Image(crafting_atlas, "ingredient_prototype.tex"))
				tooltip = tooltip.."\n".. TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_PRIMARY)..": "..STRINGS.UI.CRAFTING.PROTOTYPE
			else
				self.fg = self.image:AddChild(Image(crafting_atlas, "ingredient_craft.tex"))
				tooltip = tooltip.."\n".. TheInput:GetLocalizedControl(TheInput:GetControllerID(), CONTROL_PRIMARY)..": "..(ingredient_recipe.recipe.actionstr ~= nil and STRINGS.UI.CRAFTING.RECIPEACTION[ingredient_recipe.recipe.actionstr] or STRINGS.UI.CRAFTING.BUILD)
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

			self.ingredients = self.sub_ingredients:AddChild(CraftingMenuIngredients(self.owner, 4, ingredient_recipe.recipe, 1.5))

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