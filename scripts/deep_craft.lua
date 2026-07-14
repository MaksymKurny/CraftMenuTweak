local AddSimPostInit = AddSimPostInit

GLOBAL.setfenv(1, GLOBAL)

--Recursive ingredient auto-crafting, ported from a reference "deep craft" mod
--(originally written to hook DoRecipeClick on the build button) so it can also
--be called from an ingredient click. Given a target recipe, walks its
--ingredient tree and returns the closest ingredient recipe the player can
--craft right now, or nil if nothing in the tree is currently craftable.

--keys are products, values are arrays of recipes that craft that product sorted by priority
--priority is currently based on the total number of ingredients used
local recipesByProduct = {}

AddSimPostInit(function()
	recipesByProduct = {}
	for name, recipe in pairs(AllRecipes) do
		if recipesByProduct[recipe.product] == nil then
			recipesByProduct[recipe.product] = {}
		end
		local index = 1
		local newPriority = 0
		if recipe.ingredients ~= nil then
			for i, ingredient in ipairs(recipe.ingredients) do
				if ingredient.type == recipe.product then
					newPriority = math.huge
				end
				newPriority = newPriority + ingredient.amount
			end
		end
		while recipesByProduct[recipe.product][index] ~= nil and newPriority > recipesByProduct[recipe.product][index].priority do
			index = index + 1
		end
		table.insert(recipesByProduct[recipe.product], index, { recipeName = name, priority = newPriority })
	end
end)

--simple shallow copy
local function copyTable(t)
	local newTable = {}
	for key, value in pairs(t) do
		newTable[key] = value
	end
	return newTable
end

--true if one of the recipe ingredients was already visited this recursion (guards against A->B->A loops)
local function ifRepeats(recipe, previouslyChecked)
	for index, ingredient in ipairs(recipe.ingredients) do
		if previouslyChecked[ingredient.type] ~= nil then
			return true
		end
	end
	return false
end

--forward declaration, helper for findIngredient
local considerRecipe

--recursive function which finds a craftable ingredient recipe within recipe's ingredient tree
local function findIngredient(owner, recipe, depth, oldPreviouslyChecked)
	if recipe == nil or owner == nil or owner.replica.builder == nil then
		return nil
	end
	local previouslyChecked = copyTable(oldPreviouslyChecked)
	previouslyChecked[recipe.product] = true

	local builderTagCheck = recipe.builder_tag == nil or owner.replica.builder.inst:HasTag(recipe.builder_tag)
	local techCheck = CanPrototypeRecipe(recipe.level, owner.replica.builder:GetTechTrees())
	local skillTreeCheck = recipe.builder_skill == nil or
		owner.replica.builder.inst.components.skilltreeupdater:IsActivated(recipe.builder_skill)
	local canPrototype = techCheck and builderTagCheck and skillTreeCheck
	local knowsRecipe = owner.replica.builder:KnowsRecipe(recipe)

	--if you can't craft this recipe or we get in some weird loop, stop
	if depth > 5 or (not knowsRecipe and not canPrototype) then
		return nil
	end

	for i, ingredient in ipairs(recipe.ingredients) do
		local requiredAmount = math.max(1, RoundBiasedUp(ingredient.amount * owner.replica.builder:IngredientMod()))
		local enoughIngredient = owner.replica.inventory:Has(ingredient.type, requiredAmount, true)
		if not enoughIngredient and recipesByProduct[ingredient.type] ~= nil then
			--look up all recipes for the missing ingredient and try them in priority order
			for j, ingredientRecipeArray in ipairs(recipesByProduct[ingredient.type]) do
				local result = considerRecipe(owner, ingredientRecipeArray.recipeName, previouslyChecked, depth)
				if result ~= nil then
					return result
				end
			end
		end
	end
	return nil
end

--returns the recipe to craft next, or nil if no ingredient in the tree is currently craftable
considerRecipe = function(owner, name, previouslyChecked, depth)
	local ingredientRecipe = GetValidRecipe(name)
	if ingredientRecipe ~= nil then
		local can_prototype = CanPrototypeRecipe(ingredientRecipe.level, owner.replica.builder:GetTechTrees())
			and (ingredientRecipe.builder_tag == nil or owner.replica.builder.inst:HasTag(ingredientRecipe.builder_tag))
			and (ingredientRecipe.builder_skill == nil or
				owner.replica.builder.inst.components.skilltreeupdater:IsActivated(ingredientRecipe.builder_skill))
		local knows_recipe = owner.replica.builder:KnowsRecipe(ingredientRecipe)
		if (knows_recipe or can_prototype) and not ifRepeats(ingredientRecipe, previouslyChecked) then
			--if craftable right now, that's our target; otherwise recurse one level deeper
			if owner.replica.builder:HasIngredients(ingredientRecipe) then
				return ingredientRecipe
			else
				return findIngredient(owner, ingredientRecipe, depth + 1, previouslyChecked)
			end
		end
	end
	return nil
end

--public entry point: finds the closest currently-craftable ingredient recipe towards building "recipe"
function FindDeepCraftIngredient(owner, recipe)
	return findIngredient(owner, recipe, 0, {})
end
