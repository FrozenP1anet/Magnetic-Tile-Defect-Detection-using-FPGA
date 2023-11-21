/* 将串行IIS输入延时100ms后，转化为并行输出 */
module data_conv(
    input           clk_i,          // 27M时钟
    input           rst_i,
    input           sck_i,          // 2.7M IIS时钟    
    input           ws_i,           // IIS WS位
    input           sd_i,           // IIS数据位
    output reg[7:0] data_o,         // 输出并行数据
    output reg      data_en_o       // 输出数据有效
);

reg [19:0] cnt_delay;
reg delay_100ms;
reg ws_t0;
reg ws_t1;
wire ws_negedge;
reg ws_t0_sck;
reg ws_t1_sck;
reg [3:0] cnt;
reg [7:0] data_buff;
reg data_buff_rdy;
reg cnt_flag;

/* 延时100ms等待麦克风输出稳定 */
always@(posedge sck_i or posedge rst_i)begin
    if(rst_i)begin
        cnt_delay <= 20'd0;
    end
    else begin
        cnt_delay <= cnt_delay + 20'd1;
    end
end

always@(posedge sck_i or posedge rst_i)begin
    if(rst_i)begin
        delay_100ms <= 1'd0;
    end
    else if(cnt_delay == 20'd270_000)begin
        delay_100ms <= 1'd1;
    end
    else begin
        delay_100ms <= delay_100ms;
    end
end

/* ws下降沿捕捉 */
always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        ws_t0 <= 1'd0;
        ws_t1 <= 1'd0;
    end
    else begin
        ws_t0 <= ws_t1;
        ws_t1 <= ws_i;
    end
end

assign ws_negedge = (ws_t0 == 1'd1 && ws_t1 == 1'd0) ? 1'd1 : 1'd0;

/* 
cnt_flag: cnt计数有效
cnt_flag = 1时， 每一个sck上升沿，cnt + 1 
*/
always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        cnt_flag <= 1'd0;
    end
    else if(delay_100ms && ws_negedge)begin
//    else if(ws_negedge)begin
        cnt_flag <= 1'd1;
    end
    else if(cnt == 4'd8)begin
        cnt_flag <= 1'd0;
    end
    else begin
        cnt_flag <= cnt_flag;
    end
end

/* cnt: sd数据计数 */
always@(posedge sck_i or posedge rst_i)begin
    if(rst_i)begin
        cnt <= 4'd0;
    end
    else if(cnt_flag)begin
        cnt <= cnt + 4'd1;
    end
    else begin
        cnt <= 4'd0;
    end
end

/* ws下降沿捕捉(以sck为时钟) */
always@(posedge sck_i or posedge rst_i)begin
    if(rst_i)begin
        ws_t0_sck <= 1'd0;
        ws_t1_sck <= 1'd0;
    end
    else begin
        ws_t0_sck <= ws_t1_sck;
        ws_t1_sck <= ws_i;
    end
end

/* data_buff: 暂时储存sd数据，下一个ws时钟周期输出 */
always@(posedge sck_i or posedge rst_i)begin
    if(rst_i)begin
        data_buff <= 8'd0;
    end
    else if(cnt == 4'd1)begin
        data_buff = 8'd0;
        data_buff = data_buff | (sd_i << (4'd8 - cnt));
    end
    else if(4'd2 <= cnt && cnt <= 4'd8)begin
        data_buff <= data_buff | (sd_i << (4'd8 - cnt));
    end
    else begin
        data_buff <= data_buff;
    end
end

/* data_buff_rdy: data_buff中的数据有效，即ws为低电平时接收到数据 */
always@(posedge sck_i or posedge rst_i)begin
    if(rst_i)begin
        data_buff_rdy <= 1'd0;
    end
    else if(cnt == 4'd8)begin
        data_buff_rdy <= 1'd1;
    end
    else if(ws_t0_sck == 1'd1 && ws_t1_sck == 1'd0)begin
        data_buff_rdy <= 1'd0;
    end
    else begin
        data_buff_rdy <= data_buff_rdy;
    end
end

/* data_o */
always@(negedge ws_i or posedge rst_i)begin
    if(rst_i)begin
        data_o <= 8'd0;
    end
    else if(data_buff_rdy)begin
        data_o <= data_buff;
    end
    else begin
        data_o <= 8'd0;
    end
end

/* data_en_o */
always@(negedge ws_i or posedge rst_i)begin
    if(rst_i)begin
        data_en_o <= 1'd0;
    end
    else if(data_buff_rdy)begin
        data_en_o <= 1'd1;
    end
    else begin
        data_en_o <= 1'd0;
    end
end

endmodule
