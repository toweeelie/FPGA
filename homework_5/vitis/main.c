#include "xparameters.h"
#include "xgpio.h"
#include "xil_io.h"
#include "xil_printf.h"
#include "xstatus.h"

#define BTN_BASEADDR  XPAR_AXI_GPIO_0_BASEADDR
#define CAPTURE_BASEADDR XPAR_AXI4_BYTE_CAPTURE_0_BASEADDR

#define GPIO_CHANNEL 1U
#define GPIO_MASK    0x00000001U
#define REG_CONTROL  0x00U

int main(void)
{
    XGpio_Config *cfg_ptr;
    XGpio btn_gpio;
    u32 btn_value;
    u32 previous_btn = 0U;

    cfg_ptr = XGpio_LookupConfig(BTN_BASEADDR);
    XGpio_CfgInitialize(&btn_gpio, cfg_ptr, cfg_ptr->BaseAddress);

    /* Start with capture disabled */
    Xil_Out32(CAPTURE_BASEADDR + REG_CONTROL, 0U);

    xil_printf("Waiting for GPIO rising edge...\r\n");

    while (1) {
        btn_value = XGpio_DiscreteRead(&btn_gpio, GPIO_CHANNEL)
                     & GPIO_MASK;

        if (btn_value && !previous_btn) {
            Xil_Out32(CAPTURE_BASEADDR + REG_CONTROL, 1U);
            xil_printf("Capture started\r\n");
        }

        previous_btn = btn_value;
    }
}
