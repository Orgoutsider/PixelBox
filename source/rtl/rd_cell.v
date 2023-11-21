module rd_cell #(
    parameter                     ADDR_WIDTH      = 6'd27,
    parameter                     ADDR_OFFSET     = 32'h0000_0000,
    parameter                     H_NUM           = 12'd1920,
    parameter                     V_NUM           = 12'd1080,
    parameter                     DQ_WIDTH        = 12'd32,
    parameter                     LEN_WIDTH       = 12'd16,
    parameter                     PIX_WIDTH       = 12'd24,
    parameter                     LINE_ADDR_WIDTH = 16'd19,
    parameter                     FRAME_CNT_WIDTH = 16'd8,
    parameter                     RAM_WIDTH       = 16'd32
)  (
    input                         ddr_clk,
    input                         ddr_rstn,
    
    input                         vout_clk,
    input                         rd_fsync,
    input                         rd_en,
    input                         rd_en_part,
    output [RAM_WIDTH-1:0]        rd_data,
    output reg [RAM_WIDTH-1:0]        rd_data_1d,
    
    // input                         init_done,
    
    output                        ddr_rreq,
    output [ADDR_WIDTH- 1'b1 : 0] ddr_raddr,
    output [LEN_WIDTH- 1'b1 : 0]  ddr_rd_len,
    // input                         ddr_rrdy,
    input                         ddr_rdone,
    
    input [8*DQ_WIDTH- 1'b1 : 0]  ddr_rdata,
    input                         ddr_rdata_en,
    input [1:0]                        ddr_part,
    output reg [1:0]              rd_cnt,
    input                         rotate_180   
   );

    localparam SIM            = 1'b0;
    localparam DDR_DATA_WIDTH = DQ_WIDTH * 8;
    localparam WR_LINE_NUM    = H_NUM * PIX_WIDTH/RAM_WIDTH; // RAM中列数
    localparam RD_LINE_NUM    = WR_LINE_NUM * RAM_WIDTH/DDR_DATA_WIDTH; // DDR中列数
    localparam DDR_ADDR_OFFSET= RD_LINE_NUM*DDR_DATA_WIDTH/DQ_WIDTH; // 一列多少个32bit
    localparam DDR_ADDR_IMAGE = DDR_ADDR_OFFSET*V_NUM; // 一副图像所占的地址空间
    
    //===========================================================================
    reg       rd_fsync_1d;
    wire      rd_rst;
    reg       ddr_rstn_1d,ddr_rstn_2d;
    wire [RAM_WIDTH-1:0]        rd_data_raw;   
    wire [RAM_WIDTH-1:0]        rd_data_reverse; 
    reg rotate_180_1d, rotate_180_2d;
    reg wr_rotate_180_1d, wr_rotate_180_2d;

    always @(posedge vout_clk) begin
        rotate_180_1d <= rotate_180;
        rotate_180_2d <= rotate_180_1d;
    end  

    always @(posedge vout_clk)
    begin
        rd_fsync_1d <= rd_fsync;
        ddr_rstn_1d <= ddr_rstn;
        ddr_rstn_2d <= ddr_rstn_1d;
    end 
    assign rd_rst = ~rd_fsync_1d & rd_fsync;

    //===========================================================================
    reg      wr_fsync_1d,wr_fsync_2d,wr_fsync_3d;
    wire     wr_rst;
    
    reg      wr_en_1d,wr_en_2d,wr_en_3d;
    reg      wr_trig;
    reg [11:0] wr_line;
    always @(posedge ddr_clk)
    begin
        wr_fsync_1d <= rd_fsync;
        wr_fsync_2d <= wr_fsync_1d;
        wr_fsync_3d <= wr_fsync_2d;
        
        wr_en_1d <= rd_en;
        wr_en_2d <= wr_en_1d;
        wr_en_3d <= wr_en_2d;
        
        wr_trig <= wr_rst || (~wr_en_3d && wr_en_2d && wr_line != V_NUM);

        wr_rotate_180_1d <= rotate_180;
        wr_rotate_180_2d <= wr_rotate_180_1d;
    end 
    always @(posedge ddr_clk)
    begin
        if(wr_rst || (~ddr_rstn))
            wr_line <= 12'd1;
        else if(wr_trig)
            wr_line <= wr_line + 12'd1;
    end 
    
    assign wr_rst = ~wr_fsync_3d && wr_fsync_2d;
    
    //==========================================================================
    reg [FRAME_CNT_WIDTH - 1'b1 :0] wr_frame_cnt=0;
    always @(posedge ddr_clk)
    begin 
        if(wr_rst)
            wr_frame_cnt <= wr_frame_cnt + 1'b1;
        else
            wr_frame_cnt <= wr_frame_cnt;
    end 

    reg ddr_rdata_en_1d;
    reg [LINE_ADDR_WIDTH - 1'b1 :0] wr_cnt;
    reg doing;
     //  使得wr_cnt在适当的时候累加 
    always @(posedge ddr_clk)
    begin 
        if(wr_rst) begin
            if(!wr_rotate_180_2d)
                wr_cnt <= {LINE_ADDR_WIDTH{1'b0}};
            else
                wr_cnt <= DDR_ADDR_IMAGE - DDR_ADDR_OFFSET;
            doing <= 1'b0;
        end
        else if (ddr_rdata_en && ~ddr_rdata_en_1d) begin
            wr_cnt <= wr_cnt;
            doing <= 1'b1;
        end
        else if(ddr_rdone && doing) begin
            if(!wr_rotate_180_2d)
                wr_cnt <= wr_cnt + DDR_ADDR_OFFSET;
            else
                wr_cnt <= wr_cnt - DDR_ADDR_OFFSET;
            doing <= 1'b0;
        end
        else begin
            wr_cnt <= wr_cnt;
            doing <= doing;
        end
    end 
    
    // always @(posedge ddr_clk) begin
    //     if (wr_rst || (~wr_en_3d && wr_en_2d && wr_line != V_NUM)) 
    //         ddr_rreq <= 1'b1;
    //     else if (ddr_rdata_en)
    //         ddr_rreq <= 1'b0;
    //     else
    //         ddr_rreq <= ddr_rreq;
    // end
    assign ddr_rreq = wr_trig;

    assign ddr_raddr = {wr_frame_cnt[0],ddr_part,wr_cnt} + ADDR_OFFSET;
    assign ddr_rd_len = RD_LINE_NUM;
    
    reg  [ 8:0]           wr_addr;
    reg  [11:0]           rd_addr;
    
    //===========================================================================
    always @(posedge ddr_clk)
    begin
        if(wr_rst)
            wr_addr <= (SIM == 1'b1) ? 9'd180 : 9'd0;
        else if(ddr_rdata_en)
            wr_addr <= wr_addr + 9'd1;
        else
            wr_addr <= wr_addr;
    end 

    always @(posedge ddr_clk) begin
        if (wr_rst)
            ddr_rdata_en_1d <= 1'b0;
        else
            ddr_rdata_en_1d <= ddr_rdata_en;
    end

    rd_fram_buf rd_fram_buf (
        .wr_data    (  ddr_rdata       ),// input [255:0]            
        .wr_addr    (  wr_addr         ),// input [8:0]              
        .wr_en      (  ddr_rdata_en    ),// input                    
        .wr_clk     (  ddr_clk         ),// input                    
        .wr_rst     (  ~ddr_rstn       ),// input                    
        .rd_addr    (  rd_addr         ),// input [11:0]             
        .rd_data    (  rd_data_raw         ),// output [31:0]            
        .rd_clk     (  vout_clk        ),// input                    
        .rd_rst     (  ~ddr_rstn_2d    ) // input                    
    );

    assign rd_data_reverse = {rd_data_raw[15:0],rd_data_raw[31:16]};
    assign rd_data = rotate_180_2d ? rd_data_reverse : rd_data_raw;

    // rd_fifo_buf rd_fifo_buf (
    //     .wr_clk(ddr_clk),                    // input
    //     .wr_rst(~ddr_rstn),                    // input
    //     .wr_en(ddr_rdata_en),                      // input
    //     .wr_data(ddr_rdata),                  // input [255:0]
    //     .wr_full(),                  // output
    //     .wr_water_level(),    // output [9:0]
    //     .almost_full(),          // output
    //     .rd_clk(vout_clk),                    // input
    //     .rd_rst(~ddr_rstn_2d),                    // input
    //     .rd_en(rd_en),                      // input
    //     .rd_data(rd_data),                  // output [31:0]
    //     .rd_empty(),                // output
    //     .rd_water_level(),    // output [12:0]
    //     .almost_empty()         // output
    // );

    wire      read_en;
    always @(posedge vout_clk)
    begin
        if(rd_en_part)
            rd_cnt <= rd_cnt + 1'b1;
        else
            rd_cnt <= 2'd0;
    end 

    reg rd_en_1d, rd_en_2d;

    always @(posedge vout_clk) begin
        rd_en_1d <= rd_en;
        rd_en_2d <= rd_en_1d;
    end
    
    always @(posedge vout_clk)
    begin
        if(rd_rst)
        begin
            if(!rotate_180_2d)
                rd_addr <= 'd0;
            else
                rd_addr <= DDR_ADDR_OFFSET - 1'b1;
        end
        else if(read_en)
        begin
            if(!rotate_180_2d)
                rd_addr <= rd_addr + 1'b1;
            else
                rd_addr <= rd_addr - 1'b1;
        end
        else if (rotate_180_2d & ~rd_en_1d & rd_en_2d)
            rd_addr <= rd_addr + 2*DDR_ADDR_OFFSET;
        else
            rd_addr <= rd_addr;
    end 
         
    always @(posedge vout_clk)
    begin
        if (rd_en_part)
            rd_data_1d <= rd_data;
        else
            rd_data_1d <= rd_data_1d;
    end 

    generate
        if (PIX_WIDTH == 6'd24)
        begin
            assign read_en = rd_en_part && (rd_cnt != 2'd3);
        end
        else if (PIX_WIDTH == 6'd16) begin
            assign read_en = rd_en_part && (rd_cnt[0] != 1'b1);
        end
        else begin
            assign read_en = rd_en_part;
        end
    endgenerate
endmodule