name = "Craft Menu Tweak"
author = "Godless"
version = "6.7"
description = [[
Customize the crafting menu to your taste, open the mod settings and turn on the necessary functions.
Налаштуйте меню крафту на свій смак, відкривай налаштування моду і вмикай необхідні функції.
Настрой меню крафта на свой вкус, открывай настройки мода и включай необходимые функции.
根据您的喜好自定义制作菜单，打开模组设置并打开必要的功能。

Version: ]] .. version
api_version = 10
client_only_mod = true
dst_compatible = true
icon_atlas = "images/modicon.xml"
icon = "modicon.tex"

local LOCALE =
{
	EN =
	{
		NAME = name,
		DISABLED = "No",
		ENABLED = "Yes",
		ICON_PACK = "Icon Pack",
		CHAR_ICON = "Character Icon",
		ICON_SIZE = "Icon Size",
		FAST_CRAFT = "Craft 1 click",
		FUN_KEY = "Functional key",
		SUB_INGR = "Ingredient list",
		CRAFT_SKIN = "Skin instead of item",
		TAB_SUPPORT = "Tabs support",
		TAB_RECIPES = "Tabs recipes",
		SCRAP_BOOK = "Scrap book button",
		CRAFT_ING = "Сraft ingredients",
		COMP_PINBAR = "Compact pinn bar",
		FIX_PINBAR = "Fixed pinn bar",
		CHR_PINBAR = "Character pinn bar",
		OLD_NEW = "Old/New mode",
		COMP_CM = "Compact craft menu",
		RECIPE_SUP = "Mod Recipe Support",
		ICON_OLD = "Old",
		ICON_BLACK = "Black",
		ICON_ORG = "Origin",
		FAV_SHOW_ALL = "Show all recipe",
		CRAFT_COUNT = "Num to craft",

		ICON_PACK_HOVER = "Appearance of the main filter icons.",
		CHAR_ICON_HOVER = "Changes the avatar icon to the character tab icon.",
		ICON_SIZE_HOVER = "In case the character icon is large or small.",
		FAST_CRAFT_HOVER = "Allows you to create items by clicking on the icon 1 time, select the button to activate mode.",
		SUB_INGR_HOVER = "Will display a small list of ingredients below the bottom when hovering over a recipe",
		CRAFT_SKIN_HOVER = "Changes the standard icon of the recipe to the skin, allowing you to understand which skin will be created by double-clicking",
		FUN_KEY_HOVER = "Button to add a tab and sort favorite recipes.",
		TAB_SUPPORT_HOVER = "light port of server mod \"Tabs\"",
		TAB_RECIPES_HOVER = "Enables recipe support for tabs, tabs support must also be active",
		SCRAP_BOOK_HOVER = "Adds a small button that, when clicked, will open a Scrapbook with information about that item.",
		CRAFT_ING_HOVER = "Improved version of the original.",
		COMP_PINBAR_HOVER = "Makes it more compact and makes 12 pinn slots.",
		FIX_PINBAR_HOVER = "Makes it fixed by separating it from the crafting menu.",
		CHR_PINBAR_HOVER = "Adds an additional tab that will change depending on the selected character.",
		OLD_NEW_HOVER = "Changes the location of all crafts to the old place and removes new filters.",
		COMP_CM_HOVER = "Makes the menu compacted but higher.",
		RECIPE_SUP_HOVER = "If you do not see recipes from the mod in the filters, enable this option",
		FAV_SHOW_AL_HOVER = "Show all recipe in favorite filter.",
		CRAFT_COUNT_HOVER = "Displays information about the number of items you will receive after crafting.",

		ICON_OLD_HOVER = "Icons in the style of the old menu.",
		ICON_BLACK_HOVER = "Icons in black style and nothing more.",
		ICON_ORG_HOVER = "Leave unchanged.",
		C_ICON_OLD_HOVER = "Icon of the character's tab, if there was one.",
		C_ICON_BLACK_HOVER = "Black version of the character's head.",
	},
	RU =
	{
		NAME = name,
		DISABLED = "Нет",
		ENABLED = "Да",
		ICON_PACK = "Набор Иконок",
		CHAR_ICON = "Иконка Персонажа",
		ICON_SIZE = "Размер иконки",
		FAST_CRAFT = "Крафт 1 кликом",
		FUN_KEY = "Функциональная кнопка",
		TAB_SUPPORT = "Поддержка вкладок",
		TAB_RECIPES = "Рецепты вкладок",
		SCRAP_BOOK = "Кнопка открытия скрепбука",
		CRAFT_ING = "Крафт ингридиентов",
		COMP_PINBAR = "Компактная пин панель",
		FIX_PINBAR = "Фиксированая пин панель",
		CHR_PINBAR = "Пин панель персонажа",
		OLD_NEW = "Старо/Новий режим",
		COMP_CM = "Компактное крафт меню",
		RECIPE_SUP = "Поддержка рецептов из модов",
		ICON_OLD = "Старий",
		ICON_BLACK = "Чёрний",
		ICON_ORG = "Оригинальный",
		FAV_SHOW_ALL = "Показать все рецепты",
		CRAFT_COUNT = "Количество при крафте",

		ICON_PACK_HOVER = "Внешний вид основных значков фильтров.",
		CHAR_ICON_HOVER = "Заменяет значок аватара на значок вкладки персонажа.",
		ICON_SIZE_HOVER = "Если значок персонажа большой или маленький.",
		FAST_CRAFT_HOVER = "Позволяет создавать предметы, 1 кликом, выберите кнопку для активации режима.",
		FUN_KEY_HOVER = "Кнопка для добавления вкладок и сортировки любимых рецептов.",
		TAB_SUPPORT_HOVER = "Лёгкий порт серверного мода \"Tabs\"",
		TAB_RECIPES_HOVER = "Добавляет поддержку рецептов для вкладок, поддержка владок должна быть включена",
		SCRAP_BOOK_HOVER = "Добавляет кнопку по нажатию на которую откроется книга с доп. информацией.",
		CRAFT_ING_HOVER = "Улучшенная версия оригинала.",
		COMP_PINBAR_HOVER = "Сделает его компактным (12 слотов для пинов).",
		FIX_PINBAR_HOVER = "Фиксирует, отделяя от меню крафта.",
		CHR_PINBAR_HOVER = "Добавляет дополнительную вкладку которая будет меняться взависимости от выбраного персонажа.",
		OLD_NEW_HOVER = "Изменяет положение крафтов на старое место и удаляет новые фильтры.",
		COMP_CM_HOVER = "Уменьшает меню, делая его уже",
		RECIPE_SUP_HOVER = "Если у вас не отображаются рецепты на вкладках, вслючите авто поддержку",
		FAV_SHOW_AL_HOVER = "Показывает все рецепты в фильтре избранного.",
		CRAFT_COUNT_HOVER = "Отображает информацию о количестве предметов, которые вы получите после крафта.",

		ICON_OLD_HOVER = "Значки в стиле старого меню.",
		ICON_BLACK_HOVER = "Значки в черном стиле и ничего более.",
		ICON_ORG_HOVER = "Оставить без изменений.",
		C_ICON_OLD_HOVER = "Иконка вкладки персонажа, если она есть.",
		C_ICON_BLACK_HOVER = "Черная версия головы персонажа.",
	},
	CH =
	{
		DISABLED = "禁用",
		ENABLED = "启用",
		ICON_PACK = "选项卡图标",
		CHAR_ICON = "选项卡角色图标",
		ICON_SIZE = "角色图标大小",
		FAST_CRAFT = "配方一键制作",
		FUN_KEY = "快捷键",
		SUB_INGR = "配方悬浮材料",
		CRAFT_SKIN = "配方皮肤",
		TAB_SUPPORT = "Tabs模组支持",
		TAB_RECIPES = "标签食谱",
		CRAFT_ING = "材料栏视觉改善",
		COMP_PINBAR = "快捷制作栏更多栏",
		FIX_PINBAR = "快捷制作栏固定位置",
		CHR_PINBAR = "角色针杆",
		OLD_NEW = "传统选项卡",
		COMP_CM = "窄的三行制作栏",
		RECIPE_SUP = "模组配方识别",
		ICON_OLD = "传统风格",
		ICON_BLACK = "黑色风格",
		ICON_ORG = "当前风格",
		FAV_SHOW_ALL = "显示全部菜谱",
		CRAFT_COUNT = "制作数量",

		ICON_PACK_HOVER = "选项卡图标的视觉效果",
		CHAR_ICON_HOVER = "针对选项卡中的角色头像调整视觉效果",
		ICON_SIZE_HOVER = "预防角色头像尺寸不合在此调整",
		FAST_CRAFT_HOVER = "允许你使用按键点击道具直接制作",
		SUB_INGR_HOVER = "鼠标悬停在配方上下方显示所需材料",
		CRAFT_SKIN_HOVER = "配方图标替换为其最近使用的皮肤图标",
		FUN_KEY_HOVER = "制作栏内用此按键添加新选项卡，收藏夹内用此按键来调序；前者需要使用Tabs服务端模组和打开Tabs模组支持",
		TAB_SUPPORT_HOVER = "\"Tabs\"服务端模组的轻量接口",
		TAB_RECIPES_HOVER = "启用配方对选项卡的支持，选项卡支持也必须处于激活状态",
		CRAFT_ING_HOVER = "改善制作栏下方材料栏的视觉效果",
		COMP_PINBAR_HOVER = "最左侧的快捷制作栏从原来的9格变为12格",
		FIX_PINBAR_HOVER = "最左侧的快捷制作栏在打开制作栏后还在最左侧，需要打开窄的三行制作栏",
		CHR_PINBAR_HOVER = "添加一个附加选项卡，该选项卡将根据所选字符而变化。",
		OLD_NEW_HOVER = "制作栏还是现在的UI，但是选项卡都变成传统的，配方也都对应调整到传统配方选项卡里",
		COMP_CM_HOVER = "把制作栏变得窄但更高，以方便分割出来快捷制作栏固定在最左侧",
		RECIPE_SUP_HOVER = "如果制作栏里找不到模组配方，打开此功能",
		FAV_SHOW_AL_HOVER = "在最喜欢的过滤器中显示所有食谱。",
		CRAFT_COUNT_HOVER = "显示制作后您将收到的物品数量信息",

		ICON_OLD_HOVER = "传统风格",
		ICON_BLACK_HOVER = "黑色风格",
		ICON_ORG_HOVER = "未做任何改变",
		C_ICON_OLD_HOVER = "传统风格",
		C_ICON_BLACK_HOVER = "黑色风格",
	},
}
-- СМЕНА ЯЗЫКА НА РУС/ 将语言更改为中文 --
local STRINGS = LOCALE.EN --LOCALE.RU --LOCALE.CH

local string = ""
local keyslist = {}
local key = { "B", "C", "F", "G", "H", "I", "J", "K", "L", "N", "O", "P", "R", "T", "U", "V", "X", "Y", "Z", "ALT",
	"CTRL", "SHIFT", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0" }
for i = 1, #key do keyslist[i] = { description = key[i], data = "KEY_" .. string.upper(key[i]) } end
local bool = { { description = STRINGS.DISABLED, data = false }, { description = STRINGS.ENABLED, data = true } }
local function MakeOption(name, default, options)
	return {
		name = name,
		label = STRINGS[name],
		hover = STRINGS[name .. "_HOVER"],
		options = options or bool,
		default = default or false,
	}
end

configuration_options =
{
	MakeOption("ICON_PACK", 3, {
		{ description = STRINGS.ICON_OLD,   hover = STRINGS.ICON_OLD_HOVER,   data = 1 },
		{ description = STRINGS.ICON_BLACK, hover = STRINGS.ICON_BLACK_HOVER, data = 2 },
		{ description = STRINGS.ICON_ORG,   hover = STRINGS.ICON_ORG_HOVER,   data = 3 },
	}),
	MakeOption("CHAR_ICON", 3, {
		{ description = STRINGS.ICON_OLD,   hover = STRINGS.C_ICON_OLD_HOVER,   data = 1 },
		{ description = STRINGS.ICON_BLACK, hover = STRINGS.C_ICON_BLACK_HOVER, data = 2 },
		{ description = STRINGS.ICON_ORG,   hover = STRINGS.ICON_ORG_HOVER,     data = 3 },
	}),
	MakeOption("ICON_SIZE", 80, {
		{ description = "25",  data = 25 },
		{ description = "50",  data = 50 },
		{ description = "80",  data = 80 },
		{ description = "100", data = 100 },
	}),
	MakeOption("FAST_CRAFT", 1, {
		{ description = "Always",       hover = "Hold right button to deactivate mode", data = 0 },
		{ description = "Right Button", hover = "Hold right button and click",          data = 1 },
		{ description = "Ctrl",         hover = "Hold Ctrl and click",                  data = 2 },
	}),
	MakeOption("FUN_KEY", "KEY_X", keyslist),
	MakeOption("SUB_INGR"),
	MakeOption("CRAFT_SKIN", true),
	MakeOption("SCRAP_BOOK", true),
	MakeOption("TAB_SUPPORT", true),
	MakeOption("TAB_RECIPES"),
	MakeOption("CRAFT_ING", true),
	MakeOption("CRAFT_COUNT"),
	MakeOption("FAV_SHOW_ALL", true),
	MakeOption("COMP_PINBAR"),
	MakeOption("FIX_PINBAR"),
	MakeOption("CHR_PINBAR"),
	MakeOption("OLD_NEW"),
	MakeOption("COMP_CM"),
	MakeOption("RECIPE_SUP"),
}
