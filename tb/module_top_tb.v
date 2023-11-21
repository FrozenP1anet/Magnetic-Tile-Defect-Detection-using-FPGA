`timescale 1 ns / 1 ns
module module_top_tb();

reg clk_27M;
reg rst_n_i;
wire ws;
wire sck;
reg sd;
wire fault_detect_led;
reg infrared_en;
reg infrared_flag;      // infrared_en是否已经产生
reg ws_t0;
reg ws_t1;
wire ws_negedge;
reg cnt_flag;
reg [4:0] cnt_bit;
reg [15:0] cnt_data;
reg [7:0] TXT_Buff[4095:0];
reg [7:0] data_buff;

initial begin
    clk_27M <= 1'd0;
    rst_n_i <= 1'd0;
    # 100
    rst_n_i <= 1'd1;
end

always #18 clk_27M <= ~clk_27M;

initial begin
    infrared_en <= 1'd0;
    # 300
    infrared_en <= 1'd1;
    # 50
    infrared_en <= 1'd0;
end

always@(*)begin
    if(~rst_n_i)begin
        infrared_flag <= 1'd0;
    end
    else if(infrared_en == 1'd1)begin
        infrared_flag <= 1'd1;
    end
    else begin
        infrared_flag <= infrared_flag;
    end
end

/* ws下降沿捕捉 */
always@(posedge clk_27M or negedge rst_n_i)begin
    if(~rst_n_i)begin
        ws_t0 <= 1'd0;
        ws_t1 <= 1'd0;
    end
    else begin
        ws_t0 <= ws_t1;
        ws_t1 <= ws;
    end
end

assign ws_negedge = (ws_t0 == 1'd1 && ws_t1 == 1'd0) ? 1'd1 : 1'd0;

/* 
cnt_flag: cnt计数有效
cnt_flag = 1时， 每一个sck上升沿，cnt + 1 
*/
always@(posedge clk_27M or negedge rst_n_i)begin
    if(~rst_n_i)begin
        cnt_flag <= 1'd0;
    end
    else if(infrared_flag && ws_negedge)begin
        cnt_flag <= 1'd1;
    end
    else if(cnt_bit == 4'd8)begin
        cnt_flag <= 1'd0;
    end
    else begin
        cnt_flag <= cnt_flag;
    end
end

/* cnt_bit: sd数据位数计数，从1-8 */
always@(posedge sck or negedge rst_n_i)begin
    if(~rst_n_i)begin
        cnt_bit <= 4'd0;
    end
    else if(cnt_flag)begin
        cnt_bit <= cnt_bit + 4'd1;
    end
    else begin
        cnt_bit <= 4'd0;
    end
end

/* cnt_data: sd数据个数计数，从1-4096 */
always@(negedge ws or negedge rst_n_i)begin
    if(~rst_n_i)begin
        cnt_data <= 16'd0;
    end
    else if(infrared_flag && cnt_data == 16'd4096)begin
        cnt_data <= 16'd1;
    end
    else if(infrared_flag)begin
        cnt_data <= cnt_data + 16'd1;
    end
    else begin
        cnt_data <= 16'd0;
    end
end

/* data_buff: 加载每个周期输出的数据 */
initial begin    
      $readmemh("sound.dat",TXT_Buff);
end 

always@(posedge clk_27M or negedge rst_n_i)begin
    if(~rst_n_i)begin
        data_buff <= 8'd0;
    end
    else if(infrared_flag && ws_negedge)begin
        data_buff <= TXT_Buff[cnt_data - 16'd1];
    end
    else begin
        data_buff <= data_buff;
    end
end

/* sd */
always@(cnt_bit)begin
    if(~rst_n_i)begin
        sd <= 1'd0;
    end
    else if(cnt_bit >= 4'd1 && cnt_bit <= 4'd8)begin
        sd <= data_buff[4'd8 - cnt_bit];
    end
    else begin
        sd <= 1'd0;
    end
end

module_top u_module_top(
    .clk_i(clk_27M),          
    .rst_n_i(rst_n_i),
    .infrared_key(~infrared_en),    
    .sd_i(sd),           
    .ws_o(ws),           
    .sck_o(sck),          
    .LR_o(),           
    .fault_detect_led(fault_detect_led)
);

endmodule
