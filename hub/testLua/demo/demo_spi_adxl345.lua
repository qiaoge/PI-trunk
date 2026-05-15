local SPI_PORT = 0
local MOSI_PIN = 3
local MISO_PIN = 4
local SCK_PIN = 2
local CS_PIN = 5
local SPI_FREQ = 2000000

local function log(msg)
    lua_send_msg2http(tostring(msg) .. "\r\n")
end

local function s16(le_lsb, le_msb)
    local v = (le_msb << 8) | le_lsb
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

local function spi_read(reg, len, multi)
    local cmd = (reg | 0x80) & 0xFF
    if multi then
        cmd = (cmd | 0x40) & 0xFF
    end
    cs_low()
    local rx = spi_bus("sendrecive", SPI_PORT, string.char(cmd), len + 1)
    cs_high()
    if not rx or #rx ~= (len + 1) then
        return nil
    end
    return rx:sub(2)
end

local function spi_write(reg, val)
    cs_low()
    spi_bus("send", SPI_PORT, string.char(reg & 0x3F, val))
    cs_high()
end

-- ADXL345 uses SPI mode 3
spi_bus("init", SPI_PORT, 1, 1, SPI_FREQ, "MSB")
spi_bus("setpin", MOSI_PIN, MISO_PIN, SCK_PIN)
lua_GPIO_set(CS_PIN, 1)
cs_high()
lua_DELAY(10)

local devid = spi_read(0x00, 1, false)
if devid and #devid == 1 then
    log(string.format("ADXL345 DEVID: 0x%02X", devid:byte(1)))
end

spi_write(0x2D, 0x00) -- standby
spi_write(0x31, 0x08) -- full resolution, +-2g
spi_write(0x2C, 0x0A) -- output data rate 100Hz
spi_write(0x2D, 0x08) -- measurement mode

log("SPI ADXL345 demo started")

while true do
    local d = spi_read(0x32, 6, true)
    if d and #d == 6 then
        local b = { d:byte(1, 6) }
        local x = s16(b[1], b[2])
        local y = s16(b[3], b[4])
        local z = s16(b[5], b[6])

        -- full-resolution mode scale is ~3.9mg/LSB
        local xg = x * 0.0039
        local yg = y * 0.0039
        local zg = z * 0.0039
        log(string.format("ADXL345 X=%.3fg Y=%.3fg Z=%.3fg", xg, yg, zg))
    else
        log("ADXL345 read failed")
    end
    lua_DELAY(300)
end

