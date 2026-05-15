local I2C_PORT = 0
local SDA_PIN = 4
local SCL_PIN = 5
local I2C_FREQ = 400000

-- MPU6050 default 7-bit address is 0x68, use 8-bit address here.
local MPU6050_ADDR = 0xD0

local function log(msg)
    lua_send_msg2http(tostring(msg) .. "\r\n")
end

local function write_reg(reg, val)
    return i2c_bus("send", I2C_PORT, MPU6050_ADDR, string.char(reg, val))
end

local function read_regs(reg, len)
    return i2c_bus("receive", I2C_PORT, MPU6050_ADDR, string.char(reg), len)
end

local function s16(msb, lsb)
    local v = (msb << 8) | lsb
    if v >= 0x8000 then
        v = v - 0x10000
    end
    return v
end

i2c_bus("init", I2C_PORT, SDA_PIN, SCL_PIN, I2C_FREQ)
lua_DELAY(10)

write_reg(0x6B, 0x00) -- wake up
lua_DELAY(5)
write_reg(0x1A, 0x03) -- DLPF
write_reg(0x19, 0x07) -- sample rate divider
write_reg(0x1B, 0x00) -- gyro +/-250 dps
write_reg(0x1C, 0x00) -- accel +/-2g

local who = read_regs(0x75, 1)
if who and #who == 1 then
    log(string.format("MPU6050 WHO_AM_I: 0x%02X", who:byte(1)))
end
log("MPU6050 demo started")

while true do
    local data = read_regs(0x3B, 14)
    if data and #data == 14 then
        local b = { data:byte(1, 14) }
        local ax = s16(b[1], b[2])
        local ay = s16(b[3], b[4])
        local az = s16(b[5], b[6])
        local temp_raw = s16(b[7], b[8])
        local gx = s16(b[9], b[10])
        local gy = s16(b[11], b[12])
        local gz = s16(b[13], b[14])

        local ax_g = ax / 16384.0
        local ay_g = ay / 16384.0
        local az_g = az / 16384.0
        local temp_c = temp_raw / 340.0 + 36.53
        local gx_dps = gx / 131.0
        local gy_dps = gy / 131.0
        local gz_dps = gz / 131.0

        log(string.format("MPU6050 ACC[g] %.3f %.3f %.3f", ax_g, ay_g, az_g))
        log(string.format("MPU6050 GYR[dps] %.2f %.2f %.2f", gx_dps, gy_dps, gz_dps))
        log(string.format("MPU6050 TEMP %.2fC", temp_c))
    else
        log("MPU6050 read failed")
    end

    lua_DELAY(500)
end

