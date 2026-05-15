local I2C_PORT = 0
local SDA_PIN = 4
local SCL_PIN = 5
local I2C_FREQ = 100000

-- BH1750 default 7-bit address is 0x23, use 8-bit address here.
local BH1750_ADDR = 0x46

local function log(msg)
    lua_send_msg2http(tostring(msg) .. "\r\n")
end

local function u16be(msb, lsb)
    return (msb << 8) | lsb
end

local function send_cmd(cmd)
    return i2c_bus("send", I2C_PORT, BH1750_ADDR, string.char(cmd))
end

i2c_bus("init", I2C_PORT, SDA_PIN, SCL_PIN, I2C_FREQ)
lua_DELAY(2)

send_cmd(0x01) -- power on
lua_DELAY(2)
send_cmd(0x07) -- reset data register
lua_DELAY(2)
send_cmd(0x10) -- continuous high-res mode
lua_DELAY(180)

log("BH1750 demo started")

while true do
    local data = i2c_bus("receive", I2C_PORT, BH1750_ADDR, "", 2)
    if data and #data == 2 then
        local b1, b2 = data:byte(1, 2)
        local raw = u16be(b1, b2)
        local lux = raw / 1.2
        log(string.format("BH1750 lux: %.2f", lux))
    else
        log("BH1750 read failed")
    end
    lua_DELAY(1000)
end

