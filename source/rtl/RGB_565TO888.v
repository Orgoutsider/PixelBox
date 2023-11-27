module RGB_565TO888(
    input       [4:0]       i_rgbdata_r,
    input       [5:0]       i_rgbdata_g,
    input       [4:0]       i_rgbdata_b,
    output      [7:0]       o_rgbdata_r,
    output      [7:0]       o_rgbdata_g,
    output      [7:0]       o_rgbdata_b
);
    assign      o_rgbdata_r = {i_rgbdata_r,3'd0};
    assign      o_rgbdata_g = {i_rgbdata_g,2'd0};
    assign      o_rgbdata_b = {i_rgbdata_b,3'd0};

endmodule