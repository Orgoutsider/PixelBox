module gamma(
    input clk,
    input [15:0] RGB_data,
    input RGB_de,
    input RGB_vs,
    output reg [15:0] gamma_data_raw,
    output [15:0] gamma_data_sqrt,
    output [15:0] gamma_data_square,
    output reg gamma_de,
    output reg gamma_vs
);

wire [7:0] R;
wire [7:0] G;
wire [7:0] B;
wire [7:0] R_sqrt;
wire [7:0] G_sqrt;
wire [7:0] B_sqrt;
wire [7:0] R_square;
wire [7:0] G_square;
wire [7:0] B_square;
//==========================================================================
//==    RGB565×ªRGB888
//==========================================================================
assign R = {RGB_data[15:11],RGB_data[13:11]};
assign G = {RGB_data[10: 5],RGB_data[ 6: 5]};
assign B = {RGB_data[ 4: 0],RGB_data[ 2: 0]};
//==========================================================================
//==    gamma sqrt Í¼Ïñ±äÁÁ
//==========================================================================
rom_sqrt u_R_sqrt (
  .addr(R),          // input [7:0]
  .clk(clk),            // input
  .rst(1'b0),            // input
  .rd_data(R_sqrt)     // output [7:0]
);

rom_sqrt u_G_sqrt (
  .addr(G),          // input [7:0]
  .clk(clk),            // input
  .rst(1'b0),            // input
  .rd_data(G_sqrt)     // output [7:0]
); 

rom_sqrt u_B_sqrt (
  .addr(B),          // input [7:0]
  .clk(clk),            // input
  .rst(1'b0),            // input
  .rd_data(B_sqrt)     // output [7:0]
);

assign gamma_data_sqrt = {R_sqrt[7:3],G_sqrt[7:2],B_sqrt[7:3]};
//==========================================================================
//==    gamma square Í¼Ïñ±ä°µ
//==========================================================================
rom_square u_R_square (
  .addr(R),          // input [7:0]
  .clk(clk),            // input
  .rst(1'b0),            // input
  .rd_data(R_square)     // output [7:0]
);

rom_square u_G_square (
  .addr(G),          // input [7:0]
  .clk(clk),            // input
  .rst(1'b0),            // input
  .rd_data(G_square)     // output [7:0]
);

rom_square u_B_square (
  .addr(B),          // input [7:0]
  .clk(clk),            // input
  .rst(1'b0),            // input
  .rd_data(B_square)     // output [7:0]
);

assign gamma_data_square = {R_square[7:3],G_square[7:2],B_square[7:3]};

always @(posedge clk) begin
    gamma_data_raw <= RGB_data; 
    gamma_de <= RGB_de;
    gamma_vs <= RGB_vs;   
end

endmodule