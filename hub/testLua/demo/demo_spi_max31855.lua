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

local function read32()
    cs_low()
    local d = spi_bus("sendrecive", SPI_PORT, string.char(0x00, 0x00, 0x00, 0x00), 4)
    cs_high()
    if not d or #d ~= 4 then
        return nil
    end
    local b1, b2, b3, b4 = d:byte(1, 4)
    return ((b1 << 24) | (b2 << 16) | (b3 << 8) | b4) & 0xFFFFFFFF
end

local function sign_extend(v, bits)
    local sign = 1 << (bits - 1)
    local mask = (1 << bits) - 1
    v = v & mask
    if (v & sign) ~= 0 then
        v = v - (1 << bits)
    end
    return v
end

spi_bus("init", SPI_PORT, 0, 0, SPI_FREQ, "MSB")
spi_bus("setpin", MOSI_PIN, MISO_PIN, SCK_PIN)
lua_GPIO_set(CS_PIN, 1)
cs_high()
lua_DELAY(50)

log("SPI MAX31855 demo started")

while true do
    local raw = read32()
    if raw then
        if (raw & 0x00010000) ~= 0 then
            local fault = raw & 0x7
            log(string.format("MAX31855 fault: 0x%X", fault))
        else
            local tc_raw = sign_extend((raw >> 18) & 0x3FFF, 14)
            local cj_raw = sign_extend((raw >> 4) & 0x0FFF, 12)
            local tc = tc_raw * 0.25
            local cj = cj_raw * 0.0625
            log(string.format("MAX31855 TC=%.2fC CJ=%.2fC", tc, cj))
        end
    else
        log("MAX31855 read failed")
    end
    lua_DELAY(1000)
end

