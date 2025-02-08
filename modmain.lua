 ImageButton = require "widgets/imagebutton"
 Widget = require "widgets/widget"
 Image = require "widgets/image"
 Grid = require "widgets/grid"
 Text = require "widgets/text"
 _G = GLOBAL
 resolvefilepath = _G.resolvefilepath
 softresolvefilepath = _G.softresolvefilepath
 TheInput = _G.TheInput
 STRINGS = _G.STRINGS
 Profile = _G.Profile
 GetTime = _G.GetTime
 TheNet = _G.TheNet

 Assets = {
	Asset("IMAGE", "images/crafting_menu_avatars_o.tex"),
	Asset("ATLAS", "images/crafting_menu_avatars_o.xml"),
 }

 -- Functional key --
 F_KEYS = GetModConfigData("FUN_KEY")
 if type(F_KEYS) == "string" and _G:rawget(F_KEYS) then F_KEYS = _G[F_KEYS] end

--- Icons ---
if GetModConfigData("ICON_PACK") == 1 then
	table.insert(Assets, Asset("IMAGE", "images/old/crafting_menu_icons.tex"))
	table.insert(Assets, Asset("ATLAS", "images/old/crafting_menu_icons.xml"))
	_G.CRAFTING_ICONS_ATLAS = "images/old/crafting_menu_icons.xml"

elseif GetModConfigData("ICON_PACK") == 2 then
	table.insert(Assets, Asset("IMAGE", "images/blk/crafting_menu_icons.tex"))
	table.insert(Assets, Asset("ATLAS", "images/blk/crafting_menu_icons.xml"))
	_G.CRAFTING_ICONS_ATLAS = "images/blk/crafting_menu_icons.xml"
end

-- Icons and old/new mode --
modimport("scripts/recipes_filter")

-- Craft 1 click and favorite sort --
modimport("scripts/craftingmenu_widget")

-- Tabs client_only port --
if GetModConfigData("TAB_SUPPORT") then modimport("scripts/tabs") end

-- Compact menu --
if GetModConfigData("COMP_CM") then modimport("scripts/craftingmenu_hud") end

--- Ing quick craft ---
--- Thanks a lot for the first base code Zaptrap --
if GetModConfigData("CRAFT_ING") then modimport("scripts/ingredientui") end


--- Compact pinn bar ---
if GetModConfigData("COMP_PINBAR") then
	_G.TUNING.MAX_PINNED_RECIPES = 12
	local PinSlot = require "widgets/redux/craftingmenu_pinslot"
	AddClassPostConstruct("widgets/redux/craftingmenu_pinbar", function(self, owner, crafting_hud, height)
		local buttonsize = 60 -- 64
		local y = 241 -- 378 -76 -61
		self.pin_slots = {}
		local pinned_recipes = _G.TheCraftingMenuProfile:GetPinnedRecipes()

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
			for i = (_pin.slot_num or 0) + 1, _G.TUNING.MAX_PINNED_RECIPES do
				if self.pin_slots[i]:IsVisible() then
					return self.pin_slots[i]
				end
			end
		end

		for i = 1, _G.TUNING.MAX_PINNED_RECIPES do
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
	end)
end
