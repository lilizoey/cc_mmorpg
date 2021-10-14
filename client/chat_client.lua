local Account = require("account")
local Chat = require("chat")

local current_chat = nil

local SCREEN_WIDTH = 50
local SCREEN_HEIGHT = 19

local function cls()
  print("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
end

local Menu = {}
local menu_meta = {_index = Menu}

function Menu.new()
  local menu = setmetatable({
    selection = 1
  }, menu_meta)

  return menu
end

function Menu:join()
  cls()
  print("Enter a username:")
  io.input(io.stdin)
  local username = io.read()
  local account = Account.connect(username)
  if not account then
    print("Error connecting to account")
    return true
  end

  local chat = Chat.connect(account)
  if not chat then
    print("Error joining chats")
    return true
  end

  current_chat = chat
  return true
end

function Menu:exit()
  return false
end

-- returns true if enter is hit
function Menu:await_input(choices)
  local event, key, is_held = os.pullEvent("key")
  if key == keys.up then
    self.selection = self.selection - 1
    self.selection = ((self.selection - 1) % #choices) + 1
  elseif key == keys.down then
    self.selection = self.selection + 1
    self.selection = ((self.selection - 1) % #choices) + 1
  elseif key == keys.enter then
    return true
  end
  return false
end

function Menu:display(choices)
  cls()
  for i,v in ipairs(choices) do
    if i == self.selection then
      term.setBackgroundColor(colors.white)
      term.setTextColor(colors.black)
    end
    print(v.description)
    if i == self.selection then
      term.setBackgroundColor(colors.black)
      term.setTextColor(colors.white)
    end
  end
end

function Menu:exec()
  local choices = {
    {description = "Join", fn = self.join},
    {description = "Exit", fn = self.exit}
  }

  local continue = true
  while continue do
    parallel.waitForAny(
      function () continue = not self:await_input(choices) end,
      function () self:display(choices) end
    )
  end

  return choices[self.selection].fn(self)
end

local ChatClient = {}
local chatclient_meta = {_index = ChatClient}

function ChatClient.new(chat)
  local chat_client = setmetatable({
    chat = chat,
    tab = 1,
    rooms = {},
    room_selection = 1,
    room_scroll = 1,
    chat_content = {},
    text_box = "",
    selected = false,
    held_keys = {},

    rooms_width = 10,
    chat_width = 50 - (10 + 3)
  }, chatclient_meta)

  return chat_client
end

function ChatClient:draw_box(x,y,w,h)
  term.setCursorPos(x,y)
  term.write("┌")
  for i = x+1, x+w-1, 1 do
    term.write("─")
  end
  term.write("┐")

  for i = y + 1, y+h - 1, 1 do
    term.setCursorPos(x,i)
    term.write("│")
    term.setCursorPos(x + w - 1,i)
    term.write("│")
  end

  term.setCursorPos(x,y+w-1)
  term.write("└")
  for i = x+1, x+w-1, 1 do
    term.write("─")
  end
  term.write("┘")
end

function ChatClient:draw_rooms()
  local rooms_to_display = {}
  if #self.rooms > SCREEN_HEIGHT - 2 then
    local rooms_start = math.min(self.room_scroll, #self.rooms - (SCREEN_HEIGHT - 2))
    for i = rooms_start, rooms_start + (SCREEN_HEIGHT - 2), 1 do
      table.insert(rooms_to_display, self.rooms[i])
    end
  else
    rooms_to_display = self.rooms
  end

  term.setCursorPos(2,2)

  for i, v in ipairs(rooms_to_display) do
    local display_str = string.sub(v .. "          ", self.rooms_width)
    if i == self.selection then
      term.setBackgroundColor(colors.white)
      term.setTextColor(colors.black)
    end
    term.write(display_str)
    if i == self.selection then
      term.setBackgroundColor(colors.black)
      term.setTextColor(colors.white)
    end
    term.write(display_str)
    term.setCursorPos(2,1 + i)
  end
end

function self:draw_chat()
  local x = self.rooms_width + 3
  local y = SCREEN_HEIGHT - (3 + math.min(#self.chat, SCREEN_HEIGHT - 3))

  for i,v in ipairs(self.chat) do
    term.setCursorPos(x, y + i - 1)
    local message = "[" .. v.username .. "]: " .. v.message
    message = string.sub(message, 1, self.chat_width)
    term.write(message)
  end

  term.setCursorPos(x, SCREEN_HEIGHT - 2)
  term.write("")
  term.setCursorPos(x, SCREEN_HEIGHT - 1)
  term.write(string.sub(self.text_box, 1, self.chat_width))
end

function ChatClient:display()
  if self.tab == 1 then
    self:draw_box(1,1,self.rooms_width + 2, SCREEN_HEIGHT)
  elseif self.tab == 2 then
    self:draw_box(self.rooms_width + 2, 1, self.chat_width + 2, SCREEN_HEIGHT)
  end

  self:draw_rooms()
  self:draw_chat()
end

ChatClient.keymap = {}
ChatClient.keymap[keys.one] = "1"
ChatClient.keymap[keys.two] = "2"
ChatClient.keymap[keys.three] = "3"
ChatClient.keymap[keys.four] = "4"
ChatClient.keymap[keys.five] = "5"
ChatClient.keymap[keys.six] = "6"
ChatClient.keymap[keys.seven] = "7"
ChatClient.keymap[keys.eight] = "8"
ChatClient.keymap[keys.nine] = "9"
ChatClient.keymap[keys.zero] = "0"
ChatClient.keymap[keys.space] = " "


function ChatClient:parse_text_key(key)
  if key == keys.backspace then
    self.text_box = string.sub(self.text_box, 1, string.len(self.text_box) - 1)
  elseif string.len(keys.getName(key)) == 1 then
    keys.rig
    if self.held_keys[keys.leftShift] or self.held_keys[keys.rightShift] then
      self.text_box = self.text_box .. string.upper(keys.getName(key))
    else
      self.text_box = self.text_box .. keys.getName(key)
    end
  elseif self.keymap[key] then
    self.text_box = self.text_box .. self.keymap[key]
  end
end

function ChatClient:handle_input()
  local event, key, is_held = os.pullEvent("key")
  if key == keys.tab then
    self.tab = (self.tab % 2) + 1
  else
    if self.tab == 1 then
      if key == keys.up then
        if self.selection > 1 then
          self.selection = self.selection - 1
        elseif self.room_scroll  > 1 then
          self.room_scroll = self.room_scroll - 1
        end
      elseif key == keys.down then
        if self.selection < SCREEN_HEIGHT - 2 and self.selection < #self.rooms then
          self.selection = self.selection + 1
        elseif (self.room_scroll + (SCREEN_HEIGHT - 2)) < #self.rooms then
          self.room_scroll = self.room_scroll + 1
        end
      elseif key == keys.enter then
        self.selected = true
      end
    elseif self.tab == 2 then
      self:parse_text_key(key)
    end
  end

  if is_held then
    self.held_keys[key] = true
  end
end

function ChatClient:handle_key_up()
  while true do
    local event, key = os.pullEvent("key_up")
    self.held_keys[key] = nil
  end
end

function ChatClient:exec()
  parallel.waitForAny(
    function () self:handle_key_up() end,
    function () self:handle_input() end,
    function () self:display() end,
  )
end

local function main()
  local continue = true
  while continue do
    if current_chat then
      local client = ChatClient.new(current_chat)
      client:exec()
    else
      local menu = Menu.new()
      continue = menu:exec()
    end
  end
end

main()