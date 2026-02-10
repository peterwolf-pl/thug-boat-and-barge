-- tagboat_towship/data-final-fixes.lua
-- Runs after all mods. Final hardening for Factorio 2.0 prototype validation.

local function deep_convert_lines_per_file(root, visited)
  if type(root) ~= "table" then return end
  visited = visited or {}
  if visited[root] then return end
  visited[root] = true

  -- Factorio 2.0 no longer accepts `lines_per_file`. Prefer converting to `line_length` then remove.
  if root.lines_per_file ~= nil then
    if root.line_length == nil then
      root.line_length = root.lines_per_file
    end
    root.lines_per_file = nil
  end

  for _, v in pairs(root) do
    if type(v) == "table" then
      deep_convert_lines_per_file(v, visited)
    end
  end
end

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

-- Convert the key everywhere (some graphics mods still inject it into many prototypes).
if data and data.raw then
  deep_convert_lines_per_file(data.raw)
  deep_strip_key(data.raw, "lines_per_file")
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

  -- One more pass for absolute certainty.
  deep_convert_lines_per_file(proto)
  if proto.animation then deep_convert_lines_per_file(proto.animation) end
  if proto.pictures then deep_convert_lines_per_file(proto.pictures) end
  if proto.turret_animation then deep_convert_lines_per_file(proto.turret_animation) end
  if proto.light_animation then deep_convert_lines_per_file(proto.light_animation) end
end

force_clean_tug_animation()
if data and data.raw then
  deep_strip_key(data.raw, "lines_per_file")
end
