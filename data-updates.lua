-- tagboat_towship/data-updates.lua

-- 1) Unlock towship-tagboat with the same tech that unlocks "boat" (fallback: enable recipe)
do
  local function tech_unlocks_recipe(tech, recipe_name)
    if not (tech and tech.effects) then return false end
    for _, eff in pairs(tech.effects) do
      if eff.type == "unlock-recipe" and eff.recipe == recipe_name then
        return true
      end
    end
    return false
  end

  local function add_unlock(tech, recipe_name)
    tech.effects = tech.effects or {}
    table.insert(tech.effects, { type = "unlock-recipe", recipe = recipe_name })
  end

  local recipe_name = "towship-tagboat"
  if data.raw.recipe and data.raw.recipe[recipe_name] then
    local target_tech = nil
    if data.raw.technology then
      for _, tech in pairs(data.raw.technology) do
        if tech_unlocks_recipe(tech, "boat") then
          target_tech = tech
          break
        end
      end
    end

    if target_tech then
      add_unlock(target_tech, recipe_name)
    else
      data.raw.recipe[recipe_name].enabled = true
      log("[tagboat_towship] Could not find technology unlocking 'boat'. Enabled 'towship-tagboat' recipe.")
    end
  end
end

-- 2) Wooden Platform item now places the barge entity instead of a tile
do
  local it = data.raw["item"] and data.raw["item"]["wooden-platform"]
  if it then
    it.place_as_tile = nil
    it.place_result = "wooden-platform-barge"
    it.stack_size = it.stack_size or 100
  else
    log("[tagboat_towship] wooden-platform item not found.")
  end
end
