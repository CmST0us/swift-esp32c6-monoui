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



// Pages
class DetailPage: Page {
    @AnimationValue var offsetX: Double = 128 // 初始在屏幕右侧外
    
    let title: String
    
    init(title: String) {
        self.title = title
        // 初始位置设为 128 (屏幕外)，实际通过 offsetX 动画控制偏移
        super.init(frame: Rect(x: 128, y: 0, width: 128, height: 64))
    }
    
    override func animateIn() {
        // 进场动画：从右侧 (128) 滑入到 (0)
        // 确保使用动画属性
        offsetX = 0
    }
    
    override func animateOut() {
        // 出场动画：滑出到右侧 (128)
        offsetX = 128
    }
    
    override func isExitAnimationFinished() -> Bool {
        // 当 offsetX 接近 128 时认为完成
        return offsetX >= 127.5
    }
    
    override func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        // 同步动画值
        frame.origin.x = offsetX
        
        // 调用父类 draw，父类会自动绘制黑色背景防止透视
        super.draw(u8g2: u8g2, origin: origin)
        
        guard let u8g2 = u8g2 else { return }
        
        let absX = origin.x + frame.origin.x
        let absY = origin.y + frame.origin.y
        
        // 绘制详情内容边框 (白线)
        // 由于父类已经画了黑底，这里直接画框即可
        u8g2_SetDrawColor(u8g2, 1)
        u8g2_DrawFrame(u8g2, u8g2_uint_t(absX), u8g2_uint_t(absY), 128, 64)
        
        u8g2_SetFont(u8g2, u8g2_font_6x10_tf)
        u8g2_DrawStr(u8g2, u8g2_uint_t(absX + 10), u8g2_uint_t(absY + 20), "Detail: \(title)")
        u8g2_DrawStr(u8g2, u8g2_uint_t(absX + 10), u8g2_uint_t(absY + 40), "Press 'q' Back")
    }
    
    override func handleInput(key: Int32) {
        // 处理键盘输入
        // 'q' 或 'Q' 返回上一页 (直接使用 ASCII 值，避免 Unicode 规范化)
        let key_q: Int32 = 113  // 'q'
        let key_Q: Int32 = 81   // 'Q'
        if key == key_q || key == key_Q {
            // 需要访问 router，但这里没有直接访问，需要通过 Application.shared
            if let app = Application.shared as? ESP32C6App {
                app.router.pop()
            }
        }
    }
}

class HomePage: Page {
    let scrollView: ScrollView
    @AnimationValue var scrollOffset: Double = 0
    
    // 数据源
    static let icon1: [UInt8] = [0x00,0x00,0x00,0x40,0x00,0x00,0x40,0x04,0x00,0x40,0x04,0x00,0x40,0x04,0x00,0x50,0x14,0x00,0x50,0x15,0x00,0x54,0x15,0x00,0x55,0x55,0x01,0x50,0x55,0x00,0x50,0x15,0x00,0x50,0x04,0x00,0x40,0x04,0x00,0x40,0x04,0x00,0x40,0x00,0x00,0x00,0x00,0x00]
    static let icon2: [UInt8] = [0x80,0x00,0x48,0x01,0x38,0x02,0x98,0x04,0x48,0x09,0x24,0x12,0x12,0x24,0x09,0x48,0x66,0x30,0x64,0x10,0x04,0x17,0x04,0x15,0x04,0x17,0x04,0x15,0xfc,0x1f,0x00,0x00]
    static let icon3: [UInt8] = [0x1c,0x00,0x22,0x00,0xe3,0x3f,0x22,0x00,0x1c,0x00,0x00,0x0e,0x00,0x11,0xff,0x31,0x00,0x11,0x00,0x0e,0x1c,0x00,0x22,0x00,0xe3,0x3f,0x22,0x00,0x1c,0x00,0x00,0x00]

    // 当前选中的 Tile 索引 (0, 1, 2)
    var selectedIndex: Int = 0
    var tiles: [IconTileView]
    
    init() {
        self.scrollView = ScrollView(frame: Rect(x: 0, y: 0, width: 128, height: 45))
        // 增加宽度以允许最后一个 Tile 居中
        // Tile 3 center at 147. Viewport center 64. Offset needed 83.
        // Viewport width 128. 128 + 83 = 211. 
        self.scrollView.contentSize = Size(width: 212, height: 45)
        self.scrollView.direction = .horizontal
        
        // 必须在 super.init 之前初始化所有属性
        self.tiles = []
        
        super.init(frame: Rect(x: 0, y: 0, width: 128, height: 64))
        
        let startX: Double = 45
        let spacing: Double = 6
        let cardSize = Size(width: 36, height: 36)
        let yPos: Double = 4
        
        let tile1 = IconTileView(frame: Rect(x: startX, y: yPos, width: cardSize.width, height: cardSize.height),
                                 iconBits: Self.icon1,
                                 iconSize: Size(width: 17, height: 16)) {
            // Click Handler - 导航到详情页
            if let app = Application.shared as? ESP32C6App {
                app.router.push(DetailPage(title: "Music"))
            }
        }
        scrollView.addSubview(tile1)
        tiles.append(tile1)
        
        let tile2 = IconTileView(frame: Rect(x: startX + cardSize.width + spacing, y: yPos, width: cardSize.width, height: cardSize.height),
                                 iconBits: Self.icon2,
                                 iconSize: Size(width: 15, height: 16)) {
            // Click Handler - 导航到详情页
            if let app = Application.shared as? ESP32C6App {
                app.router.push(DetailPage(title: "Home"))
            }
        }
        scrollView.addSubview(tile2)
        tiles.append(tile2)
        
        let tile3 = IconTileView(frame: Rect(x: startX + (cardSize.width + spacing) * 2, y: yPos, width: cardSize.width, height: cardSize.height),
                                 iconBits: Self.icon3,
                                 iconSize: Size(width: 14, height: 16)) {
            // Click Handler - 导航到详情页
            if let app = Application.shared as? ESP32C6App {
                app.router.push(DetailPage(title: "Download"))
            }
        }
        scrollView.addSubview(tile3)
        tiles.append(tile3)
        
        self.addSubview(scrollView)
    }
    
    override func draw(u8g2: UnsafeMutablePointer<u8g2_t>?, origin: Point) {
        scrollView.contentOffset.x = scrollOffset
        super.draw(u8g2: u8g2, origin: origin)
        
        // 绘制底部固定条
        if let u8g2 = u8g2 {
             u8g2_DrawBox(u8g2, 0, 47, 4, 17)
        }
    }
    
    override func handleInput(key: Int32) {
        // 处理键盘输入
        // 使用 ASCII 值常量，避免 Unicode 规范化
        let key_a: Int32 = 97   // 'a'
        let key_A: Int32 = 65   // 'A'
        let key_d: Int32 = 100  // 'd'
        let key_D: Int32 = 68   // 'D'
        let key_e: Int32 = 101  // 'e'
        let key_E: Int32 = 69   // 'E'
        
        if key == key_a || key == key_A {
            // 向左
            if selectedIndex > 0 {
                selectedIndex -= 1
                scrollToSelected()
            }
        } else if key == key_d || key == key_D {
            // 向右
            if selectedIndex < tiles.count - 1 {
                selectedIndex += 1
                scrollToSelected()
            }
        } else if key == key_e || key == key_E {
            // 使用 'e' 进入/激活选中的 Tile
            tiles[selectedIndex].onClick?()
        }
    }
    
    private func scrollToSelected() {
        // 计算居中偏移量
        // 目标是将 selectedIndex 对应的 Tile 居中显示
        // Tile 中心点 x 坐标 = tile.x + tile.width / 2
        // ScrollView 中心点 x 坐标 = scrollView.width / 2
        // contentOffset.x = Tile 中心点 x - ScrollView 中心点 x
        
        let tile = tiles[selectedIndex]
        let tileCenterX = tile.frame.origin.x + tile.frame.size.width / 2
        let scrollViewCenterX = scrollView.frame.size.width / 2
        
        var targetOffset = tileCenterX - scrollViewCenterX
        
        // 边界处理：不让内容滚出可视区域太多（可选，看设计需求，这里做简单的 clamp）
        // 最小 offset = 0
        // 最大 offset = contentSize.width - scrollView.width
        let maxOffset = scrollView.contentSize.width - scrollView.frame.size.width
        
        // 如果内容比视口小，则不需要滚动或居中显示（这里假设内容比视口宽）
        if maxOffset > 0 {
            targetOffset = max(0, min(targetOffset, maxOffset))
        } else {
            targetOffset = 0
        }
        
        scrollOffset = targetOffset
    }
}

@_cdecl("app_main")
func main() {
    let context = Context(driver: ESP32C6U8g2Driver(), screenSize: Size(width: 64, height: 48))
    let app = ESP32C6App(context: context)
    app.run()
}
