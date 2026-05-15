local DEVICE_ADDR = 0xA0
local PAGE_SIZE = 32
local I2C_PORT = 0
local SDA_PIN = 4
local SCL_PIN = 5
local I2C_FREQ = 100000

local function log(msg)
    lua_send_msg2http(tostring(msg) .. "\r\n")
end

local function page_write(start_addr, data_table)
    if #data_table > PAGE_SIZE then
        return false, "page write too large: " .. #data_table
    end

    local page_start = math.floor(start_addr / PAGE_SIZE) * PAGE_SIZE
    if start_addr + #data_table - 1 > page_start + PAGE_SIZE - 1 then
        return false, "page write crosses page boundary"
    end

    local addr_high = start_addr // 256
    local addr_low = start_addr % 256
    local data_to_send = string.char(addr_high, addr_low)

    for _, byte in ipairs(data_table) do
        data_to_send = data_to_send .. string.char(byte)
    end

    local send_result = i2c_bus("send", I2C_PORT, DEVICE_ADDR, data_to_send)
    log(string.format("send result %d", send_result))

    lua_DELAY(5)
    return true, "page write successful"
end

local function sequential_read(start_addr, num_bytes)
    local addr_high = start_addr // 256
    local addr_low = start_addr % 256
    local addr_ptr = string.char(addr_high, addr_low)
    return i2c_bus("receive", I2C_PORT, DEVICE_ADDR, addr_ptr, num_bytes)
end

i2c_bus("init", I2C_PORT, SDA_PIN, SCL_PIN, I2C_FREQ)
lua_DELAY(1)

local test_data = {0x01, 0x02, 0x03, 0x04, 0x05}
local ok, err = page_write(0x200, test_data)
lua_DELAY(1)

if ok then
    local read_back = sequential_read(0x200, 5)
    if not read_back or read_back == "" then
        log("no data received")
    else
        local hex = ""
        for i = 1, #read_back do
            local byte_value = string.byte(read_back, i)
            hex = hex .. string.format("%02X ", byte_value)
        end
        log(hex)
    end
else
    log("write failed: " .. tostring(err))
end

lua_DELAY(500)
i2c_bus("deinit", I2C_PORT, SDA_PIN, SCL_PIN)
lua_DELAY(1000)
