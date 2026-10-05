#include "xparameters.h"
#include "xil_io.h"
#include "xgpio.h"

#define LED_BASEADDR   XPAR_AXI_GPIO_0_BASEADDR
#define BTN_BASEADDR   XPAR_AXI_GPIO_1_BASEADDR
#define SW_BASEADDR    XPAR_AXI_GPIO_2_BASEADDR
#define SPEED_MAX 8

XGpio led_gpio, btn_gpio, sw_gpio;

int main() {
    XGpio_Config *cfg_ptr;

    cfg_ptr = XGpio_LookupConfig(LED_BASEADDR);
    XGpio_CfgInitialize(&led_gpio, cfg_ptr, cfg_ptr->BaseAddress);

    cfg_ptr = XGpio_LookupConfig(BTN_BASEADDR);
    XGpio_CfgInitialize(&btn_gpio, cfg_ptr, cfg_ptr->BaseAddress);

    cfg_ptr = XGpio_LookupConfig(SW_BASEADDR);
    XGpio_CfgInitialize(&sw_gpio, cfg_ptr, cfg_ptr->BaseAddress);

    XGpio_SetDataDirection(&led_gpio, 1, 0x0);
    XGpio_SetDataDirection(&btn_gpio, 1, 0x7);
    XGpio_SetDataDirection(&sw_gpio,  1, 0x1);

    u8 direction = 0; // 0 - forward; 1 - reverse
    u8 speed = 0; // 0 - stop, greater and up to SPEED_MAX - run
    s8 current_led = 0;
    u32 time = 0;

    while (1) {
        u32 btn_value = XGpio_DiscreteRead(&btn_gpio, 1);
        direction = XGpio_DiscreteRead(&sw_gpio, 1);
        
        if (btn_value & 0x1) // start/stop
            speed = (speed)? 0 : 1;
            
        if (btn_value & 0x2) // speed up
            if((speed>0) && (speed<(SPEED_MAX-1))){
                speed++;
            }

        if (btn_value & 0x4) // speed down
            if(speed>1) {
                speed--;
            }
        
        if (time == 10e6*speed){
            current_led = (direction)? current_led-1 : current_led+1;
            if (current_led == -1) current_led = 3;
            if (current_led == 4)  current_led = 0;         

            XGpio_DiscreteWrite(&led_gpio, 1, 1<<current_led);
        }       
        time++;
    }

    return 0;
}