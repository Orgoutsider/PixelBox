
module image_scaler #(
    parameter PIXEL_DATA_WIDTH     = 24,
    parameter SRC_IMAGE_RES_WIDTH  = 640,
    parameter SRC_IMAGE_RES_HEIGHT = 720,
    parameter DST_IMAGE_RES_WIDTH  = 320,
    parameter DST_IMAGE_RES_HEIGHT = 360

)(
    input  pixclk_in, /*synthesis PAP_MARK_DEBUG="1"*/
    input  rst_n,

    input  de_in/*synthesis PAP_MARK_DEBUG="1"*/,  /*synthesis PAP_MARK_DEBUG="1"*/ //de_out �ź���Ч���µ�һ�п�ʼ��de��Ч��һ�д������
    output reg de_out/*synthesis PAP_MARK_DEBUG="1"*/, /*synthesis PAP_MARK_DEBUG="1"*/ //#FIXME:������,һֱ���1
    
    input  [23:0] i_pixel /*synthesis PAP_MARK_DEBUG="1"*/,/*synthesis PAP_MARK_DEBUG="1"*/ //#TODO:û����
    output reg [23:0] o_pixel,/*synthesis PAP_MARK_DEBUG="1"*/ //#FIXME:������,һֱ���0
    output reg vs_out
    // output reg vs_out
);

parameter FIRST_PIXEL  = 'd0; // ��һ�����ص�
parameter SECOND_PIXEL = 'd1; // �ڶ������ص�
parameter THIRD_PIXEL  = 'd2; // ���������ص�
parameter FOURTH_PIXEL = 'd3; // ���ĸ����ص�

parameter FIRST_LINE  = 'd0; // ��һ��
parameter SECOND_LINE = 'd1; // �ڶ���
parameter THIRD_LINE  = 'd2; // ������
parameter FOURTH_LINE = 'd3; // ������

reg [2:0] pixel_saved_cnt; /*synthesis PAP_MARK_DEBUG="1"*/ //#TODO:û����
reg two_pixels_saved; /*synthesis PAP_MARK_DEBUG="1"*/  //#TODO:û����
reg interpolation_data_save_flag; /*synthesis PAP_MARK_DEBUG="1"*/ //#TODO:û����

reg [23:0] pixel_data0; /*synthesis PAP_MARK_DEBUG="1"*/ //#TODO:û����
reg [23:0] pixel_data1; /*synthesis PAP_MARK_DEBUG="1"*/ //#TODO:û����
reg [23:0] pixel_data2; /*synthesis PAP_MARK_DEBUG="1"*/ //#TODO:û����
reg [23:0] pixel_data3; /*synthesis PAP_MARK_DEBUG="1"*/ //#TODO:û����

reg ram0_wr_en;/*synthesis PAP_MARK_DEBUG="1"*/
reg ram1_wr_en;/*synthesis PAP_MARK_DEBUG="1"*/

wire [23:0] ram0_rd_data;/*synthesis PAP_MARK_DEBUG="1"*/
wire [23:0] ram1_rd_data;/*synthesis PAP_MARK_DEBUG="1"*/

reg [23:0] ram0_wr_data;/*synthesis PAP_MARK_DEBUG="1"*/
reg [23:0] ram1_wr_data;/*synthesis PAP_MARK_DEBUG="1"*/

reg [9:0] ram0_wr_addr;/*synthesis PAP_MARK_DEBUG="1"*/
reg [9:0] ram1_wr_addr;/*synthesis PAP_MARK_DEBUG="1"*/

reg [9:0] ram0_rd_addr;/*synthesis PAP_MARK_DEBUG="1"*/
reg [9:0] ram1_rd_addr;/*synthesis PAP_MARK_DEBUG="1"*/

reg [8:0] second_interpolated_pixel_cnt_per_line; /*synthesis PAP_MARK_DEBUG="1"*/  // ���320
reg [8:0] fisrt_interpolated_pixel_cnt_per_line;  /*synthesis PAP_MARK_DEBUG="1"*/ // ���320

reg first_interpolation_done12; /*synthesis PAP_MARK_DEBUG="1"*/
reg first_interpolation_done34; /*synthesis PAP_MARK_DEBUG="1"*/
reg [1:0] first_interpolated_line; /*synthesis PAP_MARK_DEBUG="1"*/
reg second_interpolation_done12; /*synthesis PAP_MARK_DEBUG="1"*/
reg second_interpolation_done34; /*synthesis PAP_MARK_DEBUG="1"*/
reg [10:0] v_cnt;
reg de_out_1d;
reg [10:0] pix_cnt;
reg de_out_1d;
reg de_out_2d;
reg pix_vld/*synthesis PAP_MARK_DEBUG="1"*/; /*synthesis PAP_MARK_DEBUG="1"*/ 
reg [23:0] pix;/*synthesis PAP_MARK_DEBUG="1"*/ 
reg pix_vld_1d;
reg [9:0] black_cnt;/*synthesis PAP_MARK_DEBUG="1"*/

// �����������ݴ�
// ÿ�����������ݾ�����interpolation_data_save
always @(posedge pixclk_in) begin

    // $display("pixel_saved_cnt: %d", pixel_saved_cnt);
    if (!rst_n) begin
        pixel_saved_cnt  <= 'd0;             // ��ǰ�ݴ浽�ڼ������ص㣬��ֵ����
        two_pixels_saved <= 1'b0;             // ��ֵ�����־��ÿ�������ر��������
        interpolation_data_save_flag <= 1'b0; // ��ֵ�����־������ǰ������Ϊ�ͣ��������������Ϊ��
        
        pixel_data0 <= 'd0;  // ˫���Բ�ֵ�ĵ�1������
        pixel_data1 <= 'd0;  // ˫���Բ�ֵ�ĵ�2������
        pixel_data2 <= 'd0;  // ˫���Բ�ֵ�ĵ�3������
        pixel_data3 <= 'd0;  // ˫���Բ�ֵ�ĵ�4������
    end
    else if(de_in) begin   // de���ߺ�˵��������Ч���������΢�ݽ����ݴ�
        // $display("pixel_saved_cnt: %d, two_pixels_saved:%d ,interpolation_data_save_flag:%d", pixel_saved_cnt, two_pixels_saved, interpolation_data_save_flag);
        case(pixel_saved_cnt)
            FIRST_PIXEL: begin
                pixel_data0 <= i_pixel;     //�ݴ��һ��΢��
               
                two_pixels_saved <= 1'b0;   //��δ����������ݣ�Ȼ������
                pixel_saved_cnt <=  'd1;   //�Ѿ����˵�һ��΢�ݣ�׼����ڶ�������
            end
            SECOND_PIXEL: begin 
                pixel_data1 <= i_pixel;              //����ڶ�������
                
                interpolation_data_save_flag <= 'd0; //Ϊ0ʱ��1��2����ֵ�����
                two_pixels_saved <= 1'b1;            //�Ѿ������������ݣ�Ȼ������
                pixel_saved_cnt <= 'd2;             //�Ѿ����˵ڶ���΢�ݣ�׼�������������
            end
            THIRD_PIXEL: begin 
                pixel_data2 <= i_pixel;              //�ݴ��3��΢��
                
                two_pixels_saved <= 1'b0;            //��δ����������ݣ�Ȼ������
                pixel_saved_cnt <= 'd3;     //�Ѿ����˵�����΢�ݣ�׼������ĸ�����
            end
            FOURTH_PIXEL: begin
                pixel_data3 <= i_pixel;              //�ݴ��4��΢��
                
                interpolation_data_save_flag <= 'd1; // Ϊ1ʱ��34����ֵ�����
                two_pixels_saved <= 1'b1;            //�Ѿ������������ݣ�Ȼ������
                pixel_saved_cnt <= 'd0;             //�Ѿ����˵��ĸ�΢�ݣ��ַ���׼�����һ������
            end
        endcase     
    end
    else begin // ���de�ź���Ч��˵��һ�����ش������
        pixel_data0 <= 'd0;
        pixel_data1 <= 'd0;
        pixel_data2 <= 'd0;
        pixel_data3 <= 'd0;

        pixel_saved_cnt  <=  1'b0;
        two_pixels_saved <= 1'b0;
        interpolation_data_save_flag <= 'd0;
    end
end

//����������ݽ��е�һ�����Բ�ֵ
always @(posedge pixclk_in) begin
    $display("2_pix_s: %d, f_inter_line:%d, f_pix_cnt:%d, s_pix_cnt:%d",two_pixels_saved, first_interpolated_line, fisrt_interpolated_pixel_cnt_per_line, second_interpolated_pixel_cnt_per_line);
    // $display("2_pix_s: %d, f_inter_line:%d, f_pix_cnt:%d",two_pixels_saved, first_interpolated_line, fisrt_interpolated_pixel_cnt_per_line, );
    if(!rst_n) begin
        fisrt_interpolated_pixel_cnt_per_line  <= 'd0; // ����һ�����ֵ��ڼ������ؽ����˲�ֵ�����ڼ����ַ
        first_interpolated_line <= 'd0;
        ram0_wr_en   <= 1'b0;
        ram1_wr_en   <= 1'b0;
        ram0_wr_data <= 'd0;
        ram1_wr_data <= 'd0;
        ram0_wr_addr <= 'd0;
        ram1_wr_addr <= 'd0;
        first_interpolation_done12 <= 'd0;
        first_interpolation_done34 <= 'd0;
    end
    //RGB888
    else if(two_pixels_saved) begin //two_pixels_saved�ź����ߺ󣬶��ݴ���������ݽ���һ�����Բ�ֵ��ͬʱ����������ֵ�ﵽ��Ƶ����ֱ���һ��ʱ������ֵ
        // $display("2_pix_s: %d, f_inter_line:%d, f_pix_cnt:%d, r0_wen:%d, r1_wen:%d",two_pixels_saved, first_interpolated_line, fisrt_interpolated_pixel_cnt_per_line, ram0_wr_en, ram1_wr_en);
        case(first_interpolated_line)
            FIRST_LINE: begin  
                //��һ�����ݲ�ֵ������ram0��page0��
                ram0_wr_addr <= {1'b0, fisrt_interpolated_pixel_cnt_per_line}; // ��ַ�����λ��ʾҳ����0��ʾ��0ҳ��1��ʾ��1ҳ
                if(interpolation_data_save_flag == 0) begin//��save_flagΪ0ʱ������pix0pix1 д���ݵ�ram0, �мǽ��з�ͨ������
                    ram0_wr_data[23:16] <= (pixel_data0[23:16] / 2) + (pixel_data1[23:16] / 2); //r8
                    ram0_wr_data[15: 8] <= (pixel_data0[15: 8] / 2) + (pixel_data1[15: 8] / 2); //g8
                    ram0_wr_data[7 : 0] <= (pixel_data0[7 : 0] / 2) + (pixel_data1[7 : 0] / 2); //b8
                end
                else if(interpolation_data_save_flag == 1) begin
                    ram0_wr_data[23:16] <= (pixel_data2[23:16] / 2) + (pixel_data3[23:16] / 2);
                    ram0_wr_data[15: 8] <= (pixel_data2[15: 8] / 2) + (pixel_data3[15: 8] / 2);
                    ram0_wr_data[7 : 0] <= (pixel_data2[7 : 0] / 2) + (pixel_data3[7 : 0] / 2);
                end
                // ������������ص�ﵽ����Ŀ��ͼ����зֱ���ʱ��˵����0�е��������Ѿ������꣬�����1��
                if(fisrt_interpolated_pixel_cnt_per_line == DST_IMAGE_RES_WIDTH) begin
                    ram0_wr_en                             <= 1'b0;
                    // ram1_wr_en                             <= 1'b0;
                    
                    fisrt_interpolated_pixel_cnt_per_line  <= 'd0;
                    first_interpolation_done12             <= 'd0;
                    first_interpolation_done34             <= 'd0;               
                    first_interpolated_line                <= 'd1;
                end
                else begin
                    ram0_wr_en <= 1'b1; //������һ�����ص㣬�Ϳ���д��ram
                    fisrt_interpolated_pixel_cnt_per_line <= fisrt_interpolated_pixel_cnt_per_line + 1'b1; // ÿ������һ�������ص�+1
                end
            end
            SECOND_LINE: begin //�ڶ������ݲ�ֵ,����ram1��page0��
                ram1_wr_addr <= {1'b0, fisrt_interpolated_pixel_cnt_per_line};  // ��ַ�����λ��ʾҳ����0��ʾ��0ҳ��1��ʾ��1ҳ
                if(interpolation_data_save_flag == 0) begin//��save_flagΪ0ʱ������pix1pix2 
                    ram1_wr_data[23:16] <= (pixel_data0[23:16] / 2) + (pixel_data1[23:16] / 2);
                    ram1_wr_data[15: 8] <= (pixel_data0[15: 8] / 2) + (pixel_data1[15: 8] / 2);
                    ram1_wr_data[7 : 0] <= (pixel_data0[7 : 0] / 2) + (pixel_data1[7 : 0] / 2);
                end
                else if(interpolation_data_save_flag == 1) begin
                    ram1_wr_data[23:16] <= (pixel_data2[23:16] / 2) + (pixel_data3[23:16] / 2);
                    ram1_wr_data[15: 8] <= (pixel_data2[15: 8] / 2) + (pixel_data3[15: 8] / 2);
                    ram1_wr_data[7 : 0] <= (pixel_data2[7 : 0] / 2) + (pixel_data3[7 : 0] / 2);
                end
               
                if(fisrt_interpolated_pixel_cnt_per_line == DST_IMAGE_RES_WIDTH) begin
                    ram1_wr_en <= 1'b0;
                    fisrt_interpolated_pixel_cnt_per_line <= 'd0;
                    first_interpolation_done12 <= 'd1; // �������е������Ѿ�������ɣ�����
                    first_interpolated_line <= 'd2;   // ��1�����ؼ�����ɣ������������2��
                end   
                else begin
                    ram1_wr_en <= 1'b1;
                    fisrt_interpolated_pixel_cnt_per_line <= fisrt_interpolated_pixel_cnt_per_line + 1'b1;
                end
            end
            THIRD_LINE: begin     //����ǰ���в�ֵ��ɺ���Ҫ���м��㣬���Ի���Ҫ�����������������ݴ�,���������ݲ�ֵ������ram0��page1��
                ram0_wr_addr <= {1'b1, fisrt_interpolated_pixel_cnt_per_line}; // ��ַ�����λ��ʾҳ����0��ʾ��0ҳ��1��ʾ��1ҳ
                if(interpolation_data_save_flag == 0) begin  
                    ram0_wr_data[23:16] <= (pixel_data0[23:16] / 2) + (pixel_data1[23:16] / 2);
                    ram0_wr_data[15: 8] <= (pixel_data0[15: 8] / 2) + (pixel_data1[15: 8] / 2);
                    ram0_wr_data[7 : 0] <= (pixel_data0[7 : 0] / 2) + (pixel_data1[7 : 0] / 2);
                end
                else if(interpolation_data_save_flag == 1) begin
                    ram0_wr_data[23:16] <= (pixel_data2[23:16] / 2) + (pixel_data3[23:16] / 2);
                    ram0_wr_data[15: 8] <= (pixel_data2[15: 8] / 2) + (pixel_data3[15: 8] / 2);
                    ram0_wr_data[7 : 0] <= (pixel_data2[7 : 0] / 2) + (pixel_data3[7 : 0] / 2);
                end
               
                if(fisrt_interpolated_pixel_cnt_per_line == DST_IMAGE_RES_WIDTH) begin
                    ram0_wr_en <= 1'b0;
                    fisrt_interpolated_pixel_cnt_per_line <= 'd0;
                    first_interpolation_done12 <= 'd0;
                    first_interpolation_done34 <= 'd0;               
                    first_interpolated_line <= 'd3;
                end
                else begin
                    ram0_wr_en <= 1'b1;
                    fisrt_interpolated_pixel_cnt_per_line <= fisrt_interpolated_pixel_cnt_per_line + 1'b1;
                end
            end     
            FOURTH_LINE: begin //��4�����ݲ�ֵ������ram1��page1��
                ram1_wr_addr <= {1'b1, fisrt_interpolated_pixel_cnt_per_line};  // ��ַ�����λ��ʾҳ����0��ʾ��0ҳ��1��ʾ��1ҳ
                if(interpolation_data_save_flag == 0) begin
                    ram1_wr_data[23:16] <= (pixel_data0[23:16] / 2) + (pixel_data1[23:16] / 2);
                    ram1_wr_data[15: 8] <= (pixel_data0[15: 8] / 2) + (pixel_data1[15: 8] / 2);
                    ram1_wr_data[7 : 0] <= (pixel_data0[7 : 0] / 2) + (pixel_data1[7 : 0] / 2);
                end
                else if(interpolation_data_save_flag == 1) begin
                    ram1_wr_data[23:16] <= (pixel_data2[23:16] / 2) + (pixel_data3[23:16] / 2);
                    ram1_wr_data[15: 8] <= (pixel_data2[15: 8] / 2) + (pixel_data3[15: 8] / 2);
                    ram1_wr_data[7 : 0] <= (pixel_data2[7 : 0] / 2) + (pixel_data3[7 : 0] / 2);
                end
                if(fisrt_interpolated_pixel_cnt_per_line == DST_IMAGE_RES_WIDTH) begin
                    ram1_wr_en <= 1'b0;
                    fisrt_interpolated_pixel_cnt_per_line <= 'd0;
                    // first_interpolation_done12 <= 'd0;
                    first_interpolation_done34 <= 'd1; 
                    first_interpolated_line <= 'd0;
                end   
                else begin
                    ram1_wr_en <= 1'b1;
                    fisrt_interpolated_pixel_cnt_per_line <= fisrt_interpolated_pixel_cnt_per_line + 1'b1; 
                end
            end 
        endcase
    end
    // else begin 
    //     if (de_in) begin
    //         fisrt_interpolated_pixel_cnt_per_line <= fisrt_interpolated_pixel_cnt_per_line;
    //         first_interpolated_line <= first_interpolated_line;
    //         ram0_wr_en <= ram0_wr_en;
    //         ram1_wr_en <= ram1_wr_en;
    //     end
    //     else begin
    //         fisrt_interpolated_pixel_cnt_per_line <= 0;
    //         first_interpolated_line <= 0;
    //         ram0_wr_en <= 1'b0;
    //         ram1_wr_en <= 1'b0;
    //     end
    // end
    else begin
        fisrt_interpolated_pixel_cnt_per_line <= fisrt_interpolated_pixel_cnt_per_line;
        first_interpolated_line <= first_interpolated_line;
    end
end


// ÿ������һ����һ�еĵڶ������Բ�ֵ���� ssecond_interpolated_pixel_cnt_per_line ����+1
// �����ֵ��һ�о�����
//������е����Բ�ֵ�󣬶�������ram�ĵ�һ�β�ֵ����ֵ�����еڶ������Բ�֡
always @(posedge pixclk_in) begin
    // $display("two_pixels_saved: %d, fisrt_interpolated_pixel_cnt_per_line:%d, first_interpolated_line:%d",two_pixels_saved, first_interpolated_line, fisrt_interpolated_pixel_cnt_per_line);
    if(!rst_n) begin
        pix <= 'd0;
        pix_vld  <= 'd0;
        ram0_rd_addr <= 'd0;
        ram1_rd_addr <= 'd0;
        second_interpolated_pixel_cnt_per_line <= 0;
        second_interpolation_done12 <= 'd0; 
        second_interpolation_done34 <= 'd0; 
    end
    //����ram��0ҳд����ɣ�����һ���е�һ�β�ֵ�������ص������ɣ����Խ��еڶ������Բ�ֵ
    else if(first_interpolation_done12 && !second_interpolation_done12) begin     // 12�еڶ��β�ֵ

        ram0_rd_addr <= {1'b0, second_interpolated_pixel_cnt_per_line};
        ram1_rd_addr <= {1'b0, second_interpolated_pixel_cnt_per_line};
        pix[23:16] <= ram0_rd_data[23:16] / 2 + ram1_rd_data[23:16] / 2;
        pix[15: 8] <= ram0_rd_data[15: 8] / 2 + ram1_rd_data[15: 8] / 2;
        pix[7 : 0] <= ram0_rd_data[7 : 0] / 2 + ram1_rd_data[7 : 0] / 2;

        
        if(second_interpolated_pixel_cnt_per_line == DST_IMAGE_RES_WIDTH) begin
            second_interpolated_pixel_cnt_per_line <= 'd0;
            second_interpolation_done12 <= 'd1;
            second_interpolation_done34 <= 'd0;
            pix_vld <= 'd0;

        end
        else begin
            second_interpolated_pixel_cnt_per_line <= second_interpolated_pixel_cnt_per_line + 1;
            pix_vld <= 'd1;
        end
    end
    else if(first_interpolation_done34 && !second_interpolation_done34) begin     // 12�еڶ��β�ֵ

        ram0_rd_addr <= {1'b1, second_interpolated_pixel_cnt_per_line};
        ram1_rd_addr <= {1'b1, second_interpolated_pixel_cnt_per_line};
        pix[23:16] <= ram0_rd_data[23:16] / 2 + ram1_rd_data[23:16] / 2;
        pix[15: 8] <= ram0_rd_data[15: 8] / 2 + ram1_rd_data[15: 8] / 2;
        pix[7 : 0] <= ram0_rd_data[7 : 0] / 2 + ram1_rd_data[7 : 0] / 2;

        
        if(second_interpolated_pixel_cnt_per_line == DST_IMAGE_RES_WIDTH) begin
            second_interpolated_pixel_cnt_per_line <= 'd0;
            second_interpolation_done12 <= 'd0;
            second_interpolation_done34 <= 'd1;
            pix_vld <= 'd0;
        end
        else begin
            second_interpolated_pixel_cnt_per_line <= second_interpolated_pixel_cnt_per_line + 1;
            pix_vld <= 'd1;
        end
    end
    else begin // ����ֵ�ﵽĿ���С����ǰ��λ
        second_interpolated_pixel_cnt_per_line <= second_interpolated_pixel_cnt_per_line;
        pix <= 'd0;
        pix_vld <= 'd0;
    
        if (second_interpolation_done34) begin // �����еڶ��β�ֵ��ɣ���ַת��12��
            ram0_rd_addr <= {1'b0, second_interpolated_pixel_cnt_per_line};
            ram1_rd_addr <= {1'b0, second_interpolated_pixel_cnt_per_line};
        end
        else if (second_interpolation_done12) begin // һ���еڶ��β�ֵ��ɣ���ַת��34��
            ram0_rd_addr <= {1'b1, second_interpolated_pixel_cnt_per_line};
            ram1_rd_addr <= {1'b1, second_interpolated_pixel_cnt_per_line};
        end
    end
end

always @(posedge pixclk_in) begin
    if(!rst_n)
    begin
        o_pixel <= 'd0;
        de_out <= 1'b0;
    end
    else
    begin
        de_out <= pix_vld || (~pix_vld & pix_vld_1d) || (black_cnt <= DST_IMAGE_RES_WIDTH - 1'b1);
        o_pixel <= pix;
    end
end

always @(posedge pixclk_in) begin
    pix_vld_1d <= pix_vld;
end

always @(posedge pixclk_in) begin
    if(!rst_n)
        black_cnt <= DST_IMAGE_RES_WIDTH;
    else if(~pix_vld & pix_vld_1d)
        black_cnt <= 10'd1;
    else begin
        if(black_cnt >= DST_IMAGE_RES_WIDTH)
            black_cnt <= black_cnt;
        else
            black_cnt <= black_cnt + 10'd1;
    end 
end

// always @(posedge pixclk_in) begin
//     de_out_1d <= de_out;
//     de_out <= de_out_1d;
// end

always @(posedge pixclk_in) begin
    $display("v_cnt:%d, vs_out:%d", v_cnt, vs_out);
    if (!rst_n) begin
        v_cnt <= 0;
    end
    else if (~de_out_1d & de_out) begin
        v_cnt <= v_cnt + 1;
    end
end
always @(posedge pixclk_in) begin
    if (!rst_n) begin
        vs_out <= 0;
    end
    else if (v_cnt == 640) begin
        vs_out <= 1;
    end
    else begin
        vs_out <= 0;
    end
end
always @(posedge pixclk_in) begin
    $display("fisrt_interpolated_pixel_cnt_per_line:%d", fisrt_interpolated_pixel_cnt_per_line);
    if (!de_out) begin
        pix_cnt <= 0;
    end
    else begin
        pix_cnt <= pix_cnt + 1;
    end
end

// ����1, 3�����ص��ram0
image_resize_ram ram0 (
  .wr_data(ram0_wr_data),    // input [23:0]
  .wr_addr(ram0_wr_addr),    // input [10:0]
  .wr_en(ram0_wr_en),        // input
  .wr_clk(pixclk_in),      // input
  .wr_rst(~rst_n),      // input
  .rd_addr(ram0_rd_addr),    // input [10:0]
  .rd_data(ram0_rd_data),    // output [23:0]
  .rd_clk(pixclk_in),      // input
  .rd_rst(~rst_n)       // input
);

// ����2, 4�����ص��ram1
image_resize_ram ram1 (
  .wr_data(ram1_wr_data),    // input [23:0]
  .wr_addr(ram1_wr_addr),    // input [10:0]
  .wr_en(ram1_wr_en),        // input
  .wr_clk(pixclk_in),  // input
  .wr_rst(~rst_n),            // input
  .rd_addr(ram1_rd_addr),    // input [10:0]
  .rd_data(ram1_rd_data),    // output [23:0]
  .rd_clk(pixclk_in),  // input
  .rd_rst(~rst_n)             // input
);
endmodule