local SPI_PORT = 0
local MOSI_PIN = 3
local MISO_PIN = 4
local SCK_PIN = 2
local CS_PIN = 5
local SPI_FREQ = 2000000

local function log(msg)
    lua_send_msg2http(tostring(msg) .. "\r\n")
end

local function cs_low()
    lua_GPIO_write(CS_PIN, 0)
end

local function cs_high()
    lua_GPIO_write(CS_PIN, 1)
end

local function spi_read(reg, len)
    cs_low()
    local rx = spi_bus("sendrecive", SPI_PORT, string.char((reg | 0x80) & 0xFF), len + 1)
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

local function u16le(lo, hi)
    return (hi << 8) | lo
end

local function s16le(lo, hi)
    local v = u16le(lo, hi)
    if v >= 0x8000 then
        v = v - 0x10000
    end
    return v
end

local dig_T1, dig_T2, dig_T3
local dig_P1, dig_P2, dig_P3, dig_P4, dig_P5, dig_P6, dig_P7, dig_P8, dig_P9
local t_fine = 0.0

local function load_calibration()
    local c = spi_read(0x88, 24)
    if not c or #c ~= 24 then
        return false
    end
    local b = { c:byte(1, 24) }
    dig_T1 = u16le(b[1], b[2])
    dig_T2 = s16le(b[3], b[4])
    dig_T3 = s16le(b[5], b[6])
    dig_P1 = u16le(b[7], b[8])
    dig_P2 = s16le(b[9], b[10])
    dig_P3 = s16le(b[11], b[12])
    dig_P4 = s16le(b[13], b[14])
    dig_P5 = s16le(b[15], b[16])
    dig_P6 = s16le(b[17], b[18])
    dig_P7 = s16le(b[19], b[20])
    dig_P8 = s16le(b[21], b[22])
    dig_P9 = s16le(b[23], b[24])
    return true
end

local function compensate_temp(adc_t)
    local var1 = (adc_t / 16384.0 - dig_T1 / 1024.0) * dig_T2
    local var2 = ((adc_t / 131072.0 - dig_T1 / 8192.0) ^ 2) * dig_T3
    t_fine = var1 + var2
    return t_fine / 5120.0
end

local function compensate_press(adc_p)
    local var1 = t_fine / 2.0 - 64000.0
    local var2 = var1 * var1 * dig_P6 / 32768.0
    var2 = var2 + var1 * dig_P5 * 2.0
    var2 = var2 / 4.0 + dig_P4 * 65536.0
    var1 = (dig_P3 * var1 * var1 / 524288.0 + dig_P2 * var1) / 524288.0
    var1 = (1.0 + var1 / 32768.0) * dig_P1
    if var1 == 0 then
        return nil
    end
    local p = 1048576.0 - adc_p
    p = (p - var2 / 4096.0) * 6250.0 / var1
    var1 = dig_P9 * p * p / 2147483648.0
    var2 = p * dig_P8 / 32768.0
    p = p + (var1 + var2 + dig_P7) / 16.0
    return p / 100.0
end

spi_bus("init", SPI_PORT, 0, 0, SPI_FREQ, "MSB")
spi_bus("setpin", MOSI_PIN, MISO_PIN, SCK_PIN)
lua_GPIO_set(CS_PIN, 1)
cs_high()
lua_DELAY(10)

local chip = spi_read(0xD0, 1)
if chip and #chip == 1 then
    log(string.format("SPI BMP280 CHIP_ID: 0x%02X", chip:byte(1)))
end

spi_write(0xE0, 0xB6)
lua_DELAY(10)

if not load_calibration() then
    log("BMP280 calibration read failed")
    while true do
        lua_DELAY(2000)
    end
end

spi_write(0xF4, 0x27)
spi_write(0xF5, 0xA0)
log("SPI BMP280 demo started")

while true do
    local d = spi_read(0xF7, 6)
    if d and #d == 6 then
        local b1, b2, b3, b4, b5, b6 = d:byte(1, 6)
        local adc_p = (b1 << 12) | (b2 << 4) | (b3 >> 4)
        local adc_t = (b4 << 12) | (b5 << 4) | (b6 >> 4)

        local t = compensate_temp(adc_t)
        local p = compensate_press(adc_p)
        if p then
            log(string.format("BMP280 T=%.2fC P=%.2f hPa", t, p))
        else
            log("BMP280 pressure compensation failed")
        end
    else
        log("BMP280 read failed")
    end
    lua_DELAY(1000)
end

