local SPI_PORT = 0
local MOSI_PIN = 3
local MISO_PIN = 4
local SCK_PIN = 2
local CS_PIN = 5
local SPI_FREQ = 1000000

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

local function cs_low()
    lua_GPIO_write(CS_PIN, 0)
end

local function cs_high()
    lua_GPIO_write(CS_PIN, 1)
end

local function spi_read(reg, len)
    local tx = string.char((reg | 0x80) & 0xFF)
    cs_low()
    local rx = spi_bus("sendrecive", SPI_PORT, tx, len + 1)
    cs_high()
    if not rx or #rx ~= (len + 1) then
        return nil
    end
    return rx:sub(2)
end

local function spi_write(reg, val)
    cs_low()
    spi_bus("send", SPI_PORT, string.char(reg & 0x7F, val))
    cs_high()
end

spi_bus("init", SPI_PORT, 0, 0, SPI_FREQ, "MSB")
spi_bus("setpin", MOSI_PIN, MISO_PIN, SCK_PIN)
lua_GPIO_set(CS_PIN, 1)
cs_high()
lua_DELAY(10)

spi_write(0x6B, 0x00) -- PWR_MGMT_1: wake up
lua_DELAY(5)
spi_write(0x1A, 0x03) -- CONFIG
spi_write(0x1B, 0x00) -- GYRO_CONFIG
spi_write(0x1C, 0x00) -- ACCEL_CONFIG

local who = spi_read(0x75, 1)
if who and #who == 1 then
    log(string.format("SPI MPU WHO_AM_I: 0x%02X", who:byte(1)))
end
log("SPI MPU6500/9250 demo started")

while true do
    local data = spi_read(0x3B, 14)
    if data and #data == 14 then
        local b = { data:byte(1, 14) }
        local ax = s16(b[1], b[2]) / 16384.0
        local ay = s16(b[3], b[4]) / 16384.0
        local az = s16(b[5], b[6]) / 16384.0
        local temp = s16(b[7], b[8]) / 340.0 + 36.53
        local gx = s16(b[9], b[10]) / 131.0
        local gy = s16(b[11], b[12]) / 131.0
        local gz = s16(b[13], b[14]) / 131.0

        log(string.format("MPU ACC[g] %.3f %.3f %.3f", ax, ay, az))
        log(string.format("MPU GYR[dps] %.2f %.2f %.2f", gx, gy, gz))
        log(string.format("MPU TEMP %.2fC", temp))
    else
        log("MPU read failed")
    end
    lua_DELAY(500)
end

