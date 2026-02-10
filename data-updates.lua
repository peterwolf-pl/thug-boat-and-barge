-- tagboat_towship/data-updates.lua

-- Space Age compatibility: sanitize known chimney prototypes in updates stage.
-- This runs after most data-stage prototype creation and before final validation.
local function deep_sanitize_lines_per_file(root, visited)
  if type(root) ~= "table" then return end
  visited = visited or {}
  if visited[root] then return end
  visited[root] = true

  if root.lines_per_file ~= nil then
    if root.line_length == nil then
      root.line_length = root.lines_per_file
    end
    root.lines_per_file = nil
  end

  for _, v in pairs(root) do
    if type(v) == "table" then
      deep_sanitize_lines_per_file(v, visited)
    end
  end
end

do
  local simple_entities = data and data.raw and data.raw["simple-entity"]
  if simple_entities then
    local chimney = simple_entities["vulcanus-chimney"]
    if chimney then
      deep_sanitize_lines_per_file(chimney)
    end
  end
end

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
