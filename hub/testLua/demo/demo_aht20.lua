local I2C_PORT = 0
local SDA_PIN = 4
local SCL_PIN = 5
local I2C_FREQ = 100000

-- AHT20 7-bit address is 0x38, use 8-bit address here.
local AHT20_ADDR = 0x70

local function log(msg)
    lua_send_msg2http(tostring(msg) .. "\r\n")
end

local function aht20_send(b1, b2, b3)
    return i2c_bus("send", I2C_PORT, AHT20_ADDR, string.char(b1, b2, b3))
end

local function aht20_read_status()
    local data = i2c_bus("receive", I2C_PORT, AHT20_ADDR, "", 1)
    if data and #data == 1 then
        return data:byte(1)
    end
    return nil
end

i2c_bus("init", I2C_PORT, SDA_PIN, SCL_PIN, I2C_FREQ)
lua_DELAY(5)

i2c_bus("send", I2C_PORT, AHT20_ADDR, string.char(0xBA)) -- soft reset
lua_DELAY(20)
aht20_send(0xBE, 0x08, 0x00) -- initialize
lua_DELAY(20)

local st = aht20_read_status()
if st then
    log(string.format("AHT20 status: 0x%02X", st))
end
log("AHT20 demo started")

while true do
    aht20_send(0xAC, 0x33, 0x00) -- trigger measurement
    lua_DELAY(90)

    local data = i2c_bus("receive", I2C_PORT, AHT20_ADDR, "", 6)
    if data and #data == 6 then
        local b1, b2, b3, b4, b5, b6 = data:byte(1, 6)
        if (b1 & 0x80) ~= 0 then
            log("AHT20 busy")
        else
            local raw_h = (b2 << 12) | (b3 << 4) | (b4 >> 4)
            local raw_t = ((b4 & 0x0F) << 16) | (b5 << 8) | b6
            local humidity = raw_h * 100.0 / 1048576.0
            local temperature = raw_t * 200.0 / 1048576.0 - 50.0
            log(string.format("AHT20 T=%.2fC RH=%.2f%%", temperature, humidity))
        end
    else
        log("AHT20 read failed")
    end

    lua_DELAY(1000)
end

