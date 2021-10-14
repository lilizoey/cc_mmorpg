local protocol = "mmorpg-accounts"
local server_host_name = "main"

local Account = {}
local metatable = {_index = Account}

function Account.connect(username)
  local account = setmetatable({
    username = username,
    server_id = rednet.lookup(protocol, server_host_name)
  }, metatable)

  rednet.send(account.server_id, {op = "login", username = account.username}, protocol)

  local response = nil
  repeat
    local sender_id, msg = rednet.receive(protocol)
    response = msg
  until sender_id == account.server_id

  if not response then
    rednet.send(account.server_id, {op = "create", username = account.username}, protocol)
    local response = nil

    repeat
      local sender_id, msg = rednet.receive(protocol)
      response = msg
    until sender_id == account.server_id

    if not response then
      return nil
    end
  end

  return account
end

function Account:get_username()
  return self.username
end

return Account