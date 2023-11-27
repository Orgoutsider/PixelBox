`timescale 1ns / 1ps
// *********************************************************************************
// Project Name : OSXXXX
// Author       : zhangningning
// Email        : nnzhang1996@foxmail.com
// Website      : 
// Module Name  : mat_3x3.v
// Create Time  : 2020-04-07 10:42:14
// Editor       : sublime text3, tab size (2)
// CopyRight(c) : All Rights Reserved
//
// *********************************************************************************
// Modification History:
// Date             By              Version                 Change Description
// -----------------------------------------------------------------------
// XXXX       zhangningning          1.0                        Original
//  
// *********************************************************************************

module mat_3x3(
    //System Interfaces
    input                   sclk            ,
    input                   rst_n           ,
    //Communication Interfaces
    input           [ 7:0]  rx_data         ,
    input                   pi_flag         ,
    output  wire    [ 7:0]  mat_row1        ,
    output  wire    [ 7:0]  mat_row2        ,
    output  wire    [ 7:0]  mat_row3        ,
    output  wire            mat_flag        ,
    output  wire            line_flag 

);
 
//========================================================================================\
//**************Define Parameter and  Internal Signals**********************************
//========================================================================================/
parameter           COL_NUM     =   320    ;
parameter           ROW_NUM     =   720     ;

reg                 [10:0]  col_cnt         ;
reg                 [10:0]  row_cnt         ;
wire                        wr_en2          ;
wire                        wr_en3          ;
wire                        rd_en1          ;
wire                        rd_en2          ;
wire                [ 7:0]  fifo1_rd_data   ;
wire                [ 7:0]  fifo2_rd_data   ;
wire                [ 7:0]  fifo3_rd_data   ;



//========================================================================================\
//**************     Main      Code        **********************************
//========================================================================================/

assign      wr_en2          =       row_cnt >= 11'd1 ? pi_flag : 1'b0;
assign      rd_en1          =       wr_en2;
assign      wr_en3          =       row_cnt >= 11'd2 ? pi_flag : 1'b0;
assign      rd_en2          =       wr_en3;
assign      mat_flag        =       row_cnt >= 11'd3 ? pi_flag : 1'b0;
assign      line_flag        =      row_cnt == 11'd0 ? pi_flag : 1'b0;
assign      mat_row1        =       fifo1_rd_data;
assign      mat_row2        =       fifo2_rd_data;
assign      mat_row3        =       fifo3_rd_data;

always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        col_cnt             <=          11'd0;
    else if(col_cnt == COL_NUM-1 && pi_flag == 1'b1)
        col_cnt             <=          11'd0;
    else if(pi_flag == 1'b1)
        col_cnt             <=          col_cnt + 1'b1;
    else
        col_cnt             <=          col_cnt;

always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        row_cnt             <=          11'd0;
    // else if(row_cnt == ROW_NUM-1 && col_cnt == COL_NUM-1 && pi_flag == 1'b1)
    //     row_cnt             <=          11'd0;
    else if(col_cnt == COL_NUM-1 && pi_flag == 1'b1) 
        row_cnt             <=          row_cnt + 1'b1;


mat_fifo mat_fifo1 (
  .wr_data              (      rx_data      ),              // input [3:0]
  .wr_en                (      pi_flag      ),              // input
  .full                 (                   ),              // output
  .almost_full          (                   ),              // output
  .rd_data              (   fifo1_rd_data   ),              // output [3:0]
  .rd_en                (       rd_en1      ),              // input
  .empty                (                   ),              // output
  .almost_empty         (                   ),              // output
  .clk                  (       sclk        ),              // input
  .rst                  (      ~rst_n       )               // input
);

mat_fifo mat_fifo2 (
  .wr_data              (   fifo1_rd_data   ),              // input [3:0]
  .wr_en                (      wr_en2       ),              // input
  .full                 (                   ),              // output
  .almost_full          (                   ),              // output
  .rd_data              (   fifo2_rd_data   ),              // output [3:0]
  .rd_en                (       rd_en2      ),              // input
  .empty                (                   ),              // output
  .almost_empty         (                   ),              // output
  .clk                  (       sclk        ),              // input
  .rst                  (      ~rst_n       )               // input
);

mat_fifo mat_fifo3 (
  .wr_data              (   fifo2_rd_data   ),              // input [3:0]
  .wr_en                (      wr_en3       ),              // input
  .full                 (                   ),              // output
  .almost_full          (                   ),              // output
  .rd_data              (   fifo3_rd_data   ),              // output [3:0]
  .rd_en                (      mat_flag     ),              // input
  .empty                (                   ),              // output
  .almost_empty         (                   ),              // output
  .clk                  (       sclk        ),              // input
  .rst                  (      ~rst_n       )               // input
);

//ԭ����FIFO IP
// fifo_generator_0 mat_fifo1 (
//   .clk              (sclk                       ),      // input wire clk
//   .srst             (~rst_n                     ),    // input wire srst
//   .din              (rx_data                    ),      // input wire [7 : 0] din
//   .wr_en            (pi_flag                    ),  // input wire wr_en
//   .rd_en            (rd_en1                     ),  // input wire rd_en
//   .dout             (fifo1_rd_data              ),    // output wire [7 : 0] dout
//   .full             (                           ),    // output wire full
//   .empty            (                           )  // output wire empty
// );
        
// fifo_generator_0 mat_fifo2 (
//   .clk              (sclk                       ),      // input wire clk
//   .srst             (~rst_n                     ),    // input wire srst
//   .din              (fifo1_rd_data              ),      // input wire [7 : 0] din
//   .wr_en            (wr_en2                     ),  // input wire wr_en
//   .rd_en            (rd_en2                     ),  // input wire rd_en
//   .dout             (fifo2_rd_data              ),    // output wire [7 : 0] dout
//   .full             (                           ),    // output wire full
//   .empty            (                           )  // output wire empty
// );
    
// fifo_generator_0 mat_fifo3 (
//   .clk              (sclk                       ),      // input wire clk
//   .srst             (~rst_n                     ),    // input wire srst
//   .din              (fifo2_rd_data              ),      // input wire [7 : 0] din
//   .wr_en            (wr_en3                     ),  // input wire wr_en
//   .rd_en            (mat_flag                   ),  // input wire rd_en
//   .dout             (fifo3_rd_data              ),    // output wire [7 : 0] dout
//   .full             (                           ),    // output wire full
//   .empty            (                           )  // output wire empty
// );
    


endmodule

