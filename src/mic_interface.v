/* mic_driver和data_conv构成的模块 */
module mic_interface(
    input           clk_i,          // 27M
    input           rst_i,
    input           sd_i,           // IIS串行数据输入
    output          ws_o,           // IIS WS信号
    output          sck_o,          // IIS SCK信号
    output          LR_o,           // 左右声道选择
    output [7:0]    data_o,         // 并行数据输出
    output          data_en_o       // 数据输出有效
);

mic_driver#(
    .CLK_FREQ(27_000_000),
    .SCK_FREQ(27_000_00)
)u_mic_driver(
    .clk_i(clk_i),  
    .rst_n_i(~rst_i),
    .sck_o(sck_o),  
    .ws_o(ws_o),   
    .LR_o(LR_o)    
);

data_conv u_data_conv(
    .clk_i(clk_i),   
    .rst_i(rst_i),
    .sck_i(sck_o),   
    .ws_i(ws_o),    
    .sd_i(sd_i),
    .data_o(data_o),  
    .data_en_o(data_en_o)
);

endmodule
