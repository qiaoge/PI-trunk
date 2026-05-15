local HMC5883L_ADDR = 0x3C
local I2C_PORT = 1
local SDA_PIN = 2
local SCL_PIN = 3
local I2C_FREQ = 100000

local function log(msg)
    lua_send_msg2http(tostring(msg) .. "\r\n")
end

i2c_bus("init", I2C_PORT, SDA_PIN, SCL_PIN, I2C_FREQ)

-- Config registers:
-- Reg 0x00: 8-average, 15 Hz, normal measurement
-- Reg 0x01: gain configuration
-- Reg 0x02: continuous measurement mode
i2c_bus("send", I2C_PORT, HMC5883L_ADDR, string.char(0x00, 0x70))
i2c_bus("send", I2C_PORT, HMC5883L_ADDR, string.char(0x01, 0x20))
i2c_bus("send", I2C_PORT, HMC5883L_ADDR, string.char(0x02, 0x00))

while true do
    local reg = string.char(0x03)
    local data = i2c_bus("receive", I2C_PORT, HMC5883L_ADDR, reg, 6)

    if data ~= nil and #data == 6 then
        local out = ""
        for i = 1, #data do
            out = out .. string.format("%02X ", string.byte(data, i))
        end
        log(out)
    else
        log("no data")
    end

    lua_DELAY(3000)
end
