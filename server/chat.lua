local exports = {}

local protocol = "mmorpg-chat"
local host_name = "main"

if not rednet.isOpen("right") then
  rednet.open("right")
end
rednet.host(protocol, host_name)

local rooms = {}

local function create_room(creator, name)
  if rooms[name] then
    return
  end

  rooms[name] = {
    creator = creator,
    users = {}
  }
  log(1, "user with id" .. rooms[name].creator .. "created room with name " .. name)
end

local function join_room(client_id, username, room_name)
  if not accounts.authenticate(client_id, username) then
    return false
  end

  if not rooms[room_name] then
    return false
  end

  rooms[room_name].users[username] = {client_id = client_id, username = username, join_time = os.clock()}

  log(1, "user " .. username .. " joined the room " .. room_name)

  return true
end

local function leave_room(client_id, username, room_name)
  if not accounts.authenticate(client_id, username) then
    return
  end

  if not rooms[room_name] then
    return
  end

  rooms[room_name].users[username] = nil

  log(1, "user " .. username .. " left the room " .. room_name)
end

local function send_message(client_id, username, room_name, message)
  if not accounts.authenticate(client_id, username) then
    return
  end

  if not rooms[room_name] then
    return
  end

  for k, user in pairs(rooms[room_name].users) do
    rednet.send(user.client_id, {op = "chat_msg", username = username, message = message}, protocol)
    log(0, "sending message to " .. user.username)
  end

  log(1, username .. " sent a message to room " .. room_name)
end

local function main()
  while true do
    local sender_id, msg, p = rednet.receive(protocol)

    if msg and msg["op"] then
      log(1, "received msg with opcode: \"" .. msg.op .. "\"")
      if msg.op == "create" then
        create_room(sender_id, msg.name)
      elseif msg.op == "join" then
        local result = join_room(sender_id, msg.username, msg.room_name)
        rednet.send(sender_id, result, protocol)
      elseif msg.op == "leave" then
        leave_room(sender_id, msg.username, msg.room_name)
      elseif msg.op == "send" then
        send_message(sender_id, msg.username, msg.room_name, msg.message)
      elseif msg.op == "list" then
      elseif msg.op == "list_in" then
      end

    end
  end
end

local function timeout_handler()
  while true do
    os.sleep(60)
    for k, room in pairs(rooms) do
      local to_remove = {}
      for k, user in pairs(room.users) do
        if user and (os.clock() - user.join_time) > 60 * 5 then
          table.insert(to_remove, k)
        end
      end

      for i,v in ipairs(to_remove) do
        room.users[v] = nil
      end
    end
  end
end

exports.coroutines = {main}

return exports