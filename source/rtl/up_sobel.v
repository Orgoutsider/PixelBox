module up_sobel(
    input                       sclk            ,
    input                       rst_n           ,
    //Communication Interfaces
    input           [15:0]     rx_data          ,
    input                      pi_flag          ,
    output          [15:0]     tx_data          ,
    output          [15:0]     o_grey_data      ,  
    output                     po_flag 
);

reg         [15:0]          r_tx_data   /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/ 
reg         [ 7:0]          r_grey8b    /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
reg         [15:0]          r_grey_data /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/

// wire signals
wire     [ 7:0]         w_grey8b        /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
wire     [ 7:0]         w_sobel_data    /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
wire     [ 15:0]         w_grey_data     /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/

rgb_togrey u_rgb_togrey(
    .i_clk               (     sclk         )   ,
    .i_rst_n             (     rst_n        )   ,
    .i_rgbdata           (     rx_data      )   ,
    .o_greydata          (     w_grey_data  )   ,
    .o_grey8b            (     w_grey8b     )   
);


sub_sobel u_sub_sobel(
    //System Interfaces
   .sclk                        (      sclk             )    ,
   .rst_n                       (      rst_n            )    ,
   .rx_data                     (      r_grey8b         )    ,
   .pi_flag                     (      pi_flag          )    ,
   .tx_data                     (      w_sobel_data     )    ,
   .po_flag                     (      po_flag          )    
);

always @(posedge sclk) begin
    r_tx_data <= {w_sobel_data[7:3], w_sobel_data[7:2], w_sobel_data[7:3]};
    r_grey8b <= w_grey8b;
    r_grey_data <= w_grey_data;
end

assign tx_data = r_tx_data;
assign o_grey_data = r_grey_data;

endmodule