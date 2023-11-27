module RGB_888TO565(
    input        [7:0]       i_rgbdata_r,
    input        [7:0]       i_rgbdata_g,
    input        [7:0]       i_rgbdata_b,
    output       [4:0]       o_rgbdata_r,
    output       [5:0]       o_rgbdata_g,
    output       [4:0]       o_rgbdata_b
);
    assign      o_rgbdata_r = {i_rgbdata_r[7:3]};
    assign      o_rgbdata_g = {i_rgbdata_g[7:2]};
    assign      o_rgbdata_b = {i_rgbdata_b[7:3]};

endmodule