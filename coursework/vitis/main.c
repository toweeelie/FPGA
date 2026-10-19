#include "xparameters.h"
#include "xil_io.h"

#define ECHO_BASEADDR  XPAR_AXI_DIGITAL_ECHO_0_BASEADDR

int main(void)
{
    /*
    XGpio_Config *cfg_ptr;
    XGpio btn_gpio, capture_gpio;
    u32 btn_value;
    u32 previous_btn = 0U;

    // init button
    cfg_ptr = XGpio_LookupConfig(BTN_BASEADDR);
    XGpio_CfgInitialize(&btn_gpio, cfg_ptr, cfg_ptr->BaseAddress);

    cfg_ptr = XGpio_LookupConfig(CAPTURE_BASEADDR);
    XGpio_CfgInitialize(&capture_gpio, cfg_ptr, cfg_ptr->BaseAddress);

    // init dma
    XAxiDma_Config *cfg = XAxiDma_LookupConfig(DMA_BASEADDR);
    if (cfg == NULL) { errors = -2; while (1) {} }
    XAxiDma_CfgInitialize(&dma_inst, cfg);
    if (XAxiDma_HasSg(&dma_inst)) { errors = -3; while (1) {} }

    while (1) {
        btn_value = XGpio_DiscreteRead(&btn_gpio, GPIO_CHANNEL)
                     & GPIO_MASK;

        if (btn_value && !previous_btn) {
            // start transfer
            XAxiDma_SimpleTransfer(&dma_inst, DST_ADDR, LENGTH, XAXIDMA_DEVICE_TO_DMA);
            XGpio_DiscreteWrite(&capture_gpio, GPIO_CHANNEL, 1);
            XGpio_DiscreteWrite(&capture_gpio, GPIO_CHANNEL, 0);
            while (XAxiDma_Busy(&dma_inst, XAXIDMA_DEVICE_TO_DMA)) {};           
        }

        previous_btn = btn_value;
    }
    */
}
