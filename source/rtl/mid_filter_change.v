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

module median_filter(
    //System Interfaces
    input                   sclk            ,
    input                   rst_n           ,
    //Communication Interfaces
    input           [ 23:0]  rx_data         ,
    input                   pi_flag         ,
    output  reg     [ 23:0]  tx_data         ,
    output  reg             po_flag 
    );
 
//========================================================================================\
//**************Define Parameter and  Internal Signals**********************************
//========================================================================================/
parameter           COL_NUM     =   1024    ;
parameter           ROW_NUM     =   768     ;
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

reg                 [ 7:0]  max_h1          ;
reg                 [ 7:0]  mid_h1          ;  
reg                 [ 7:0]  min_h1          ; 
reg                 [ 7:0]  max_h2          ;
reg                 [ 7:0]  mid_h2          ;  
reg                 [ 7:0]  min_h2          ;  
reg                 [ 7:0]  max_h3          ;
reg                 [ 7:0]  mid_h3          ;  
reg                 [ 7:0]  min_h3          ; 
reg                 [ 7:0]  min_max         ;
reg                 [ 7:0]  mid_mid         ;
reg                 [ 7:0]  max_min         ;       
  

 
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
        max_h1              <=          8'd0;        
    else if(mat_row1 >= mat_row1_1 && mat_row1 >= mat_row1_2)
        max_h1              <=          mat_row1;
    else if(mat_row1_1 >= mat_row1 && mat_row1_1 >= mat_row1_2) 
        max_h1              <=          mat_row1_1;
    else
        max_h1              <=          mat_row1_2;

always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        mid_h1              <=          8'd0;        
    else if((mat_row1 >= mat_row1_1 && mat_row1_1 >= mat_row1_2) || (mat_row1_2 >= mat_row1_1 && mat_row1_1 >= mat_row1))
        mid_h1              <=          mat_row1_1;
    else if((mat_row1_1 >= mat_row1 && mat_row1 >= mat_row1_2) || (mat_row1_2 >= mat_row1 && mat_row1 >= mat_row1_1))
        mid_h1              <=          mat_row1;
    else
        mid_h1              <=          mat_row1_2;
          
always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        min_h1              <=          8'd0;        
    else if(mat_row1 <= mat_row1_1 && mat_row1 <= mat_row1_2)
        min_h1              <=          mat_row1;
    else if(mat_row1_1 <= mat_row1 && mat_row1_1 <= mat_row1_2) 
        min_h1              <=          mat_row1_1;
    else
        min_h1              <=          mat_row1_2;  

always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        max_h2              <=          8'd0;        
    else if(mat_row2 >= mat_row2_1 && mat_row2 >= mat_row2_2)
        max_h2              <=          mat_row2;
    else if(mat_row2_1 >= mat_row2 && mat_row2_1 >= mat_row2_2) 
        max_h2              <=          mat_row2_1;
    else
        max_h2              <=          mat_row2_2;

always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        mid_h2              <=          8'd0;        
    else if((mat_row2 >= mat_row2_1 && mat_row2_1 >= mat_row2_2) || (mat_row2_2 >= mat_row2_1 && mat_row2_1 >= mat_row2))
        mid_h2              <=          mat_row2_1;
    else if((mat_row2_1 >= mat_row2 && mat_row2 >= mat_row2_2) || (mat_row2_2 >= mat_row2 && mat_row2 >= mat_row2_1))
        mid_h2              <=          mat_row2;
    else
        mid_h2              <=          mat_row2_2;
          
always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        min_h2              <=          8'd0;        
    else if(mat_row2 <= mat_row2_1 && mat_row2 <= mat_row2_2)
        min_h2              <=          mat_row2;
    else if(mat_row2_1 <= mat_row2 && mat_row2_1 <= mat_row2_2) 
        min_h2              <=          mat_row2_1;
    else
        min_h2              <=          mat_row2_2;  

always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        max_h3              <=          8'd0;        
    else if(mat_row3 >= mat_row3_1 && mat_row3 >= mat_row3_2)
        max_h3              <=          mat_row3;
    else if(mat_row3_1 >= mat_row3 && mat_row3_1 >= mat_row3_2) 
        max_h3              <=          mat_row3_1;
    else
        max_h3              <=          mat_row3_2;

always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        mid_h3              <=          8'd0;        
    else if((mat_row3 >= mat_row3_1 && mat_row3_1 >= mat_row3_2) || (mat_row3_2 >= mat_row3_1 && mat_row3_1 >= mat_row3))
        mid_h3              <=          mat_row3_1;
    else if((mat_row3_1 >= mat_row3 && mat_row3 >= mat_row3_2) || (mat_row3_2 >= mat_row3 && mat_row3 >= mat_row3_1)) 
        mid_h3              <=          mat_row3;
    else
        mid_h3              <=          mat_row3_2;
 
          
always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        min_h3              <=          8'd0;        
    else if(mat_row3 <= mat_row3_1 && mat_row3 <= mat_row3_2)
        min_h3              <=          mat_row3;
    else if(mat_row3_1 <= mat_row3 && mat_row3_1 <= mat_row3_2) 
        min_h3              <=          mat_row3_1;
    else
        min_h3              <=          mat_row3_2;


always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        min_max             <=          8'd0;
    else if(max_h1 <= max_h2 && max_h1 <= max_h3)
        min_max             <=          max_h1;
    else if(max_h2 <= max_h1 && max_h2 <= max_h3)
        min_max             <=          max_h2;
    else
        min_max             <=          max_h3;
          
   
always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        mid_mid             <=          8'd0;
    else if((mid_h1 >= mid_h2 && mid_h2 >= mid_h3) || (mid_h3 >= mid_h2 && mid_h2 >= mid_h1))
        mid_mid             <=          mid_h2;
    else if((mid_h2 >= mid_h1 && mid_h1 >= mid_h3) || (mid_h3 >= mid_h1 && mid_h1 >= mid_h2))
        mid_mid             <=          mid_h1;
    else
        mid_mid             <=          mid_h3;

always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        max_min             <=          8'd0;
    else if(min_h1 <= min_h2 && min_h1 <= min_h3) 
        max_min             <=          min_h1;
    else if(min_h2 <= min_h1 && min_h2 <= min_h3)
        max_min             <=          min_h2;
    else
        max_min             <=          min_h3;
           
always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        tx_data             <=          8'd0; 
    else if((mid_mid >= min_max && min_max >= max_min) || (max_min >= min_max && min_max >= mid_mid))
        tx_data             <=          min_max;
    else if((min_max >= mid_mid && mid_mid >= max_min) || (max_min >= mid_mid && mid_mid >= min_max))
        tx_data             <=          mid_mid;
    else
        tx_data             <=          max_min;
          
always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        po_flag             <=          1'b0;
    else if(mat_flag_2 == 1'b1 && mat_flag_4 == 1'b1) 
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