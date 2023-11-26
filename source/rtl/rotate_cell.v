module rotate_cell #(
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
    output [RAM_WIDTH-1:0]        rd_data_1d,
    
    // input                         init_done,
    
    output                        ddr_rreq,
    output [ADDR_WIDTH- 1'b1 : 0] ddr_raddr,
    output [LEN_WIDTH- 1'b1 : 0]  ddr_rd_len,
    // input                         ddr_rrdy,
    input                         ddr_rdone,
    
    input [8*DQ_WIDTH- 1'b1 : 0]  ddr_rdata,
    input                         ddr_rdata_en,
    output reg                    ddr_rdata_ban,
    input [1:0]                   ddr_part,
    output reg [1:0]              rd_cnt,
    input [12:0]                  rd_line,
    input                         rotate_90 /*synthesis PAP_MARK_DEBUG="1"*/ 
);

    localparam SIM            = 1'b0;
    localparam DDR_DATA_WIDTH = DQ_WIDTH * 8;
    localparam WR_LINE_NUM    = H_NUM * PIX_WIDTH/RAM_WIDTH; // RAM中列数
    localparam RD_LINE_NUM    = WR_LINE_NUM * RAM_WIDTH/DDR_DATA_WIDTH; // DDR中列数
    localparam DDR_ADDR_OFFSET= RD_LINE_NUM*DDR_DATA_WIDTH/DQ_WIDTH; // 一行多少个32bit
    // localparam DDR_ADDR_IMAGE = DDR_ADDR_OFFSET*V_NUM; // 一副图像所占的地址空间
    localparam V_START        = V_NUM/2-H_NUM/2; //40
    localparam V_END          = V_NUM/2+H_NUM/2; //680
    //===========================================================================
    reg       rd_fsync_1d;
    wire      rd_rst;
    reg       ddr_rstn_1d,ddr_rstn_2d;
    wire [RAM_WIDTH-1:0]        rd_data_raw;   
    wire [RAM_WIDTH-1:0]        rd_data_reverse; 
    // reg wr_rotate_90_1d, wr_rotate_90_2d;

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
    reg [3:0] wr_line_vld;
    always @(posedge ddr_clk)
    begin
        wr_fsync_1d <= rd_fsync;
        wr_fsync_2d <= wr_fsync_1d;
        wr_fsync_3d <= wr_fsync_2d;
        
        wr_en_1d <= rd_en;
        wr_en_2d <= wr_en_1d;
        wr_en_3d <= wr_en_2d;
        
        wr_trig <= wr_rst || (~wr_en_3d && wr_en_2d && wr_line != V_NUM);

        // wr_rotate_90_1d <= rotate_90;
        // wr_rotate_90_2d <= wr_rotate_90_1d;
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

    reg ddr_rdata_vld;
    always @(posedge ddr_clk) begin
        // if(!wr_rotate_90_2d)
        //     ddr_rdata_vld <= 1'b0;
        if((wr_rst || (~ddr_rstn)))
            ddr_rdata_vld <= 1'b0;
        else if (~wr_en_3d && wr_en_2d)
        begin
            if(wr_line == V_START)
                ddr_rdata_vld <= 1'b1;
            else if(wr_line == V_END)
                ddr_rdata_vld <= 1'b0;
        end 
    end

    reg [3:0] cnt;
    // reg wr_buf_done; // 写完一个buf准备切换
    always @(posedge ddr_clk)
        wr_line_vld <= wr_line - V_START;
    always @(posedge ddr_clk) begin
        if (wr_rst)
            ddr_rdata_ban <= 1'b0;
        else if (!rotate_90)
            ddr_rdata_ban <= 1'b0;
        else if (ddr_rdone && doing && (cnt == 4'd9))
            ddr_rdata_ban <= 1'b1;
        else if ((wr_line_vld == 4'd3) && ddr_rdata_vld) // 写后延3行避免冲突
            ddr_rdata_ban <= 1'b0;
    end

    reg wr_en_buf1;
    reg doing; //  使得wr_cnt在适当的时候累加  
    always @(posedge ddr_clk)
        if(wr_rst)
            cnt <= 4'd0;
        else if (doing && ddr_rdone)
        begin
            if (cnt == 4'd9)
                cnt <= 4'd0;
            else
                cnt <= cnt + 4'd1;
        end 

    // always @(posedge ddr_clk) begin
    //     if (wr_rst)
    //         wr_buf_done <= 1'b0;
    //     else if (ddr_rdone && doing && (cnt == 2'd3)) 
    //         wr_buf_done <= 1'b1;
    //     else if ((wr_addr1 == 16*DDR_ADDR_OFFSET) || (wr_addr2 == 16*DDR_ADDR_OFFSET))
    //         wr_buf_done <= 1'b0;
    // end

    // reg wr_buf_done_1d;
    // always @(posedge ddr_clk) begin
    //     wr_buf_done_1d <= wr_buf_done;
    // end

    always @(posedge ddr_clk) begin
        if(wr_rst)
            wr_en_buf1 <= 1'b1;
        else if(ddr_rdone && doing && (cnt == 4'd9))
            wr_en_buf1 <= ~wr_en_buf1;
    end

    reg [LINE_ADDR_WIDTH - 1'b1 :0] wr_cnt;
    always @(posedge ddr_clk) begin
        if (wr_rst)
            // wr_cnt <= (V_START+1'b1)*DDR_ADDR_OFFSET-22'd8;
            wr_cnt <= 16*DDR_ADDR_OFFSET-22'd128;//256*16/32
        else if (ddr_rdone && doing)
        begin
            if (cnt != 4'd9)
                wr_cnt <= wr_cnt + 64*DDR_ADDR_OFFSET;//4*16*一行
            else
                wr_cnt <= wr_cnt - 576*DDR_ADDR_OFFSET - 22'd128;//64*3
        end 
    end
    
    reg ddr_rdata_en_1d;
    always @(posedge ddr_clk) begin
        ddr_rdata_en_1d <= ddr_rdata_en;
        if (wr_rst) 
            doing <= 1'b0;
        else if (ddr_rdata_en & ~ddr_rdata_en_1d)
            doing <= 1'b1;
        else if (ddr_rdone & doing)
            doing <= 1'b0;
        else
            doing <= doing;
    end

    // always @(posedge vout_clk) begin
    //     wr_en_buf1_1d <= wr_en_buf1;
    //     wr_en_buf1_2d <= wr_en_buf1_1d;
    // end

    // reg ddr_rdata_ban_1d, ddr_rdata_ban_2d, ddr_rdata_ban_3d;
    reg rd_vld;
    always @(posedge vout_clk) begin
        if (rd_rst)
            rd_vld <= 1'b0;
        else if (rd_line == V_START)
            rd_vld <= 1'b1;
        else if (rd_line == V_END)
            rd_vld <= 1'b0;
    end
    reg [3:0] rd_line_vld;
    always @(posedge vout_clk) begin
        rd_line_vld <= rd_line - V_START;
    end
    reg rd_en_buf2;
    reg rd_en_1d;

    always @(posedge vout_clk) begin
        rd_en_1d <= rd_en;
    end
    // always @(posedge vout_clk) begin
    //     ddr_rdata_ban_1d <= ddr_rdata_ban;
    //     ddr_rdata_ban_2d <= ddr_rdata_ban_1d;        
    //     ddr_rdata_ban_3d <= ddr_rdata_ban_2d;
    // end
    always @(posedge vout_clk) begin
        if (rd_rst)
            rd_en_buf2 <= 1'b1;
        else if (rd_en && ~rd_en_1d && (rd_line_vld == 4'd0) && rd_vld)
            rd_en_buf2 <= ~rd_en_buf2; 
    end

    assign ddr_rreq = wr_trig;
    assign ddr_raddr = {wr_frame_cnt[0],ddr_part,wr_cnt} + ADDR_OFFSET;
    assign ddr_rd_len = 16'd64;

    reg  [ 9:0]           wr_addr1;
    reg  [ 9:0]           wr_addr2;
    reg  [12:0]           rd_addr1;
    reg  [12:0]           rd_addr2;
    wire [31:0]           rd_data1;
    wire [31:0]           rd_data2;
    wire                  ddr_rdata_en1;
    wire                  ddr_rdata_en2;
    wire                  rd_en_part1;
    wire                  rd_en_part2;
    reg                   rd_cnt_buf1, rd_cnt_buf2;

    assign ddr_rdata_en1 = wr_en_buf1 ? ddr_rdata_en : 1'b0;
    assign ddr_rdata_en2 =~wr_en_buf1 ? ddr_rdata_en : 1'b0;

    always @(posedge ddr_clk)
    begin
        if(wr_rst)
            wr_addr1 <= (SIM == 1'b1) ? 10'd180 : 10'd0;
        else if(ddr_rdata_en1)
        begin
            if (wr_addr1 == 16*RD_LINE_NUM-1'b1)
                wr_addr1 <= 10'd0;
            else
                wr_addr1 <= wr_addr1 + 10'd1;
        end
        else
            wr_addr1 <= wr_addr1;
    end 
    always @(posedge ddr_clk)
    begin
        if(wr_rst)
            wr_addr2 <= (SIM == 1'b1) ? 10'd180 : 10'd0;
        else if(ddr_rdata_en2)
        begin
            if (wr_addr2 == 16*RD_LINE_NUM-1'b1)
                wr_addr2 <= 10'd0;
            else
                wr_addr2 <= wr_addr2 + 10'd1;
        end
        else
            wr_addr2 <= wr_addr2;
    end 

    rd_rotate_buf rd_rotate_buf1 (
        .wr_data(ddr_rdata),    // input [255:0]
        .wr_addr(wr_addr1),    // input [9:0]
        .wr_en(ddr_rdata_en1),        // input
        .wr_clk(ddr_clk),      // input
        .wr_rst(~ddr_rstn),      // input
        .rd_addr(rd_addr1),    // input [12:0]
        .rd_data(rd_data1),    // output [31:0]
        .rd_clk(vout_clk),      // input
        .rd_rst(~ddr_rstn_2d)       // input
    );

    rd_rotate_buf rd_rotate_buf2 (
        .wr_data(ddr_rdata),    // input [255:0]
        .wr_addr(wr_addr2),    // input [9:0]
        .wr_en(ddr_rdata_en2),        // input
        .wr_clk(ddr_clk),      // input
        .wr_rst(~ddr_rstn),      // input
        .rd_addr(rd_addr2),    // input [12:0]
        .rd_data(rd_data2),    // output [31:0]
        .rd_clk(vout_clk),      // input
        .rd_rst(~ddr_rstn_2d)       // input
    );

    assign rd_data = ~rd_vld ? 32'd0 : (rd_en_buf2 ? rd_data2 : rd_data1); 
    assign rd_en_part1 = (rd_vld & ~rd_en_buf2)? rd_en_part : 1'b0;
    assign rd_en_part2 = (rd_vld & rd_en_buf2) ? rd_en_part : 1'b0;
    // always @(posedge vout_clk)
    // begin
    //     if(rd_en_part)
    //         rd_cnt <= rd_cnt + 1'b1;
    //     else
    //         rd_cnt <= 2'd0;
    // end 

    always @(posedge vout_clk)
    begin
        if(rd_rst)
        begin
            rd_addr1 <= 13'd7;
            rd_cnt_buf1 <= 1'b0;
        end
        else if(rd_en_part1)
        begin
            if (rd_addr1 == 13'd5112)
            begin
                if (rd_cnt_buf1)
                begin
                    rd_cnt_buf1 <= 1'b0;
                    rd_addr1 <= 13'd7;
                end
                else
                begin
                    rd_addr1 <= rd_addr1 - 13'd5112;
                    rd_cnt_buf1 <= ~rd_cnt_buf1;
                end
            end
            else if (rd_addr1 > 13'd5112) // (640-1)*8换行
            begin
                rd_cnt_buf1 <= ~rd_cnt_buf1;
                if (rd_cnt_buf1)
                    rd_addr1 <= rd_addr1 - 13'd5113;
                else
                    rd_addr1 <= rd_addr1 - 13'd5112;
            end
            else
            begin
                rd_cnt_buf1 <= rd_cnt_buf1;
                rd_addr1 <= rd_addr1 + 13'd8;
            end
        end
    end 

    always @(posedge vout_clk)
    begin
        if(rd_rst)
        begin
            rd_addr2 <= 13'd7;
            rd_cnt_buf2 <= 1'b0;
        end
        else if(rd_en_part2)
        begin
            if (rd_addr2 == 13'd5112)
            begin
                if (rd_cnt_buf2)
                begin
                    rd_cnt_buf2 <= 1'b0;
                    rd_addr2 <= 13'd7;
                end
                else
                begin
                    rd_addr2 <= rd_addr2 - 13'd5112;
                    rd_cnt_buf2 <= ~rd_cnt_buf2;
                end
            end
            else if (rd_addr2 > 13'd5112) // (640-1)*8换行
            begin
                rd_cnt_buf2 <= ~rd_cnt_buf2;
                if (rd_cnt_buf2)
                    rd_addr2 <= rd_addr2 - 13'd5113;
                else
                    rd_addr2 <= rd_addr2 - 13'd5112;
            end
            else
            begin
                rd_cnt_buf2 <= rd_cnt_buf2;
                rd_addr2 <= rd_addr2 + 13'd8;
            end
        end
    end 

    always @(posedge vout_clk) begin
        if(rd_rst)
            rd_cnt <= 2'd0;
        else if (~rd_en_buf2)
            rd_cnt <= {1'b0,rd_cnt_buf1};
        else
            rd_cnt <= {1'b0,rd_cnt_buf2};
    end

    assign rd_data_1d = rd_data;         
    // always @(posedge vout_clk)
    // begin
    //     if (rd_en_part)
    //         rd_data_1d <= rd_data;
    //     else
    //         rd_data_1d <= rd_data_1d;
    // end 

    // generate
    //     if (PIX_WIDTH == 6'd24)
    //     begin
    //         assign read_en = rd_en_part && (rd_cnt != 2'd3);
    //     end
    //     else if (PIX_WIDTH == 6'd16) begin
    //         assign read_en = rd_en_part && (rd_cnt[0] != 1'b1);
    //     end
    //     else begin
    //         assign read_en = rd_en_part;
    //     end
    // endgenerate

endmodule