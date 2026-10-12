module axi4_byte_capture #(
    parameter integer FIFO_WORDS = 65536,
    parameter integer FRAME_WORDS = 64000
)(
    input  wire        clk,
    input  wire        rst_n,

    // Continuous 8-bit input
    input  wire [7:0]  data_in,

    // AXI4-Lite slave: MicroBlaze
    input  wire [7:0]  s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,

    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,

    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,

    input  wire [7:0]  s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,

    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,

    // AXI4-Stream master
    output reg  [31:0] m_axis_tdata,
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire [3:0]  m_axis_tkeep,
    output reg         m_axis_tlast
);

    // FIFO_WORDS must be a power of two and >= 2.
    localparam integer PTR_W = $clog2(FIFO_WORDS);
    localparam integer CNT_W = $clog2(FIFO_WORDS + 1);
    localparam integer FRAME_CNT_W =
        (FRAME_WORDS > 1) ? $clog2(FRAME_WORDS) : 1;

    // ---------------------------------------------------------
    // AXI4-Lite control registers
    //
    // 0x00: bit 0 = capture enable
    // 0x04: bit 1 = overflow status (read)
    //       bit 0 = clear overflow (write 1)
    // 0x08: FIFO occupancy in 32-bit words (read)
    // ---------------------------------------------------------

    reg capture_enable;
    reg overflow;

    reg        aw_held;
    reg        w_held;
    reg [7:0]  awaddr_reg;
    reg [31:0] wdata_reg;
    reg [3:0]  wstrb_reg;

    wire aw_fire = s_axi_awvalid && s_axi_awready;
    wire w_fire  = s_axi_wvalid  && s_axi_wready;

    wire write_fire =
        (aw_held || aw_fire) &&
        (w_held  || w_fire)  &&
        !s_axi_bvalid;

    wire [7:0] write_addr =
        aw_held ? awaddr_reg : s_axi_awaddr;

    wire [31:0] write_data =
        w_held ? wdata_reg : s_axi_wdata;

    wire [3:0] write_strb =
        w_held ? wstrb_reg : s_axi_wstrb;

    assign s_axi_awready = !aw_held && !s_axi_bvalid;
    assign s_axi_wready  = !w_held  && !s_axi_bvalid;
    assign s_axi_arready = !s_axi_rvalid;

    assign m_axis_tkeep = 4'b1111;

    // ---------------------------------------------------------
    // 32-bit word FIFO
    // ---------------------------------------------------------

    (* ram_style = "block" *)
    reg [31:0] fifo_mem [0:FIFO_WORDS-1];

    reg [PTR_W-1:0] wr_ptr;
    reg [PTR_W-1:0] rd_ptr;
    reg [CNT_W-1:0] fifo_count;

    // Assemble four consecutive bytes into one word.
    // First byte captured goes into bits [7:0].
    reg [31:0] pack_data;
    reg [1:0]  byte_index;

    // Output register can accept a word if empty or
    // if the current word is being consumed.
    wire output_slot = !m_axis_tvalid || m_axis_tready;

    wire fifo_pop = output_slot && (fifo_count != 0);

    // A complete input word is ready every four input clocks.
    // If the FIFO is full, a simultaneous output transfer
    // allows a replacement word to be written.
    wire fifo_push =
        capture_enable &&
        (byte_index == 2'd3) &&
        ((fifo_count < FIFO_WORDS) || fifo_pop);

    reg [FRAME_CNT_W-1:0] frame_count;

    // ---------------------------------------------------------
    // Sequential logic
    // ---------------------------------------------------------

    always @(posedge clk) begin
        if (!rst_n) begin
            capture_enable <= 1'b0;
            overflow       <= 1'b0;

            aw_held        <= 1'b0;
            w_held         <= 1'b0;
            awaddr_reg     <= 8'd0;
            wdata_reg      <= 32'd0;
            wstrb_reg      <= 4'd0;

            s_axi_bresp    <= 2'b00;
            s_axi_bvalid   <= 1'b0;

            s_axi_rdata    <= 32'd0;
            s_axi_rresp    <= 2'b00;
            s_axi_rvalid   <= 1'b0;

            wr_ptr         <= '0;
            rd_ptr         <= '0;
            fifo_count     <= '0;

            pack_data      <= 32'd0;
            byte_index     <= 2'd0;

            m_axis_tdata   <= 32'd0;
            m_axis_tvalid  <= 1'b0;
            m_axis_tlast   <= 1'b0;

            frame_count    <= '0;

        end else begin

            // -------------------------------------------------
            // AXI4-Lite write address and data channels
            // -------------------------------------------------

            if (aw_fire) begin
                awaddr_reg <= s_axi_awaddr;
                aw_held    <= 1'b1;
            end

            if (w_fire) begin
                wdata_reg <= s_axi_wdata;
                wstrb_reg <= s_axi_wstrb;
                w_held    <= 1'b1;
            end

            if (write_fire) begin
                aw_held      <= 1'b0;
                w_held       <= 1'b0;

                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;

                case (write_addr)
                    8'h00: begin
                        if (write_strb[0])
                            capture_enable <= write_data[0];
                    end

                    8'h04: begin
                        if (write_strb[0] && write_data[0])
                            overflow <= 1'b0;
                    end

                    default: begin
                        s_axi_bresp <= 2'b10; // SLVERR
                    end
                endcase
            end

            if (s_axi_bvalid && s_axi_bready)
                s_axi_bvalid <= 1'b0;

            // -------------------------------------------------
            // AXI4-Lite read channel
            // -------------------------------------------------

            if (s_axi_arvalid && s_axi_arready) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00;

                case (s_axi_araddr)
                    8'h00:
                        s_axi_rdata <= {31'd0, capture_enable};

                    8'h04:
                        s_axi_rdata <= {
                            30'd0, overflow, capture_enable
                        };

                    8'h08:
                        s_axi_rdata <= fifo_count;

                    default: begin
                        s_axi_rdata <= 32'd0;
                        s_axi_rresp <= 2'b10; // SLVERR
                    end
                endcase
            end

            if (s_axi_rvalid && s_axi_rready)
                s_axi_rvalid <= 1'b0;

            // -------------------------------------------------
            // Capture continuous 8-bit input
            // -------------------------------------------------

            if (capture_enable) begin
                case (byte_index)
                    2'd0: begin
                        pack_data[7:0] <= data_in;
                        byte_index <= 2'd1;
                    end

                    2'd1: begin
                        pack_data[15:8] <= data_in;
                        byte_index <= 2'd2;
                    end

                    2'd2: begin
                        pack_data[23:16] <= data_in;
                        byte_index <= 2'd3;
                    end

                    2'd3: begin
                        // Fourth byte completes the word.
                        byte_index <= 2'd0;

                        if (fifo_push) begin
                            fifo_mem[wr_ptr] <= {
                                data_in,
                                pack_data[23:0]
                            };

                            wr_ptr <= wr_ptr + 1'b1;
                        end else begin
                            // Input cannot be paused.
                            // This complete word is lost.
                            overflow <= 1'b1;
                        end
                    end
                endcase
            end

            // -------------------------------------------------
            // AXI4-Stream output
            // -------------------------------------------------

            if (fifo_pop) begin
                // Registered FIFO read. The output register
                // holds its word during downstream backpressure.
                m_axis_tdata  <= fifo_mem[rd_ptr];
                m_axis_tvalid <= 1'b1;

                // TLAST marks the final word of each frame.
                m_axis_tlast <=
                    (frame_count == FRAME_WORDS - 1);

                rd_ptr <= rd_ptr + 1'b1;

                if (frame_count == FRAME_WORDS - 1)
                    frame_count <= '0;
                else
                    frame_count <= frame_count + 1'b1;

            end else if (m_axis_tvalid && m_axis_tready) begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast  <= 1'b0;
            end

            // -------------------------------------------------
            // FIFO occupancy
            // -------------------------------------------------

            case ({fifo_push, fifo_pop})
                2'b10: fifo_count <= fifo_count + 1'b1;
                2'b01: fifo_count <= fifo_count - 1'b1;
                default: ;
            endcase
        end
    end

endmodule