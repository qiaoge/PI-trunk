Lua sensor demos for current lua_fun drivers
============================================

All demos in this folder use the current I2C Lua API:
  i2c_bus("init", i2c_port, sda_pin, scl_pin, freq_hz)
  i2c_bus("send", i2c_port, addr_8bit, data_string)
  i2c_bus("receive", i2c_port, addr_8bit, reg_string, read_len)

Important:
1) Use 8-bit I2C address in Lua script.
   The C driver shifts address right by 1 internally.
2) Update pin config in each script before running:
   I2C_PORT / SDA_PIN / SCL_PIN / I2C_FREQ

Demo list:
- demo_bh1750.lua   : Ambient light (lux)
- demo_aht20.lua    : Temperature + humidity
- demo_sht30.lua    : Temperature + humidity (with CRC check)
- demo_mpu6050.lua  : Acc + gyro + internal temperature
- demo_bmp280.lua   : Temperature + pressure
- demo_hmc5883l.lua : 3-axis magnetometer + heading

SPI notes
---------
SPI Lua API for current driver:
  spi_bus("init", spi_port, cpol, cpha, freq_hz, "MSB")
  spi_bus("setpin", mosi_pin, miso_pin, sck_pin)
  spi_bus("send", spi_port, data_string_or_byte)
  spi_bus("recive", spi_port, rx_len)           -- keep spelling "recive"
  spi_bus("sendrecive", spi_port, tx_string, rx_len)

SPI CS pin is controlled by GPIO in Lua:
  lua_GPIO_set(cs_pin, 1)
  lua_GPIO_write(cs_pin, 0)  -- CS low
  lua_GPIO_write(cs_pin, 1)  -- CS high

SPI demo list:
- demo_spi_mpu6500.lua : IMU raw data, compatible with MPU6500/MPU9250 class
- demo_spi_adxl345.lua : 3-axis acceleration (g)
- demo_spi_bmp280.lua  : Temperature + pressure
- demo_spi_max31855.lua: Thermocouple + cold-junction temperature

GPIO demos
----------
GPIO Lua API for current driver:
  lua_GPIO_set(pin, dir)                    -- dir: 1 output, 0 input
  lua_GPIO_write(pin, level)                -- level: 1 high, 0 low
  lua_GPIO_read(pin)                        -- returns true/false
  lua_GPIO_init_irq(pin, mask, callback)    -- callback(pin, events)
  lua_GPIO_deinit_irq(pin)

GPIO event mask bits:
  1 = level low
  2 = level high
  4 = edge fall
  8 = edge rise

GPIO demo list:
- demo_gpio_output_blink.lua : Output blink
- demo_gpio_input_poll.lua   : Input polling
- demo_gpio_irq.lua          : Input interrupt callback

See README_GPIO.md for full Chinese guide.
