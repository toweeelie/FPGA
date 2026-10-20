
module digital_echo #(
    parameter int C_S_AXI_DATA_WIDTH = 32,
    parameter int C_S_AXI_ADDR_WIDTH = 5
)(
    // clk and rst
    input  logic                              S_AXI_ACLK,
    input  logic                              S_AXI_ARESETN,

    // Write Address Channel
    input  logic [C_S_AXI_ADDR_WIDTH-1 : 0]   S_AXI_AWADDR,
    input  logic                              S_AXI_AWVALID,
    output logic                              S_AXI_AWREADY,

    // Write Data Channel
    input  logic [C_S_AXI_DATA_WIDTH-1 : 0]   S_AXI_WDATA,
    input  logic [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  logic                              S_AXI_WVALID,
    output logic                              S_AXI_WREADY,

    // Write Response Channel
    output logic [1 : 0]                      S_AXI_BRESP,
    output logic                              S_AXI_BVALID,
    input  logic                              S_AXI_BREADY,

    // Read Address Channel
    input  logic [C_S_AXI_ADDR_WIDTH-1 : 0]   S_AXI_ARADDR,
    input  logic                              S_AXI_ARVALID,
    output logic                              S_AXI_ARREADY,

    // Read Data Channel
    output logic [C_S_AXI_DATA_WIDTH-1 : 0]   S_AXI_RDATA,
    output logic [1 : 0]                      S_AXI_RRESP,
    output logic                              S_AXI_RVALID,
    input  logic                              S_AXI_RREADY
);

    // AXI responses
    typedef enum logic [1:0] {
        AXI_RESP_OKAY   = 2'b00,
        AXI_RESP_EXOKAY = 2'b01,
        AXI_RESP_SLVERR = 2'b10,
        AXI_RESP_DECERR = 2'b11
    } axi_resp_e;
    
    typedef enum logic [2:0] {
        AXI_REG_IDX_IN,
        AXI_REG_IDX_OUT,
        AXI_REG_IDX_D,
        AXI_REG_IDX_SHIFT,
        AXI_REG_IDX_CTRL,
        AXI_REG_IDX_SIZEOF
    } axi_reg_idx_e;
    
    // registers
    logic [C_S_AXI_DATA_WIDTH-1:0] slv_regs [AXI_REG_IDX_SIZEOF-1:0];

    // addresses
    logic [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    logic [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;

    // ----------------------------------------------------
    // write logic
    // ----------------------------------------------------
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_AWREADY <= 1'b0;
            S_AXI_WREADY  <= 1'b0;
            S_AXI_BVALID  <= 1'b0;
            S_AXI_BRESP   <= AXI_RESP_OKAY;
            axi_awaddr    <= '0;
        end else begin
            // ready to get addr and data
            if (!S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WVALID) begin
                S_AXI_AWREADY <= 1'b1;
                S_AXI_WREADY  <= 1'b1;
                axi_awaddr    <= S_AXI_AWADDR;
            end else begin
                S_AXI_AWREADY <= 1'b0;
                S_AXI_WREADY  <= 1'b0;
            end

            // BVALID generation
            if (S_AXI_AWREADY && S_AXI_AWVALID && S_AXI_WREADY && S_AXI_WVALID) begin
                S_AXI_BVALID <= 1'b1;
                S_AXI_BRESP  <= AXI_RESP_OKAY;
            end else if (S_AXI_BREADY && S_AXI_BVALID) begin
                S_AXI_BVALID <= 1'b0;
            end
        end
    end

    // ----------------------------------------------------
    // write to inner regs
    // ----------------------------------------------------
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            foreach (slv_regs[i])
                slv_regs[i] <= '0;
        end else begin
            if (S_AXI_WREADY && S_AXI_WVALID && S_AXI_AWREADY && S_AXI_AWVALID) begin
                logic w_idx = axi_awaddr[C_S_AXI_ADDR_WIDTH-1:2];
                if (w_idx < AXI_REG_IDX_SIZEOF) begin
                    foreach (S_AXI_WSTRB[i])
                        if (S_AXI_WSTRB[i]) slv_regs[w_idx][(i*8)+:8] <= S_AXI_WDATA[(i*8)+:8];
                end
            end
        end
    end

    // ----------------------------------------------------
    // read logic
    // ----------------------------------------------------
    always_ff @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            S_AXI_ARREADY <= 1'b0;
            S_AXI_RVALID  <= 1'b0;
            S_AXI_RRESP   <= AXI_RESP_OKAY;
            S_AXI_RDATA   <= '0;
            axi_araddr    <= '0;
        end else begin
            // read address
            if (!S_AXI_ARREADY && S_AXI_ARVALID) begin
                S_AXI_ARREADY <= 1'b1;
                axi_araddr    <= S_AXI_ARADDR;
            end else begin
                S_AXI_ARREADY <= 1'b0;
            end

            if (S_AXI_ARREADY && S_AXI_ARVALID && !S_AXI_RVALID) begin
                logic r_idx = axi_araddr[C_S_AXI_ADDR_WIDTH-1:2];
                S_AXI_RVALID <= 1'b1;
                if (r_idx < AXI_REG_IDX_SIZEOF) begin
                    S_AXI_RDATA <= slv_regs[r_idx]; 
                    S_AXI_RRESP <= AXI_RESP_OKAY;
                end else begin
                    S_AXI_RDATA <= 32'hDEADBEEF; 
                    S_AXI_RRESP <= AXI_RESP_DECERR;
                end               
            end else if (S_AXI_RVALID && S_AXI_RREADY) begin
                S_AXI_RVALID <= 1'b0;
            end
        end
    end

endmodule
