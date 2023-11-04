`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Meyesemi
// Engineer: Nill
// 
// Create Date: 07/03/23 19:13:35
// Design Name: 
// Module Name: wr_buf
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
module wr_buf #(
    parameter                     ADDR_WIDTH      = 6'd27,
    parameter                     ADDR_OFFSET     = 32'h0000_0000,
    parameter                     H_NUM           = 12'd1920,
    parameter                     V_NUM           = 12'd1080,
    parameter                     DQ_WIDTH        = 12'd32,
    parameter                     LEN_WIDTH       = 12'd16,
    parameter                     PIX_WIDTH       = 12'd24,
    parameter                     LINE_ADDR_WIDTH = 16'd19,
    parameter                     FRAME_CNT_WIDTH = 16'd8
) (                               
    input                         ddr_clk,
    input                         ddr_rstn,
                                  
    input                         wr_clk1,
    input                         wr_fsync1,
    input                         wr_en1,
    input  [PIX_WIDTH- 1'b1 : 0]  wr_data1,
    input                         wr_clk2,
    input                         wr_fsync2,
    input                         wr_en2,
    input  [PIX_WIDTH- 1'b1 : 0]  wr_data2,
    
    input                         rd_bac,
    output                        ddr_wreq,
    output [ADDR_WIDTH- 1'b1 : 0] ddr_waddr,
    output [LEN_WIDTH- 1'b1 : 0]  ddr_wr_len,
    input                         ddr_wrdy,
    input                         ddr_wdone,
    output [8*DQ_WIDTH- 1'b1 : 0] ddr_wdata,
    input                         ddr_wdata_req1,
    input                         ddr_wdata_req2,
    
    // output [FRAME_CNT_WIDTH-1 :0] frame_wcnt,
    output                        frame_wirq,
    input                         wr_opera_en_2
);

    wire [ADDR_WIDTH- 1'b1 : 0] ddr_waddr1;
    wire [ADDR_WIDTH- 1'b1 : 0] ddr_waddr2;
    wire  [LEN_WIDTH- 1'b1 : 0]  ddr_wr_len1;
    wire  [LEN_WIDTH- 1'b1 : 0]  ddr_wr_len2;
    wire [8*DQ_WIDTH- 1'b1 : 0] ddr_wdata1;
    wire [8*DQ_WIDTH- 1'b1 : 0] ddr_wdata2;
    wire frame_wirq1;
    wire frame_wirq2;

    wr_cell #(
        .ADDR_WIDTH      (ADDR_WIDTH),
        .ADDR_OFFSET     (ADDR_OFFSET),
        .H_NUM           (H_NUM),
        .V_NUM           (V_NUM),
        .DQ_WIDTH        (DQ_WIDTH),
        .LEN_WIDTH       (LEN_WIDTH),
        .PIX_WIDTH       (PIX_WIDTH),
        .LINE_ADDR_WIDTH (LINE_ADDR_WIDTH) 
    ) wr_cell1 (
        .ddr_clk(ddr_clk),// input                         ddr_clk,
        .ddr_rstn(ddr_rstn),// input                         ddr_rstn,
                          
        .wr_clk(wr_clk1),// input                         wr_clk,
        .wr_fsync(wr_fsync1),// input                         wr_fsync,
        .wr_en(wr_en1),// input                         wr_en,
        .wr_data(wr_data1),// input  [PIX_WIDTH- 1'b1 : 0]  wr_data,

        // .rd_bac,// input                         rd_bac,
        .ddr_wreq(ddr_wreq1),// output                        ddr_wreq,
        .ddr_waddr(ddr_waddr1),// output [ADDR_WIDTH- 1'b1 : 0] ddr_waddr,
        .ddr_wr_len(ddr_wr_len1),// output [LEN_WIDTH- 1'b1 : 0]  ddr_wr_len,
        // .ddr_wrdy,// input                         ddr_wrdy,
        .ddr_wdone(ddr_wdone),// input                         ddr_wdone,
        .ddr_wdata(ddr_wdata1),// output [8*DQ_WIDTH- 1'b1 : 0] ddr_wdata,
        .ddr_wdata_req(ddr_wdata_req1),// input                         ddr_wdata_req,
        .frame_wirq(frame_wirq1),
        .ddr_part(1'b0) // input                         ddr_part 
    );

    wr_cell #(
        .ADDR_WIDTH      (ADDR_WIDTH),
        .ADDR_OFFSET     (ADDR_OFFSET),
        .H_NUM           (H_NUM),
        .V_NUM           (V_NUM),
        .DQ_WIDTH        (DQ_WIDTH),
        .LEN_WIDTH       (LEN_WIDTH),
        .PIX_WIDTH       (PIX_WIDTH),
        .LINE_ADDR_WIDTH (LINE_ADDR_WIDTH) 
    ) wr_cell2 (
        .ddr_clk(ddr_clk),// input                         ddr_clk,
        .ddr_rstn(ddr_rstn),// input                         ddr_rstn,
                          
        .wr_clk(wr_clk2),// input                         wr_clk,
        .wr_fsync(wr_fsync2),// input                         wr_fsync,
        .wr_en(wr_en2),// input                         wr_en,
        .wr_data(wr_data2),// input  [PIX_WIDTH- 1'b1 : 0]  wr_data,

        // .rd_bac,// input                         rd_bac,
        .ddr_wreq(ddr_wreq2),// output                        ddr_wreq,
        .ddr_waddr(ddr_waddr2),// output [ADDR_WIDTH- 1'b1 : 0] ddr_waddr,
        .ddr_wr_len(ddr_wr_len2),// output [LEN_WIDTH- 1'b1 : 0]  ddr_wr_len,
        // .ddr_wrdy,// input                         ddr_wrdy,
        .ddr_wdone(ddr_wdone),// input                         ddr_wdone,
        .ddr_wdata(ddr_wdata2),// output [8*DQ_WIDTH- 1'b1 : 0] ddr_wdata,
        .ddr_wdata_req(ddr_wdata_req2),// input                         ddr_wdata_req,
        .frame_wirq(frame_wirq2),
        .ddr_part(1'b1) // input                         ddr_part 
    );

    assign ddr_wdata = (~wr_opera_en_2) ? ddr_wdata1 : ddr_wdata2;
    assign ddr_waddr = (~wr_opera_en_2) ? ddr_waddr1 : ddr_waddr2;
    assign ddr_wr_len =(~wr_opera_en_2) ? ddr_wr_len1 : ddr_wr_len2;
    assign frame_wirq =frame_wirq1 | frame_wirq2;
    assign ddr_wreq = (~wr_opera_en_2) ? ddr_wreq1 : ddr_wreq2;
    // assign frame_wcnt = rd_frame_cnt;
    
endmodule
