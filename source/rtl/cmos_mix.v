module cmos_mix#(
    parameter H_ACT = 12'd320,
    parameter H_OFFSET = 12'd80,
    parameter LEFT = 1'b1
)
(
    input pixel_clk,
    input [15:0] pdata_i,
    input de_i,
    input vs_i,
    input [1:0] gamma_ctrl,
    input [1:0] saturation_ctrl,
    output reg [15:0] pdata_o,
    output reg de_o,
    output reg vs_o
);
localparam H_BEGIN = LEFT ? (H_ACT - H_OFFSET - 1'b1) : H_OFFSET;

reg [11:0] x_cnt;
wire RGB_de;
wire RGB_vs;
wire [15:0] gamma_data_raw;
wire [15:0] gamma_data_sqrt;
wire [15:0] gamma_data_square;
reg [15:0] gamma_data;
wire gamma_de;
wire gamma_vs;
wire [15:0] saturation_data_raw;
wire [15:0] saturation_data_dst;
wire saturation_de;
wire saturation_vs;
reg [1:0] gamma_ctrl_1d;
reg [1:0] gamma_ctrl_2d;
reg saturation_ctrl_1d;
reg saturation_ctrl_2d;
reg sobel_ctrl_1d;
reg sobel_ctrl_2d;

wire [7:0]  rx_RGB_DATA_R/*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
wire [7:0]  rx_RGB_DATA_G/*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
wire [7:0]  rx_RGB_DATA_B/*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/

wire [7:0]  tx_RGB_DATA_R /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
wire [7:0]  tx_RGB_DATA_G /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
wire [7:0]  tx_RGB_DATA_B /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/

// wire [7:0]  o_sobel_RGB_DATA_R /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
// wire [7:0]  o_sobel_RGB_DATA_G /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
// wire [7:0]  o_sobel_RGB_DATA_B /*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/

// wire [7:0]  o_sobel_data_R/*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
// wire [7:0]  o_sobel_data_G/*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
// wire [7:0]  o_sobel_data_B/*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/

wire [15:0] o_sobel_data/*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
wire [15:0] o_greydata/*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
wire [ 7:0] o_greydata_8b/*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/

wire [4:0] median_filter_data_R/*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
wire [5:0] median_filter_data_G/*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
wire [4:0] median_filter_data_B/*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
// wire [15:0] median_filter_data/*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
wire median_filter_de;
wire median_filter_vs;

wire sobel_de/*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
wire sobel_vs;

wire grey_de;
wire grey_vs;

wire median_filter_rst;
// reg enable = 1'b0;
// reg enable_1d;
reg saturation_vs_1d;
reg [15:0] median_filter_data/*synthesis PAP_MARK_DEBUG="1"*/;/*synthesis PAP_MARK_DEBUG="1"*/
// reg [7:0 ] gray_data;

always @(posedge pixel_clk) begin
    saturation_vs_1d <= saturation_vs;
    gamma_ctrl_1d <= gamma_ctrl;
    gamma_ctrl_2d <= gamma_ctrl_1d;
    saturation_ctrl_1d <= (saturation_ctrl == 2'd1);
    saturation_ctrl_2d <= saturation_ctrl_1d;
    sobel_ctrl_1d <= (saturation_ctrl == 2'd2);
    sobel_ctrl_2d <= sobel_ctrl_1d;
    // enable_1d <= enable;
    // if(~saturation_vs_1d & saturation_vs)
    //     enable <= 1'b1;
    // else
    //     enable <= enable; 
end

assign median_filter_rst = ~saturation_vs_1d & saturation_vs;

// //RGB_565 TO RGB_888
// wire [7:0]  rx_RGB_DATA_R;
// wire [7:0]  rx_RGB_DATA_G;
// wire [7:0]  rx_RGB_DATA_B;

// wire [7:0]  tx_RGB_DATA_R;
// wire [7:0]  tx_RGB_DATA_G;
// wire [7:0]  tx_RGB_DATA_B;  

// assign rx_RGB_DATA_R = {pdata_i[15:11], 3'd0};
// assign rx_RGB_DATA_G = {pdata_i[10:5 ], 2'd0};
// assign rx_RGB_DATA_B = {pdata_i[ 4:0 ], 3'd0};
// //RGB_565 TO RGB_888
    RGB_565TO888    u_rgb528(
        .i_rgbdata_r        ( median_filter_data[15:11]),
        .i_rgbdata_g        ( median_filter_data[10:5] ),
        .i_rgbdata_b        ( median_filter_data[4:0]  ),
        .o_rgbdata_r        ( rx_RGB_DATA_R ),
        .o_rgbdata_g        ( rx_RGB_DATA_G ),
        .o_rgbdata_b        ( rx_RGB_DATA_B )
    );



    always @(posedge pixel_clk) begin
        if (de_i)
            x_cnt <= x_cnt + 1'b1;
        else
            x_cnt <= 12'd0; 
    end

    assign RGB_de = (x_cnt >= H_BEGIN) && (x_cnt < H_BEGIN + H_ACT) && de_i;
    assign RGB_vs = vs_i;

    gamma u_gamma(
        .clk(pixel_clk),// input clk,
        .RGB_data(pdata_i),// input [15:0] RGB_data,
        .RGB_de(RGB_de),
        .RGB_vs(RGB_vs),
        .gamma_data_raw(gamma_data_raw),//gamma_data_raw
        .gamma_data_sqrt(gamma_data_sqrt),// output [15:0] gamma_data_sqrt,
        .gamma_data_square(gamma_data_square),// output [15:0] gamma_data_square
        .gamma_de(gamma_de),
        .gamma_vs(gamma_vs)
    );

    saturation u_saturation(
        .clk(pixel_clk),// input clk,
        .RGB_data(gamma_data),// input [15:0] RGB_data,
        .RGB_de(gamma_de),// input RGB_de,
        .RGB_vs(gamma_vs),// input RGB_vs,
        .saturation_data_raw(saturation_data_raw),// output reg [15:0] saturation_data_raw,
        .saturation_data_dst(saturation_data_dst),// output [15:0] saturation_data_dst,
        .saturation_de(saturation_de),// output reg saturation_de,
        .saturation_vs(saturation_vs)// output reg saturation_vs
    );

    up_median_filter u_up_median_filter(
        .sclk                       (   pixel_clk       ),
        .rst_n                      (   ~median_filter_rst   ),
        //Communication Interfaces
        .rx_data_R                  ( rx_RGB_DATA_R     ),
        .rx_data_G                  ( rx_RGB_DATA_G     ),
        .rx_data_B                  ( rx_RGB_DATA_B     ),
        .pi_flag                    ( saturation_de     ),
        .i_vs                       ( saturation_vs     ),
        .tx_data_R                  ( tx_RGB_DATA_R     ),
        .tx_data_G                  ( tx_RGB_DATA_G     ),
        .tx_data_B                  ( tx_RGB_DATA_B     ),
        .po_flag                    ( median_filter_de  ),
        .o_vs                       ( median_filter_vs  )
        
    );
    // up_sobel  u_up_sobel(
    //     .sclk                       (   pixel_clk           ),
    //     .rst_n                      (   ~median_filter_rst  ),
    //     .rx_data_R                  (   rx_RGB_DATA_R       ),
    //     .rx_data_G                  (   rx_RGB_DATA_G       ),
    //     .rx_data_B                  (   rx_RGB_DATA_B       ),
    //     .pi_flag                    (   saturation_de       ),
    //     .tx_data_R                  (   o_sobel_RGB_DATA_R  ),
    //     .tx_data_G                  (   o_sobel_RGB_DATA_G  ),
    //     .tx_data_B                  (   o_sobel_RGB_DATA_B  ),
    //     .po_flag                    (   sobel_de            )   
    // );
    
    // up_sobel    u_up_sobel(
    //     .sclk               (    pixel_clk              )    ,
    //     .rst_n              (    ~median_filter_rst     )    ,
    //     .rx_data            (    median_filter_data     )    ,
    //     .pi_flag            (    saturation_de          )    ,
    //     .tx_data            (    o_sobel_data           )    ,
    //     .o_grey_data        (    o_greydata           )    ,
    //     .po_flag            (    sobel_de               )
    // );

    // rgb_togrey u_rgb_togrey(
    //     .i_clk            (    pixel_clk            )   ,
    //     .i_rst_n          (    ~median_filter_rst   )   ,
    //     .i_rgbdata        (    median_filter_data   )   ,
    //     .i_de             (    median_filter_de     )   ,
    //     .i_vs             (    median_filter_vs     )   ,
    //     .o_greydata       (    o_greydata           )   ,
    //     .o_grey8b         (    o_greydata_8b        )   ,
    //     .o_de             (    grey_de              )   ,                            ,
    //     .o_vs             (    grey_vs              )   
    // );

    rgb_togrey u_rgb_togrey(
        .i_clk         (    pixel_clk           )     ,
        .i_rst_n       (    ~median_filter_rst  )     ,
        .i_rgbdata     (    {median_filter_data_R,median_filter_data_G,median_filter_data_B}  )     ,
        .i_de          (    median_filter_de    )     ,
        .i_vs          (    median_filter_vs    )     ,
        .o_greydata    (    o_greydata          )     ,
        .o_grey8b      (    o_greydata_8b       )     ,
        .o_de          (    grey_de             )     ,
        .o_vs          (    grey_vs             )     
    );

    sobel    u_sobel(
        .sclk               (    pixel_clk              )   ,
        .rst_n              (    ~median_filter_rst     )   ,
        .rx_data            (    o_greydata_8b          )   ,
        .i_de               (    grey_de                )   ,
        .i_vs               (    grey_vs                )   ,
        .tx_data            (    o_sobel_data           )   ,
        .o_de               (    sobel_de               )   ,
        .o_vs               (    sobel_vs               )
    );

    RGB_888TO565    u_rgb825(
        .i_rgbdata_r                ( tx_RGB_DATA_R         ),
        .i_rgbdata_g                ( tx_RGB_DATA_G         ),
        .i_rgbdata_b                ( tx_RGB_DATA_B         ),
        .o_rgbdata_r                ( median_filter_data_R  ),
        .o_rgbdata_g                ( median_filter_data_G  ),
        .o_rgbdata_b                ( median_filter_data_B  )
    );

    // RGB_888TO565    u_sobel_rgb825(
    //     .i_rgbdata_r                ( o_sobel_RGB_DATA_R    ),
    //     .i_rgbdata_g                ( o_sobel_RGB_DATA_G    ),
    //     .i_rgbdata_b                ( o_sobel_RGB_DATA_B    ),
    //     .o_rgbdata_r                ( o_sobel_data_R        ),
    //     .o_rgbdata_g                ( o_sobel_data_G        ),
    //     .o_rgbdata_b                ( o_sobel_data_B        )
    // );

    // assign  pdata_o = {median_filter_data_R,median_filter_data_G,median_filter_data_B};
    // assign  pdata_o = o_sobel_data;
    // assign  pdata_o = o_greydata;
    // assign de_o = median_filter_de;
    // assign de_o = sobel_de      ;
    // assign vs_o = sobel_vs      ;

    always @(*) begin
        case (gamma_ctrl_2d)
            2'd0: gamma_data = gamma_data_raw;
            2'd1: gamma_data = gamma_data_square;
            2'd2: gamma_data = gamma_data_sqrt;
            default: gamma_data = gamma_data_raw;
        endcase
    end

    always @(*) begin
        if (saturation_ctrl_2d)
            median_filter_data = saturation_data_dst;
        else
            median_filter_data = saturation_data_raw; 
    end

    always @(*) begin
    if (sobel_ctrl_2d)
        pdata_o = o_sobel_data;
    else 
        pdata_o = {median_filter_data_R,median_filter_data_G,median_filter_data_B}  ;
    end

    always @(*) begin
    if (sobel_ctrl_2d)
        de_o = sobel_de;
    else 
        de_o = median_filter_de;
    end

    always @(*) begin
    if (sobel_ctrl_2d)
        vs_o = sobel_vs;
    else 
        vs_o = median_filter_vs;
    end
endmodule