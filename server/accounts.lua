local exports = {}

local accounts = {}

local function save()
  local file = io.open("accountsdb", "w")
  io.output(file)
  io.write(textutils.serialize(accounts))
  io.close(file)
end

local function load()
  local file = io.open("accounts", "w")
  io.input(file)
  local lines = io.read()
  if not lines then 
    return
  end
  accounts = textutils.unserialize(lines)
  io.close(file)
end

function exports.create_account(client_id, username)
  if not client_id or not username or accounts[username] then
    return nil
  end

  local new_account = {
    client_id = client_id,
    username = username
  }
  accounts[username] = new_account
  save()
  return new_account
end

function exports.get_account(client_id, username)
  if exports.authenticate(client_id, username) then
    return accounts[username]
  end
  return nil
end

function exports.authenticate(client_id, username)
  return accounts[username] and accounts[username].client_id == client_id
end

function exports.main()
  local protocol = "mmorpg-accounts"
  local host_name = "main"

  if not rednet.isOpen("right") then
    rednet.open("right")
  end

  rednet.host(protocol, host_name)

  while true do
    local sender_id, msg, p = rednet.receive(protocol)
    if msg and msg["op"] then
      if msg.op == "create" then
        local account = exports.create_account(sender_id, msg.username)
        rednet.send(sender_id, account, protocol)
      elseif msg.op == "login" then
        local result = exports.get_account(sender_id, msg.username)
        rednet.send(sender_id, result, protocol)
      end
    end
  end
end

load()

return exports