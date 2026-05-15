local seq = 0

while true do
    seq = seq + 1

    local tick = 0
    if lua_TICK then
        tick = lua_TICK()
    end

    local msg = string.format("MLVDS_CMD_DATA_SEND test seq=%d tick=%d", seq, tick)
    local ok, err = lua_send_msg(msg, 20)

    if not ok then
        lua_send_msg2http("mlvds send fail: " .. tostring(err))
    else
        lua_send_msg2http("mlvds send ok: " .. msg)
    end

    lua_DELAY(2000)
end
