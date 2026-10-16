
module sync_fifo #(
    parameter int DATA_WIDTH = 32,
    parameter int FIFO_DEPTH = 16,
    localparam int ADDR_WIDTH = $clog2(FIFO_DEPTH)
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    wr_en,
    input  logic [DATA_WIDTH-1:0]   din,
    input  logic                    rd_en,
    output logic [DATA_WIDTH-1:0]   dout,
    output logic                    full,
    output logic                    empty
);
    logic [DATA_WIDTH-1:0] memory [FIFO_DEPTH-1:0];
    logic [ADDR_WIDTH:0] wr_ptr;
    logic [ADDR_WIDTH:0] rd_ptr;
    assign empty = (wr_ptr == rd_ptr);
    assign full  = (wr_ptr[ADDR_WIDTH] != rd_ptr[ADDR_WIDTH]) && 
                   (wr_ptr[ADDR_WIDTH-1:0] == rd_ptr[ADDR_WIDTH-1:0]);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
        end else if (wr_en && !full) begin
            memory[wr_ptr[ADDR_WIDTH-1:0]] <= din;
            wr_ptr                         <= wr_ptr + 1'b1;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= '0;
            dout   <= '0;
        end else if (rd_en && !empty) begin
            dout   <= memory[rd_ptr[ADDR_WIDTH-1:0]];
            rd_ptr <= rd_ptr + 1'b1;
        end
    end

endmodule

module axi4_byte_capture #(
    parameter integer FIFO_WORDS = 128,
    parameter integer FRAME_WORDS = 64000
)(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        start,
    input  logic [7:0]  data_in,

    // AXI4-Stream master
    output logic [31:0] m_axis_tdata,
    output logic        m_axis_tvalid,
    input  logic        m_axis_tready,
    output logic [3:0]  m_axis_tkeep,
    output logic        m_axis_tlast
);

    logic capture_active;
    logic [31:0] pack_reg;
    logic [1:0]  byte_count;
    logic [$clog2(FRAME_WORDS)-1:0] word_count;
    
    logic fifo_full;
    logic fifo_empty;
    logic fifo_wr;
    logic fifo_rd;
    
    assign m_axis_tkeep = 4'b1111;
    assign fifo_wr = (byte_count == 2'd0 && !fifo_full && capture_active);
    assign fifo_rd = (m_axis_tready && !fifo_empty);
    
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            capture_active <= 0;
            m_axis_tvalid <= 0;
            m_axis_tlast <= 0;
            byte_count <= 0;
            word_count <= 0;
        end else begin

            if (start || capture_active) begin
                case (byte_count)
                    2'd0: pack_reg[7:0]   <= data_in;
                    2'd1: pack_reg[15:8]  <= data_in;
                    2'd2: pack_reg[23:16] <= data_in;
                    2'd3: pack_reg[31:24] <= data_in;
                endcase
                byte_count <= byte_count + 1'b1;
                capture_active <= 1;
                if (start) begin
                    m_axis_tlast <= 0;
                end  
            end
            
            if (fifo_rd) begin
                if (word_count == FRAME_WORDS-1) begin
                    m_axis_tlast <= 1;
                    capture_active <= 0;
                    byte_count <= 0;
                    word_count <= 0;
                end else begin                
                    word_count <= word_count + 1'b1;
                end
                m_axis_tvalid <= 1;
            end else begin    
                m_axis_tvalid <= 0;
            end
            
        end
    end

    sync_fifo #(
        .FIFO_DEPTH (FIFO_WORDS)
    ) fifo_inst (
        .clk   (clk),
        .rst_n (rst_n || m_axis_tlast),     
        .wr_en (fifo_wr),
        .din   (pack_reg),    
        .rd_en (fifo_rd),
        .dout  (m_axis_tdata),
        .full  (fifo_full),
        .empty (fifo_empty)
    );

    ila_0 #() ila_0_inst (
        .clk(clk),
        .probe0(m_axis_tdata),
        .probe1(start),
        .probe2(m_axis_tready),
        .probe3(m_axis_tvalid),
        .probe4(m_axis_tlast)
    );

endmodule
