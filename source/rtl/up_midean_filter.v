module up_median_filter(
    input                       sclk            ,
    input                       rst_n           ,
    //Communication Interfaces
    input           [ 7:0]      rx_data_R       ,
    input           [ 7:0]      rx_data_G       ,
    input           [ 7:0]      rx_data_B       ,
    input                       pi_flag         ,
    input                       i_vs            ,
    output  reg     [ 7:0]      tx_data_R       ,
    output  reg     [ 7:0]      tx_data_G       ,
    output  reg     [ 7:0]      tx_data_B       ,
    output                      po_flag         ,
    output  reg                 o_vs            
);

// wire signals
wire      [7:0]         out_data_R;
wire      [7:0]         out_data_G;
wire      [7:0]         out_data_B;



always @(posedge sclk) begin
    tx_data_R   <=  out_data_R;
    tx_data_G   <=  out_data_G;
    tx_data_B   <=  out_data_B;
    o_vs  <=  i_vs;
end

sub_median_filter_module u1_sub_median_filter(
    .sclk                       (     sclk          ),
    .rst_n                      (     rst_n         ),
    .rx_data                    (   rx_data_R       ),
    .pi_flag                    (     pi_flag       ),
    .tx_data                    (   out_data_R       ),
    .po_flag                    (     po_flag       )
);

sub_median_filter_module u2_sub_median_filter(
    .sclk                       (     sclk          ),
    .rst_n                      (     rst_n         ),
    .rx_data                    (   rx_data_G       ),
    .pi_flag                    (     pi_flag       ),
    .tx_data                    (   out_data_G       ),
    .po_flag                    (                     )
);

sub_median_filter_module u3_sub_median_filter(
    .sclk                       (     sclk          ),
    .rst_n                      (     rst_n         ),
    .rx_data                    (   rx_data_B       ),
    .pi_flag                    (     pi_flag       ),
    .tx_data                    (   out_data_B       ),
    .po_flag                    (                    )
);




endmodule