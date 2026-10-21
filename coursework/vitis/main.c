#include "xparameters.h"
#include "xil_io.h"
#include "xil_printf.h"

#define ECHO_BASEADDR  XPAR_DIGITAL_ECHO_0_BASEADDR

typedef enum {
    DIGITAL_ECHO_0_IN = 0x00,
    DIGITAL_ECHO_0_OUT = 0x04,
    DIGITAL_ECHO_0_D = 0x08,
    DIGITAL_ECHO_0_SHIFT = 0x0c,
    DIGITAL_ECHO_0_CTRL = 0x10
} digital_echo_reg_offset_t;

int main(void)
{
    u32 value;
    
    Xil_Out32(ECHO_BASEADDR+DIGITAL_ECHO_0_D, 4);
    Xil_Out32(ECHO_BASEADDR+DIGITAL_ECHO_0_SHIFT, 1);
    
    for (int i = 0; i < 24; i++)
    {
        Xil_Out32(ECHO_BASEADDR+DIGITAL_ECHO_0_IN, (i)? 0 : 1000);
        value = Xil_In32(ECHO_BASEADDR+DIGITAL_ECHO_0_OUT);
        xil_printf("%02d:%04x\n", i, (u16)value);
    }

    xil_printf("IDLE\n");
    while (1) {}
}
