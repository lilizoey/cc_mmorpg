local protocol = "mmorpg"
local server_host_name = "main"

rednet.open("right")

local server_id = rednet.lookup(protocol, server_host_name)

local players = {}

local current_character = nil

local function get_number(min, max)
  print("Choose a number [" .. min .. "-" .. max .. "]")
  io.input(io.stdin)
  local number = tonumber(io.read())
  if number and number >= min and number <= max then
    return number
  else
    return nil
  end

end

local function present_options(options)
  print("What do you want to do?")
  for i,v in ipairs(options) do
    print(i .. ". " .. v.description)
  end

  local number = get_number(1, #options)
  if not number then
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

local function choose_character()
  print("Choose a character: ")
  for i,v in ipairs(players) do
    print(i .. ": " .. v.name)
  end

  local number = get_number(1, #players)
  if not number then
    return nil
  end

  current_character = players[number]
end

local function move_character()
  print("Move where?")
  io.input(io.stdin)
  local new_location = io.read()
  if not new_location then
    print("Error, no location gotten")
    return nil
  end

  rednet.send(server_id, {op = "move_player", player_id = current_character.id, new_location = new_location}, protocol)
end

while true do
  local choice = nil
  if current_character then
    print("Current character: " .. current_character.name)
    choice = present_options({
      {description = "Create a character", fn = create_character},
      {description = "Choose a character", fn = choose_character},
      {description = "Move character", fn = move_character}
    })
  else
    choice = present_options({
      {description = "Create a character", fn = create_character},
      {description = "Choose a character", fn = choose_character}
    })
  end


  if choice then
    choice.fn()
  end
end