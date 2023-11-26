`timescale 1ns / 1ps
// *********************************************************************************
// Project Name : OSXXXX
// Author       : zhangningning
// Email        : nnzhang1996@foxmail.com
// Website      : 
// Module Name  : sobel.v
// Create Time  : 2020-04-08 08:32:02
// Editor       : sublime text3, tab size (4)
// CopyRight(c) : All Rights Reserved
//
// *********************************************************************************
// Modification History:
// Date             By              Version                 Change Description
// -----------------------------------------------------------------------
// XXXX       zhangningning          1.0                        Original
//  
// *********************************************************************************

module sub_sobel(
    //System Interfaces
    input                   sclk            ,
    input                   rst_n           ,
    //Communication Interfaces
    input           [ 7:0]  rx_data         ,
    input                   pi_flag         ,
    output  reg     [ 7:0]  tx_data         ,
    output  reg             po_flag         
);
 
//========================================================================================\
//**************Define Parameter and  Internal Signals**********************************
//========================================================================================/
parameter           COL_NUM     =   320    ;
parameter           ROW_NUM     =   720     ;
parameter           VALUE       =   80      ;

wire                [ 7:0]  mat_row1        ;
wire                [ 7:0]  mat_row2        ;
wire                [ 7:0]  mat_row3        ;
wire                        mat_flag        ; 
reg                 [ 7:0]  mat_row1_1      ;
reg                 [ 7:0]  mat_row2_1      ;
reg                 [ 7:0]  mat_row3_1      ;
reg                 [ 7:0]  mat_row1_2      ;
reg                 [ 7:0]  mat_row2_2      ;
reg                 [ 7:0]  mat_row3_2      ;
reg                         mat_flag_1      ; 
reg                         mat_flag_2      ; 
reg                         mat_flag_3      ; 
reg                         mat_flag_4      ; 
reg                         mat_flag_5      ; 
reg                         mat_flag_6      ; 
reg                         mat_flag_7      ; 
reg                 [10:0]  row_cnt         ;
reg                 [ 7:0]  dx              ;
reg                 [ 7:0]  dy              ; 
reg                 [ 7:0]  abs_dx          ;
reg                 [ 7:0]  abs_dy          ;
reg                 [ 7:0]  abs_dxy         ;  

 
//========================================================================================\
//**************     Main      Code        **********************************
//========================================================================================/
always @(posedge sclk)
    begin
        mat_row1_1          <=          mat_row1;
        mat_row2_1          <=          mat_row2;
        mat_row3_1          <=          mat_row3;
        mat_row1_2          <=          mat_row1_1;
        mat_row2_2          <=          mat_row2_1;
        mat_row3_2          <=          mat_row3_1;
    end
    
always @(posedge sclk)
    begin
        mat_flag_1          <=          mat_flag;      
        mat_flag_2          <=          mat_flag_1;      
        mat_flag_3          <=          mat_flag_2;      
        mat_flag_4          <=          mat_flag_3;      
        mat_flag_5          <=          mat_flag_4;      
        mat_flag_6          <=          mat_flag_5;      
        mat_flag_7          <=          mat_flag_6;      
    end
    

always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        row_cnt             <=          11'd0;
    else if(row_cnt == ROW_NUM-1 && mat_flag == 1'b1)
        row_cnt             <=          11'd0;
    else if(mat_flag == 1'b1)
        row_cnt             <=          row_cnt + 1'b1;
    else
        row_cnt             <=          row_cnt;
    
always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        dx                  <=          8'd0;
    else
        dx                  <=          mat_row1_2-mat_row1+((mat_row2_2-mat_row2)<<1)+mat_row3_2-mat_row3;         
    
always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        dy                  <=          8'd0;
    else
        dy                  <=          mat_row1-mat_row3+((mat_row1_1-mat_row3_1)<<1)+mat_row1_2-mat_row3_2;
    
always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        abs_dx              <=          8'd0; 
    else if(dx[7] == 1'b1)
        abs_dx              <=          (~dx)+1'b1;
    else
        abs_dx              <=          dx;
        
always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        abs_dy              <=          8'd0; 
    else if(dy[7] == 1'b1)
        abs_dy              <=          (~dy)+1'b1;
    else
        abs_dy              <=          dy;

always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        abs_dxy             <=          8'd0; 
    else
        abs_dxy             <=          abs_dx + abs_dy;
        
always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        tx_data             <=          8'd0; 
    else if(abs_dxy >= VALUE)
        tx_data             <=          8'd0;
    else
        tx_data             <=          8'd255;
          
always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        po_flag             <=          1'b0;
    else if(mat_flag_3 == 1'b1 && mat_flag_5 == 1'b1) 
        po_flag             <=          1'b1;
    else
        po_flag             <=          1'b0;      
        

mat_3x3 mat_3x3_inst(
    //System Interfaces
    .sclk                   (sclk                   ),
    .rst_n                  (rst_n                  ),
    //Communication Interfaces
    .rx_data                (rx_data                ),
    .pi_flag                (pi_flag                ),
    .mat_row1               (mat_row1               ),
    .mat_row2               (mat_row2               ),
    .mat_row3               (mat_row3               ),
    .mat_flag               (mat_flag               )

);
 

endmodule