#ifndef UART_H
#define UART_H

#include <stdint.h>
#include <stdbool.h>

// 初始化 UART（默认使用 UART_NUM_0，通常是 USB Serial/JTAG）
void uart_init(void);

// 从串口读取一个字符（非阻塞）
// 返回: 读取到的字符（0-255），如果没有数据则返回 -1
int32_t uart_read_char(void);

// 检查是否有可用的字符
bool uart_has_data(void);

#endif // UART_H

