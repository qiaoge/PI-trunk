local I2C_PORT = 0
local SDA_PIN = 4
local SCL_PIN = 5
local I2C_FREQ = 100000

-- SHT30 default 7-bit address is 0x44, use 8-bit address here.
local SHT30_ADDR = 0x88

local function log(msg)
    lua_send_msg2http(tostring(msg) .. "\r\n")
end

local function crc8_sht30(b1, b2)
    local crc = 0xFF
    local function step(byte)
        crc = crc ~ byte
        for _ = 1, 8 do
            if (crc & 0x80) ~= 0 then
                crc = ((crc << 1) ~ 0x31) & 0xFF
            else
                crc = (crc << 1) & 0xFF
            end
        end
    end

    step(b1)
    step(b2)
    return crc
end

i2c_bus("init", I2C_PORT, SDA_PIN, SCL_PIN, I2C_FREQ)
lua_DELAY(2)
log("SHT30 demo started")

while true do
    -- single shot, high repeatability, clock stretching disabled
    i2c_bus("send", I2C_PORT, SHT30_ADDR, string.char(0x24, 0x00))
    lua_DELAY(20)

    local data = i2c_bus("receive", I2C_PORT, SHT30_ADDR, "", 6)
    if data and #data == 6 then
        local t_msb, t_lsb, t_crc, h_msb, h_lsb, h_crc = data:byte(1, 6)
        local ok_t = crc8_sht30(t_msb, t_lsb) == t_crc
        local ok_h = crc8_sht30(h_msb, h_lsb) == h_crc

        if ok_t and ok_h then
            local raw_t = (t_msb << 8) | t_lsb
            local raw_h = (h_msb << 8) | h_lsb
            local temperature = -45.0 + 175.0 * raw_t / 65535.0
            local humidity = 100.0 * raw_h / 65535.0
            log(string.format("SHT30 T=%.2fC RH=%.2f%%", temperature, humidity))
        else
            log("SHT30 CRC check failed")
        end
    else
        log("SHT30 read failed")
    end

    lua_DELAY(1000)
end

