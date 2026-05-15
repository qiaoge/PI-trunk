lua_GPIO_set(1, 1)
while true do
    local command = 1
    if command == 2 then
        break
    end
    lua_GPIO_write(1, 1)
    lua_DELAY(1000)
    lua_GPIO_write(1, 0)
    lua_DELAY(1000)
    lua_send_msg2http("lua_22")
end
