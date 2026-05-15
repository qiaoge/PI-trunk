-- GPIO interrupt demo (edge trigger).
-- Change INPUT_PIN to your board pin.

local INPUT_PIN = 2
local LOOP_DELAY_MS = 100
local RUN_TIME_MS = 0 -- 0 means run forever

-- Event mask bits from C:
-- level low  = 1
-- level high = 2
-- edge fall  = 4
-- edge rise  = 8
local GPIO_IRQ_LEVEL_LOW = 1
local GPIO_IRQ_LEVEL_HIGH = 2
local GPIO_IRQ_EDGE_FALL = 4
local GPIO_IRQ_EDGE_RISE = 8

local function log(msg)
    lua_send_msg2http(tostring(msg) .. "\r\n")
end

local function decode_events(events)
    local parts = {}
    if (events & GPIO_IRQ_LEVEL_LOW) ~= 0 then
        parts[#parts + 1] = "LEVEL_LOW"
    end
    if (events & GPIO_IRQ_LEVEL_HIGH) ~= 0 then
        parts[#parts + 1] = "LEVEL_HIGH"
    end
    if (events & GPIO_IRQ_EDGE_FALL) ~= 0 then
        parts[#parts + 1] = "EDGE_FALL"
    end
    if (events & GPIO_IRQ_EDGE_RISE) ~= 0 then
        parts[#parts + 1] = "EDGE_RISE"
    end
    if #parts == 0 then
        return "NONE"
    end
    return table.concat(parts, "|")
end

local function gpio_irq_cb(pin, events)
    log(string.format("IRQ pin=%d events=0x%X (%s)", pin, events, decode_events(events)))
end

local ok = lua_GPIO_set(INPUT_PIN, 0)
if not ok then
    log("GPIO set failed, pin=" .. INPUT_PIN)
    return
end

local mask = GPIO_IRQ_EDGE_FALL + GPIO_IRQ_EDGE_RISE
ok = lua_GPIO_init_irq(INPUT_PIN, mask, gpio_irq_cb)
if not ok then
    log("GPIO init irq failed, pin=" .. INPUT_PIN)
    return
end

log("GPIO irq demo started, pin=" .. INPUT_PIN .. ", mask=EDGE_FALL|EDGE_RISE")

local elapsed_ms = 0
while true do
    lua_DELAY(LOOP_DELAY_MS)
    elapsed_ms = elapsed_ms + LOOP_DELAY_MS
    if RUN_TIME_MS > 0 then
        if elapsed_ms >= RUN_TIME_MS then
            break
        end
    end
end

lua_GPIO_deinit_irq(INPUT_PIN)
log("GPIO irq demo stopped")
