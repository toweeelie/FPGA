module axi4_byte_capture #(
    parameter integer FIFO_WORDS = 2048,
    parameter integer FRAME_WORDS = 64000
)(
    input  wire        clk,
    input  wire        rst_n,

    // Start capture on rising edge
    input  wire        start,

    // Continuous input byte stream
    input  wire [7:0]  data_in,

    // AXI4-Stream master -> AXI DMA S_AXIS_S2MM
    output reg  [31:0] m_axis_tdata,
    output reg         m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire [3:0]  m_axis_tkeep,
    output reg         m_axis_tlast
);

    localparam integer PTR_WIDTH   = $clog2(FIFO_WORDS);
    localparam integer COUNT_WIDTH = $clog2(FIFO_WORDS + 1);

    assign m_axis_tkeep = 4'b1111;

    // FIFO: complete 32-bit words
    reg [31:0] fifo_mem [0:FIFO_WORDS-1];

    reg [PTR_WIDTH-1:0]   wr_ptr;
    reg [PTR_WIDTH-1:0]   rd_ptr;
    reg [COUNT_WIDTH-1:0] fifo_count;

    // Byte packer: first byte goes into bits [7:0]
    reg [31:0] pack_reg;
    reg [1:0]  byte_count;

    // Capture state
    reg        capture_active;
    reg [31:0] captured_words;
    reg [31:0] loaded_words;

    // Synchronize external start signal to clk
    reg start_meta;
    reg start_sync;
    reg start_sync_d;

    wire start_rise = start_sync && !start_sync_d;

    // AXI stream handshake
    wire output_slot_available =
        !m_axis_tvalid || m_axis_tready;

    wire fifo_pop =
        output_slot_available && (fifo_count != 0);

    wire fifo_push =
        capture_active &&
        (byte_count == 2'd3) &&
        (fifo_count < FIFO_WORDS);

    always @(posedge clk) begin
        if (!rst_n) begin
            start_meta   <= 1'b0;
            start_sync   <= 1'b0;
            start_sync_d <= 1'b0;
        end else begin
            start_meta   <= start;
            start_sync   <= start_meta;
            start_sync_d <= start_sync;
        end
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr         <= 0;
            rd_ptr         <= 0;
            fifo_count     <= 0;

            pack_reg       <= 0;
            byte_count     <= 0;

            capture_active <= 0;
            captured_words <= 0;
            loaded_words   <= 0;

            m_axis_tdata   <= 0;
            m_axis_tvalid  <= 0;
            m_axis_tlast   <= 0;
        end else if (start_rise) begin
            // Start a new frame and clear previous-frame state
            wr_ptr         <= 0;
            rd_ptr         <= 0;
            fifo_count     <= 0;

            pack_reg       <= 0;
            byte_count     <= 0;

            capture_active <= 1;
            captured_words <= 0;
            loaded_words   <= 0;

            m_axis_tdata   <= 0;
            m_axis_tvalid  <= 0;
            m_axis_tlast   <= 0;
        end else begin

            // Capture and pack four consecutive bytes
            if (capture_active) begin
                case (byte_count)
                    2'd0: pack_reg[7:0]   <= data_in;
                    2'd1: pack_reg[15:8]  <= data_in;
                    2'd2: pack_reg[23:16] <= data_in;
                    2'd3: pack_reg[31:24] <= data_in;
                endcase

                byte_count <= byte_count + 1'b1;

                if (byte_count == 2'd3 && fifo_push) begin
                    fifo_mem[wr_ptr] <= {
                        data_in,
                        pack_reg[23:0]
                    };

                    wr_ptr <= wr_ptr + 1'b1;
                    captured_words <= captured_words + 1'b1;

                    if (captured_words == FRAME_WORDS - 1)
                        capture_active <= 1'b0;
                end
            end

            // Load a word into the AXI output register.
            // TLAST is attached to the final word and held during stalls.
            if (fifo_pop) begin
                m_axis_tdata  <= fifo_mem[rd_ptr];
                m_axis_tvalid <= 1'b1;
                m_axis_tlast  <= (loaded_words == FRAME_WORDS - 1);

                rd_ptr       <= rd_ptr + 1'b1;
                loaded_words <= loaded_words + 1'b1;
            end else if (output_slot_available) begin
                m_axis_tvalid <= 1'b0;
                m_axis_tlast  <= 1'b0;
            end

            // Update FIFO occupancy
            case ({fifo_push, fifo_pop})
                2'b10: fifo_count <= fifo_count + 1'b1;
                2'b01: fifo_count <= fifo_count - 1'b1;
                default: fifo_count <= fifo_count;
            endcase
        end
    end

endmodule
