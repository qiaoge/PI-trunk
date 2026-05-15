lua_GPIO_set(0, 1)
while true do
    local command = 1
    if command == 2 then
        break
    end
    lua_GPIO_write(0, 1)
    lua_DELAY(1000)
    lua_GPIO_write(0, 0)
    lua_DELAY(1000)
    lua_send_msg2http("test gpio\r\n")
end

