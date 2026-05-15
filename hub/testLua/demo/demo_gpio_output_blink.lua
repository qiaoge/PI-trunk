-- GPIO output demo: blink one LED pin.
-- Change OUTPUT_PIN to your board pin.

local OUTPUT_PIN = 0
local PERIOD_MS = 500

local function log(msg)
    lua_send_msg2http(tostring(msg) .. "\r\n")
end

local ok = lua_GPIO_set(OUTPUT_PIN, 1)
if not ok then
    log("GPIO set failed, pin=" .. OUTPUT_PIN)
    return
end

log("GPIO output blink demo started, pin=" .. OUTPUT_PIN)

while true do
    lua_GPIO_write(OUTPUT_PIN, 1)
    lua_DELAY(PERIOD_MS)
    lua_GPIO_write(OUTPUT_PIN, 0)
    lua_DELAY(PERIOD_MS)
end
