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
    parameter int AXI_ADDR_WIDTH = 5
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

    // registers
    logic [AXI_DATA_WIDTH-1:0] slv_regs [AXI_REG_IDX_SIZEOF-1:0];

    // addresses
    logic [AXI_ADDR_WIDTH-1:0] axi_awaddr;
    logic [AXI_ADDR_WIDTH-1:0] axi_araddr;

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
            foreach (slv_regs[i])
                slv_regs[i] <= '0;
        end else begin
            if (s_axi_wready && s_axi_wvalid && s_axi_awready && s_axi_awvalid) begin
                logic w_idx = axi_awaddr[AXI_ADDR_WIDTH-1:2];
                if (w_idx < AXI_REG_IDX_SIZEOF) begin
                    foreach (s_axi_wstrb[i])
                        if (s_axi_wstrb[i]) slv_regs[w_idx][(i*8)+:8] <= s_axi_wdata[(i*8)+:8];
                end
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
                logic r_idx = axi_araddr[AXI_ADDR_WIDTH-1:2];
                s_axi_rvalid <= 1'b1;
                if (r_idx < AXI_REG_IDX_SIZEOF) begin
                    s_axi_rdata <= slv_regs[r_idx]; 
                    s_axi_rresp <= AXI_RESP_OKAY;
                end else begin
                    s_axi_rdata <= 32'hDEADBEEF; 
                    s_axi_rresp <= AXI_RESP_DECERR;
                end               
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule
