local devIn =  dev_input
lua_dev_init("UART","UART_TEST","UART_TEST",devIn);
while true do
    local command = 1
    if command == 2 then
        break
    end
    lua_DELAY(3000)
    lua_send_msg2http("dev test\r\n")
end

