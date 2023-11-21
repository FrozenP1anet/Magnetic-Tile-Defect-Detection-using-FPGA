module fault_detect_top(
    input clk_i,
    input rst_i,
    input [7:0] data_i,             // 8b数据输入
    input start_i,                  // 一个时钟周期高电平，表示数据开始输入
    output fault_detected_o,        // 一个时钟周期高电平，表示检测到磁瓦缺陷
    output vaild_o                  // fault_detected_o信号有效位
);

wire [31:0] amp;
wire amp_vaild;

fft_wrapper u_fft_wrapper(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .data_i(data_i),
    .start_i(start_i),
    .amp_o(amp),
    .amp_vaild_o(amp_vaild)
);

fault_detect u_fault_detect(
    .clk_i(clk_i),
    .rst_i(rst_i),
    .amp_i(amp),
    .amp_vaild_i(amp_vaild),
    .fault_detected_o(fault_detected_o),
    .vaild_o(vaild_o)
);

endmodule
