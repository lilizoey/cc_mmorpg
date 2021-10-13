local accounts_protocol = "mmorpg-accounts"
local chat_protocol = "mmorpg-chat"
local server_host_name = "main"

if not rednet.isOpen("right") then
  rednet.open("right")
end
local account_server_ip = rednet.lookup(accounts_protocol, server_host_name)
local chat_server_ip = rednet.lookup(chat_protocol, server_host_name)

local current_account = nil

local current_room = nil

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


local function create_account()
  print("Enter a username")
  io.input(io.stdin)
  local username = io.read()

  rednet.send(account_server_ip, {op = "create", username = username}, accounts_protocol)
  local account = rednet.receive(accounts_protocol)
  if not account then
    print("Username already taken or not valid")
  else
    current_account = account
  end
end

local function log_in()
  print("Enter a username")
  io.input(io.stdin)
  local username = io.read()

  rednet.send(account_server_ip, {op = "login", username = username}, accounts_protocol)
  local account = nil

  repeat
    local sender_id, msg = rednet.receive(accounts_protocol)
    account = msg
  until sender_id == account_server_ip

  if not account then
    print("Cannot log in as " .. username)
  else
    current_account = account
  end
end

local state = "menu"
local text_box = ""
local chat = {}
local chat_limit = 8

local function update_chat()
  while true do
    local sender_id, msg, p = rednet.receive(chat_protocol)
    if sender_id == sender_id and msg and msg["op"] then
      if msg.op == "chat_msg" then
        table.insert(chat, msg)
        if #chat > chat_limit then
          table.remove(chat, 1)
        end
      end
    end
  end
end

local function send_message(text)
  rednet.send(chat_server_ip, {op = "send", username = current_account.username, room_name = current_room, message = text}, chat_protocol)
end

local function chat_keys()
  while true do
    local event, key, is_held = os.pullEvent("key")
    if key == keys.backspace then
      text_box = string.sub(text_box, 1, string.len(text_box) - 1)
    elseif key == keys.enter then
      send_message(text_box)
      text_box = ""
    elseif key == keys.home then
      state = "menu"
      return
    elseif string.len(keys.getName(key)) == 1 then
      text_box = text_box .. keys.getName(key)
    end
  end
end

local function cls()
  print("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
end

local function display_chat()
  while true do
    cls()
    for k,v in pairs(chat) do
      print("[" .. v.username .. "]: " .. v.message)
    end
    print("-------------------")
    print(text_box)
    os.sleep(1)
  end
end

local function leave_room()
  if current_room then
    rednet.send(chat_server_ip, {username = current_account.username, room_name = current_room}, chat_protocol)
  end
end

local function join_room()
  if current_room then
    leave_room()
  end

  print("Enter a room name")
  io.input(io.stdin)
  local room_name = io.read()

  rednet.send(chat_server_ip, {op = "join", username = current_account.username, room_name = room_name}, chat_protocol)
  local result = nil
  repeat
    local sender_id, msg, p = rednet.receive(chat_protocol)
    result = msg
  until sender_id == chat_server_ip

  if result then
    state = "chat"
  else
    print("Error joining room " .. room_name)
  end
end

local function create_room()
  print("Enter a room name")
  io.input(io.stdin)
  local room_name = io.read()

  rednet.send(chat_server_ip, {op = "create", name = room_name}, chat_protocol)
end

local function log_out()
  current_account = nil
end

local function menu()
  leave_room()

  local choice = present_options({
    {description = "Create room", fn = create_room},
    {description = "Join room", fn = join_room},
    {description = "Log out", fn = log_out},
  })

  choice.fn()
end

local function main()
  while true do
    if not current_account then
      local choice = present_options({
        {description = "Create account", fn = create_account},
        {description = "Log in", fn = log_in},
      })

      choice.fn()
    else
      while current_account do
        if state == "chat" then
          parallel.waitForAny(chat_keys, update_chat, display_chat)
        else
          menu()
        end
      end
    end
  end
end

main()