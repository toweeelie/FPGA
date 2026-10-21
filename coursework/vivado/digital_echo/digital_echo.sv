
`define ARITHM_SHIFT 1

package digital_echo_p;
    typedef enum logic [2:0] {
        AXI_REG_IDX_IN,
        AXI_REG_IDX_OUT,
        AXI_REG_IDX_D,
        AXI_REG_IDX_SHIFT,
        AXI_REG_IDX_CTRL,
        AXI_REG_IDX_SIZEOF
    } axi_reg_idx_e;
endpackage

import digital_echo_p::*;

module digital_echo #(
    parameter int AXI_DATA_WIDTH = 32,
    parameter int AXI_ADDR_WIDTH = 5,
    parameter int MAX_D_VALUE = 8,
    parameter int MAX_SHIFT_VALUE = 3
)(
    // clk and rst
    input  logic                          s_axi_aclk,
    input  logic                          s_axi_aresetn,

    // Write Address Channel
    input  logic [AXI_ADDR_WIDTH-1 : 0]   s_axi_awaddr,
    input  logic                          s_axi_awvalid,
    output logic                          s_axi_awready,

    // Write Data Channel
    input  logic [AXI_DATA_WIDTH-1 : 0]   s_axi_wdata,
    input  logic [(AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  logic                          s_axi_wvalid,
    output logic                          s_axi_wready,

    // Write Response Channel
    output logic [1 : 0]                  s_axi_bresp,
    output logic                          s_axi_bvalid,
    input  logic                          s_axi_bready,

    // Read Address Channel
    input  logic [AXI_ADDR_WIDTH-1 : 0]   s_axi_araddr,
    input  logic                          s_axi_arvalid,
    output logic                          s_axi_arready,

    // Read Data Channel
    output logic [AXI_DATA_WIDTH-1 : 0]   s_axi_rdata,
    output logic [1 : 0]                  s_axi_rresp,
    output logic                          s_axi_rvalid,
    input  logic                          s_axi_rready
);

    // AXI responses
    typedef enum logic [1:0] {
        AXI_RESP_OKAY   = 2'b00,
        AXI_RESP_EXOKAY = 2'b01,
        AXI_RESP_SLVERR = 2'b10,
        AXI_RESP_DECERR = 2'b11
    } axi_resp_e;

    // addresses
    logic [AXI_ADDR_WIDTH-1:0] axi_awaddr;
    logic [AXI_ADDR_WIDTH-1:0] axi_araddr;
    
    // inner memory
    logic [AXI_DATA_WIDTH-1:0] d;
    logic [AXI_DATA_WIDTH-1:0] shift;
    logic signed [AXI_DATA_WIDTH-1:0] delay_line [MAX_D_VALUE:0];   
    logic signed [AXI_DATA_WIDTH-1:0] interm_res;

    // ----------------------------------------------------
    // write logic
    // ----------------------------------------------------
    always_ff @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= AXI_RESP_OKAY;
            axi_awaddr    <= '0;
        end else begin
            // ready to get addr and data
            if (!s_axi_awready && s_axi_awvalid && s_axi_wvalid) begin
                s_axi_awready <= 1'b1;
                s_axi_wready  <= 1'b1;
                axi_awaddr    <= s_axi_awaddr;
            end else begin
                s_axi_awready <= 1'b0;
                s_axi_wready  <= 1'b0;
            end

            // BVALID generation
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= AXI_RESP_OKAY;
            end else if (s_axi_bready && s_axi_bvalid) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    // ----------------------------------------------------
    // write to inner regs
    // ----------------------------------------------------
    always_ff @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            d <= 1;
            shift <= 1;
            foreach (delay_line[i])
                delay_line[i] <= '0;
        end else begin
            if (s_axi_wready && s_axi_wvalid && s_axi_awready && s_axi_awvalid) begin
                unique case (axi_awaddr[AXI_ADDR_WIDTH-1:2])
                    AXI_REG_IDX_IN: begin
                        if (s_axi_wstrb[1:0] === '1) begin
                        `ifdef ARITHM_SHIFT
                            interm_res = $signed(s_axi_wdata[15:0]) + (delay_line[d-1] >>> shift);
                        `else
                            interm_res = $signed(s_axi_wdata[15:0]) + (delay_line[d-1] >> shift);
                        `endif
                            for(int i = MAX_D_VALUE; i > 0; i--)
                                delay_line[i] <= delay_line[i-1];                            
                            if (interm_res > 32'sd32767)
                                delay_line[0] <= 32'sd32767;
                            else if (interm_res < -32'sd32768)
                                delay_line[0] <= -32'sd32768;
                            else                                
                                delay_line[0] <= interm_res;
                        end
                    end
                    AXI_REG_IDX_D: begin
                        if (s_axi_wstrb[0] && (s_axi_wdata[7:0] > 0) && (s_axi_wdata[7:0] < MAX_D_VALUE+1)) begin
                            d[7:0] <= s_axi_wdata[7:0];
                        end 
                    end
                    AXI_REG_IDX_SHIFT: begin
                        if (s_axi_wstrb[0] && (s_axi_wdata[7:0] > 0) && (s_axi_wdata[7:0] < MAX_SHIFT_VALUE+1)) begin
                            shift[7:0] <= s_axi_wdata[7:0];
                        end 
                    end
                    AXI_REG_IDX_CTRL: begin
                        if (s_axi_wstrb[0] && s_axi_wdata[7:0] === 8'h01) begin
                            foreach (delay_line[i])
                                delay_line[i] <= '0;
                        end 
                    end
                    default: begin
                    end
                endcase
            end
        end
    end

    // ----------------------------------------------------
    // read logic
    // ----------------------------------------------------
    always_ff @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= AXI_RESP_OKAY;
            s_axi_rdata   <= '0;
            axi_araddr    <= '0;
        end else begin
            // read address
            if (!s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
                axi_araddr    <= s_axi_araddr;
            end else begin
                s_axi_arready <= 1'b0;
            end

            if (s_axi_arready && s_axi_arvalid && !s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                unique case (axi_araddr[AXI_ADDR_WIDTH-1:2])
                    AXI_REG_IDX_OUT: begin
                        s_axi_rdata <= delay_line[0]; 
                        s_axi_rresp <= AXI_RESP_OKAY;
                    end
                    AXI_REG_IDX_D: begin
                        s_axi_rdata <= d; 
                        s_axi_rresp <= AXI_RESP_OKAY;
                    end
                    AXI_REG_IDX_SHIFT: begin
                        s_axi_rdata <= shift; 
                        s_axi_rresp <= AXI_RESP_OKAY;
                    end
                    default: begin
                        s_axi_rdata <= 32'hDEADBEEF; 
                        s_axi_rresp <= AXI_RESP_DECERR;
                    end
                endcase              
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule
