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
    input [1:0]                   ddr_part_rd,
    input [9:0]                   angle,
    output                        ddr_line  /* synthesis PAP_MARK_DEBUG="true" */  
);

    localparam RAM_WIDTH      = 16'd32;
    localparam DDR_DATA_WIDTH = DQ_WIDTH * 8;
    localparam WR_LINE_NUM    = H_NUM * PIX_WIDTH/RAM_WIDTH; // RAM中列数
    localparam RD_LINE_NUM    = WR_LINE_NUM * RAM_WIDTH/DDR_DATA_WIDTH; // DDR中列数
    localparam DDR_ADDR_OFFSET= RD_LINE_NUM*DDR_DATA_WIDTH/DQ_WIDTH; // 一列多少个32bit

    reg [31:0]  x_cnt;
    reg [31:0]  y_cnt;
    wire [31:0]  x_rotate;
    wire [31:0]  y_rotate;
    reg [31:0]  x_rotate_reg;
    reg [31:0]  y_rotate_reg;
    reg doing;
    reg ddr_rdata_en_1d;
    wire [LINE_ADDR_WIDTH - 1'b1 :0] wr_cnt;
    reg [LINE_ADDR_WIDTH:0] pix_cnt;
    reg [11:0] wr_addr;
    reg [7:0] rd_addr=8'd0;
    wire [DDR_DATA_WIDTH-1'b1:0] rd_data;
    wire [15:0] wr_data;

    always @(posedge ddr_clk) begin
        ddr_rdata_en_1d <= ddr_rdata_en;
    end
    //  使得wr_cnt在适当的时候累加 
    always @(posedge ddr_clk) begin
        if(~ddr_rstn)
            doing <= 1'b0;
        else if (ddr_rdata_en && ~ddr_rdata_en_1d) begin
            doing <= 1'b1;
        end 
        else if (ddr_rdone & doing)
            doing <= 1'b0;
        else
            doing <= doing;
    end
    always @(posedge ddr_clk) begin
        if(~ddr_rstn)
            x_cnt <= 32'd0;
        else if (ddr_rdone && doing) begin
            if (x_cnt == H_NUM - 32'd1)
                x_cnt <= 32'd0;
            else
                x_cnt <= x_cnt + 32'd1;
        end 
    end
    always @(posedge ddr_clk) begin
        if (~ddr_rstn)
            y_cnt <= 32'd0;
        else if (ddr_rdone && doing && x_cnt == H_NUM - 32'd1) begin
            if (y_cnt == V_NUM - 32'd1) begin
                y_cnt <= 32'd0;
            end
            else
                y_cnt <= y_cnt + 32'd1;
        end 
    end

    reg [FRAME_CNT_WIDTH - 1'b1 :0] wr_frame_cnt=0;
    always @(posedge ddr_clk)
    begin 
        if(ddr_rdone && doing && x_cnt == H_NUM - 32'd1 && y_cnt == V_NUM - 32'd1)
            wr_frame_cnt <= wr_frame_cnt + 1'b1;
        else
            wr_frame_cnt <= wr_frame_cnt;
    end 

    coor_trans #(
        .IMAGE_W(H_NUM),
        .IMAGE_H(V_NUM)
    )
    coor_trans_inst
    (
        .clk		(	ddr_clk			),
        .rst_n		(	~ddr_rstn		),
        
        
        .angle		(	angle			),
        .x_in		(	x_cnt			),
        .y_in		(	y_cnt			),
    

        .x_out		(	x_rotate		),
        .y_out		(	y_rotate		)
    );
    always @(posedge ddr_clk) begin
        x_rotate_reg <= x_rotate;
        y_rotate_reg <= y_rotate;
        pix_cnt <= x_rotate_reg + (y_rotate_reg << 9) + (y_rotate_reg << 6); // y_rotate*640
    end

    // DQ32位，去掉pix_cnt最后1位做地址
    assign wr_cnt = pix_cnt[LINE_ADDR_WIDTH:1]; 
    assign ddr_raddr = {wr_frame_cnt[0],ddr_part_rd,wr_cnt} + ADDR_OFFSET;
    assign ddr_rd_len = RD_LINE_NUM;

    always @(posedge ddr_clk)
    begin
        if(x_cnt == H_NUM - 32'd1 && doing && ddr_rdone)
            wr_addr <= 12'd0;
        else if(ddr_rdata_en)
            wr_addr <= wr_addr + 12'd1;
        else
            wr_addr <= wr_addr;
    end

    assign wr_data = pix_cnt[0] ? ddr_rdata[31:16] : ddr_rdata[15:0];

    rotate_fram_buf rotate_fram_buf (
    .wr_data(wr_data),    // input [15:0]
    .wr_addr(wr_addr),    // input [11:0]
    .wr_en(ddr_rdata_en),        // input
    .wr_clk(ddr_clk),      // input
    .wr_rst(~ddr_rstn),      // input
    .rd_addr(rd_addr),    // input [7:0]
    .rd_data(rd_data),    // output [255:0]
    .rd_clk(ddr_clk),      // input
    .rd_rst(~ddr_rstn)       // input
    );

    assign ddr_line = doing && (x_cnt == H_NUM - 32'd1);
endmodule