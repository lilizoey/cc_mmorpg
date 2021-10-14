local protocol = "mmorpg-chat"
local server_host_name = "main"

local Chat = {}
local metatable = {_index = Chat}

function Chat.connect(account)
  local chat = setmetatable({
    account = account,
    server_id = rednet.lookup(protocol, server_host_name)
  }, metatable)

  return chat
end

function Chat:create_room(room_name)
  rednet.send(self.server_id, {op = "create", name = room_name}, protocol)
end

function Chat:join_room(room_name)
  rednet.send(self.server_id, {
    op = "join",
    username = self.account:get_username(),
    room_name = room_name
  }, protocol)

  local response = nil
  repeat
    local sender_id, msg = rednet.receive(protocol)
    response = msg
  until sender_id == self.server_id

  return response
end

function Chat:leave_room(room_name)
  rednet.send(self.server_id, {
    op = "leave",
    username = self.account:get_username(),
    room_name = room_name
  }, protocol)

  local response = nil
  repeat
    local sender_id, msg = rednet.receive(protocol)
    response = msg
  until sender_id == self.server_id

  return response
end

function Chat:send(room_name, message)
  rednet.send(self.server_id, {
    op = "send",
    username = self.account:get_username(),
    room_name = room_name,
    message = message
  }, protocol)
end

function Chat:wait_for_message()
  local message = nil
  repeat
    local sender_id, msg = rednet.receive(protocol)
    message = msg
  until sender_id == self.server_id and message and message["op"] and message.op == "chat_msg"

  return message
end

function Chat:get_rooms()
  rednet.send(self.server_id, {op = "list"}, protocol)

  local response = nil
  repeat
    local sender_id, msg = rednet.receive(protocol)
    response = msg
  until sender_id == self.server_id

  return response
end

return Chat