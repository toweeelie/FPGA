
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

    // registers
    logic [C_S_AXI_DATA_WIDTH-1:0] slv_reg0; // IN
    logic [C_S_AXI_DATA_WIDTH-1:0] slv_reg1; // OUT
    logic [C_S_AXI_DATA_WIDTH-1:0] slv_reg2; // D
    logic [C_S_AXI_DATA_WIDTH-1:0] slv_reg3; // SHIFT
    logic [C_S_AXI_DATA_WIDTH-1:0] slv_reg4; // CTRL

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
            slv_reg0 <= '0;
            slv_reg1 <= '0;
            slv_reg2 <= '0;
            slv_reg3 <= '0;
            slv_reg4 <= '0;
        end else begin
            if (S_AXI_WREADY && S_AXI_WVALID && S_AXI_AWREADY && S_AXI_AWVALID) begin
                unique case (axi_awaddr[C_S_AXI_ADDR_WIDTH-1:2])
                    2'h0: begin
                        foreach (S_AXI_WSTRB[i])
                            if (S_AXI_WSTRB[i]) slv_reg0[(i*8)+:8] <= S_AXI_WDATA[(i*8)+:8];
                    end
                    2'h1: begin
                        foreach (S_AXI_WSTRB[i])
                            if (S_AXI_WSTRB[i]) slv_reg1[(i*8)+:8] <= S_AXI_WDATA[(i*8)+:8];
                    end
                    2'h2: begin
                        foreach (S_AXI_WSTRB[i])
                            if (S_AXI_WSTRB[i]) slv_reg2[(i*8)+:8] <= S_AXI_WDATA[(i*8)+:8];
                    end
                    2'h3: begin
                        foreach (S_AXI_WSTRB[i])
                            if (S_AXI_WSTRB[i]) slv_reg3[(i*8)+:8] <= S_AXI_WDATA[(i*8)+:8];
                    end
                    2'h3: begin
                        foreach (S_AXI_WSTRB[i])
                            if (S_AXI_WSTRB[i]) slv_reg3[(i*8)+:8] <= S_AXI_WDATA[(i*8)+:8];
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
                S_AXI_RVALID <= 1'b1;
                
                unique case (axi_araddr[C_S_AXI_ADDR_WIDTH-1:2])
                    2'h0   : begin S_AXI_RDATA <= slv_reg0; S_AXI_RRESP <= AXI_RESP_OKAY; end
                    2'h1   : begin S_AXI_RDATA <= slv_reg1; S_AXI_RRESP <= AXI_RESP_OKAY; end
                    2'h2   : begin S_AXI_RDATA <= slv_reg2; S_AXI_RRESP <= AXI_RESP_OKAY; end
                    2'h3   : begin S_AXI_RDATA <= slv_reg3; S_AXI_RRESP <= AXI_RESP_OKAY; end
                    2'h4   : begin S_AXI_RDATA <= slv_reg3; S_AXI_RRESP <= AXI_RESP_OKAY; end
                    default: begin S_AXI_RDATA <= 32'hDEADBEEF; S_AXI_RRESP <= AXI_RESP_DECERR; end // wrong address handling
                endcase
            end else if (S_AXI_RVALID && S_AXI_RREADY) begin
                S_AXI_RVALID <= 1'b0;
            end
        end
    end

endmodule
