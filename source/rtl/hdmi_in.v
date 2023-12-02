module hdmi_in # (
    parameter H_ACT = 12'd640,
    parameter V_ACT = 12'd720
)
(
    input pixclk_in,
    input init_over_tx, // д��ʼ������
    input vs_in,
    input hs_in,
    input de_in /*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/
    input [7:0] r_in,
    input [7:0] g_in,
    input [7:0] b_in,
    // input scaler_ctrl, 
    input [5:0] scaler_ctrl_width, 
    input [6:0] scaler_ctrl_height, 
    input color_reverse_ctrl,
    input [5:0] panning_y_ctrl,
    input [6:0] panning_x_ctrl,

    output reg vs_out /*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/
    output reg hs_out /*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/
    output reg de_out /*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/
    output [23:0] data_out /*synthesis PAP_MARK_DEBUG="1"*/
);
//--------------------------------------------���űȶ���������------------------------------------------------------//
    parameter INT_WIDTH   = 8;   // ����λ��
    parameter FIX_WIDTH   = 12;  // С��λ��

    parameter SRC_IMAGE_WIDTH  = H_ACT; // ԭͼ��
    parameter SRC_IMAGE_HEIGHT = V_ACT; // ԭͼ��

    parameter DEST_IMAGE_WIDTH  = 400; // Ŀ��ͼ��
    parameter DEST_IMAGE_HEIGHT = 500; // Ŀ��ͼ��

    parameter SCALE_INTX = SRC_IMAGE_WIDTH  / DEST_IMAGE_WIDTH;  // ��������x��������
    parameter SCALE_INTY = SRC_IMAGE_HEIGHT / DEST_IMAGE_HEIGHT; // ��������y��������

    parameter SCALE_FRACX = ((SRC_IMAGE_WIDTH  - SCALE_INTX * DEST_IMAGE_WIDTH)  << FIX_WIDTH) / DEST_IMAGE_WIDTH; //��������xС������
    parameter SCALE_FRACY = ((SRC_IMAGE_HEIGHT - SCALE_INTY * DEST_IMAGE_HEIGHT) << FIX_WIDTH) / DEST_IMAGE_HEIGHT; //��������yС������

    parameter SCALE_FACTORX = (SCALE_INTX  << FIX_WIDTH) + SCALE_FRACX; //SRC_IMAGE_WIDTH / DEST_IMAGE_WIDTH
    parameter SCALE_FACTORY = (SCALE_INTY  << FIX_WIDTH) + SCALE_FRACY; //SRC_IMAGE_HEIGHT / DEST_IMAGE_HEIGHT

    wire [7:0] r_o;/*synthesis PAP_MARK_DEBUG="1"*/
    wire [7:0] g_o;/*synthesis PAP_MARK_DEBUG="1"*/
    wire [7:0] b_o;/*synthesis PAP_MARK_DEBUG="1"*/
    reg [11:0] h_cnt; /*synthesis PAP_MARK_DEBUG="1"*/
    reg [11:0] v_cnt;     /*synthesis PAP_MARK_DEBUG="1"*/
    reg [11:0] black_cnt; /*synthesis PAP_MARK_DEBUG="1"*/
    reg o_de_scaler_1d;   /*synthesis PAP_MARK_DEBUG="1"*/
    reg o_de_scaler_2d;
    reg  vs_in_1d;        /*synthesis PAP_MARK_DEBUG="1"*/
    reg  de_in_1d;        /*synthesis PAP_MARK_DEBUG="1"*/
    reg  i_de_scaler;     /*synthesis PAP_MARK_DEBUG="1"*/ // ��������ģ���de
    wire o_de_scaler_r;   /*synthesis PAP_MARK_DEBUG="1"*/ // ����ģ�������de
    wire o_de_scaler_g;   /*synthesis PAP_MARK_DEBUG="1"*/ // ����ģ�������de
    wire o_de_scaler_b;   /*synthesis PAP_MARK_DEBUG="1"*/ // ����ģ�������de
    wire rst_scaler;      /*synthesis PAP_MARK_DEBUG="1"*/ 
    reg  scaler_ctrl_1d;  /*synthesis PAP_MARK_DEBUG="1"*/
    reg  scaler_ctrl_2d;  /*synthesis PAP_MARK_DEBUG="1"*/
    wire tready_o_r;      /*synthesis PAP_MARK_DEBUG="1"*/
    wire tready_o_g;      /*synthesis PAP_MARK_DEBUG="1"*/
    wire tready_o_b;      /*synthesis PAP_MARK_DEBUG="1"*/
    reg [16:0] scaler_de_cnt;   /*synthesis PAP_MARK_DEBUG="1"*/
    reg [16:0] de_row_cnt; /*synthesis PAP_MARK_DEBUG="1"*/
    reg [16:0] de_out_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
    reg vs_state;/*synthesis PAP_MARK_DEBUG="1"*/
    reg vs_out_1d;/*synthesis PAP_MARK_DEBUG="1"*/
    reg [16:0] real_de_row_cnt;/*synthesis PAP_MARK_DEBUG="1"*/
    reg de_out_1d;/*synthesis PAP_MARK_DEBUG="1"*/

    reg [5:0] scaler_ctrl_width_1d;//0-63
    reg [5:0] scaler_ctrl_width_2d;//0-63
    reg [6:0] scaler_ctrl_height_1d;//0-71
    reg [6:0] scaler_ctrl_height_2d;//0-71
    reg color_reverse_ctrl_1d;//0-1
    reg color_reverse_ctrl_2d;//0-1
    reg [5:0] panning_y_ctrl_1d;//0-36
    reg [5:0] panning_y_ctrl_2d;//0-36
    reg [6:0] panning_x_ctrl_1d;//0-64
    reg [6:0] panning_x_ctrl_2d;//0-64

    reg [11:0] dest_width_i = 'd640; /*synthesis PAP_MARK_DEBUG="1"*/
    reg [11:0] dest_height_i  = 'd720; /*synthesis PAP_MARK_DEBUG="1"*/
    reg [INT_WIDTH-1:0] scale_intx;/*synthesis PAP_MARK_DEBUG="1"*/
    reg [INT_WIDTH-1:0] scale_inty;/*synthesis PAP_MARK_DEBUG="1"*/
    reg [FIX_WIDTH-1:0] scale_fracx;/*synthesis PAP_MARK_DEBUG="1"*/
    reg [FIX_WIDTH-1:0] scale_fracy;/*synthesis PAP_MARK_DEBUG="1"*/
    reg [INT_WIDTH + FIX_WIDTH - 1:0] scale_factorx;/*synthesis PAP_MARK_DEBUG="1"*/
    reg [INT_WIDTH + FIX_WIDTH - 1:0] scale_factory;/*synthesis PAP_MARK_DEBUG="1"*/

    reg [8:0] offset_y;/*synthesis PAP_MARK_DEBUG="1"*/
    reg [9:0] offset_x;/*synthesis PAP_MARK_DEBUG="1"*/
    
    `include "get_fracx.v"
    `include "get_fracy.v"
    `include "get_offset_y.v"
    `include "get_offset_x.v"
    `include "get_intx.v"
    `include "get_inty.v"

    always @(posedge pixclk_in) begin
        scale_fracx <= get_fracx(scaler_ctrl_width_2d);
    end
    always @(posedge pixclk_in) begin
        scale_fracy <= get_fracy(scaler_ctrl_height_2d);
    end

    always @(posedge pixclk_in) begin
        offset_y <= get_offset_y(panning_y_ctrl_2d);
    end
    always @(posedge pixclk_in) begin
        offset_x <= get_offset_x(panning_x_ctrl_2d);
    end

    always @(*) begin
        scale_factorx = (scale_intx  << FIX_WIDTH) + scale_fracx;
        scale_factory = (scale_inty  << FIX_WIDTH) + scale_fracy;
    end

    always @(posedge pixclk_in) begin
        scale_intx <= get_intx(scaler_ctrl_width_2d);
        scale_inty <= get_inty(scaler_ctrl_height_2d);
    end

    always @(posedge pixclk_in) begin
        if (scaler_ctrl_width_2d <= 6'd31) begin
            dest_width_i <= 12'd640 - scaler_ctrl_width_2d * 6'd20;
        end
        else begin
            dest_width_i <= scaler_ctrl_width_2d * 6'd20 - 12'd600;
        end
    end

    always @(posedge pixclk_in) begin
        if (scaler_ctrl_height_2d <= 7'd35) begin
            dest_height_i <= 12'd720 - scaler_ctrl_height_2d * 6'd20;
        end
        else begin
            dest_height_i <= scaler_ctrl_height_2d * 6'd20 - 12'd700;
        end
    end

    always @(posedge pixclk_in) begin
        scaler_ctrl_width_1d <= scaler_ctrl_width;
        scaler_ctrl_width_2d <= scaler_ctrl_width_1d;
    end

    always @(posedge pixclk_in) begin
        scaler_ctrl_height_1d <= scaler_ctrl_height;
        scaler_ctrl_height_2d <= scaler_ctrl_height_1d;
    end

    always @(posedge pixclk_in) begin
        color_reverse_ctrl_1d <= color_reverse_ctrl;
        color_reverse_ctrl_2d <= color_reverse_ctrl_1d;
    end
    always @(posedge pixclk_in) begin
        panning_y_ctrl_1d <= panning_y_ctrl;
        panning_y_ctrl_2d <= panning_y_ctrl_1d;
    end
    always @(posedge pixclk_in) begin
        panning_x_ctrl_1d <= panning_x_ctrl;
        panning_x_ctrl_2d <= panning_x_ctrl_1d;
    end


    // always @(posedge pixclk_in) begin
    //     de_out_1d <= de_out;        
    // end
    
    // always @(posedge pixclk_in) begin
    //     if (!init_over_tx) begin
    //         vs_state <= 0;
    //     end
    //     else if (vs_out & ~vs_out_1d) begin 
    //         vs_state <= ~vs_state;
    //     
    // end

    // �����?720�����⵽�׶��ٺ���
    // always @(posedge pixclk_in) begin
    //     if(!init_over_tx) begin
    //         real_de_row_cnt <= 0;
    //     end
    //     else if ((v_cnt > V_ACT - 1'b1) && (de_out & ~de_out_1d)) begin
    //         real_de_row_cnt <= real_de_row_cnt + 1;
    //     end
    //     else if (~vs_in_1d & vs_in) begin
    //         real_de_row_cnt <= 0;
    //     end
    //     else if (vs_state == 0) begin
    //         real_de_row_cnt <= 0;
    //     end
    // end
    // scaler �����de����
    always @(posedge pixclk_in) begin
        if (!init_over_tx) begin
            scaler_de_cnt <= 0;
        end
        else if (o_de_scaler_1d && de_row_cnt == 1) begin
            scaler_de_cnt <= scaler_de_cnt + 1;
        end
    end

    // hdmi�����de����
    always @(posedge pixclk_in) begin
        if (!init_over_tx) begin
            de_out_cnt <= 0;
        end
        else if (de_out  && de_row_cnt == 1) begin
            de_out_cnt <= de_out_cnt + 1;
       end 
    end

    //�м���
    always @(posedge pixclk_in) begin
        if (!init_over_tx) begin    
            de_row_cnt <= 0;
        end
        if (o_de_scaler_1d & ~o_de_scaler_2d) begin
            de_row_cnt <= de_row_cnt + 1; 
        end
    end


    always  @(posedge pixclk_in) begin
        if(!init_over_tx)begin
            vs_out  <=  1'b0        ;
            hs_out  <=  1'b0        ;
            i_de_scaler   <=  1'b0        ;
        end
    	else begin
            // vs_out  <=  vs_in ; // ֡��ͷ�ͽ�β��һ��
            // vs_out  <=  vs_in || (v_cnt >= 900); // ֡��ͷ�ͽ�β��һ��
            vs_out  <=  vs_in || (v_cnt >= 1080 - offset_y); // ֡��ͷ�ͽ�β��һ��
            hs_out  <=  hs_in;
            i_de_scaler    <=  ((tready_o_r && tready_o_g && tready_o_b) && de_in && (h_cnt < H_ACT + 2) && (v_cnt < V_ACT)) ;
        end
    end


    
    reg [23:0] delay_data;/*synthesis PAP_MARK_DEBUG="1"*/
    wire [15:0] delay_c;/*synthesis PAP_MARK_DEBUG="1"*/
    delay_laps#(    
        .MAX_DATA_WIDTH(24),
        .MAX_DELAY_LAPS(640)
    ) u_delay_laps(
        .clk(pixclk_in),
        .rst_n(init_over_tx),
        .i_data(delay_data),
        .delaylap(offset_x),
        .o_data(data_out),
        .delay_cnt(delay_c)
    );

    always @(posedge pixclk_in) begin
        if (!init_over_tx) begin
            delay_data <= 0;
        end
        else begin
            if (o_de_scaler_r) begin
                if (color_reverse_ctrl_2d)
                    delay_data <= {~r_o, ~g_o, ~b_o};
                else begin
                    delay_data <= {r_o, g_o, b_o};
                end
            end
            else 
                delay_data <= 0;
        end
    end
    
    //������м���h
    always @(posedge pixclk_in) begin
        if (!de_in)
            h_cnt <= 12'd0;
        else
            h_cnt <= h_cnt + 1'b1;
    end

    // �����м���
    always @(posedge pixclk_in) begin
        if(!init_over_tx)begin
            v_cnt <= 12'd0;
        end
        else begin
            if (~vs_in_1d & vs_in) // ���vs�������أ�˵����һ֡���ˣ�vs_cnt�м�������
                v_cnt <= 12'd0;
            else if (de_in_1d & ~de_in) // ���de�����أ�˵����һ�����ˣ�vs_cnt�м���+1
                v_cnt <= v_cnt + 1'b1;
        end
    end

    always @(posedge pixclk_in) begin
        vs_in_1d <= vs_in;
        de_in_1d <= de_in;
    end

    assign rst_scaler = (vs_in & ~vs_in_1d);
    

    // ��һ�ģ������½���
    always @(posedge pixclk_in) begin
        o_de_scaler_1d <= o_de_scaler_r;
        o_de_scaler_2d <= o_de_scaler_1d;
    end


    // ��ɫ�ؼ���
    always @(posedge pixclk_in) begin
        if(!init_over_tx)
            black_cnt <= dest_width_i;
        else if(~o_de_scaler_1d & o_de_scaler_2d)//һ�����½��ؾͿ�ʼ����
            black_cnt <= dest_width_i + 1;
        else begin
            if(black_cnt >= H_ACT)
                black_cnt <= black_cnt;
            else
                black_cnt <= black_cnt + 1;
        end 
    end

    always @(posedge pixclk_in)  begin   
        if (!init_over_tx) begin
            de_out <= 0;
        end
        else begin
            // de_out <= o_de_scaler_r || (o_de_scaler_1d & ~o_de_scaler_r) || (black_cnt < H_ACT);
            de_out <=  (scaler_ctrl_width_2d == 0 || scaler_ctrl_width_2d == 62) ? 
                       ((o_de_scaler_1d)||(((h_cnt < H_ACT) || ((H_ACT + H_ACT + 20 > h_cnt) && (h_cnt > H_ACT + 20))) && (v_cnt > V_ACT - 1'b1) && de_in)) :
                       ((o_de_scaler_1d || (o_de_scaler_2d & ~o_de_scaler_1d) || (black_cnt < H_ACT)) ||  (((h_cnt < H_ACT) || ((H_ACT + H_ACT + 20 > h_cnt) && (h_cnt > H_ACT + 20))) && (v_cnt > V_ACT - 1'b1) && de_in));
            // de_out <=  ((o_de_scaler_r || (o_de_scaler_1d & ~o_de_scaler_r) || (black_cnt < H_ACT)) ||  (((h_cnt < H_ACT) || ((H_ACT + H_ACT + 20 > h_cnt) && (h_cnt > H_ACT + 20))) && (v_cnt > V_ACT - 1'b1) && de_in));
            // de_out <=  ((o_de_scaler_r || (o_de_scaler_1d & ~o_de_scaler_r) || (black_cnt < H_ACT)) ||  ((h_cnt < H_ACT) && (v_cnt > V_ACT - 1'b1) && de_in));
        
        end
    end


scaler_gray_top #(
        .ADJUST_MODE(1), // �������ص���㷽ʽ��ֱ�Ӽ���?0 ���� ���Ķ���1
        .BRAM_DEEPTH(1280),//src_width_i * 2
        .DATA_WIDTH(8), // ÿ��ͨ����������
        .INDEX_WIDTH(11), // �������ȣ���ͼ�γ����ķ�Χ
        .INT_WIDTH(8),   // 
        .FIX_WIDTH(12)
) u_image_scaler_r (
        .clk_i(pixclk_in), // ʱ��
        .rst_i(rst_scaler), // ��λ
        
        .tvalid_i(i_de_scaler), // ����de
        .tdata_i(r_in),  //��������
        .tready_o(tready_o_r), // ������������
        
        
        .src_width_i(H_ACT),// ����ͼ��Ŀ�?
        .src_height_i(V_ACT),// ����ͼ��ĸ�?
        .dest_width_i(dest_width_i),  //  Ŀ��ͼ��Ŀ�?
        .dest_height_i(dest_height_i),//  Ŀ��ͼ��ĸ�?                                                                             

        .scale_factorx_i(scale_factorx), //srcx_width / destx_width x�������ű�
        .scale_factory_i(scale_factory), //srcy_height / desty_height y�������ű�

        .tvalid_o(o_de_scaler_r), // ���de
        .tdata_o(r_o)   // �������?                                                        
        );

scaler_gray_top #(
        .ADJUST_MODE(1), // �������ص���㷽ʽ��ֱ�Ӽ���?0 ���� ���Ķ���1
        .BRAM_DEEPTH(1280),//src_width_i * 2
        .DATA_WIDTH(8), // ÿ��ͨ����������
        .INDEX_WIDTH(11), // �������ȣ���ͼ�γ����ķ�Χ
        .INT_WIDTH(8),   // <= INDEX_WIDTH
        .FIX_WIDTH(12)
) u_image_scaler_g (
        .clk_i(pixclk_in), // ʱ��
        .rst_i(rst_scaler), // ��λ
        
        .tvalid_i(i_de_scaler), // ����de
        .tdata_i(g_in),  //��������
        .tready_o(tready_o_g), // 
        
        
        .src_width_i(H_ACT),// ����ͼ��Ŀ�?
        .src_height_i(V_ACT),// ����ͼ��ĸ�?
        .dest_width_i(dest_width_i),  //  Ŀ��ͼ��Ŀ�?
        .dest_height_i(dest_height_i),//  Ŀ��ͼ��ĸ�?                                                                             

        .scale_factorx_i(scale_factorx), //srcx_width / destx_width x�������ű�
        .scale_factory_i(scale_factory), //srcy_height / desty_height y�������ű�

        .tvalid_o(o_de_scaler_g), // ���de
        .tdata_o(g_o)   // �������?                                                        
        );

scaler_gray_top #(
        .ADJUST_MODE(1),   // �������ص���㷽ʽ��ֱ�Ӽ���?0 ���� ���Ķ���1
        .BRAM_DEEPTH(1280),//src_width_i * 2
        .DATA_WIDTH(8),    // ÿ��ͨ����������
        .INDEX_WIDTH(11),  // �������ȣ���ͼ�γ����ķ�Χ
        .INT_WIDTH(8),     // <= INDEX_WIDTH
        .FIX_WIDTH(12)
) u_image_scaler_b (
        .clk_i(pixclk_in), // ʱ��
        .rst_i(rst_scaler), // ��λ
        
        .tvalid_i(i_de_scaler), // ����de
        .tdata_i(b_in),  //��������
        .tready_o(tready_o_b), // 
        
        
        .src_width_i(H_ACT),// ����ͼ��Ŀ�?
        .src_height_i(V_ACT),// ����ͼ��ĸ�?
        .dest_width_i(dest_width_i),  //  Ŀ��ͼ��Ŀ�?
        .dest_height_i(dest_height_i),//  Ŀ��ͼ��ĸ�?                                                                             

        .scale_factorx_i(scale_factorx), //srcx_width / destx_width x�������ű�
        .scale_factory_i(scale_factory), //srcy_height / desty_height y�������ű�

        .tvalid_o(o_de_scaler_b), // ���de
        .tdata_o(b_o)   // �������?                                                        
        );
endmodule