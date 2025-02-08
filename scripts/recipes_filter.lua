local size = GetModConfigData("ICON_SIZE")
local MOD_LIST = {}
local modimport = modimport
local GetModConfigData = GetModConfigData

GLOBAL.setfenv(1, GLOBAL)

local function GetCharacterAtlas(owner)
	-- mod character avatars for the crafting menu should be placed in "/images/crafting_menu_avatars/avatar_<name>.xml" with image "avatar_<name>.tex"
	-- if the mod character does not have a specific crafting menu icon, then it will fallback to "/images/avatars/avatar_<name>.xml" with image "avatar_<name>.tex"
	-- these paths will also respect being redirected via MOD_CRAFTING_AVATAR_LOCATIONS or MOD_AVATAR_LOCATIONS

	local atlas_name = nil
	if GetModConfigData("CHAR_ICON") == 2 and owner ~= nil then
		atlas_name = (owner.prefab == "wanda" and "images/hud2.xml" or softresolvefilepath("images/avatars/self_inspect_" .. owner.prefab .. ".xml")) or
		"images/hud.xml"
	elseif owner ~= nil and table.contains(MODCHARACTERLIST, owner.prefab) then
		atlas_name = (MOD_CRAFTING_AVATAR_LOCATIONS[owner.prefab] or MOD_CRAFTING_AVATAR_LOCATIONS.Default) ..
		"avatar_" .. owner.prefab .. ".xml"
		if softresolvefilepath(atlas_name) == nil then
			atlas_name = (MOD_AVATAR_LOCATIONS[owner.prefab] or MOD_AVATAR_LOCATIONS.Default) ..
			"avatar_" .. owner.prefab .. ".xml"
		end
	elseif GetModConfigData("CHAR_ICON") == 1 then
		atlas_name = resolvefilepath("images/crafting_menu_avatars_o.xml")
	else
		atlas_name = resolvefilepath("images/crafting_menu_avatars.xml")
	end
	return atlas_name
end

local function GetCharacterImage(owner)
	if GetModConfigData("CHAR_ICON") == 2 then
		return owner ~= nil and ("self_inspect_" .. owner.prefab .. ".tex") or "self_inspect_mod.tex"
	else
		return owner ~= nil and ("avatar_" .. owner.prefab .. ".tex") or "avatar_mod.tex"
	end
end

local function GetCraftingMenuAtlas()
	return resolvefilepath(CRAFTING_ICONS_ATLAS)
end

if not GetModConfigData("OLD_NEW") then
	if CRAFTING_FILTER_DEFS[5].name == "CHARACTER" then
		CRAFTING_FILTER_DEFS[5].atlas = GetCharacterAtlas
		CRAFTING_FILTER_DEFS[5].image = GetCharacterImage
		CRAFTING_FILTER_DEFS[5].image_size = size
	end
else                    --- Old/New mode ---
	modimport("scripts/strings")
	CRAFTING_FILTER_DEFS = --Old filter type
	{
		{ name = "FAVORITES",        atlas = GetCraftingMenuAtlas, image = "filter_favorites.tex", custom_pos = true },
		{ name = "CRAFTING_STATION", atlas = GetCraftingMenuAtlas, image = "filter_none.tex",      custom_pos = true, recipes = CRAFTING_FILTERS.CRAFTING_STATION.recipes },
		{ name = "SPECIAL_EVENT",    atlas = GetCraftingMenuAtlas, image = "filter_events.tex",    custom_pos = true, recipes = CRAFTING_FILTERS.SPECIAL_EVENT.recipes },
		{ name = "MODS",             atlas = GetCraftingMenuAtlas, image = "filter_modded.tex",    custom_pos = true, recipes = CRAFTING_FILTERS.MODS.recipes },

		{ name = "TOOLS",            atlas = GetCraftingMenuAtlas, image = "filter_tool.tex", },
		{ name = "LIGHT",            atlas = GetCraftingMenuAtlas, image = "filter_fire.tex", },
		{ name = "RESTORATION",      atlas = GetCraftingMenuAtlas, image = "filter_health.tex", },
		{ name = "GARDENING",        atlas = GetCraftingMenuAtlas, image = "filter_gardening.tex", },
		{ name = "PROTOTYPERS",      atlas = GetCraftingMenuAtlas, image = "filter_science.tex", },
		{ name = "WEAPONS",          atlas = GetCraftingMenuAtlas, image = "filter_weapon.tex", },
		{ name = "STRUCTURES",       atlas = GetCraftingMenuAtlas, image = "filter_structure.tex", },
		{ name = "DECOR",            atlas = GetCraftingMenuAtlas, image = "filter_cosmetic.tex", },
		{ name = "SEAFARING",        atlas = GetCraftingMenuAtlas, image = "filter_sailing.tex", },
		{ name = "REFINE",           atlas = GetCraftingMenuAtlas, image = "filter_refine.tex", },
		{ name = "MAGIC",            atlas = GetCraftingMenuAtlas, image = "filter_skull.tex", },
		{ name = "CLOTHING",         atlas = GetCraftingMenuAtlas, image = "filter_warable.tex", },
		{ name = "FISHING",          atlas = GetCraftingMenuAtlas, image = "filter_fishing.tex", },
		{ name = "CHARACTER",        atlas = GetCharacterAtlas,    image = GetCharacterImage,      image_size = size, recipes = CRAFTING_FILTERS.CHARACTER.recipes },
		{ name = "EVERYTHING",       atlas = GetCraftingMenuAtlas, image = "filter_none.tex",      show_hidden = true },
	}
	for i, v in ipairs(CRAFTING_FILTER_DEFS) do
		--if GetModConfigData("RECIPE_SUP") and (i > 4 and i < 18) then
		--	MOD_LIST[v.name] = {recipes={unpack(CRAFTING_FILTERS[v.name].recipes), unpack(CRAFTING_FILTERS["ARMOUR"].recipes)}}
		--end -- Recipe2 support
		CRAFTING_FILTERS[v.name] = v
	end

	CRAFTING_FILTERS.TOOLS.recipes =
	{
		"axe",
		"goldenaxe",
		"machete",
		"goldenmachete",
		"pickaxe",
		"goldenpickaxe",

		"shears", --TE

		"shovel",
		"goldenshovel",

		"farm_hoe",
		"golden_farm_hoe",

		"hammer",
		"pitchfork",
		"goldenpitchfork",
		"antlionhat",

		"wateringcan",
		"premiumwateringcan",

		"telescope",
		"supertelescope",

		"wagpunkbits_kit",

		"razor",
		"featherpencil",
		"pocket_scale",
		"beef_bell",
		"saddlehorn",
		"saddle_basic",
		"saddle_war",
		"saddle_race",
		"brush",
		"saltlick",
		"saltlick_improved",
	}

	CRAFTING_FILTERS.LIGHT.recipes =
	{
		"campfire",
		"firepit",
		"chiminea",                        -- TE
		"sea_chiminea", "porto_sea_chiminea", --IA TE
		"lighter",
		"torch",
		"tarlamp",
		"coldfire",
		"coldfirepit",
		"obsidianfirepit",
		"cotl_tabernacle_level1",

		"candlehat", --TE
		"minerhat",
		"molehat",
		"bathat", --TE

		"pumpkin_lantern",
		"lantern",
		"bottlelantern",

		"boat_torch",
		"boat_lantern",

		"mushroom_light",
		"mushroom_light2",
		"buoy", "porto_buoy", -- IA TE
	}

	CRAFTING_FILTERS.PROTOTYPERS.recipes =
	{
		"madscience_lab",
		"researchlab",
		"researchlab2",
		"sea_lab", "porto_researchlab5", -- IA TE
		"transistor",
		--"diviningrod",
		"seafaring_prototyper",
		"cartographydesk",
		"sculptingtable",
		"winterometer",
		"rainometer",
		"gunpowder",
		"lightning_rod",
		"firesuppressor",

		"smelter", --TE
		"basefan", --TE
		"icemaker",
		"quackendrill",

		"chestupgrade_stacksize",

		"turfcraftingstation",
		"carpentry_station",
		"moon_device_construction1",
	}

	CRAFTING_FILTERS.REFINE.recipes =
	{
		"rope",
		"walter_rope",
		"boards",
		"cutstone",
		"papyrus",
		"fabric",
		"limestonenugget", "limestone", --AI TE
		"goldnugget",
		"waxpaper",
		"beeswax",

		-- "venomgland", --TE
		"nubbin",
		"marblebean",
		-- "clawpalmtree_sapling", --TE

		"ice",
		"ia_messagebottleempty", "messagebottleempty1", --IA TE
		"bearger_fur",
		"nightmarefuel",
		"purplegem",
		"moonrockcrater",
		"malbatross_feathered_weave",
		"refined_dust",
	}

	CRAFTING_FILTERS.WEAPONS.recipes =
	{
		"spear_wathgrithr",
		"spear_wathgrithr_lightning",
		"wathgrithrhat",
		"wathgrithr_improvedhat",
		"wathgrithr_shield",
		"slingshot",
		"spear",

		"halberd", --TE
		"spear_poison",
		"cork_bat", --TE

		"hambat",
		"nightstick",
		"whip",
		"armorgrass",
		"armorwood",
		"armorseashell", "armor_seashell", -- IA TE
		"armormarble",
		"armordreadstone",
		"dreadstonehat",
		"armorwagpunk",
		"wagpunkhat",
		"armorlimestone", "armor_limestone", -- IA TE
		"armorcactus",
		"armor_weevole",                   --TE

		"antmaskhat",                      --TE
		"antsuit",                         --TE

		"footballhat",
		"oxhat",
		"cookiecutterhat",

		"metalplatehat",  --TE
		"armor_metalplate", --TE

		"sleepbomb",

		"blowdart_sleep",
		"blowdart_fire",
		"blowdart_pipe",
		"blowdart_yellow",
		"blowdart_poison",
		"boomerang",
		"beemine",
		"trap_teeth",
		"coconade",
		"spear_launcher",
		"cutlass",
		"blunderbuss", --TE
		"armordragonfly",
		"staff_tornado",
		"staff_lunarplant",

		"trident",
		"fence_rotator",
	}

	CRAFTING_FILTERS.CLOTHING.recipes =
	{
		"sewing_kit",

		"mermhat",
		"walterhat",

		"flowerhat",
		"strawhat",
		"tophat",
		"rainhat",
		"earmuffshat",
		"beefalohat",
		"winterhat",
		"catcoonhat",

		"gasmaskhat", --TE

		"kelphat",
		"goggleshat",
		"deserthat",
		"moonstorm_goggleshat",
		"brainjellyhat",
		"watermelonhat",
		"pithhat",      --TE
		"thunderhat",   --TE
		"shark_teethhat", --IA
		"icehat",
		"beehat",
		"featherhat",
		"bushhat",
		"snakeskinhat",
		"raincoat",
		"armor_snakeskin",
		"blubbersuit",
		"tarsuit",
		"sweatervest",
		"trunkvest_summer",
		"trunkvest_winter",
		"reflectivevest",
		"hawaiianshirt",
		"cane",
		"beargervest",
		"eyebrellahat",
		"double_umbrellahat",
		"armor_windbreaker",
		"gashat",
		"aerodynamichat",
		"red_mushroomhat",
		"green_mushroomhat",
		"blue_mushroomhat",
		"polly_rogershat",
	}

	CRAFTING_FILTERS.RESTORATION.recipes =
	{
		"reviver",
		"healingsalve",
		"healingsalve_acid",
		"tillweedsalve",
		"bandage",
		"antivenom", "antidote", -- IA TE
		"lifeinjector",
		"bernie_inactive",
		"trap",
		"birdtrap",
		"bugnet",
		"thulecitebugnet",
		"fishingrod",
		"oceanfishingrod",
		"monkeyball",
		"miniflare",
		"megaflare",
		"grass_umbrella",
		"palmleaf_umbrella",
		"umbrella",

		"bugrepellent", --TE
		"waterballoon",
		"compass",
		"heatrock",
		"giftwrap",
		"bundlewrap",
		"thatchpack",
		"spicepack",
		"backpack",
		"candybag",
		"seedpouch",
		"piggyback",
		"icepack",
		"seasack",
		"bedroll_straw",
		"bedroll_furry",
		"tent",
		"siestahut",
		"palmleaf_hut",
		"portabletent_item",
		"doydoynest", -- no TE
		--"antler",-- TE
		"minifan",
		"featherfan",
		"doydoyfan", "tropicalfan", -- IA TE
	}

	CRAFTING_FILTERS.GARDENING.recipes =
	{
		"cookpot",
		"cookbook",

		"icebox",
		"saltbox",

		"farm_plow_item",
		"fish_farm", "porto_fish_farm", -- IA TE
		"seatrap",
		"mussel_bed",
		"mussel_stick",
		"sprinkler1", -- TE
		"fertilizer",
		"soil_amender",
		"treegrowthsolution",
		"compostingbin",
		"plantregistryhat",

		"mushroom_farm",
		"beebox",
		"meatrack",
		--NOTE: add portable cookware to UNCRAFTABLE section as well!
		"portablecookpot_item",
		"portableblender_item",
		"portablespicer_item",
	}

	CRAFTING_FILTERS.FISHING.recipes =
	{
		"tacklestation",

		"oceanfishingbobber_ball",
		"oceanfishingbobber_oval",
		"oceanfishingbobber_crow",
		"oceanfishingbobber_robin",
		"oceanfishingbobber_robin_winter",
		"oceanfishingbobber_canary",
		"oceanfishingbobber_goose",
		"oceanfishingbobber_malbatross",

		"oceanfishinglure_spoon_red",
		"oceanfishinglure_spoon_green",
		"oceanfishinglure_spoon_blue",
		"oceanfishinglure_spinner_red",
		"oceanfishinglure_spinner_green",
		"oceanfishinglure_spinner_blue",
		"oceanfishinglure_hermit_rain",
		"oceanfishinglure_hermit_snow",
		"oceanfishinglure_hermit_drowsy",
		"oceanfishinglure_hermit_heavy",

		"chum",
	}

	CRAFTING_FILTERS.SEAFARING.recipes =
	{
		"boat_grass_item",
		"boat_item",
		"boat_lograft", "porto_lograft_old",   --IA TE
		"boat_raft", "porto_raft_old",         --IA TE
		"boat_row", "porto_rowboat",           --IA TE
		"corkboatitem",                        --TE
		"boat_cargo", "porto_cargoboat",       --IA TE
		"boat_armoured", "porto_armouredboat", --IA TE
		"boat_encrusted", "porto_encrustedboat", --IA TE
		"boatpatch_kelp",
		"boatpatch",
		"boatrepairkit",
		"oar",
		"oar_driftwood",
		"anchor_item",
		"steeringwheel_item",
		"boat_rotator_kit",
		"mast_item",
		"mast_malbatross_item",
		"sail_palmleaf", "sail",         --IA TE
		"sail_cloth", "clothsail",       -- IA TE
		"sail_snakeskin", "snakeskinsail", --IA TE
		"sail_feather", "feathersail",   --IA TE
		"malbatrossail",                 --TE
		"ironwind",

		"boat_bumper_kelp_kit",
		"boat_bumper_shell_kit",
		"boat_bumper_yotd_kit",

		"boat_cannon_kit",
		"cannonball_rock_item",
		"boatcannon",

		"quackeringram",
		"trawlnet",
		"ocean_trawler_kit",

		"mastupgrade_lamp_item",
		"mastupgrade_lightningrod_item",
		"mastupgrade_lamp_item_yotd",

		"captainhat",
		"piratehat",
		"armor_lifejacket",
		"fish_box",
		"winch",
		"waterpump",
		"boat_magnet_kit",
		"boat_magnet_beacon",

		"dock_kit",
		"dock_woodposts_item",
		"tar_extractor", "porto_tar_extractor", -- IA TE
		"sea_yard", "porto_sea_yard",         -- IA TE

		"chesspiece_anchor_sketch",
	}

	CRAFTING_FILTERS.STRUCTURES.recipes =
	{
		"wintersfeastoven",
		"table_winters_feast",
		"winter_treestand",

		"perdshrine",
		"wargshrine",
		"pigshrine",
		"yotc_carratshrine",
		"yotb_beefaloshrine",
		"yot_catcoonshrine",
		"yotr_rabbitshrine",
		"yotd_dragonshrine",
		"yots_snakeshrine",

		"mermhouse_crafted",
		"mermthrone_construction",
		"mermwatchtower",
		"turf_marsh",

		"sisturn",

		"treasurechest",
		"waterchest", "porto_waterchest1", -- IA TE
		"corkchest",                     --TE PL
		"homesign",
		"arrowsign_post",
		"minisign_item",
		"minisign",

		"rope_bridge_kit",

		"fence_gate_item",
		"fence_item",
		"wall_hay_item",
		"wall_wood_item",
		"wall_stone_item",
		"wall_limestone_item",
		"wall_enforcedlimestone_item",
		"wall_scrap_item",
		"wall_moonrock_item",
		"wall_dreadstone_item",

		"wardrobe",
		"beefalo_groomer",
		"pighouse",
		"wildborehouse",
		"ballphinhouse",
		"primeapebarrel",
		"rabbithouse",
		"dragoonden",
		"birdcage",
		"scarecrow",
		"sewing_mannequin",

		"punchingbag",
		"punchingbag_lunar",
		"punchingbag_shadow",

		"sandbagsmall_item", "sandbag_item", -- IA TE
		"sandcastle", "sand_castle",      --IA TE
		"dragonflychest",
		"magician_chest",
		"dragonflyfurnace",

		"support_pillar_scaffold",
		"archive_resonator_item",
	}

	CRAFTING_FILTERS.DECOR.recipes =
	{
		"reskin_tool",
		"pottedfern",
		"succulent_potted",
		"endtable",
		"trophyscale_fish",
		"trophyscale_oversizedveggies",

		"pirate_flag_pole",

		"turf_road",
		"turf_cotl_brick",
		"turf_woodfloor",
		"turf_cotl_gold",
		"turf_checkerfloor",
		"turf_carpetfloor",
		"turf_carpetfloor2",
		"turf_mosaic_red",
		"turf_mosaic_blue",
		"turf_mosaic_grey",
		"turf_dragonfly",
		"turf_ruinsbrick",
		"turf_ruinsbrick_glow",
		"turf_ruinstiles",
		"turf_ruinstiles_glow",
		"turf_ruinstrim",
		"turf_ruinstrim_glow",
		"turf_archive",

		"turf_snakeskin",             -- ?`
		"turf_beard_hair",            --?
		"turf_lawn",                  --?
		"turf_fields",                --?
		"turf_deeprainforest_nocanopy", --?

		"turf_pebblebeach",
		"turf_shellbeach",
		"turf_monkey_ground",

		"turf_forest",
		"turf_grass",
		"turf_savanna",
		"turf_deciduous",
		"turf_desertdirt",
		"turf_rocky",
		"turf_cave",
		"turf_underrock",
		"turf_sinkhole",
		"turf_marsh",
		"turf_mud",
		"turf_fungus",
		"turf_fungus_red",
		"turf_fungus_green",
		"turf_beard_rug",

		--IA
		"turf_jungle",
		"turf_meadow",
		"turf_tidalmarsh",
		"turf_magmafield",
		"turf_ash",
		"turf_volcano",

		"ruinsrelic_plate",
		"ruinsrelic_chipbowl",
		"ruinsrelic_bowl",
		"ruinsrelic_vase",
		"ruinsrelic_chair",
		"ruinsrelic_table",

		"phonograph",
		"record",

		"wood_chair",
		"stone_chair",
		"wood_stool",
		"stone_stool",
		"wood_table_round",
		"stone_table_round",
		"wood_table_square",
		"stone_table_square",
		"decor_centerpiece",
		"decor_lamp",
		"decor_flowervase",
		"decor_pictureframe",
		"decor_portraitframe",
	}

	CRAFTING_FILTERS.MAGIC.recipes =
	{
		"abigail_flower",
		"wereitem_goose",
		"wereitem_beaver",
		"wereitem_moose",
		"hogusporkusator", --PL
		"piratihatitator",
		"researchlab4",
		"researchlab3",
		"resurrectionstatue",
		"panflute",
		"ox_flute",
		"onemanband",
		"nightlight",
		"armor_sanity",

		"armorvortexcloak", --PL
		"living_artifact", --PL

		"nightsword",
		"batbat",
		"armorslurper",

		"roottrunk_child", --TE, PL

		"amulet",
		"blueamulet",
		"purpleamulet",
		"firestaff",
		"icestaff",
		"bonestaff", --PL
		"telestaff",
		"telebase",
		"sentryward",
		"moondial",
		"townportal",
		"shipwrecked_entrance",
		-- This is here so that the exit in the world can be hammered for goods.
		"shipwrecked_exit", --?
		--"porkland_entrance", --TE
	}

	for i, filter in pairs(CRAFTING_FILTERS) do
		if filter.recipes ~= nil then
			filter.default_sort_values = table.invert(filter.recipes)
		end
	end
	-- RECIPE2 SUPPORT --
	--if GetModConfigData("RECIPE_SUP") then
	--	for name, filter in pairs(MOD_LIST) do
	--		for _, recipe in ipairs(filter.recipes) do
	--			if AllRecipes[recipe].rpc_id > 1000 then
	--				print("WORK?",name, recipe)
	--				AddRecipeToFilter(recipe, name)
	--end	end end end
	--------------------
	CRAFTING_FILTERS.FAVORITES.recipes = function() return TheCraftingMenuProfile:GetFavorites() end
	CRAFTING_FILTERS.FAVORITES.default_sort_values = function() return TheCraftingMenuProfile:GetFavoritesOrder() end
end
