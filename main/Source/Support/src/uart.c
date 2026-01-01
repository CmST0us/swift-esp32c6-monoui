#include "uart.h"
#include "driver/uart.h"
#include "driver/gpio.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"

#define UART_NUM UART_NUM_0
#define BUF_SIZE 1024

void uart_init(void) {
    // 配置 UART 参数
    uart_config_t uart_config = {
        .baud_rate = 115200,
        .data_bits = UART_DATA_8_BITS,
        .parity = UART_PARITY_DISABLE,
        .stop_bits = UART_STOP_BITS_1,
        .flow_ctrl = UART_HW_FLOWCTRL_DISABLE,
        .source_clk = UART_SCLK_DEFAULT,
    };
    
    // 安装 UART 驱动
    uart_driver_install(UART_NUM, BUF_SIZE * 2, 0, 0, NULL, 0);
    
    // 配置 UART 参数
    uart_param_config(UART_NUM, &uart_config);
    
    // 设置 UART 引脚（ESP32-C6 默认使用 USB Serial/JTAG，通常不需要设置引脚）
    // 如果需要使用其他 UART，可以在这里设置：
    // uart_set_pin(UART_NUM, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE, UART_PIN_NO_CHANGE);
}

int32_t uart_read_char(void) {
    uint8_t data = 0;
    int len = uart_read_bytes(UART_NUM, &data, 1, 0); // 非阻塞读取
    if (len > 0) {
        return (int32_t)data;
    }
    return -1; // 没有数据
}

bool uart_has_data(void) {
    size_t available = 0;
    uart_get_buffered_data_len(UART_NUM, &available);
    return available > 0;
}

