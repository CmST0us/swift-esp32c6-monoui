#ifndef SPI_H
#define SPI_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

// SPI pin definitions for OLED display
// CS:G6, MOSI:G21, SCK:G20, DC:G18, RST:G15
#define SPI_MOSI_PIN    21
#define SPI_SCK_PIN     20
#define SPI_CS_PIN      6
#define SPI_DC_PIN      18
#define SPI_RST_PIN     15

// SPI configuration
#define SPI_CLOCK_SPEED_HZ  10000000  // 10MHz

// Function declarations
bool spi_init(void);
bool spi_write_data(uint8_t* data, size_t data_len);

// GPIO control functions
void spi_gpio_init(void);
void spi_set_cs(uint8_t level);
void spi_set_dc(uint8_t level);
void spi_set_rst(uint8_t level);

// Delay functions
void delay_ms(uint32_t ms);
void delay_us(uint32_t us);

#endif /* SPI_H */
