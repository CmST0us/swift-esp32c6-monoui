# CLAUDE.md - swift-esp32c6-monoui

ESP32-C6 demo application using MonoUI framework with Embedded Swift.

## Build Commands

```bash
# Setup ESP-IDF environment
get_idf_5.5.1

# Build
idf.py build

# Flash to device
idf.py flash

# Monitor serial output (also used for keyboard input)
idf.py monitor

# Build, flash, and monitor in one command
idf.py flash monitor
```

## Project Structure

```
main/
├── Source/
│   ├── App/
│   │   ├── App.swift              # Application entry point, ESP32C6App class
│   │   ├── Pages.swift            # Page implementations (HomePage, DetailPage, etc.)
│   │   └── ESP32C6U8g2Driver.swift # U8g2 display driver implementation
│   └── Support/
│       ├── include/
│       │   ├── i2c.h              # I2C configuration (pins, frequency)
│       │   └── uart.h             # UART interface
│       └── src/
│           ├── i2c.c              # I2C driver (new master API)
│           └── uart.c             # USB Serial/JTAG for input
├── CMakeLists.txt                 # Swift/ESP-IDF integration
├── Package.swift                  # Swift package definition
└── BridgingHeader.h               # C/Swift bridging
```

## Hardware Configuration

| Component | Configuration |
|-----------|---------------|
| Display | SSD1306 128x64 OLED |
| I2C Address | 0x3C |
| I2C Frequency | 1MHz (Fast Mode Plus) |
| I2C SCL Pin | GPIO 4 |
| I2C SDA Pin | GPIO 5 |
| Input | USB Serial/JTAG (via `idf.py monitor`) |

## CMake/Swift Integration

The `CMakeLists.txt` handles complex Swift toolchain integration:

1. **Swift Package Manager** builds the archive separately
2. **Force link symbols** ensure ESP-IDF drivers are linked:
   ```cmake
   # I2C (new master API)
   target_link_libraries(__idf_main "-Wl,-u,i2c_new_master_bus")
   target_link_libraries(__idf_main "-Wl,-u,i2c_master_bus_add_device")
   target_link_libraries(__idf_main "-Wl,-u,i2c_master_transmit")
   ```
3. **`patch_sections_ld.cmake`** patches ESP-IDF linker script for `.got/.got.plt` sections
4. Object file with `app_main()` extracted and linked explicitly for FreeRTOS

### Adding New ESP-IDF Driver Symbols

When using new ESP-IDF drivers that aren't automatically linked, add force link symbols:

```cmake
target_link_libraries(__idf_main "-Wl,-u,<function_name>")
```

## Embedded Swift Constraints

### No `weak` References

Embedded Swift does not support `weak` attribute. Avoid `[weak self]` in closures:

```swift
// BAD - will not compile
button.onTap = { [weak self] in
    self?.doSomething()
}

// GOOD - use direct capture
button.onTap = {
    self.doSomething()
}
```

### No Unicode Normalization

Use ASCII integer values directly:

```swift
// BAD - may not work in Embedded Swift
let key = Character("q").asciiValue

// GOOD - use integer directly
let key_q: Int32 = 113
let key_w: Int32 = 119
```

### No Runtime Type Checking (`as?`, `is`)

Embedded Swift does not support `as?` or `is` for runtime type checking:

```swift
// BAD - will crash or not compile
if let page = view as? HomePage { ... }

// GOOD - use virtual methods (polymorphism)
class View {
    open func handleSpecialCase() { }
}
class HomePage: View {
    override func handleSpecialCase() { /* implementation */ }
}
```

### No Protocol Existential Types

Arrays of protocol types (`[SomeProtocol]`) are not supported:

```swift
// BAD - existential type
protocol Updateable { func update() }
var items: [Updateable] = []  // Won't work

// GOOD - use base class
class Updater { func update() {} }
var items: [Updater] = []  // Works
```

## Key Implementation Notes

### Application Setup

```swift
@_cdecl("app_main")
func app_main() {
    // Initialize hardware
    i2c_init()
    uart_init()
    u8g2_setup()

    // Create context with correct screen size
    let context = Context(
        driver: ESP32C6U8g2Driver(),
        screenSize: Size(width: 128, height: 64)  // Must match display
    )

    // Create and run application
    let app = ESP32C6App(context: context)
    app.run()
}
```

### Time and Sleep (FreeRTOS Integration)

```swift
override func getCurrentTime() -> Double {
    let ticks = xTaskGetTickCount()
    return Double(ticks) / Double(configTICK_RATE_HZ)
}

override func sleepMicroseconds(_ us: UInt32) {
    vTaskDelay(1)  // Minimum 1 tick delay
}
```

### Input Handling

Keyboard input comes through USB Serial/JTAG when using `idf.py monitor`:

```swift
override func loop() {
    // Check for keyboard input
    if uart_has_data() {
        let key = uart_read_char()
        router.handleInput(key: key)
    }
    // ... rest of loop
}
```

Common key codes:
- `w/a/s/d` = 119/97/115/100 (navigation)
- `q` = 113 (back/quit)
- `e/Enter` = 101/13 (confirm)
