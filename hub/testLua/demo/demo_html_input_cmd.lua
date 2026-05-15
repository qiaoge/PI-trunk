-- HTML input command demo.
-- Purpose:
-- 1) register a Lua device that appears in the HTML input dropdown
-- 2) register input hint shown by typing 'help' in HTML terminal
-- 3) receive input text from HTML and update device output

local BUS_NAME = "UART"
local DEV_NAME = "HTML_CMD_DEMO"
local POLL_MS = 100

local function log(msg)
    lua_send_msg2http("[" .. DEV_NAME .. "] " .. tostring(msg) .. "\r\n")
end

local function set_output(msg)
    lua_dev_ouput(tostring(msg))
end

local ok = lua_dev_init(BUS_NAME, DEV_NAME, "HTML input command demo")
if not ok then
    log("lua_dev_init failed")
    return
end

-- Hint shown when user types: help
local hint = "ping | status | echo <text> | led on | led off"
ok = lua_dev_input_register(hint, true)
if not ok then
    log("lua_dev_input_register failed")
else
    log("input registered")
end

set_output("ready: type help for command hint")

local last_input = ""

while true do
    local input = lua_dev_get_input()

    if type(input) == "string" and input ~= "" and input ~= last_input then
        last_input = input
        local cmd = string.lower(input)

        if cmd == "ping" then
            set_output("pong")
        elseif cmd == "status" then
            set_output("status: running")
        elseif cmd == "led on" then
            -- Replace with your real GPIO control if needed.
            set_output("led: on (demo)")
        elseif cmd == "led off" then
            -- Replace with your real GPIO control if needed.
            set_output("led: off (demo)")
        elseif string.sub(cmd, 1, 5) == "echo " then
            set_output(string.sub(input, 6))
        else
            set_output("unknown command: " .. input)
        end

        log("recv: " .. input)
    end

    lua_DELAY(POLL_MS)
end
