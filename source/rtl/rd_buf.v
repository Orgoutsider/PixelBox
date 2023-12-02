`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Meyesemi
// Engineer: Nill
// 
// Create Date: 15/03/23 15:02:21
// Design Name: 
// Module Name: rd_buf
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`define UD #1
module rd_buf #(
    parameter                     ADDR_WIDTH      = 6'd27,
    parameter                     ADDR_OFFSET     = 32'h0000_0000,
    parameter                     H_NUM           = 12'd1920,
    parameter                     V_NUM           = 12'd1080,
    parameter                     DQ_WIDTH        = 12'd32,
    parameter                     LEN_WIDTH       = 12'd16,
    parameter                     PIX_WIDTH       = 12'd24,
    parameter                     LINE_ADDR_WIDTH = 16'd19,
    parameter                     FRAME_CNT_WIDTH = 16'd8
)  (
    input                         ddr_clk,
    input                         ddr_rstn,
    
    input                         vout_clk,
    input                         rd_fsync,
    input                         rd_en,
    output                        vout_de,
    output [PIX_WIDTH- 1'b1 : 0]  vout_data,
    
    input                         init_done,
    
    output                        ddr_rreq,
    output reg [ADDR_WIDTH- 1'b1 : 0] ddr_raddr,
    output reg [LEN_WIDTH- 1'b1 : 0]  ddr_rd_len,
    input                         ddr_rrdy,
    input                         ddr_rdone,
    
    input [8*DQ_WIDTH- 1'b1 : 0]  ddr_rdata,
    input                         ddr_rdata_en1, 
    input                         ddr_rdata_en2,
    input                         ddr_rdata_en3,
    input                         rd_opera_en_1,
    input                         rd_opera_en_2,
    input                         rd_opera_en_3,
    input [3 : 0]                 num,
    input                         num_vld,
    input                         rotate_180, 
    input                         rotate_90, 
    input  [ADDR_WIDTH- 1'b1 : 0]  ddr_raddr4,
    input  [LEN_WIDTH- 1'b1 : 0]   ddr_rd_len4,
    output                         ddr_rdata_ban,
    input                          frame_wcnt1,
    input                          frame_wcnt2,
    input                          frame_wcnt3,
    input                          frame_wcnt4
);

    localparam RAM_WIDTH      = 16'd32;
    localparam H_NUM2         = H_NUM / 2;
    
    //===========================================================================
    reg [12:0]  x_cnt;
    reg [12:0]  y_cnt;
    reg         rd_fsync_1d;
    wire      rd_en_part1;
    wire      rd_en_part2;
    wire      rd_en_part3;
    wire      ddr_rreq1;
    wire      ddr_rreq2;
    wire      ddr_rreq3;
    wire      ddr_rreq4;
    reg [RAM_WIDTH-1:0]        rd_data;
    reg [RAM_WIDTH-1:0]        rd_data_1d;
    wire [RAM_WIDTH-1:0]        rd_data1;
    wire [RAM_WIDTH-1:0]        rd_data2;
    wire [RAM_WIDTH-1:0]        rd_data3;
    wire [RAM_WIDTH-1:0]        rd_data4;
    wire [RAM_WIDTH-1:0]        rd_data1_1d;
    wire [RAM_WIDTH-1:0]        rd_data2_1d;
    wire [RAM_WIDTH-1:0]        rd_data3_1d;
    wire [RAM_WIDTH-1:0]        rd_data4_1d;
    wire [ADDR_WIDTH- 1'b1 : 0] ddr_raddr1;
    wire [ADDR_WIDTH- 1'b1 : 0] ddr_raddr2;
    wire [ADDR_WIDTH- 1'b1 : 0] ddr_raddr3;
    wire [ADDR_WIDTH- 1'b1 : 0] ddr_raddr5;
    wire [LEN_WIDTH- 1'b1 : 0] ddr_rd_len1;
    wire [LEN_WIDTH- 1'b1 : 0] ddr_rd_len2;
    wire [LEN_WIDTH- 1'b1 : 0] ddr_rd_len3;
    wire [LEN_WIDTH- 1'b1 : 0] ddr_rd_len5;
    wire [1:0] rd_cnt1;
    wire [1:0] rd_cnt2;
    wire [1:0] rd_cnt3;
    wire [1:0] rd_cnt4;
    reg [1:0] rd_cnt_part;
    reg rd_en_1d, rd_en_2d;
    reg [PIX_WIDTH- 1'b1 : 0]  read_data;
    wire pos_en;
    reg rotate_90_1d, rotate_90_2d;
    reg wr_rotate_90_1d, wr_rotate_90_2d;

    always @(posedge vout_clk) begin
        rotate_90_1d <= rotate_90;
        rotate_90_2d <= rotate_90_1d;
    end 

    always @(posedge ddr_clk) begin
        wr_rotate_90_1d <= rotate_90;
        wr_rotate_90_2d <= wr_rotate_90_1d;
    end

    //像素显示请求信号切换，即显示器左侧请求buf0显示，右侧请求buf1显示
    assign rd_en_part1 = (x_cnt <= H_NUM2 - 1'b1) ? rd_en : 1'b0;
    assign rd_en_part2 = (x_cnt <= H_NUM - 1'b1) ? 1'b0 : rd_en;
    assign rd_en_part3 = (x_cnt <= H_NUM - 1'b1 && x_cnt > H_NUM2 - 1'b1) ? rd_en : 1'b0;

    //像素在显示器显示位置的切换
    always @(*) begin
        if (x_cnt <= H_NUM2)
            rd_data = rd_data1;
        else if (x_cnt > H_NUM)
        begin
            if (rotate_90_2d)
                rd_data = rd_data4;
            else
                rd_data = rd_data2; 
        end
        else
            rd_data = rd_data3;
    end
    always @(*) begin
        if (x_cnt <= H_NUM2)
            rd_data_1d = rd_data1_1d;
        else if (x_cnt > H_NUM)
        begin
            if (rotate_90_2d)
                rd_data_1d = rd_data4_1d;
            else
                rd_data_1d = rd_data2_1d;
        end
        else
            rd_data_1d = rd_data3_1d;
    end
    always @(*) begin
        if (x_cnt <= H_NUM2)
            rd_cnt_part = rd_cnt1;
        else if (x_cnt > H_NUM)
        begin
            if (rotate_90_2d)
                rd_cnt_part = rd_cnt4;
            else 
                rd_cnt_part = rd_cnt2;
        end
        else
            rd_cnt_part = rd_cnt3;
    end

    always @(posedge vout_clk) begin
        rd_en_1d <= rd_en;
        rd_en_2d <= rd_en_1d;
    end

    generate
        if(PIX_WIDTH == 6'd24)
        begin
            always @(posedge vout_clk)
            begin
                if(rd_en_1d)
                begin
                    if(rd_cnt_part[1:0] == 2'd1)
                        read_data <= rd_data[PIX_WIDTH-1:0];
                    else if(rd_cnt_part[1:0] == 2'd2)
                        read_data <= {rd_data[15:0],rd_data_1d[31:PIX_WIDTH]};
                    else if(rd_cnt_part[1:0] == 2'd3)
                        read_data <= {rd_data[7:0],rd_data_1d[31:16]};
                    else
                        read_data <= rd_data_1d[31:8];
                end 
                else
                    read_data <= 'd0;
            end 
        end
        else if(PIX_WIDTH == 6'd16)
        begin
            always @(posedge vout_clk)
            begin
                if(rd_en_1d)
                begin
                    if(rd_cnt_part[0])
                        read_data <= rd_data[15:0];
                    else
                        read_data <= rd_data_1d[31:16];
                end 
                else
                    read_data <= 'd0;
            end 
        end
        else
        begin            
            always @(posedge vout_clk)
            begin
                read_data <= rd_data;
            end 
        end
    endgenerate

    //对读请求信号列计数
    always @(posedge vout_clk) begin
        if(rd_en) x_cnt <= x_cnt + 1'b1;
        else x_cnt <= 13'd0;
    end

    always @(posedge vout_clk) begin
        rd_fsync_1d <= rd_fsync;
    end

    //对读请求信号行计数
    always @(posedge vout_clk)
    begin 
        if(~rd_fsync_1d & rd_fsync)
            y_cnt <= 13'd0;
        else if(rd_en_1d & ~rd_en)
            y_cnt <= y_cnt + 1'b1;
        else
            y_cnt <= y_cnt;
    end 

    rd_cell #(  
        .ADDR_WIDTH      (ADDR_WIDTH),
        .ADDR_OFFSET     (ADDR_OFFSET),
        .H_NUM           (H_NUM2),
        .V_NUM           (V_NUM),
        .DQ_WIDTH        (DQ_WIDTH),
        .LEN_WIDTH       (LEN_WIDTH),
        .PIX_WIDTH       (PIX_WIDTH),
        .LINE_ADDR_WIDTH (LINE_ADDR_WIDTH),
        .FRAME_CNT_WIDTH (FRAME_CNT_WIDTH),
        .RAM_WIDTH       (RAM_WIDTH)
    ) rd_cell1 (
        .ddr_clk(ddr_clk)          ,// input                         ddr_clk,
        .ddr_rstn(ddr_rstn)        , // input                         ddr_rstn,         
        .vout_clk(vout_clk)        , // input                         vout_clk,
        .rd_fsync(rd_fsync)        , // input                         rd_fsync,
        .rd_en(rd_en)              ,// input                         rd_en,
        .rd_en_part(rd_en_part1)    ,     // input                         rd_en_part,
        .rd_data(rd_data1)           , // output [RAM_WIDTH-1:0]        rd_data,
        .rd_data_1d(rd_data1_1d)     ,       // output [RAM_WIDTH-1:0]        rd_data_1d,
        // .vout_data(vout_data1)      ,   // output [PIX_WIDTH- 1'b1 : 0]  vout_data,       
        // input                         init_done,     
        .ddr_rreq(ddr_rreq1)        , // output                        ddr_rreq,
        .ddr_raddr(ddr_raddr1)      ,   // output [ADDR_WIDTH- 1'b1 : 0] ddr_raddr,
        .ddr_rd_len(ddr_rd_len1)    ,     // output [LEN_WIDTH- 1'b1 : 0]  ddr_rd_len,
        // .ddr_rrdy(ddr_rrdy)        , // input                         ddr_rrdy,
        .ddr_rdone(ddr_rdone)      ,   // input                         ddr_rdone,      
        .ddr_rdata(ddr_rdata)      ,   // input [8*DQ_WIDTH- 1'b1 : 0]  ddr_rdata,
        .ddr_rdata_en(ddr_rdata_en1),         // input                         ddr_rdata_en,
        .ddr_part(2'd0)        , // input                         ddr_part 
        .rd_cnt(rd_cnt1)   ,// output [1:0] rd_cnt  
        .rotate_180(1'b0),
        .frame_wcnt(frame_wcnt1)  
    );

    rd_cell #(  
        .ADDR_WIDTH      (ADDR_WIDTH),
        .ADDR_OFFSET     (ADDR_OFFSET),
        .H_NUM           (H_NUM),
        .V_NUM           (V_NUM),
        .DQ_WIDTH        (DQ_WIDTH),
        .LEN_WIDTH       (LEN_WIDTH),
        .PIX_WIDTH       (PIX_WIDTH),
        .LINE_ADDR_WIDTH (LINE_ADDR_WIDTH),
        .FRAME_CNT_WIDTH (FRAME_CNT_WIDTH),
        .RAM_WIDTH       (RAM_WIDTH)
    ) rd_cell2 (
        .ddr_clk(ddr_clk)          ,// input                         ddr_clk,
        .ddr_rstn(ddr_rstn)        , // input                         ddr_rstn,         
        .vout_clk(vout_clk)        , // input                         vout_clk,
        .rd_fsync(rd_fsync)        , // input                         rd_fsync,
        .rd_en(rd_en)              ,// input                         rd_en,
        .rd_en_part(rd_en_part2)    ,     // input                         rd_en_part,
        .rd_data(rd_data2)           , // output [RAM_WIDTH-1:0]        rd_data,
        .rd_data_1d(rd_data2_1d)     ,       // output [RAM_WIDTH-1:0]        rd_data_1d,
        // .vout_data(vout_data1)      ,   // output [PIX_WIDTH- 1'b1 : 0]  vout_data,       
        // input                         init_done,     
        .ddr_rreq(ddr_rreq2)        , // output                        ddr_rreq,
        .ddr_raddr(ddr_raddr2)      ,   // output [ADDR_WIDTH- 1'b1 : 0] ddr_raddr,
        .ddr_rd_len(ddr_rd_len2)    ,     // output [LEN_WIDTH- 1'b1 : 0]  ddr_rd_len,
        // .ddr_rrdy(ddr_rrdy)        , // input                         ddr_rrdy,
        .ddr_rdone(ddr_rdone)      ,   // input                         ddr_rdone,      
        .ddr_rdata(ddr_rdata)      ,   // input [8*DQ_WIDTH- 1'b1 : 0]  ddr_rdata,
        .ddr_rdata_en(ddr_rdata_en2),         // input                         ddr_rdata_en,
        .ddr_part(2'd1)        , // input                         ddr_part 
        .rd_cnt(rd_cnt2)    , // output [1:0] rd_cnt    
        .rotate_180(rotate_180),
        .frame_wcnt(wr_rotate_90_2d ? frame_wcnt4: frame_wcnt2)  
    );

    rd_cell #(  
        .ADDR_WIDTH      (ADDR_WIDTH),
        .ADDR_OFFSET     (ADDR_OFFSET),
        .H_NUM           (H_NUM2),
        .V_NUM           (V_NUM),
        .DQ_WIDTH        (DQ_WIDTH),
        .LEN_WIDTH       (LEN_WIDTH),
        .PIX_WIDTH       (PIX_WIDTH),
        .LINE_ADDR_WIDTH (LINE_ADDR_WIDTH),
        .FRAME_CNT_WIDTH (FRAME_CNT_WIDTH),
        .RAM_WIDTH       (RAM_WIDTH)
    ) rd_cell3 (
        .ddr_clk(ddr_clk)          ,// input                         ddr_clk,
        .ddr_rstn(ddr_rstn)        , // input                         ddr_rstn,         
        .vout_clk(vout_clk)        , // input                         vout_clk,
        .rd_fsync(rd_fsync)        , // input                         rd_fsync,
        .rd_en(rd_en)              ,// input                         rd_en,
        .rd_en_part(rd_en_part3)    ,     // input                         rd_en_part,
        .rd_data(rd_data3)           , // output [RAM_WIDTH-1:0]        rd_data,
        .rd_data_1d(rd_data3_1d)     ,       // output [RAM_WIDTH-1:0]        rd_data_1d,
        // .vout_data(vout_data1)      ,   // output [PIX_WIDTH- 1'b1 : 0]  vout_data,       
        // input                         init_done,     
        .ddr_rreq(ddr_rreq3)        , // output                        ddr_rreq,
        .ddr_raddr(ddr_raddr3)      ,   // output [ADDR_WIDTH- 1'b1 : 0] ddr_raddr,
        .ddr_rd_len(ddr_rd_len3)    ,     // output [LEN_WIDTH- 1'b1 : 0]  ddr_rd_len,
        // .ddr_rrdy(ddr_rrdy)        , // input                         ddr_rrdy,
        .ddr_rdone(ddr_rdone)      ,   // input                         ddr_rdone,      
        .ddr_rdata(ddr_rdata)      ,   // input [8*DQ_WIDTH- 1'b1 : 0]  ddr_rdata,
        .ddr_rdata_en(ddr_rdata_en3),         // input                         ddr_rdata_en,
        .ddr_part(2'd2)        , // input                         ddr_part 
        .rd_cnt(rd_cnt3)      , // output [1:0] rd_cnt    
        .rotate_180(1'b0)   ,
        .frame_wcnt(frame_wcnt3)  
    );

    rotate_cell #(
        .ADDR_WIDTH      (ADDR_WIDTH),// parameter                     ADDR_WIDTH      = 6'd27,
        .ADDR_OFFSET     (ADDR_OFFSET),// parameter                     ADDR_OFFSET     = 32'h0000_0000,
        .H_NUM           (H_NUM),// parameter                     H_NUM           = 12'd1920,
        .V_NUM           (V_NUM),// parameter                     V_NUM           = 12'd1080,
        .DQ_WIDTH        (DQ_WIDTH),// parameter                     DQ_WIDTH        = 12'd32,
        .LEN_WIDTH       (LEN_WIDTH),// parameter                     LEN_WIDTH       = 12'd16,
        .PIX_WIDTH       (PIX_WIDTH),// parameter                     PIX_WIDTH       = 12'd24,
        .LINE_ADDR_WIDTH (LINE_ADDR_WIDTH),// parameter                     LINE_ADDR_WIDTH = 16'd19,
        .FRAME_CNT_WIDTH (FRAME_CNT_WIDTH),// parameter                     FRAME_CNT_WIDTH = 16'd8,
        .RAM_WIDTH       (RAM_WIDTH)// parameter                     RAM_WIDTH       = 16'd32
    ) rotate_cell (
        .ddr_clk(ddr_clk),// input                         ddr_clk,
        .ddr_rstn(ddr_rstn),// input                         ddr_rstn,
        .vout_clk(vout_clk),// input                         vout_clk,
        .rd_fsync(rd_fsync),// input                         rd_fsync,
        .rd_en(rd_en),// input                         rd_en,
        .rd_en_part(rd_en_part2),// input                         rd_en_part,
        .rd_data(rd_data4),// output [RAM_WIDTH-1:0]        rd_data,
        .rd_data_1d(rd_data4_1d),// output [RAM_WIDTH-1:0]        rd_data_1d,
        .ddr_rreq(ddr_rreq4),// output                        ddr_rreq,
        .ddr_raddr(ddr_raddr5),// output [ADDR_WIDTH- 1'b1 : 0] ddr_raddr,
        .ddr_rd_len(ddr_rd_len5),// output [LEN_WIDTH- 1'b1 : 0]  ddr_rd_len,
        .ddr_rdone(ddr_rdone),// input                         ddr_rdone,
        .ddr_rdata(ddr_rdata),// input [8*DQ_WIDTH- 1'b1 : 0]  ddr_rdata,
        .ddr_rdata_en(ddr_rdata_en2),// input                         ddr_rdata_en,
        .ddr_rdata_ban(ddr_rdata_ban),// output reg                    ddr_rdata_ban,
        .ddr_part(2'd3),// input [1:0]                   ddr_part,
        .rd_cnt(rd_cnt4),// output reg [1:0]              rd_cnt,
        .rd_line(y_cnt),// input [12:0]                  rd_line,
        .rotate_90(wr_rotate_90_2d)// input                         rotate_90  
    );

    assign vout_de = rd_en_2d;
    assign vout_data = pos_en ? 16'hf800 : read_data;
    assign ddr_rreq = ddr_rreq1;
    // 3路切换
    always @(*) begin
        if (rd_opera_en_1)
            ddr_raddr = ddr_raddr1;
        else if (rd_opera_en_2)
        begin
            if (wr_rotate_90_2d)
                ddr_raddr = ddr_raddr5;
            else 
                ddr_raddr = ddr_raddr2;
        end
        else if (rd_opera_en_3)
            ddr_raddr = ddr_raddr3;
        else
            ddr_raddr = ddr_raddr4; 
    end
    always @(*) begin
        if (rd_opera_en_1)
            ddr_rd_len = ddr_rd_len1;
        else if (rd_opera_en_2)
        begin
            if (wr_rotate_90_2d)
                ddr_rd_len = ddr_rd_len5;
            else
                ddr_rd_len = ddr_rd_len2; 
        end
        else if (rd_opera_en_3)
            ddr_rd_len = ddr_rd_len3;
        else
            ddr_rd_len = ddr_rd_len4;
    end

    // num转时钟域
    reg [3:0] num_1d;
    reg [3:0] num_2d;
    reg num_vld_1d;
    reg num_vld_2d;
    reg num_vld_3d;
    reg num_en=1'b0;
    reg [3:0] num_reg;

    always @(posedge vout_clk) begin
        num_1d <= num;
        num_2d <= num_1d;
        num_vld_1d <= num_vld;
        num_vld_2d <= num_vld_1d;
        num_vld_3d <= num_vld_2d;
    end

    always @(posedge vout_clk) begin
        if (num_vld_2d & ~num_vld_3d)
            num_en <= 1'b1;
    end

    always @(posedge vout_clk) begin
        if (!num_en)
            num_reg <= 4'd10; 
        else
            num_reg <= num_2d;
    end

    osd_display  #(
        .OSD_WIDTH   (12'd16),
        .OSD_HEGIHT  (12'd32)
    )u_osd_display
    (
        .clk(vout_clk),    // input clk,
        .num(num_reg),//input [3:0] num,
        .pos_x(x_cnt),    // input [12:0] pos_x,
        .pos_y(y_cnt),    // input [12:0] pos_y,
        .pos_de(rd_en),    // input pos_de,
        .pos_vs(rd_fsync),    // input pos_vs,
        .pos_en(pos_en)       // output pos_en
    );

endmodule
