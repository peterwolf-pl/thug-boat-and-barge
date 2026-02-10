-- tagboat_towship/data.lua
local function deepcopy(x) return table.deepcopy(x) end

-- Keybinds:
data:extend({
  { type = "custom-input", name = "tagboat-attach-barge", key_sequence = "J", consuming = "none" },
  { type = "custom-input", name = "tagboat-detach-barge", key_sequence = "K", consuming = "none" }
})

local empty_sprite = {
  filename = "__core__/graphics/empty.png",
  priority = "extra-high",
  width = 1,
  height = 1,
 -- frame_count = 1,
  direction_count = 1
}

-- Defensive: Factorio 2.0 removed/doesn't accept "lines_per_file" in sprite definitions.
-- Some upstream prototypes (or graphics mods) may still contain it; strip it everywhere.
local function deep_strip_key(root, key, visited)
  if type(root) ~= "table" then return end
  visited = visited or {}
  if visited[root] then return end
  visited[root] = true
  root[key] = nil
  for _, v in pairs(root) do
    if type(v) == "table" then
      deep_strip_key(v, key, visited)
    end
  end
end

-- Space Age compatibility: sanitize known prototype that can still carry legacy sprite keys.
do
  local chimney = data.raw["simple-entity"] and data.raw["simple-entity"]["vulcanus-chimney"]
  if chimney then
    deep_strip_key(chimney, "lines_per_file")
    if chimney.pictures then
      deep_strip_key(chimney.pictures, "lines_per_file")
    end
  end
end



-- Barge animation using 256 prerendered frames (8 directions x 32 frames)
local function make_barge_animation()
  local filenames = {}
  for i = 1, 256 do
    filenames[#filenames+1] = string.format("__tagboat_barge_graphics__/graphics/barge/%04d.png", i)
  end

  return {
    type = "rotated",
    direction_count = 256,
    -- frame_count = 1,
    -- animation_speed = 1,
    filenames = filenames,
    slice = 1,
    width = 474,
    height = 458,
    shift = util and util.by_pixel(0, -6) or {0, -6/32},
    -- Keep vanilla car defaults where possible
    priority = "high"
  }
end
-- 1) Towship-tagboat = clone of cargo-ships "indep-boat" (car)
do
  local base = data.raw["car"] and data.raw["car"]["indep-boat"]
  local base_item = (data.raw["item-with-entity-data"] and data.raw["item-with-entity-data"]["boat"])
                 or (data.raw["item"] and data.raw["item"]["boat"])
  local base_recipe = data.raw["recipe"] and data.raw["recipe"]["boat"]

  if base and base_item and base_recipe then
    local tug = deepcopy(base)
    tug.name = "towship-tagboat"
    tug.flags = tug.flags or {}
    table.insert(tug.flags, "get-by-unit-number")
    tug.minable = tug.minable or {}
    tug.minable.result = "towship-tagboat"
    tug.allow_passengers = true
    -- Custom tugboat graphics are provided by separate graphics mod (same scheme as barge)
    -- Expected files: __tagboat_barge_graphics__/graphics/tugboat/0001.png .. 0256.png
    -- Tugboat animation using 256 prerendered frames (8 directions x 32 frames)
    local function make_tug_animation()
      local filenames = {}
      for i = 1, 256 do
        filenames[#filenames+1] = string.format("__tagboat_barge_graphics__/graphics/tugboat/%04d.png", i)
      end

      return {
        type = "rotated",
        direction_count = 256,
        filenames = filenames,
        slice = 1,
        width = 474,
        height = 458,
        shift = util and util.by_pixel(0, -6) or {0, -6/32},
        priority = "high"
      }
    end

    -- Use our own rotated animation to avoid legacy sprite fields (e.g. "lines_per_file")
    tug.animation = make_tug_animation()
    tug.pictures = nil
    tug.turret_animation = tug.turret_animation or empty_sprite
    deep_strip_key(tug, "lines_per_file")


    -- Slightly tug-ish handling
    tug.weight = (tug.weight or 1000) * 1.20
    tug.friction_force = (tug.friction_force or 0.01) * 1.10
    tug.braking_force = (tug.braking_force or 0.1) * 1.10

    data:extend({ tug })

    -- Item: clone boat item but place our tug
    local item = deepcopy(base_item)
    item.name = "towship-tagboat"
    item.place_result = "towship-tagboat"
    item.order = (item.order or "a") .. "-tagboat"
    item.stack_size = item.stack_size or 5
    data:extend({ item })

    -- Recipe: clone boat recipe but output our tug (Factorio 2.0 uses results)
    local recipe = deepcopy(base_recipe)
    recipe.name = "towship-tagboat"
    recipe.enabled = false
    recipe.result = nil
    recipe.result_count = nil
    recipe.results = { { type = "item", name = "towship-tagboat", amount = 1 } }
    data:extend({ recipe })
  else
    log("[tagboat_towship] Missing prototypes from cargo-ships: car.indep-boat and item/recipe boat.")
  end
end

-- 2) Wooden platform -> floating barge entity (car) that paints wooden-platform tiles under itself
do
  local base = data.raw["car"] and data.raw["car"]["indep-boat"]
  local wp_item = data.raw["item"] and data.raw["item"]["wooden-platform"]
  local wp_recipe = data.raw["recipe"] and data.raw["recipe"]["wooden-platform"]

  if base and wp_item and wp_recipe then
    local barge = deepcopy(base)
    barge.name = "wooden-platform-barge"
    barge.flags = barge.flags or {}
    table.insert(barge.flags, "get-by-unit-number")
    barge.minable = barge.minable or {}
    barge.minable.result = "wooden-platform"
    barge.allow_passengers = false

    -- Make it feel like a heavy barge
    barge.weight = (barge.weight or 1000) * 3.0
    barge.friction_force = (barge.friction_force or 0.01) * 0.45
    barge.braking_force = (barge.braking_force or 0.1) * 0.45
    barge.max_speed = math.min(barge.max_speed or 0.2, 0.10)

    -- Hide the boat graphics; we will show the platform via tiles.
    barge.animation = make_barge_animation()
    barge.turret_animation = empty_sprite
    barge.working_sound = nil
    deep_strip_key(barge, "lines_per_file")
    -- Barge should NOT require fuel / energy
    barge.burner = nil
    barge.consumption = "0kW"
    barge.effectivity = 0

    data:extend({ barge })
  else
    log("[tagboat_towship] Missing prototypes: car.indep-boat (cargo-ships) and item/recipe wooden-platform (wooden_platform).")
  end
end
-- 3) Hidden tow wire anchors (electric-pole) to render a real copper wire between tug and barge
do
  local base = data.raw["electric-pole"] and data.raw["electric-pole"]["small-electric-pole"]
  if base then
    local anchor = deepcopy(base)
    anchor.name = "tow-wire-anchor"
    anchor.icon = base.icon
    anchor.icon_size = base.icon_size
    anchor.icon_mipmaps = base.icon_mipmaps

    anchor.flags = anchor.flags or {}
    -- keep base flags, add safety / hidden behavior
    table.insert(anchor.flags, "placeable-off-grid")
    table.insert(anchor.flags, "not-on-map")
    table.insert(anchor.flags, "not-blueprintable")
    table.insert(anchor.flags, "not-deconstructable")
    table.insert(anchor.flags, "not-selectable-in-game")

    anchor.minable = nil
    anchor.destructible = false

    anchor.collision_box = {{-0.05, -0.05}, {0.05, 0.05}}
    anchor.selection_box = {{-0.05, -0.05}, {0.05, 0.05}}
    anchor.collision_mask = { layers = {} }

    -- no power distribution; only for wire rendering
    anchor.maximum_wire_distance = 32
    anchor.supply_area_distance = 0
    -- Keep base pictures/connection points counts intact (Factorio 2.0 requires them to match).
    -- Make the pole effectively invisible by shrinking & tinting its sprites.
    if anchor.pictures then
      local function _shrink(pic)
        if type(pic) ~= "table" then return end
        if pic.layers then
          for _, layer in pairs(pic.layers) do _shrink(layer) end
        else
          pic.scale = (pic.scale or 1) * 0.01
          pic.tint = {1, 1, 1, 0}
        end
      end
      _shrink(anchor.pictures)
    end
    anchor.radius_visualisation_picture = empty_sprite

    -- avoid interactions / upgrades
    anchor.fast_replaceable_group = nil
    anchor.next_upgrade = nil
    anchor.working_sound = nil

    data:extend({ anchor })
  else
    log("[tagboat_towship] small-electric-pole prototype not found; tow wire will fall back to rendering line.")
  end
end


-- Custom input for safe disembark (runtime handler in control.lua)
if not (data.raw["custom-input"] and data.raw["custom-input"]["tagboat-disembark"]) then
  data:extend({
    {
      type = "custom-input",
      name = "tagboat-disembark",
      key_sequence = "L",
      consuming = "game-only",
      order = "z[tagboat]-a[disembark]"
    }
  })
end



if not (data.raw["custom-input"] and data.raw["custom-input"]["tagboat-embark"]) then
  data:extend({
    {
      type = "custom-input",
      name = "tagboat-embark",
      key_sequence = "K",
      consuming = "game-only",
      order = "z[tagboat]-b[embark]"
    }
  })
end
