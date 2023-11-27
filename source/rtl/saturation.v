module saturation(
    input clk,
    input [15:0] RGB_data,
    input RGB_de,
    input RGB_vs,
    output reg [15:0] saturation_data_raw,
    output [15:0] saturation_data_dst,
    output reg saturation_de,
    output reg saturation_vs
);

wire [7:0] R;
wire [7:0] G;
wire [7:0] B;
wire [9:0] R4;
wire [9:0] G4;
wire [9:0] B4;
wire [9:0] sum;
reg [7:0] R_sat;
reg [7:0] G_sat;
reg [7:0] B_sat;
//==========================================================================
//==    RGB565תRGB888
//==========================================================================
assign R = {RGB_data[15:11],3'b0};
assign G = {RGB_data[10: 5],2'b0};
assign B = {RGB_data[ 4: 0],3'b0};
assign sum = R + G + B;
assign R4 = (R << 2);
assign G4 = (G << 2);
assign B4 = (B << 2);

always @(posedge clk ) begin
    if (R4 < sum)
        R_sat <=  8'b0;
    else if (10'd255 + sum < R4)
        R_sat <= 8'd255;
    else
        R_sat <= R4 - sum;    
end
always @(posedge clk ) begin
    if (G4 < sum)
        G_sat <=  8'b0;
    else if (10'd255 + sum < G4)
        G_sat <= 8'd255;
    else
        G_sat <= G4 - sum;    
end
always @(posedge clk ) begin
    if (B4 < sum)
        B_sat <=  8'b0;
    else if (10'd255 + sum < B4)
        B_sat <= 8'd255;
    else
        B_sat <= B4 - sum;    
end

assign saturation_data_dst = {R_sat[7:3],G_sat[7:2],B_sat[7:3]};

always @(negedge clk ) begin
    saturation_data_raw <= RGB_data;
    saturation_de <= RGB_de;
    saturation_vs <= RGB_vs;    
end
endmodule