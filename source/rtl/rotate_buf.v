module rotate_buf#(
    parameter                     ADDR_WIDTH      = 6'd27,
    parameter                     ADDR_OFFSET     = 32'h0000_0000,
    parameter                     H_NUM           = 12'd1920,
    parameter                     V_NUM           = 12'd1080,
    parameter                     DQ_WIDTH        = 12'd32,
    parameter                     LEN_WIDTH       = 12'd16,
    parameter                     PIX_WIDTH       = 12'd16,
    parameter                     LINE_ADDR_WIDTH = 16'd22,
    parameter                     FRAME_CNT_WIDTH = 16'd8
) (
    input                         ddr_clk,
    input                         ddr_rstn,
    output [ADDR_WIDTH- 1'b1 : 0] ddr_raddr  /* synthesis PAP_MARK_DEBUG="true" */, 
    output [LEN_WIDTH- 1'b1 : 0]  ddr_rd_len  /* synthesis PAP_MARK_DEBUG="true" */,
    input                         ddr_rdone  /* synthesis PAP_MARK_DEBUG="true" */,
    input [8*DQ_WIDTH- 1'b1 : 0]  ddr_rdata,
    input                         ddr_rdata_en  /* synthesis PAP_MARK_DEBUG="true" */,
    input [1:0]                   ddr_part_wr,
    output                        ddr_wreq,
    output [ADDR_WIDTH- 1'b1 : 0] ddr_waddr,
    output [LEN_WIDTH- 1'b1 : 0]  ddr_wr_len,
    input                         ddr_wdone,
    output [8*DQ_WIDTH- 1'b1 : 0] ddr_wdata,
    input                         ddr_wdata_req,
    input  [1:0]                  ddr_part_rd,
    input                         frame_wcnt,
    output                        frame_wcnt_out
    // output reg                    ddr_rdata_ban 
);

    localparam RAM_WIDTH      = 16'd32;
    localparam DDR_DATA_WIDTH = DQ_WIDTH * 8;
    localparam WR_LINE_NUM    = H_NUM * PIX_WIDTH/RAM_WIDTH; // RAM中列数
    localparam RD_LINE_NUM    = WR_LINE_NUM * RAM_WIDTH/DDR_DATA_WIDTH; // DDR中列数
    localparam DDR_ADDR_OFFSET= RD_LINE_NUM*DDR_DATA_WIDTH/DQ_WIDTH; // 一列多少个32bit

    reg [12:0]  x_cnt;
    reg [12:0]  y_cnt;
    reg [3:0] cnt; // 16次一计数
    // wire [31:0]  x_rotate;
    // wire [31:0]  y_rotate;
    // reg [31:0]  x_rotate_reg;
    // reg [31:0]  y_rotate_reg;
    reg doing;
    reg ddr_rdata_en_1d;
    wire [LINE_ADDR_WIDTH - 1'b1 :0] wr_cnt;
    reg [LINE_ADDR_WIDTH:0] pix_cnt;
    reg [7:0] wr_addr;
    reg [7:0] rd_addr=8'd0;
    wire rst;
    // reg frame_invld;
    // wire [DDR_DATA_WIDTH-1'b1:0] rd_data;
    // wire [15:0] wr_data;
    assign rst = doing_w & ddr_rdata_en & ~ddr_rdata_en_1d;

    always @(posedge ddr_clk) begin
        ddr_rdata_en_1d <= ddr_rdata_en;
    end

    always @(posedge ddr_clk) begin
        if (~ddr_rstn | rst)
            cnt <= 4'd0;
        else if (ddr_rdone & doing) begin
            cnt <= cnt + 4'd1;
        end
    end

    // always @(posedge ddr_clk) begin
    //     if(~ddr_rstn)
    //         frame_invld <= 1'b0;
    //     else if(rst)
    //         frame_invld <= 1'b1;
    //     else if(ddr_wdone & doing_w & rd_img) 
    //         frame_invld <= 1'b0;
    // end

    //  使得wr_cnt在适当的时候累加 
    always @(posedge ddr_clk) begin
        if(~ddr_rstn)
            doing <= 1'b0;
        else if (rst)
            doing <= 1'b1;
        else if (ddr_rdata_en && ~ddr_rdata_en_1d) begin
            doing <= 1'b1;
        end 
        else if (ddr_rdone & doing)
            doing <= 1'b0;
        else
            doing <= doing;
    end
    
    always @(posedge ddr_clk) begin
        if(~ddr_rstn | rst)
            x_cnt <= 13'd0;
        else if (ddr_rdone && doing && (cnt == 4'd15)) begin
            if (x_cnt + 13'd256 > H_NUM - 13'd1)
                x_cnt <= 13'd0;
            else
                x_cnt <= x_cnt + 13'd256;
        end 
    end
    // y_cnt是从非黑色区域开始计
    always @(posedge ddr_clk) begin
        if (~ddr_rstn | rst)
            y_cnt <= 13'd0;
        else if (ddr_rdone && doing) begin
            if (cnt == 4'd15) begin
                if(x_cnt + 13'd256 > H_NUM - 13'd1)
                begin
                    if(y_cnt >= H_NUM - 13'd1)
                        y_cnt <= 13'd0;
                    else
                        y_cnt <= y_cnt + 13'd1;
                end
                else
                    y_cnt <= y_cnt - 13'd15;
            end
            else
                y_cnt <= y_cnt + 13'd1;
        end 
    end

    reg [FRAME_CNT_WIDTH - 1'b1 :0] wr_frame_cnt=0;
    always @(posedge ddr_clk)
    begin 
        if(ddr_rdone && doing && (x_cnt + 13'd256 > H_NUM - 13'd1) && (y_cnt >= H_NUM - 13'd1) && (cnt == 4'd15))
            wr_frame_cnt <= {{FRAME_CNT_WIDTH - 1'b1{1'b0}},~frame_wcnt};
        else
            wr_frame_cnt <= wr_frame_cnt;
    end 

    // coor_trans #(
    //     .IMAGE_W(H_NUM),
    //     .IMAGE_H(V_NUM)
    // )
    // coor_trans_inst
    // (
    //     .clk		(	ddr_clk			),
    //     .rst_n		(	~ddr_rstn		),
        
        
    //     .angle		(	angle			),
    //     .x_in		(	x_cnt			),
    //     .y_in		(	y_cnt			),
    

    //     .x_out		(	x_rotate		),
    //     .y_out		(	y_rotate		)
    // );
    always @(posedge ddr_clk) begin
        pix_cnt <= x_cnt + {y_cnt,9'b0} + {y_cnt,7'b0}; 
        // y_cnt*640
    end

    // DQ32位，去掉pix_cnt最后1位做地址
    assign wr_cnt = pix_cnt[LINE_ADDR_WIDTH:1] + (V_NUM/2-H_NUM/2)*DDR_ADDR_OFFSET; 
    assign ddr_raddr = {wr_frame_cnt[0],ddr_part_wr,wr_cnt} + ADDR_OFFSET;
    assign ddr_rd_len = 16'd16;

    always @(posedge ddr_clk)
    begin
        if (~ddr_rstn)
            wr_addr <= 8'd0;
        else if (rst)
            wr_addr <= 8'd1;
        else if(ddr_rdone && doing && (cnt == 4'd15))
            wr_addr <= 8'd0;
        else if(ddr_rdata_en)
            wr_addr <= wr_addr + 8'd1;
        else
            wr_addr <= wr_addr;
    end

    // assign wr_data = pix_cnt[0] ? ddr_rdata[31:16] : ddr_rdata[15:0];

    rotate_fram_buf rotate_fram_buf (
        .wr_data(ddr_rdata),    // input [255:0]
        .wr_addr(wr_addr),    // input [7:0]
        .wr_en(ddr_rdata_en),        // input
        .wr_clk(ddr_clk),      // input
        .wr_rst(~ddr_rstn),      // input
        .rd_addr(rd_addr),    // input [7:0]
        .rd_data(ddr_wdata),    // output [255:0]
        .rd_clk(ddr_clk),      // input
        .rd_rst(~ddr_rstn)       // input
    );

    reg ddr_wr_req=0;
    always @(posedge ddr_clk) begin
        if (~ddr_rstn | rst)
            ddr_wr_req <= 1'b0;
        else if(ddr_rdone && doing && (cnt == 4'd15))
            ddr_wr_req <= 1'b1;
        else if (ddr_wdata_req)
            ddr_wr_req <= 1'b0;
        else
            ddr_wr_req <= ddr_wr_req;
    end

    reg [3:0] rd_len; // 阅读多少个块
    reg rd_img; // 写完一幅图标志
    reg [3:0] rd_row_cnt;
    reg [3:0] rd_col_cnt;
    reg doing_w;
    always @(posedge ddr_clk) begin
        if(~ddr_rstn | rst)
            rd_len <= 4'd0;
        else if (ddr_wdone & doing_w)
            rd_len <= 4'd0;
        else if (ddr_rdone && doing && (cnt == 4'd15) && (x_cnt + 13'd256 > H_NUM - 13'd1))
            rd_len <= 4'd7;
        else if (ddr_rdone && doing && (cnt == 4'd15) )
            rd_len <= 4'd15;
    end

    always @(posedge ddr_clk) begin
        if(~ddr_rstn | rst)
            rd_row_cnt <= 4'd0;
        else if (ddr_wdone & doing_w)
            rd_row_cnt <= 4'd0;
        else if (ddr_wdata_req)
            rd_row_cnt <= rd_row_cnt + 1'b1; 
    end

    always @(posedge ddr_clk) begin
        if (~ddr_rstn | rst)
            rd_col_cnt <= 4'd0;
        else if (ddr_wdone & doing_w)
            rd_col_cnt <= 4'd0;
        else if (ddr_wdata_req & (rd_row_cnt == 4'd15))
        begin
            if (rd_col_cnt < rd_len)
                rd_col_cnt <= rd_col_cnt + 1'b1;
            else
                rd_col_cnt <= 4'd0;
        end
    end

    always @(posedge ddr_clk) begin
        if(~ddr_rstn | rst)
            rd_addr <= 8'd0;
        else if (ddr_wdone & doing_w)
            rd_addr <= 8'd0;
        else if(ddr_wdata_req) 
        begin
            if ((rd_col_cnt >= rd_len) && (rd_row_cnt == 4'd15))
                rd_addr <= 8'd0;
            else if(rd_row_cnt == 4'd15)
                rd_addr <= rd_addr + 8'd17;    
            else
                rd_addr <= rd_addr + 8'd16;     
        end 
    end

    reg [FRAME_CNT_WIDTH - 1'b1 :0] rd_frame_cnt=1;

    always @(posedge ddr_clk)
    begin
        if(~ddr_rstn | rst)
            rd_img <= 1'b0;
        else if (ddr_wdone && doing_w)
            rd_img <= 1'b0;
        else if(ddr_rdone && doing && (x_cnt + 13'd256 > H_NUM - 13'd1) && (y_cnt >= H_NUM - 13'd1) && (cnt == 4'd15)) 
            rd_img <= 1'b1;
        else 
            rd_img <= rd_img;
    end

    always @(posedge ddr_clk)
    begin 
        if(~ddr_rstn)
            rd_frame_cnt <= 'd0;
        else if(ddr_wdone & doing_w & rd_img)
            rd_frame_cnt <= rd_frame_cnt + 1'b1;
        else
            rd_frame_cnt <= rd_frame_cnt;
    end 
    assign frame_wcnt_out = rd_frame_cnt[0];

    reg [LINE_ADDR_WIDTH - 1'b1 :0] rd_cnt;
    reg ddr_wdata_req_1d;

    always @(posedge ddr_clk) begin
        ddr_wdata_req_1d <= ddr_wdata_req;
    end

    always @(posedge ddr_clk) begin
        if(~ddr_rstn | rst) begin
            rd_cnt <= {LINE_ADDR_WIDTH{1'b0}};
            doing_w <= 1'b0;
        end
        else if(ddr_wdone & doing_w)
        begin
            if (rd_img)
                rd_cnt <= {LINE_ADDR_WIDTH{1'b0}};
            else
                rd_cnt <= rd_cnt + 22'd128 * (rd_len + 22'd1);
            doing_w <= 1'b0;
        end
        else if(~ddr_wdata_req_1d & ddr_wdata_req)
        begin
            rd_cnt <= rd_cnt;
            doing_w <= 1'b1;
        end
        else begin
            rd_cnt <= rd_cnt;
            doing_w <= doing_w;
        end
    end
    assign ddr_wreq = ddr_wr_req;
    assign ddr_waddr = {rd_frame_cnt[0],ddr_part_rd,rd_cnt} + ADDR_OFFSET;
    assign ddr_wr_len = (rd_len + 16'b1) * 16'd16;
    // assign ddr_line = doing && (x_cnt == H_NUM - 13'd1);

    // always @(posedge ddr_clk) begin
    //     if(~ddr_rstn)
    //         ddr_rdata_ban <= 1'b0;
    //     else if (ddr_wdone & doing_w)
    //         ddr_rdata_ban <= 1'b0;
    //     else if (ddr_rdone && doing && (cnt == 4'd15)) 
    //         ddr_rdata_ban <= 1'b1;
    //     else
    //         ddr_rdata_ban <= ddr_rdata_ban;
    // end
endmodule