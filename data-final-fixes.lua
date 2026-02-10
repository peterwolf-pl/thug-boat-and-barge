-- tagboat_towship/data-final-fixes.lua
-- Runs after all mods. Final hardening for Factorio 2.0 prototype validation.

local function deep_sanitize_lines_per_file(root, visited)
  if type(root) ~= "table" then return end
  visited = visited or {}
  if visited[root] then return end
  visited[root] = true

  -- Factorio 2.0 no longer accepts `lines_per_file`.
  -- Preserve intent by mapping to `line_length` when missing, then remove legacy key.
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

local function make_rotated_from_filenames(filenames)
  return {
    type = "rotated",
    direction_count = 256,
    filenames = filenames,
    slice = 1,
    width = 474,
    height = 458,
    shift = (util and util.by_pixel(0, -6)) or {0, -6/32},
    priority = "high"
  }
end

local function sanitize_space_age_chimneys()
  local simple_entities = data and data.raw and data.raw["simple-entity"]
  if not simple_entities then return end

  -- Space Age can define chimney layers with legacy `lines_per_file`.
  local chimney = simple_entities["vulcanus-chimney"]
  if chimney then
    deep_sanitize_lines_per_file(chimney)
  end

  -- Defensive: sanitize any vulcanus chimney variants, if present.
  for name, proto in pairs(simple_entities) do
    if type(name) == "string" and string.find(name, "vulcanus%-chimney", 1, false) then
      deep_sanitize_lines_per_file(proto)
    end
  end
end

local function force_clean_tug_animation()
  if not (data and data.raw and data.raw["car"] and data.raw["car"]["towship-tagboat"]) then return end
  local proto = data.raw["car"]["towship-tagboat"]

  -- Force a known-clean rotated animation at the very end, in case any mod patched legacy keys back in.
  local filenames = {}
  for i = 1, 256 do
    filenames[#filenames+1] = string.format("__tagboat_barge_graphics__/graphics/tugboat/%04d.png", i)
  end

  proto.animation = make_rotated_from_filenames(filenames)
  proto.pictures = nil

  -- One more pass for absolute certainty on this prototype.
  deep_sanitize_lines_per_file(proto)
end

sanitize_space_age_chimneys()
force_clean_tug_animation()

-- Final global pass after all local edits.
if data and data.raw then
  deep_sanitize_lines_per_file(data.raw)
end
