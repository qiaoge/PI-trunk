# Lua Interface Reference (`src/lua_fun`)

This document describes the Lua APIs implemented in the `src/lua_fun` folder.
It is intended for public releases where C source is private, and users only get:

- a firmware `.uf2` file
- Lua scripts (`.lua`)
- script config (`config.txt`)

The API signatures below match the current firmware source.

## 1. Runtime Modules Exposed To Lua

In the default firmware runtime (`vLuaTask`), these modules are registered:

- GPIO: `lua_GPIO_*`, `lua_DELAY`, `lua_TICK`, `invoke_callback`
- Queue/HTTP output: `lua_receive_msg`, `lua_send_msg2http`
- PWM: `pwm_cmd(...)`
- I2C: `i2c_bus(...)`
- SPI: `spi_bus(...)`
- UART: `uart_bus(...)`

Note:
- `lua_cdc_write` and `lua_cdc_read` exist in `lua_cdc_fun.c`, but `luaopen_cdc(L)` is not called in the default runtime path. They are available only if your firmware explicitly registers them.

## 2. General Data Rules

- Binary buffers are exchanged as Lua strings.
- Use `string.char(...)` to build bytes.
- Use `string.byte(...)` to parse bytes.
- Most APIs return `true`/`false` for success.
- Read APIs usually return a Lua string, or `nil` when no data / allocation failed.

## 3. GPIO API (`lua_gpio_fun.c`)

### `lua_GPIO_set(pin, dir)`
- `pin`: GPIO number
- `dir`: `1` output, `0` input
- return: `true`

### `lua_GPIO_write(pin, level)`
- `level`: non-zero = high, `0` = low
- return: `true`

### `lua_GPIO_read(pin)`
- return: `true` (high) or `false` (low)

### `lua_GPIO_deinit(pin)`
- return: `true`

### `lua_GPIO_init_irq(pin, mask, callback)`
- `mask` bit field: `1` level low, `2` level high, `4` edge fall, `8` edge rise
- `callback` signature: `function(pin, events)`
- return: `true` on success, `false` on invalid mask or allocation failure

### `lua_GPIO_deinit_irq(pin)`
- return: `true` on success, `false` if no IRQ callback was bound

### `invoke_callback()`
- Processes pending GPIO IRQ callbacks immediately.
- return: number of callbacks invoked

### `lua_DELAY(ms)`
- FreeRTOS delay in milliseconds.

### `lua_TICK()`
- return: current FreeRTOS tick count

## 4. I2C API (`lua_i2c_fun.c`)

Single entry:

`i2c_bus(command, ...)`

### `i2c_bus("init", i2c_port, sda_pin, scl_pin, freq_hz)`
- `i2c_port`: `0` or `1`
- `freq_hz`: if `0`, firmware uses `1000000` (1 MHz)
- return: `true`

### `i2c_bus("deinit", i2c_port, sda_pin, scl_pin)`
- return: `true`

### `i2c_bus("setpin", sda_pin, scl_pin)`
- Sets pins to I2C function and enables pull-ups.
- return: `true`

### `i2c_bus("send", i2c_port, addr_8bit, data_string)`
- `addr_8bit` must be 8-bit address form (for example `0xD0` for BMP280).
- Driver shifts right by 1 internally.
- return: SDK write result (typically number of bytes written, or negative error code)

### `i2c_bus("receive", i2c_port, addr_8bit, reg_string, read_len)`
- Writes `reg_string` first, then reads `read_len` bytes.
- `reg_string` can be empty string `""`.
- return: read data as Lua string (length `read_len`), `""` if `read_len == 0`, or `nil` on allocation failure

## 5. SPI API (`lua_spi_fun.c`)

Single entry:

`spi_bus(command, ...)`

### `spi_bus("init", spi_port, cpol, cpha, freq_hz, bit_order)`
- `spi_port`: `0` or `1`
- `cpol`: `0` or `1`
- `cpha`: `0` or `1`
- `freq_hz`: if omitted uses 1 MHz; if set to `0`, returns `false`
- `bit_order`: `"MSB"` (default) or `"LSB"`
- return: `true`/`false`

### `spi_bus("deinit", spi_port)`
- return: `true`

### `spi_bus("setpin", mosi_pin, miso_pin, sck_pin)`
- return: `true`

### `spi_bus("send", spi_port, tx)`
- `tx` can be Lua string or number (single byte)
- return: `true`/`false`

### `spi_bus("recive", spi_port, rx_len)`
- Keep spelling as `"recive"` (current firmware keyword).
- return: Lua string, `""` when `rx_len == 0`, or `nil` on allocation failure

### `spi_bus("sendrecive", spi_port, tx_string, rx_len)`
- Full-duplex transfer.
- If `#tx_string < rx_len`, firmware pads with `0xFF`.
- return: received bytes as Lua string, `""` when `rx_len == 0`, or `nil` on allocation failure

## 6. UART API (`lua_uart_fun.c`)

Single entry:

`uart_bus(command, ...)`

### `uart_bus("init", uart_port, tx_pin, rx_pin, baud)`
- `uart_port`: `0` or `1`
- `baud` must be non-zero
- return: `true`/`false`

### `uart_bus("send", uart_port, tx)`
- `tx` can be Lua string or number (single byte)
- return: `true`/`false`

### `uart_bus("receive", uart_port, len)`
- Blocking read of exactly `len` bytes.
- return: Lua string, `""` when `len == 0`, or `nil` on allocation failure

## 7. PWM API (`lua_pwm_fun.c`)

Single entry:

`pwm_cmd(command, ...)`

### `pwm_cmd("init", chan, pin, wrap)`
- `chan`: `0` for channel A, non-zero for channel B
- `wrap`: PWM top value
- return: `true`

### `pwm_cmd("set_pwm", chan, pin, level)`
- Sets duty level for selected channel.
- return: `true`

### `pwm_cmd("deinit", chan, pin)`
- Disables the PWM slice for this pin.
- return: `true`

## 8. Queue And HTTP Output API (`lua_queue_fun.c`)

### `lua_receive_msg()`
- Non-blocking (short timeout) receive from Lua task message queue.
- return: message string or `nil`

### `lua_send_msg2http(text)`
- Sends text to web output channel.
- return: `true`

Recommended logging helper:

```lua
local function log(msg)
    lua_send_msg2http(tostring(msg) .. "\r\n")
end
```

## 9. Optional CDC API (`lua_cdc_fun.c`)

Only available if firmware registers `luaopen_cdc(L)`.

### `lua_cdc_write(text)`
- return: `true` if USB CDC host is connected, else `false`

### `lua_cdc_read()`
- return: received string, or `nil` if no data

## 10. Common Pitfalls

- Use exact command words from firmware: `"recive"` and `"sendrecive"` in SPI, `"set_pwm"` in PWM.
- I2C expects 8-bit address in Lua; driver shifts right internally.
- SPI CS is not automatic. Control CS with GPIO in Lua.
- `uart_bus("receive", ...)` is blocking; run in loops with care.
- Keep IRQ callback logic short; do heavy work in the main loop.
