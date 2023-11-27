`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/11/2020 11:33:38 AM
// Design Name: 
// Module Name: data_delay
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


module data_delay
#(parameter WIDTH = 24,
  parameter DEPTH1 = 40,
  parameter DEPTH2 = 46)
(
input clk_i,
input[WIDTH-1:0] data_i,
output[WIDTH-1:0] depth1_data_o,
output[WIDTH-1:0] depth2_data_o
);

reg[WIDTH-1:0] data_d[DEPTH2:0];

always@(posedge clk_i)begin
  data_d[0] <= data_i;
end

genvar i;
generate
for(i = 0; i < DEPTH2; i = i + 1)begin:delay_gen
  always@(posedge clk_i)begin
    data_d[i+1] <= data_d[i];
  end
end
endgenerate

assign depth1_data_o = data_d[DEPTH1 - 1];
assign depth2_data_o = data_d[DEPTH2 - 1];

endmodule
