uart_bus("init", 0, 0, 1, 115200)

while true do
    local read_back = uart_bus("receive", 0, 1)
    if read_back ~= nil and read_back ~= "" then
        lua_send_msg2http(read_back)
        lua_DELAY(2)
    end
    lua_DELAY(10)
end
