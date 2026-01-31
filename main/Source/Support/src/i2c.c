#include "i2c.h"
#include "driver/i2c_master.h"
#include "esp_log.h"

static const char *TAG = "I2C";

static i2c_master_bus_handle_t bus_handle = NULL;
static i2c_master_dev_handle_t dev_handle = NULL;

bool i2c_init(void) {
    // Configure I2C master bus
    i2c_master_bus_config_t bus_config = {
        .i2c_port = I2C_NUM_0,
        .sda_io_num = I2C_SDA_PIN,
        .scl_io_num = I2C_SCL_PIN,
        .clk_source = I2C_CLK_SRC_DEFAULT,
        .glitch_ignore_cnt = 7,
        .flags.enable_internal_pullup = true,
    };

    ESP_LOGI(TAG, "Creating I2C master bus...");
    esp_err_t ret = i2c_new_master_bus(&bus_config, &bus_handle);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "I2C master bus creation failed: %s", esp_err_to_name(ret));
        return false;
    }

    // Configure device (SSD1306 OLED at address 0x3C)
    i2c_device_config_t dev_config = {
        .dev_addr_length = I2C_ADDR_BIT_LEN_7,
        .device_address = 0x3C,
        .scl_speed_hz = I2C_MASTER_FREQ_HZ,
    };

    ESP_LOGI(TAG, "Adding I2C device...");
    ret = i2c_master_bus_add_device(bus_handle, &dev_config, &dev_handle);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "I2C device addition failed: %s", esp_err_to_name(ret));
        return false;
    }

    ESP_LOGI(TAG, "I2C initialization successful - SCL: %d, SDA: %d, Frequency: %d Hz",
             I2C_SCL_PIN, I2C_SDA_PIN, I2C_MASTER_FREQ_HZ);
    return true;
}

bool i2c_write_data(uint8_t device_address, uint8_t* data, size_t data_len) {
    if (dev_handle == NULL) {
        ESP_LOGE(TAG, "I2C not initialized");
        return false;
    }

    esp_err_t ret = i2c_master_transmit(dev_handle, data, data_len, I2C_MASTER_TIMEOUT_MS);
    if (ret != ESP_OK) {
        ESP_LOGE(TAG, "I2C write failed: %s", esp_err_to_name(ret));
        return false;
    }
    return true;
}
