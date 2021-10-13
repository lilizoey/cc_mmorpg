local protocol = "mmorpg"
local server_host_name = "main"

rednet.open("right")

local server_id = rednet.lookup(protocol, server_host_name)

local players = {}

local function present_options(options)
  print("What do you want to do? [1-" .. #options .. "]")
  for i,v in ipairs(options) do
    print(i .. ". " .. v.description)
  end

  io.input(io.stdin)
  local number = tonumber(io.read())
  if not number or not options[number] then
    return nil
  end

  return options[number]
end

local function create_character()
  print("Enter a name for the character: ")
  io.input(io.stdin)
  local name = io.read()
  if not name then
    print("Error, no name gotten")
    return nil
  end

  rednet.send(server_id, {op = "create_player", name = name}, protocol)
  local new_player_id = #players + 1
  repeat
    local sender_id, player, p = rednet.receive(protocol)
    players[new_player_id] = player
  until sender_id == sender_id
end

while true do
  local choice = present_options({
    {description = "Create a character", fn = create_character}
  })

  if choice then
    choice.fn()
  end
end