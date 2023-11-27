`timescale 1ns / 1ps
module HDMA_fifo_ctrl #(
	parameter VIDEO_DATA_BIT   = 32		// ������Ƶ����λ��,����ѡ��32,Ҳ����ѡ��16
)(
    input                       rst_n            ,  //��λ�ź�
    input                       wr_clk           ,  //wfifoʱ��
    input                       rd_clk           ,  //rfifoʱ��
    input                       clk_100          ,  //�û�ʱ��
    input                       datain_valid     ,  //������Чʹ���ź�
    input  [VIDEO_DATA_BIT-1:0] datain           ,  //��Ч����
    input  [127:0]              rfifo_din        ,  //�û�������
    input                       rdata_req        ,  //�������ص���ɫ��������
    input                       rfifo_wren       ,  //��ddr3�������ݵ���Чʹ��
    input                       wfifo_rden       ,  //wfifo��ʹ��
    input                       rd_load          ,  //���Դ���ź�
    input                       wr_load          ,  //����Դ���ź�
    output [127:0]              wfifo_dout       ,  //�û�д����
    output [10:0]               wfifo_rcount     ,  //rfifoʣ�����ݼ���
    output [10:0]               rfifo_wcount     ,  //wfifoд�����ݼ���
    output [VIDEO_DATA_BIT-1:0] pic_data            //��Ч����
    );

//reg define
reg          rd_load_d0        ;
reg  [15:0]  rd_load_d         ;  //�����Դ���ź���λƴ�ӵõ�
reg          rdfifo_rst_h      ;  //rfifo��λ�źţ�����Ч
reg          wr_load_d0        ;
reg  [15:0]  wr_load_d         ;  //������Դ���ź���λƴ�ӵõ� 
reg          wfifo_rst_h       ;  //wfifo��λ�źţ�����Ч

//*****************************************************
//**                    main code
//*****************************************************  

//�����Դ���ź�ȡ��
always @(posedge clk_100 or negedge rst_n) begin
    if(!rst_n) rd_load_d0 <= 1'b0;
    else rd_load_d0 <= rd_load;      
end 

//�����Դ���źŽ�����λ�Ĵ�
always @(posedge clk_100 or negedge rst_n) begin
    if(!rst_n) rd_load_d <= 1'b0;
    else rd_load_d <= {rd_load_d[14:0],rd_load_d0};
end 

//����һ�θ�λ��ƽ������fifo��λʱ��
always @(posedge clk_100 or negedge rst_n) begin
    if(!rst_n) rdfifo_rst_h <= 1'b0;
    else if(rd_load_d[0] && !rd_load_d[14]) rdfifo_rst_h <= 1'b1;
    else rdfifo_rst_h <= 1'b0;
end  

//������Դ���źŽ�����λ�Ĵ�
 always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n)begin
        wr_load_d0 <= 1'b0;
        wr_load_d  <= 16'b0;
    end     
    else begin
        wr_load_d0 <= wr_load;
        wr_load_d <= {wr_load_d[14:0],wr_load_d0};
    end
end

//����һ�θ�λ��ƽ������fifo��λʱ�� 
 always @(posedge wr_clk or negedge rst_n) begin
    if(!rst_n) wfifo_rst_h <= 1'b0;
    else if(wr_load_d[0] && !wr_load_d[15]) wfifo_rst_h <= 1'b1;
    else wfifo_rst_h <= 1'b0;
end   

rd_fifo u_rd_fifo (
  .wr_clk         (clk_100          ), // input
  .wr_rst         (!rst_n|rdfifo_rst_h), // input ~rst_n|rd_load_d0
  .wr_en          (rfifo_wren       ), // input
  .wr_data        (rfifo_din        ), // input [127:0]
  .wr_full        (                 ), // output
  .wr_water_level (rfifo_wcount     ), // output [12:0]
  .almost_full    (                 ), // output
  .rd_clk         (rd_clk           ), // input
  .rd_rst         (!rst_n|rdfifo_rst_h), // input rfifo_rden
  .rd_en          (rdata_req        ), // input
  .rd_data        (pic_data         ), // output [15:0]
  .rd_empty       (                 ), // output
  .rd_water_level (                 ), // output [12:0]
  .almost_empty   (                 )  // output
);

wr_fifo u_wr_fifo (
  .wr_clk         (wr_clk            ), // input
  .wr_rst         (!rst_n|wfifo_rst_h), // input
  .wr_en          (datain_valid      ), // input
  .wr_data        (datain            ), // input [15:0]
  .wr_full        (                  ), // output
  .wr_water_level (                  ), // output [12:0]
  .almost_full    (                  ), // output
  .rd_clk         (clk_100           ), // input ~rst_n|wfifo_rst_h
  .rd_rst         (!rst_n|wfifo_rst_h), // input
  .rd_en          (wfifo_rden        ), // input
  .rd_data        (wfifo_dout        ), // output [127:0]
  .rd_empty       (                  ), // output
  .rd_water_level (wfifo_rcount      ), // output [12:0]
  .almost_empty   (                  )  // output
);

endmodule