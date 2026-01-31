import Support
import CU8g2
import MonoUI

class ESP32C6App: Application {

    override init(context: Context) {
        super.init(context: context)
    }

    /// 重写 getCurrentTime 以使用 FreeRTOS 的 tick 计数
    /// 返回自系统启动以来的秒数（单调递增）
    override func getCurrentTime() -> Double {
        // 使用 FreeRTOS 的 tick 计数，转换为秒
        // get_tick_count_ms() 返回毫秒数，除以 1000.0 得到秒数
        return Double(get_tick_count_ms()) / 1000.0
    }

    override func setup() {
        // 初始化串口（用于键盘输入）
        uart_init()

        // 初始化显示
        driver.withUnsafeU8g2 { u8g2 in
            u8g2_InitDisplay(u8g2)
            u8g2_SetPowerSave(u8g2, 0)
            u8g2_ClearBuffer(u8g2)
        }

        // 设置根页面
        let root = HomePage()
        router.setRoot(root)
    }

    override func loop() {
        // 处理串口键盘输入
        while uart_has_data() {
            let key = uart_read_char()
            if key >= 0 {
                // 将字符转换为 Int32 并传递给当前页面处理
                router.handleInput(key: Int32(key))
            }
        }

        // 原子更新显示缓冲区，避免屏幕撕裂
        // 确保 ClearBuffer -> Draw -> SendBuffer 在一个操作中完成
        driver.withUnsafeU8g2 { u8g2 in
            // 清除缓冲区
            u8g2_ClearBuffer(u8g2)
            u8g2_SetBitmapMode(u8g2, 1) // 开启透明模式
            u8g2_SetFontMode(u8g2, 1)

            // 绘制 Router (包含 Pages)
            router.draw(u8g2: u8g2)

            // 发送完整缓冲区到屏幕
            // 这确保了整个帧是一次性更新的，避免部分更新导致的撕裂
            u8g2_SendBuffer(u8g2)
        }
    }
}

@_cdecl("app_main")
func main() {
    let context = Context(driver: ESP32C6U8g2Driver(), screenSize: Size(width: 128, height: 64))
    let app = ESP32C6App(context: context)
    app.run()
}
