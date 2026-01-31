#include "spi.h"
#include "driver/spi_master.h"
#include "driver/gpio.h"
#include "esp_log.h"
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_rom_sys.h"

static const char *TAG = "SPI";
static spi_device_handle_t spi_handle = NULL;

bool spi_init(void) {
    // SPI bus configuration
    spi_bus_config_t buscfg = {
        .mosi_io_num = SPI_MOSI_PIN,
        .miso_io_num = -1,  // Not used for OLED
        .sclk_io_num = SPI_SCK_PIN,
        .quadwp_io_num = -1,
        .quadhd_io_num = -1,
        .max_transfer_sz = 1024,
    };

    // SPI device configuration
    spi_device_interface_config_t devcfg = {
        .clock_speed_hz = SPI_CLOCK_SPEED_HZ,
        .mode = 0,  // SPI mode 0
        .spics_io_num = -1,  // We control CS manually
        .queue_size = 1,
        .flags = SPI_DEVICE_NO_DUMMY,
    };

    ESP_LOGI(TAG, "Initializing SPI bus...");
    esp_err_t ret = spi_bus_initialize(SPI2_HOST, &buscfg, SPI_DMA_CH_AUTO);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "SPI bus initialization failed: %d", ret);
        return false;
    }

    ESP_LOGI(TAG, "Adding SPI device...");
    ret = spi_bus_add_device(SPI2_HOST, &devcfg, &spi_handle);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "SPI device add failed: %d", ret);
        return false;
    }

    ESP_LOGI(TAG, "SPI initialization successful - MOSI: %d, SCK: %d, Speed: %d Hz",
             SPI_MOSI_PIN, SPI_SCK_PIN, SPI_CLOCK_SPEED_HZ);
    return true;
}

bool spi_write_data(uint8_t* data, size_t data_len) {
    if (spi_handle == NULL || data_len == 0) {
        return false;
    }

    spi_transaction_t trans = {
        .length = data_len * 8,  // Length in bits
        .tx_buffer = data,
        .rx_buffer = NULL,
    };

    esp_err_t ret = spi_device_polling_transmit(spi_handle, &trans);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "SPI write data failed: %d", ret);
        return false;
    }
    return true;
}

void spi_gpio_init(void) {
    // Configure CS pin
    gpio_config_t io_conf = {
        .pin_bit_mask = (1ULL << SPI_CS_PIN) | (1ULL << SPI_DC_PIN) | (1ULL << SPI_RST_PIN),
        .mode = GPIO_MODE_OUTPUT,
        .pull_up_en = GPIO_PULLUP_DISABLE,
        .pull_down_en = GPIO_PULLDOWN_DISABLE,
        .intr_type = GPIO_INTR_DISABLE,
    };
    gpio_config(&io_conf);

    // Set initial states
    gpio_set_level(SPI_CS_PIN, 1);   // CS high (inactive)
    gpio_set_level(SPI_DC_PIN, 1);   // DC high (data mode)
    gpio_set_level(SPI_RST_PIN, 1);  // RST high (not in reset)

    ESP_LOGI(TAG, "GPIO initialized - CS: %d, DC: %d, RST: %d",
             SPI_CS_PIN, SPI_DC_PIN, SPI_RST_PIN);
}

void spi_set_cs(uint8_t level) {
    gpio_set_level(SPI_CS_PIN, level);
}

void spi_set_dc(uint8_t level) {
    gpio_set_level(SPI_DC_PIN, level);
}

void spi_set_rst(uint8_t level) {
    gpio_set_level(SPI_RST_PIN, level);
}

// delay_ms is defined in rtos_utils.c

void delay_us(uint32_t us) {
    esp_rom_delay_us(us);
}
