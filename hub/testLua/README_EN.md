# RP2350 Lua Firmware User Guide (UF2 + Lua Release)

This guide is for end users of the public release package:

- prebuilt firmware `.uf2`
- Lua scripts (`.lua`)
- `config.txt`

No C toolchain is required for normal use.

For full API details, see:
- `../src/lua_fun/README.md`

## 1. Quick Start

1. Flash firmware:
- Copy the provided `.uf2` to the RP2350 USB boot drive.

2. Copy Lua files:
- Put your `.lua` scripts and `config.txt` on the firmware storage area (same place where scripts are currently stored by this project).

3. Configure auto-run:
- Edit `config.txt` to list each script task.

4. Start or restart Lua tasks:
- Reboot device, or trigger Lua restart from the web UI (if enabled in your firmware build).

## 2. `config.txt` Format

Each Lua task uses 3 lines in this order:

```txt
Path = /your_script.lua
TaskSize = 4096
Priority = -1
```

Example with two tasks:

```txt
Path = /demo_gpio_output_blink.lua
TaskSize = 4096
Priority = -1

Path = /demo_bh1750.lua
TaskSize = 4096
Priority = -1
```

Notes:
- `Path` should include the leading `/`.
- Keep one `Path` + `TaskSize` + `Priority` group per script.
- If formatting is broken, task creation may fail silently.

## 3. Logging And Debug Output

Use this in scripts:

```lua
local function log(msg)
    lua_send_msg2http(tostring(msg) .. "\r\n")
end
```

This prints to the firmware web output channel.

## 4. API Summary

- GPIO: `lua_GPIO_set`, `lua_GPIO_write`, `lua_GPIO_read`, IRQ APIs
- Delay/Tick: `lua_DELAY`, `lua_TICK`
- I2C: `i2c_bus("init"/"send"/"receive"/...)`
- SPI: `spi_bus("init"/"send"/"recive"/"sendrecive"/...)`
- UART: `uart_bus("init"/"send"/"receive")`
- PWM: `pwm_cmd("init"/"set_pwm"/"deinit")`
- Queue/Web output: `lua_receive_msg`, `lua_send_msg2http`

Important compatibility details:
- SPI keyword is `"recive"` (current firmware spelling).
- I2C address in Lua is 8-bit form; firmware shifts right by 1 internally.
- SPI chip-select must be controlled manually via GPIO.

## 5. Demo Scripts

Ready-to-run demos are in:

- `demo/demo_gpio_output_blink.lua`
- `demo/demo_gpio_input_poll.lua`
- `demo/demo_gpio_irq.lua`
- `demo/demo_bh1750.lua`
- `demo/demo_aht20.lua`
- `demo/demo_sht30.lua`
- `demo/demo_mpu6050.lua`
- `demo/demo_bmp280.lua`
- `demo/demo_hmc5883l.lua`
- `demo/demo_spi_mpu6500.lua`
- `demo/demo_spi_adxl345.lua`
- `demo/demo_spi_bmp280.lua`
- `demo/demo_spi_max31855.lua`

## 6. Recommended Public Repository Layout

When releasing closed-source firmware + open Lua scripts:

```txt
release/
  firmware/
    rp2350_mcus_hub.uf2
  lua/
    config.txt
    demo_gpio_output_blink.lua
    demo_bh1750.lua
    ...
  docs/
    LUA_API.md
    QUICK_START.md
```

This makes updates clear:
- firmware changes: replace UF2
- behavior changes: update Lua scripts
- user guidance: update docs only

