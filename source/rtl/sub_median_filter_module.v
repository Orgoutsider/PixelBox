module sub_median_filter_module#(
    parameter           COL_NUM     =   320    ,
    parameter           ROW_NUM     =   720     ,
    parameter           VALUE       =   80      
)(
    input                       sclk,
    input                       rst_n,
    input           [7:0]       rx_data,
    input                       pi_flag,
    output  reg     [7:0]       tx_data,
    output  reg                 po_flag
);



wire                [ 7:0]  mat_row1        /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
wire                [ 7:0]  mat_row2        /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
wire                [ 7:0]  mat_row3        /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
wire                        mat_flag        /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
reg                 [ 7:0]  mat_row1_1      /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
reg                 [ 7:0]  mat_row2_1      /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
reg                 [ 7:0]  mat_row3_1      /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
reg                 [ 7:0]  mat_row1_2      /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
reg                 [ 7:0]  mat_row2_2      /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
reg                 [ 7:0]  mat_row3_2      /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
reg                         mat_flag_1      /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
reg                         mat_flag_2      /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
reg                         mat_flag_3      /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
reg                         mat_flag_4      /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
reg                         mat_flag_5      /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
reg                         mat_flag_6      /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
reg                         mat_flag_7      /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/

reg                 [ 7:0]  max_h1          /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
reg                 [ 7:0]  mid_h1          /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/  
reg                 [ 7:0]  min_h1          /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/ 
reg                 [ 7:0]  max_h2          /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
reg                 [ 7:0]  mid_h2          /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/  
reg                 [ 7:0]  min_h2          /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/  
reg                 [ 7:0]  max_h3          /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
reg                 [ 7:0]  mid_h3          /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/  
reg                 [ 7:0]  min_h3          /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/ 
reg                 [ 7:0]  min_max         /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
reg                 [ 7:0]  mid_mid         /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
reg                 [ 7:0]  max_min         /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
wire                        line_flag;

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
    else if(line_flag)
        tx_data             <=          rx_data;
    else if((mid_mid >= min_max && min_max >= max_min) || (max_min >= min_max && min_max >= mid_mid))
        tx_data             <=          min_max;
    else if((min_max >= mid_mid && mid_mid >= max_min) || (max_min >= mid_mid && mid_mid >= min_max))
        tx_data             <=          mid_mid;
    else
        tx_data             <=          max_min;
          
always @(posedge sclk or negedge rst_n)
    if(rst_n == 1'b0)
        po_flag             <=          1'b0;
    // else if(mat_flag_2 == 1'b1 && mat_flag_4 == 1'b1) 
    else if(mat_flag_4 == 1'b1 || line_flag == 1'b1) 
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
    .mat_flag               (mat_flag               ),
    .line_flag               (line_flag               )

);


endmodule

