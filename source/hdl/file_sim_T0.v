`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/16/2021 09:43:51 AM
// Design Name: 
// Module Name: file_sim_T0
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


module file_sim_T0();

parameter PERIOD = 4;

// parameter SRC_IMAGE_WIDTH = 640;
// parameter SRC_IMAGE_HEIGHT = 960;

// parameter DEST_IMAGE_WIDTH = 192;
// parameter DEST_IMAGE_HEIGHT = 180;

parameter SRC_IMAGE_WIDTH = 640;
parameter SRC_IMAGE_HEIGHT = 960;

parameter DEST_IMAGE_WIDTH = 160;
parameter DEST_IMAGE_HEIGHT = 180;

parameter SRC_FRAME_RATE = 60;
parameter SRC_FRAME_INTERVAL = 1000_000_000 / PERIOD / SRC_FRAME_RATE;
parameter SRC_LINE_INTERVAL = SRC_FRAME_INTERVAL / SRC_IMAGE_HEIGHT;
parameter SRC_LINE_DELAY = SRC_LINE_INTERVAL - SRC_IMAGE_WIDTH;

parameter ADJUST_MODE = 1;                   
parameter BRAM_DEEPTH = SRC_IMAGE_WIDTH * 2;                 
parameter DATA_WIDTH  = 8;                   
parameter INDEX_WIDTH = 16;                   
parameter INT_WIDTH   = 8;   // <= INDEX_WIDTH
parameter FIX_WIDTH   = 12;

parameter SCALE_INTX = SRC_IMAGE_WIDTH  / DEST_IMAGE_WIDTH;
parameter SCALE_INTY = SRC_IMAGE_HEIGHT / DEST_IMAGE_HEIGHT;

parameter SCALE_FRACX = ((SRC_IMAGE_WIDTH - SCALE_INTX * DEST_IMAGE_WIDTH)  << FIX_WIDTH) / DEST_IMAGE_WIDTH;
parameter SCALE_FRACY = ((SRC_IMAGE_HEIGHT - SCALE_INTY * DEST_IMAGE_HEIGHT)  << FIX_WIDTH) / DEST_IMAGE_HEIGHT;

parameter SCALE_FACTORX = (SCALE_INTX  << FIX_WIDTH) + SCALE_FRACX;//SRC_IMAGE_WIDTH / DEST_IMAGE_WIDTH
parameter SCALE_FACTORY = (SCALE_INTY  << FIX_WIDTH) + SCALE_FRACY;//SRC_IMAGE_HEIGHT / DEST_IMAGE_HEIGHT
                 
reg                     clk_i = 1'b0;
reg                     clk_x2_i = 1'b0;
reg                     rst_i = 1'b1;
reg                     datav_i = 1'b0;
reg[15 : 0]             data_i = 32'd0;
reg                     tuser_i;

wire                    tready_o;

wire                    R_G_B_valid_o;


wire[7:0]               R_o;
wire[7:0]               G_o;
wire[7:0]               B_o;

reg[31 : 0]  seq_data = 32'd0;
reg          seq_start = 0;

wire GRS_N;

GTP_GRS GRS_INST (

.GRS_N(1'b1)

);

initial begin
  clk_i = 1'b0;
  #(PERIOD/2);
  forever
  #(PERIOD/2) clk_i = ~clk_i;
end

initial begin
  clk_x2_i = 1'b0;
  #(PERIOD/4);
  forever
  #(PERIOD/4) clk_x2_i = ~clk_x2_i;
end 

initial begin
  rst_i = 1'b1;
  #100 rst_i = 1'b0;
  #(8*PERIOD) seq_start = 1;  
end 

integer file_hex_rd;
integer file_hex_wr;
initial begin
  file_hex_rd = $fopen("D:/BaiduNetdiskDownload/bilinear_scaler/mat/hex_gray.txt","r");//hex_pic
  file_hex_wr = $fopen("D:/BaiduNetdiskDownload/bilinear_scaler/mat/wr_pic.txt","w");
end

always@(*)begin
  tuser_i <= datav_i && (data_i < 4);
end

reg[2:0]  rd_st = 3'd0;
reg[31:0] pixel_cnt = 0;
reg[31:0] row_cnt = 0;
reg[31:0] delay_cnt = 0;
reg[15:0] data = 32'd0;
reg       datav = 1'd0;


//-----------sequence number-------
always@(posedge clk_i)begin
  if(rst_i) begin
    pixel_cnt <= 32'd0;
    row_cnt   <= 32'd0;
    delay_cnt <= 32'd0;
    rd_st     <= 3'd0;
    datav_i   <= 1'b0;
  end 
  else begin
    case(rd_st)
    0:begin
      if(seq_start) begin
        rd_st  <= 3'd1;
      end else begin
        rd_st  <= 3'd0;
      end         
    end    
    
    1:begin //one line
      if(tready_o)begin
        datav_i     <= 1'b1;
        $fscanf(file_hex_rd,"%h" ,data_i);
        pixel_cnt <= pixel_cnt + 1;    
        if(pixel_cnt < SRC_IMAGE_WIDTH -1)begin       
          rd_st  <= 3'd1;
        end 
        else begin
          rd_st  <= 3'd2;
        end
      end 
      else begin
        datav_i   <= 1'b0;
        pixel_cnt <= pixel_cnt;       
        rd_st     <= 3'd1;      
      end         
    end
    
    2:begin
      pixel_cnt <= 0;
      datav_i   <= 1'b0;
      row_cnt   <= row_cnt + 32'd1;
      rd_st     <= 3'd3;
    end

    3:begin
      delay_cnt <=  0;
      if(row_cnt < SRC_IMAGE_HEIGHT)begin
        rd_st  <= 3'd4;
      end 
      else begin
        rd_st  <= 3'd5;
      end 
    end
    
    4:begin
      delay_cnt <=  delay_cnt + 1;
      if(delay_cnt < SRC_LINE_DELAY)begin
        rd_st  <= 3'd4;
      end 
      else begin
        rd_st  <= 3'd1;
      end 
    end 
    
    5:begin
      rd_st  <= 3'd5; 
    end           
   endcase   
  end  
end


//always@(posedge clk_i) begin
//  if(rst_i)begin
//    datav_i <= 1'b0;
//    data_i  <= 24'd0;
//  end else begin
//    if(seq_start)begin
//      datav_i <= 1'b1;
//      data_i  <= seq_data;
//      seq_data <= seq_data + 1;
          
//    end else begin
//      datav_i  <= 1'b0;
//      data_i   <= 24'd0;
//      seq_data <= seq_data;    
//    end
//  end  
//end



scaler_gray_top #(
  .ADJUST_MODE(ADJUST_MODE),
  .BRAM_DEEPTH(BRAM_DEEPTH),
  .DATA_WIDTH(DATA_WIDTH),
  .INDEX_WIDTH(INDEX_WIDTH),
  .INT_WIDTH(INT_WIDTH),   
  .FIX_WIDTH(FIX_WIDTH),
  .DEST_IMAGE_WIDTH(DEST_IMAGE_WIDTH),
  .DEST_IMAGE_HEIGHT(DEST_IMAGE_HEIGHT)
  )u0 (
  .clk_i(clk_i),
  .rst_i(rst_i),
  
  .tvalid_i(datav_i),
  .tdata_i(data_i),//image stream
  .tready_o(tready_o),
  
  
  .src_width_i(SRC_IMAGE_WIDTH),//
  .src_height_i(SRC_IMAGE_HEIGHT),//
  .dest_width_i(DEST_IMAGE_WIDTH),//
  .dest_height_i(DEST_IMAGE_HEIGHT),//                                                                               
  
  .scale_factorx_i(SCALE_FACTORX),//srcx_width/destx_width
  .scale_factory_i(SCALE_FACTORY),//srcy_height/desty_height
  
  .tvalid_o(R_G_B_valid_o),
  .tdata_o(R_o) //                                                             
  );


//将输出数据写入txt
reg wr_st = 1'b0;
reg[31:0] wr_cnt = 0;
always@(posedge clk_i)begin
  if(rst_i)begin
    wr_cnt  <= 32'd0;
    wr_st <= 1'b0;
  end else begin
    case(wr_st)
    0:begin
      if(wr_cnt < DEST_IMAGE_WIDTH *  DEST_IMAGE_HEIGHT)begin
        if(R_G_B_valid_o)begin // 数据没写完
          $fwrite(file_hex_wr,"%h\n",R_o);
          wr_cnt <= wr_cnt +1;
          $display("%d %d", wr_cnt, R_o);
        end 
        else begin
          wr_st <= 1'b0;
        end
      end 
      else begin // 数据写完
        wr_st <= 1'b1;
      end         
    end
    1:begin

      $fclose(file_hex_wr);
      $stop;
      wr_st <= 1'b1;
    end

   endcase   
  end  
end



endmodule
