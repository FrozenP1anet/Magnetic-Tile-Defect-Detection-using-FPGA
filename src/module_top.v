module module_top(
    input           clk_i,              // 27M
    input           rst_n_i,            // 低电平复位
    input           infrared_key,       // 红外检测有效
    input           sd_i,               // IIS串行数据输入
    output          ws_o,               // IIS WS信号
    output          sck_o,              // IIS SCK信号
    output          LR_o,               // 左右声道选择
    output reg      fault_detect_led,   // 缺陷检测指示灯
    output          motor_pwm,          // 舵机PWM信号
    output          uart_tx_o           // 串口屏uart发送
);

parameter CLK_FREQ = 27_000_000;        // 输入时钟频率
parameter UART_BPS = 9600;              // 串口屏波特率
parameter VAILD_DATA_NUM_TH = 1;        // mic_capture模块中，捕获到的有效数据个数门限值
parameter VAILD_DATA_VALUE_TH = 20;     // mic_capture模块中，捕获到的有效数据数值门限值
parameter DUTY_CENTRAL = 40500;         // 舵机归位时的计数值

reg mic_active;
wire [7:0] data;
wire data_en;
wire capture_en;
reg r_en;
reg r_en_t0;
reg r_en_t1;
wire fifo_full;
wire fifo_empty;
wire [7:0] data_fifo_out;
wire data_start;
wire fault_detect;                  // 缺陷检测信号
wire fault_detect_vaild;            // 缺陷检测信号有效
wire infrared_en;
reg good_pulse;                     // 磁瓦完好指示脉冲
reg bad_pulse;                      // 磁瓦缺陷指示脉冲

/* mic_active有效时，代表麦克风在采集数据 */
assign infrared_en = ~infrared_key;
always@(infrared_en or fifo_full or rst_n_i)begin
    if(~rst_n_i)begin
        mic_active <= 1'd0;
    end
    else if(infrared_en)begin
        mic_active <= 1'd1;
    end
    else if(fifo_full)begin
        mic_active <= 1'd0;
    end
    else begin
        mic_active <= mic_active;
    end
end

/* r_en: FIFO读有效 */
always@(posedge clk_i or negedge rst_n_i)begin
    if(~rst_n_i)begin
        r_en <= 1'd0;
    end
    else if(fifo_empty)begin
        r_en <= 1'd0;
    end
    else if(fifo_full)begin
        r_en <= 1'd1;
    end
    else begin
        r_en <= r_en;
    end
end

/* r_en上升沿捕捉 */
always@(posedge clk_i or negedge rst_n_i)begin
    if(~rst_n_i)begin
        r_en_t0 <= 1'd0;
        r_en_t1 <= 1'd0;
    end
    else begin
        r_en_t0 <= r_en_t1;
        r_en_t1 <= r_en;
    end
end

assign data_start = (r_en_t0 == 1'd0 && r_en_t1 == 1'd1) ? 1'd1 : 1'd0;

/* 检测到缺陷，led亮 */
always@(posedge clk_i or negedge rst_n_i)begin
    if(~rst_n_i || infrared_en)begin
        fault_detect_led <= 1'd1;
    end
    else if(fault_detect_vaild)begin
        fault_detect_led <= ~fault_detect;
    end
    else begin
        fault_detect_led <= fault_detect_led;
    end
end

/* 磁瓦好坏指示脉冲 */
always@(posedge clk_i or negedge rst_n_i)begin
    if(~rst_n_i)begin
        good_pulse <= 1'd0;
        bad_pulse <= 1'd0;
    end
    else if(fault_detect_vaild && fault_detect)begin
        good_pulse <= 1'd0;
        bad_pulse <= 1'd1;
    end
    else if(fault_detect_vaild)begin
        good_pulse <= 1'd1;
        bad_pulse <= 1'd0;
    end
    else begin
        good_pulse <= 1'd0;
        bad_pulse <= 1'd0;
    end
end

mic_interface u_mic_interface(
    .clk_i(clk_i),   
    .rst_i(~mic_active),
    .sd_i(sd_i),    
    .ws_o(ws_o),    
    .sck_o(sck_o),   
    .LR_o(LR_o),    
    .data_o(data),  
    .data_en_o(data_en)
);

mic_capture#(
    .VAILD_DATA_NUM_TH(VAILD_DATA_NUM_TH),
    .VAILD_DATA_VALUE_TH(VAILD_DATA_VALUE_TH)
)u_mic_capture(
    .clk_i(ws_o),
    .rst_i(~mic_active),
    .data_i(data),
    .data_en_i(data_en),
    .capture_en_o(capture_en)
);

/* infrared_en需要作为复位信号，因为fifo_full在WrClk消失后一直为高电平 */
FIFO_HS_Top u_FIFO(
    .Data(data),            //input [7:0] Data
    .Reset(~rst_n_i || infrared_en),       //input Reset
    .WrClk(ws_o),           //input WrClk
    .RdClk(clk_i),          //input RdClk
    .WrEn(capture_en),      //input WrEn
    .RdEn(r_en),            //input RdEn
    .Q(data_fifo_out),      //output [7:0] Q
    .Empty(fifo_empty),     //output Empty
    .Full(fifo_full)        //output Full
);

fault_detect_top u_fault_detect_top(
    .clk_i(clk_i),
    .rst_i(~rst_n_i),
    .data_i(data_fifo_out),
    .start_i(data_start),
    .fault_detected_o(fault_detect),
    .vaild_o(fault_detect_vaild)
);

motor_ctrl#(
    .DUTY_CENTRAL(DUTY_CENTRAL)
)u_motor_ctrl(
    .clk_i(clk_i),
    .rst_i(~rst_n_i),
    .left_i(good_pulse), 
    .right_i(bad_pulse),
    .pwm_o(motor_pwm)   
);

uart_screen_ctrl#(
    .CLK_FREQ(CLK_FREQ),
    .UART_BPS(UART_BPS)
)u_uart_screen_ctrl(
    .clk_i(clk_i),
    .rst_i(~rst_n_i),
    .good_i(good_pulse),
    .bad_i(bad_pulse),
    .uart_tx(uart_tx_o)
);

///* uart发送模块 */
//uart_conv #(
//    .CLK_FREQ(27_000_000),
//    .UART_BPS(115200)
//)u_uart_conv(
//    .clk_i(clk_i),
//    .rst_i(~rst_n_i),
//    .sck_i(sck_o),
//    .ws_i(ws_o), 
//    .sd_i(sd_i), 
//    .txd_o(uart_tx_o) 
//);

endmodule
