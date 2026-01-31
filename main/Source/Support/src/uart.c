#include "uart.h"
#include "driver/usb_serial_jtag.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#define BUF_SIZE 256

static bool initialized = false;
static uint8_t peek_buffer = 0;
static bool has_peek_data = false;

void uart_init(void) {
    if (initialized) return;

    // 配置 USB Serial/JTAG
    usb_serial_jtag_driver_config_t usb_serial_config = {
        .tx_buffer_size = BUF_SIZE,
        .rx_buffer_size = BUF_SIZE,
    };

    // 安装 USB Serial/JTAG 驱动
    usb_serial_jtag_driver_install(&usb_serial_config);

    initialized = true;
}

int32_t uart_read_char(void) {
    // 先检查是否有预读的数据
    if (has_peek_data) {
        has_peek_data = false;
        return (int32_t)peek_buffer;
    }

    uint8_t data = 0;
    // 非阻塞读取 (timeout = 0)
    int len = usb_serial_jtag_read_bytes(&data, 1, 0);
    if (len > 0) {
        return (int32_t)data;
    }
    return -1; // 没有数据
}

bool uart_has_data(void) {
    // 如果已经有预读数据，直接返回 true
    if (has_peek_data) {
        return true;
    }

    // 尝试读取一个字节
    int len = usb_serial_jtag_read_bytes(&peek_buffer, 1, 0);
    if (len > 0) {
        has_peek_data = true;
        return true;
    }
    return false;
}
