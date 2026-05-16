# RP2350 MCU Hub User Guide (Without Lua API)

Version: 0.1  
Date: 2026-05-15  
Applicable firmware: `rp2350_mcus_hub`

## 1. Document Scope

This document is intended for firmware usage, delivery, testing, and field maintenance. It describes RP2350 MCU Hub flashing, USB connection, Web management, the device tree, the MLVDS bus, file upload, and troubleshooting.

This document does not cover the Lua scripting language, Lua driver functions, or Lua example script syntax. For those topics, use the separate Lua user guide.

The typical delivery package includes:

- `rp2350_mcus_hub.uf2`: main firmware
- `flash_nuke.uf2`: Flash erase/recovery tool, located in `FlashRecover/`
- This user guide
- A separate Lua user guide and example files, if needed

## 2. System Overview

After startup, the RP2350 MCU Hub firmware enumerates as a USB composite device and provides the following capabilities:

- USB virtual network adapter: the host creates a local network link to the device over USB.
- Web management page: open the device page in a browser to view the device tree, output logs, memory status, and send input to devices.
- USB mass storage: the device exposes a small FAT file area for configuration files, web files, and script/data files.
- USB CDC serial port: you can access the device tree through text commands or use it as a host-side communication channel.
- MLVDS host bus: automatically discovers MLVDS slave devices, assigns IDs, maintains heartbeats, exchanges data, and uploads files.
- Device tree: provides a unified view of the name, description, input, output, and refresh time for UART, SPI, I2C, MLVDS, and other device nodes.
- HTTP file upload: upload `.uf2`, `.lua`, and `.txt` files to a specified MLVDS slave through the Web page or HTTP POST.

## 3. Hardware and Connections

### 3.1 MCU and Clock

- Main controller board: Pico 2 / RP2350
- Firmware CPU frequency: 200 MHz
- USB: connected to a PC or upper-level controller as a USB device

### 3.2 MLVDS Pins

By default, MLVDS uses the following GPIO pins:

| Signal | GPIO |
| --- | --- |
| D | GPIO0 |
| DE | GPIO1 |
| R | GPIO2 |
| RE | GPIO3 |

The default MLVDS rate is configured at the 2.5 MBps level. Actual cabling, transceivers, power supply, and termination resistors must match the hardware design requirements.

## 4. Firmware Flashing

### 4.1 Normal Flashing

1. Press and hold the `BOOTSEL` button on the RP2350 board.
2. Connect the board to the PC through USB.
3. After the RP2350 UF2 boot drive appears on the PC, release `BOOTSEL`.
4. Copy `rp2350_mcus_hub.uf2` to the UF2 boot drive.
5. After copying finishes, the device reboots automatically and runs the new firmware.

### 4.2 Flash Recovery

If the device file area is corrupted, the firmware cannot boot normally, or Flash must be erased:

1. Enter `BOOTSEL` mode.
2. Copy `FlashRecover/flash_nuke.uf2` to the UF2 boot drive.
3. Wait for the device to reboot and erase Flash.
4. Enter `BOOTSEL` mode again.
5. Copy `rp2350_mcus_hub.uf2` again.

## 5. USB Enumeration and Network Access

### 5.1 USB Composite Device

The firmware enumerates the following USB functions:

- NCM virtual network adapter
- CDC serial port
- MSC mass storage

The current USB string descriptors use the default TinyUSB names. The system may display names such as `TinyUSB Device`, `TinyUSB Network Interface`, `TinyUSB CDC`, `TinyUSB MSC`, or similar variants.

### 5.2 IP Address

Fixed device-side network settings:

- Device IP: `192.168.7.1`
- Subnet mask: `255.255.255.0`
- DNS name: `hub.usb`

The device includes a built-in DHCP service and assigns one of the following addresses to the PC:

- `192.168.7.3`
- `192.168.7.4`
- `192.168.7.5`

### 5.3 Open the Web Page

After the device is connected, open the following address in a browser:

```text
http://hub.usb/
```

If the DNS name cannot be resolved, use the fixed IP address:

```text
http://192.168.7.1/
```

The host's USB virtual network interface and the slave node's cannot be used simultaneously. 
The slave node's IP address is 
```text
http://192.168.7.2/
```

## 6. Web Management Page

The Web page reads `index.html` from the device file area by default. The main page sections are:

- Left device tree: shows the `UART`, `SPI`, `I2C`, and `MLVDS` buses and their devices.
- Thread/status area: shows script runtime status and remaining memory. Script APIs are not expanded in this document.
- Terminal output area: shows device output, errors, and upload results.
- Input area: select a target device and send commands or parameters.
- Connection status: shows states such as `Connected`, `Reconnecting`, and `Connection error`.

### 6.1 Refresh the Device Tree

Click the title area of the device tree on the left side to request a device tree refresh. The device tree is also updated automatically through SSE push events.

### 6.2 Select a Device and Send Input

1. Click the target device in the left-side device tree, or select a device from the drop-down list in the input area.
2. Enter the content to send in the input box.
3. Click `Send`.
4. For MLVDS devices, the input is sent to the corresponding slave through MLVDS `DATA_SEND`.

If you enter `help`, the page shows the registered input hint for that device. If no hint is registered, no hint is shown.

### 6.3 View Output

Device output is shown in the Terminal area. Data reported by MLVDS slaves updates the `output` field of the device tree and is displayed by the page refresh.

### 6.4 Upload Files to an MLVDS Slave

1. Confirm that the MLVDS slave is online and appears under the `MLVDS` bus on the left.
2. Right-click the target MLVDS device.
3. Select `Update Device Code`.
4. Choose a file.
5. Wait for the Terminal area to display the upload result.

Supported file extensions:

- `.uf2`
- `.lua`
- `.txt`

The maximum size of a single file is 3 MB. During upload, do not disconnect USB, reset the host or slave, or start a second upload to the same device at the same time.

## 7. USB Mass Storage File Area

The device exposes part of its internal Flash as a FAT file area:

- Start address: `0x300000`
- Block size: 4096 bytes
- Block count: 256
- Capacity: about 1 MB

This file area stores Web pages, configuration files, and runtime files. On first boot, if the file system cannot be mounted, the firmware attempts to format and remount it automatically.

Notes for use:

- After writing files, safely eject the device in the PC operating system before disconnecting USB.
- While a file upload is in progress or the device is reading/writing Flash internally, MSC may appear unavailable for a short time. This is normal mutual-exclusion protection.
- It is not recommended to modify the file area from the PC while Web upload is active, while the device is running critical tasks, or during frequent read/write activity.
- If the PC prompts you to format the disk, cancel the action first and reconnect the device. If the issue remains, follow the Flash recovery procedure.

## 8. Device Tree

The device tree is the unified structure used by the firmware to expose device status externally. By default, it includes the following buses:

- `UART`
- `SPI`
- `I2C`
- `MLVDS`

Device node fields:

| Field | Meaning |
| --- | --- |
| `name` | Device name |
| `describe` | Device description |
| `freshtick` | Most recent refresh tick |
| `input` | Most recent input |
| `output` | Most recent output |
| `input_hint` | Input hint |
| `input_registered` | Whether input capability is registered |

The Web page receives device tree changes through SSE. The CDC serial port can also query the device tree directly.

## 9. HTTP Interface

The HTTP service runs at:

```text
http://192.168.7.1/
```

### 9.1 Static Files

| Request | Description |
| --- | --- |
| `GET /` | Returns the default page in the file area, usually `index.html` |
| `GET /index.html` | Returns the Web management page |

### 9.2 SSE Push

| Request | Description |
| --- | --- |
| `GET /events.event` | Opens a long-lived SSE connection and receives status updates |

SSE event types:

| Event | Meaning |
| --- | --- |
| `dev_tree` | Device tree JSON |
| `lua_thread` | Script thread status, used only for page display |
| `str_output` | Terminal output |
| `free_memory` | Remaining heap memory in bytes |

### 9.3 Control Endpoints

| Request | Description | Return |
| --- | --- | --- |
| `GET /refresh_devtree` | Triggers a device tree refresh | `OK` |
| `GET /restart_lua` | Requests a restart of the script runtime environment | `OK` |
| `GET /str_input:<text>` | Sends a string to the script input channel | `OK` |
| `GET /devTree` | Triggers device tree request handling | `OK` |
| `GET /devTree/<bus>/<dev>:<input>` | Writes input to a device; for MLVDS devices, the input is forwarded to the slave | `OK` |

`<bus>`, `<dev>`, and `<input>` must be URL-encoded.

Example:

```text
GET /devTree/MLVDS/motor01:speed%20100
```

### 9.4 File Upload Endpoints

| Request | Description |
| --- | --- |
| `POST /upload/<deviceName>/<fileName>` | Uploads a file to the specified MLVDS slave |
| `GET /upload_result.json` | Retrieves the latest upload result |

Constraints:

- `fileName` supports only `.uf2`, `.lua`, and `.txt`.
- File size must be greater than 0 and no larger than 3 MB.
- `deviceName` must be the name of an online MLVDS slave.
- The URL must not contain `..` or backslashes.

Upload result format:

```json
{"ok":true,"message":"upload success"}
```

The actual `message` content depends on the firmware response.

## 10. CDC Serial Commands

The CDC serial port uses text commands terminated by carriage return or newline.

### 10.1 Device Tree Commands

Query the full device tree:

```text
/devTree
```

Query device output:

```text
/devTree/<bus>/<dev>
```

Write input to a device and return that device's output:

```text
/devTree/<bus>/<dev>:<input>
```

Example:

```text
/devTree/MLVDS/motor01:speed 100
```

Return values:

- Success: returns the device `output` field text
- Device not found: `ERR dev not found`
- Format error: `ERR format use /devTree[/bus/dev[:input]]`
- Command too long: `ERR command too long`

### 10.2 Host Framed Channel

CDC also supports length-prefixed frames:

```text
<len>:<payload>
```

For example:

```text
5:hello
```

`len` must equal the byte length of `payload`, with a maximum of 512 bytes. This channel is used for message exchange between the host and internal device tasks.

## 11. MLVDS Bus Operation

### 11.1 Slave Online Registration

The MLVDS host automatically handles slave ID requests:

1. The slave sends an ID request.
2. The host assigns a logical ID based on the SN rule.
3. The slave ACKs and includes its device name and description.
4. The host registers the slave under the `MLVDS` bus in the device tree.

The slave name can be up to 32 bytes and the description up to 64 bytes. The name should remain stable and unique; otherwise uploads and command delivery may target the wrong device or fail to find it.

### 11.2 Heartbeat and Offline Detection

The host periodically checks MLVDS nodes:

- If there is no activity for about 2.5 seconds, the host attempts a ping.
- If there is no valid response for about 5 seconds, the host releases the ID and removes the node from the device tree.

### 11.3 Data Transfer

- When a slave reports normal data, the host updates that node's `output`.
- When Web or CDC writes input to an MLVDS device, the host sends the input content to the corresponding slave as a data packet.
- The raw payload of a single frame is about 254 bytes maximum. Longer data is fragmented according to the firmware logic.

### 11.4 File Upload

The file upload flow is:

1. The host sends an upload-start frame containing the total size and file name.
2. The slave enters upgrade/receive mode and returns an acknowledgment.
3. The host sends file data in chunks.
4. Each chunk waits for a slave acknowledgment.
5. The host sends the end frame.
6. The slave closes receive mode and returns online.

The upload timeout is about 5 seconds. If any stage times out, the slave goes offline, or an error is returned, the upload fails.

## 12. FAQ

### 12.1 The Browser Cannot Open the Page

Recommended troubleshooting order:

1. Confirm that USB is connected and the device is powered normally.
2. Visit `http://192.168.7.1/` first instead of relying only on `hub.usb`.
3. Check whether the PC shows a USB NCM network adapter.
4. Check whether the PC has obtained a `192.168.7.x` address.
5. Reconnect the USB cable.
6. If the problem remains, reflash the firmware.

### 12.2 The Page Keeps Reconnecting

Possible causes:

- Unstable USB connection
- Device reset or watchdog reboot
- The browser SSE connection is interrupted by system network policy
- `index.html` in the device file area does not match the firmware interface

Prefer the page files released together with the firmware.

### 12.3 MLVDS Slave Is Not Visible

Check the following:

- Whether MLVDS D/DE/R/RE pin connections are correct
- Whether transceiver power, direction control, and termination are correct
- Whether the slave sends ID requests and ACKs
- Whether the reported slave name is empty or duplicated
- Whether there is a short circuit, reversed polarity, or rate mismatch on the bus

### 12.4 File Upload Fails

Check the following:

- Whether the target device is online and listed under the `MLVDS` bus
- Whether the file is `.uf2`, `.lua`, or `.txt`
- Whether the file exceeds 3 MB
- Whether the slave reset or went offline during upload
- Whether the slave correctly responds to the upload start, chunk, and end frames

### 12.5 USB Storage File Area Is Abnormal

Handling steps:

1. Safely eject first, then reconnect the device.
2. Do not format the disk directly if the PC prompts you to do so.
3. If the issue still cannot be recovered, use `flash_nuke.uf2` to erase Flash.
4. Reflash the main firmware and restore the required files.

## 13. Field Usage Notes

- Do not power off or disconnect USB while a file upload is in progress.
- After modifying the file area, always safely eject the device.
- If multiple browser windows operate on the same device at the same time, uploads and input commands may interfere with each other.
- MLVDS slave names should use short names that can be URL-encoded. Avoid spaces, forward slashes, backslashes, and special control characters.
- For production versions, it is recommended to fix the USB product name, manufacturer name, VID/PID, and Web page version to make field identification easier.
