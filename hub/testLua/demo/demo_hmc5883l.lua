local I2C_PORT = 0
local SDA_PIN = 4
local SCL_PIN = 5
local I2C_FREQ = 100000

-- HMC5883L 7-bit address is 0x1E, use 8-bit address here.
local HMC5883L_ADDR = 0x3C

local function log(msg)
    lua_send_msg2http(tostring(msg) .. "\r\n")
end

local function s16(msb, lsb)
    local v = (msb << 8) | lsb
    if v >= 0x8000 then
        v = v - 0x10000
    end
    return v
end

local function write_reg(reg, val)
    return i2c_bus("send", I2C_PORT, HMC5883L_ADDR, string.char(reg, val))
end

i2c_bus("init", I2C_PORT, SDA_PIN, SCL_PIN, I2C_FREQ)
lua_DELAY(2)

write_reg(0x00, 0x70) -- 8-sample average, 15Hz
write_reg(0x01, 0x20) -- gain
write_reg(0x02, 0x00) -- continuous mode

log("HMC5883L demo started")

while true do
    local data = i2c_bus("receive", I2C_PORT, HMC5883L_ADDR, string.char(0x03), 6)
    if data and #data == 6 then
        local b = { data:byte(1, 6) }
        local x = s16(b[1], b[2])
        local z = s16(b[3], b[4])
        local y = s16(b[5], b[6])

        local heading = math.deg(math.atan(y, x))
        if heading < 0 then
            heading = heading + 360.0
        end

        log(string.format("HMC5883L X=%d Y=%d Z=%d HDG=%.1f", x, y, z, heading))
    else
        log("HMC5883L read failed")
    end
    lua_DELAY(500)
end

