# GPIO Lua 驱动使用说明

本文说明当前固件中 `lua_gpio_fun.c` 暴露给 `.lua` 脚本的 GPIO API。

## 1. API 列表

### 1.1 `lua_GPIO_set(pin, dir)`
- 功能: 初始化 GPIO 并设置方向。
- 参数:
  - `pin`: GPIO 编号
  - `dir`: 方向，`1=输出`，`0=输入`
- 返回:
  - `true` 成功，`false` 失败

### 1.2 `lua_GPIO_write(pin, state)`
- 功能: 输出引脚写电平。
- 参数:
  - `pin`: GPIO 编号
  - `state`: `1=高电平`，`0=低电平`
- 返回:
  - `true`

### 1.3 `lua_GPIO_read(pin)`
- 功能: 读取引脚电平。
- 参数:
  - `pin`: GPIO 编号
- 返回:
  - `true`(高电平) / `false`(低电平)

### 1.4 `lua_GPIO_init_irq(pin, event_mask, callback)`
- 功能: 初始化 GPIO 中断并注册回调。
- 参数:
  - `pin`: GPIO 编号
  - `event_mask`: 中断类型掩码，可按位相加
    - `1`: `LEVEL_LOW`
    - `2`: `LEVEL_HIGH`
    - `4`: `EDGE_FALL`
    - `8`: `EDGE_RISE`
  - `callback`: 回调函数，签名 `function(pin, events)`
- 返回:
  - `true` 成功，`false` 失败

### 1.5 `lua_GPIO_deinit_irq(pin)`
- 功能: 关闭 GPIO 中断并解绑回调。
- 参数:
  - `pin`: GPIO 编号
- 返回:
  - `true` 成功，`false` 失败

### 1.6 `lua_GPIO_deinit(pin)`
- 功能: 反初始化 GPIO。
- 参数:
  - `pin`: GPIO 编号
- 返回:
  - `true`

### 1.7 `lua_DELAY(ms)`
- 功能: 任务延时（毫秒）。
- 参数:
  - `ms`: 延时毫秒

### 1.8 `lua_TICK()`
- 功能: 获取系统 tick 计数。
- 返回:
  - 当前 tick

## 2. 推荐使用流程

### 输出
1. `lua_GPIO_set(pin, 1)`
2. 循环 `lua_GPIO_write(pin, 1/0)` + `lua_DELAY(ms)`

### 输入轮询
1. `lua_GPIO_set(pin, 0)`
2. 周期性 `lua_GPIO_read(pin)`

### 输入中断
1. `lua_GPIO_set(pin, 0)`
2. `lua_GPIO_init_irq(pin, EDGE_FALL + EDGE_RISE, callback)`
3. 主循环里保留 `lua_DELAY(...)`，让脚本持续运行
4. 结束前调用 `lua_GPIO_deinit_irq(pin)`

## 3. Demo 文件

`testLua/demo/` 下新增了以下示例:
- `demo_gpio_output_blink.lua`: GPIO 输出闪灯
- `demo_gpio_input_poll.lua`: GPIO 输入轮询
- `demo_gpio_irq.lua`: GPIO 边沿中断回调

## 4. 注意事项

- 本目录 demo 的 `log()` 已统一使用 `lua_send_msg2http`，日志会显示在 HTTP 页面。
- 脚本里延时函数名是 `lua_DELAY`（大写），不是 `lua_delay`。
- 中断回调建议只做轻量逻辑，耗时处理放到主循环。
- 若输入脚没有外部上下拉，请根据硬件设计补上电阻网络。
