-- GPIO input polling demo.
-- Change INPUT_PIN to your board pin.

local INPUT_PIN = 2
local POLL_MS = 100

local function log(msg)
    lua_send_msg2http(tostring(msg) .. "\r\n")
end

local ok = lua_GPIO_set(INPUT_PIN, 0)
if not ok then
    log("GPIO set failed, pin=" .. INPUT_PIN)
    return
end

log("GPIO input polling demo started, pin=" .. INPUT_PIN)

local last = lua_GPIO_read(INPUT_PIN)
log("initial state=" .. tostring(last and 1 or 0))

while true do
    local now = lua_GPIO_read(INPUT_PIN)
    if now ~= last then
        last = now
        log("pin " .. INPUT_PIN .. " changed to " .. (now and "1" or "0"))
    end
    lua_DELAY(POLL_MS)
end
