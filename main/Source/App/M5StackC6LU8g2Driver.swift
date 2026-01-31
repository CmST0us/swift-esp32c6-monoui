import U8g2Kit
import CU8g2
import Support

class M5StackC6LU8g2Driver: Driver {

    init() {
        super.init(u8g2_Setup_ssd1306_64x48_er_f, &U8g2Kit.u8g2_cb_r0)
    }

    override func onByte(msg: UInt8, arg_int: UInt8, arg_ptr: UnsafeMutableRawPointer?) -> UInt8 {
        switch Int32(msg) {
        case U8X8_MSG_BYTE_INIT:
            spi_init()
            return 1

        case U8X8_MSG_BYTE_SET_DC:
            spi_set_dc(arg_int)
            return 1

        case U8X8_MSG_BYTE_START_TRANSFER:
            spi_set_cs(0)  // CS low - start transfer
            return 1

        case U8X8_MSG_BYTE_SEND:
            if let ptr = arg_ptr {
                let data = ptr.assumingMemoryBound(to: UInt8.self)
                var tempBuffer: [UInt8] = Array(repeating: 0, count: Int(arg_int))
                for i in 0..<Int(arg_int) {
                    tempBuffer[i] = data[i]
                }
                spi_write_data(&tempBuffer, Int(arg_int))
            }
            return 1

        case U8X8_MSG_BYTE_END_TRANSFER:
            spi_set_cs(1)  // CS high - end transfer
            return 1

        default:
            return 1
        }
    }

    // GPIO message constants (calculated from u8x8.h: U8X8_MSG_GPIO(x) = 64 + x)
    // U8X8_PIN_CS = 9, U8X8_PIN_DC = 10, U8X8_PIN_RESET = 11
    private static let MSG_GPIO_CS: Int32 = 73      // 64 + 9
    private static let MSG_GPIO_DC: Int32 = 74      // 64 + 10
    private static let MSG_GPIO_RESET: Int32 = 75   // 64 + 11

    override func onGpioAndDelay(msg: UInt8, arg_int: UInt8, arg_ptr: UnsafeMutableRawPointer?) -> UInt8 {
        switch Int32(msg) {
        case U8X8_MSG_GPIO_AND_DELAY_INIT:
            spi_gpio_init()
            return 1

        case Self.MSG_GPIO_CS:
            spi_set_cs(arg_int)
            return 1

        case Self.MSG_GPIO_DC:
            spi_set_dc(arg_int)
            return 1

        case Self.MSG_GPIO_RESET:
            spi_set_rst(arg_int)
            return 1

        case U8X8_MSG_DELAY_MILLI:
            delay_ms(UInt32(arg_int))
            return 1

        case U8X8_MSG_DELAY_10MICRO:
            delay_us(UInt32(arg_int) * 10)
            return 1

        case U8X8_MSG_DELAY_100NANO:
            // Very short delay, just return
            return 1

        default:
            return 1
        }
    }
}
