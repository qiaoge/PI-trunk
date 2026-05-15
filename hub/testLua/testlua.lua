
while true do
    local command = 1
    if command == 2 then
        break
    end
    lua_DELAY(3000)
    lua_send_msg2http("dev test\r\n")
end

