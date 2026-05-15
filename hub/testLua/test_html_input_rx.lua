local BUS = "UART"
local DEV = "HTML_INPUT_TEST"
local DESC = "Lua HTML input receive test"
local HINT = "velocity %f(m/s)"

local function log(msg)
    lua_send_msg2http("[HTML-RX] " .. tostring(msg) .. "\r\n")
end

if not lua_dev_init(BUS, DEV, DESC) then
    log("lua_dev_init failed")
    return
end

if lua_dev_input_register then
    local ok = lua_dev_input_register(HINT, true)
    if ok then
        log("input channel registered: " .. HINT)
    else
        log("input channel register failed")
    end
else
    log("lua_dev_input_register not found")
end

log("ready")

while true do
    local cmd = lua_dev_get_input(200)
    if cmd ~= nil then
        cmd = tostring(cmd)
        log("recv: " .. cmd)

        if cmd == "quit" then
            log("exit by quit")
            break
        elseif cmd == "ping" then
            log("pong")
        elseif cmd == "help" then
            log("hint: " .. HINT)
        else
            local v = string.match(cmd, "^velocity%s+([%+%-]?%d+%.?%d*)$")
            if v then
                log("velocity set to " .. v .. " m/s")
            else
                log("unknown cmd: " .. cmd)
            end
        end

        lua_dev_ouput("last_cmd=" .. cmd)
    end

    lua_DELAY(20)
end
