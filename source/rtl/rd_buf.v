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
    output [ADDR_WIDTH- 1'b1 : 0] ddr_raddr,
    output [LEN_WIDTH- 1'b1 : 0]  ddr_rd_len,
    input                         ddr_rrdy,
    input                         ddr_rdone,
    
    input [8*DQ_WIDTH- 1'b1 : 0]  ddr_rdata,
    input                         ddr_rdata_en 
);
    localparam SIM            = 1'b0;
    localparam RAM_WIDTH      = 16'd32;
    localparam DDR_DATA_WIDTH = DQ_WIDTH * 8;
    localparam WR_LINE_NUM    = H_NUM * PIX_WIDTH/RAM_WIDTH;
    localparam RD_LINE_NUM    = WR_LINE_NUM * RAM_WIDTH/DDR_DATA_WIDTH;
    localparam DDR_ADDR_OFFSET= RD_LINE_NUM*DDR_DATA_WIDTH/DQ_WIDTH; 
    
    //===========================================================================
    reg       rd_fsync_1d;
    reg       rd_en_1d,rd_en_2d;
    wire      rd_rst;
    reg       ddr_rstn_1d,ddr_rstn_2d;   
    reg [12:0]  rd_cnt;
    wire      rd_en1, rd_en2;

    always @(posedge vout_clk)
    begin
        rd_fsync_1d <= rd_fsync;
        rd_en_1d <= rd_en; 
        rd_en_2d <= rd_en_1d;
        ddr_rstn_1d <= ddr_rstn;
        ddr_rstn_2d <= ddr_rstn_1d;
    end 
    assign rd_rst = ~rd_fsync_1d &rd_fsync;

    //ÏñËØÏÔÊ¾ÇëÇóÐÅºÅÇÐ»»£¬¼´ÏÔÊ¾Æ÷×ó²àÇëÇóbuf0ÏÔÊ¾£¬ÓÒ²àÇëÇóbuf1ÏÔÊ¾
    assign rd_en1 = (rd_cnt <= H_NUM - 1) ? rd_en : 1'b0;
    assign rd_en2 = (rd_cnt <= H_NUM - 1) ? 1'b0 : rd_en;

    //ÏñËØÔÚÏÔÊ¾Æ÷ÏÔÊ¾Î»ÖÃµÄÇÐ»»
    assign rd_data = (rd_cnt <= H_NUM) ? rd_data1 : 32'b0; 

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

    reg [LINE_ADDR_WIDTH - 1'b1 :0] wr_cnt;
    always @(posedge ddr_clk)
    begin 
        if(wr_rst)
            wr_cnt <= 9'd0;
        else if(ddr_rdone)
            wr_cnt <= wr_cnt + DDR_ADDR_OFFSET;
        else
            wr_cnt <= wr_cnt;
    end 
    
    assign ddr_rreq = wr_trig;
    assign ddr_raddr = {wr_frame_cnt[0],wr_cnt} + ADDR_OFFSET;
    assign ddr_rd_len = RD_LINE_NUM;
    
    reg  [ 8:0]           wr_addr;
    reg  [11:0]           rd_addr1;
    wire [RAM_WIDTH-1:0]  rd_data1;
    wire [RAM_WIDTH-1:0]  rd_data;
    
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

    rd_fram_buf rd_fram_buf (
        .wr_data    (  ddr_rdata       ),// input [255:0]            
        .wr_addr    (  wr_addr         ),// input [8:0]              
        .wr_en      (  ddr_rdata_en    ),// input                    
        .wr_clk     (  ddr_clk         ),// input                    
        .wr_rst     (  ~ddr_rstn       ),// input                    
        .rd_addr    (  rd_addr1         ),// input [11:0]             
        .rd_data    (  rd_data1         ),// output [31:0]            
        .rd_clk     (  vout_clk        ),// input                    
        .rd_rst     (  ~ddr_rstn_2d    ) // input                    
    );

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
    
    reg [1:0] rd_cnt1;
    wire      read_en1;
    always @(posedge vout_clk)
    begin
        if(rd_en1)
            rd_cnt1 <= rd_cnt1 + 1'b1;
        else
            rd_cnt1 <= 2'd0;
    end 

    //¶Ô¶ÁÇëÇóÐÅºÅ¼ÆÊý
    always @(posedge vout_clk) begin
        if(rd_en) rd_cnt <= rd_cnt + 1'b1;
        else rd_cnt <= 13'd0;
    end
    
    always @(posedge vout_clk)
    begin
        if(rd_rst)
            rd_addr1 <= 'd0;
        else if(read_en1)
            rd_addr1 <= rd_addr1 + 1'b1;
        else
            rd_addr1 <= rd_addr1;
    end 
    
    reg [PIX_WIDTH- 1'b1 : 0] read_data;
    reg [RAM_WIDTH-1:0]       rd_data_1d;
    always @(posedge vout_clk)
    begin
        rd_data_1d <= rd_data;
    end 
    
    generate
    if(PIX_WIDTH == 6'd24)
    begin
        assign read_en1 = rd_en1 && (rd_cnt1 != 2'd3);
        
        always @(posedge vout_clk)
        begin
            if(rd_en_1d)
            begin
                if(rd_cnt1[1:0] == 2'd1)
                    read_data <= rd_data[PIX_WIDTH-1:0];
                else if(rd_cnt1[1:0] == 2'd2)
                    read_data <= {rd_data[15:0],rd_data_1d[31:PIX_WIDTH]};
                else if(rd_cnt1[1:0] == 2'd3)
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
        assign read_en1 = rd_en && (rd_cnt1[0] != 1'b1);
        
        always @(posedge vout_clk)
        begin
            if(rd_en_1d)
            begin
                if(rd_cnt1[0])
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
        assign read_en1 = rd_en;
        
        always @(posedge vout_clk)
        begin
            read_data <= rd_data;
        end 
    end
endgenerate

    assign vout_de = rd_en_2d;
    assign vout_data = read_data;

endmodule
