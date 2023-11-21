/* 当连续输入1个有效数据时，capture_en输出高电平，代表捕获到碰撞声音 */
module mic_capture(
    input           clk_i,
    input           rst_i,
    input [7:0]     data_i,
    input           data_en_i,
    output reg      capture_en_o          // 捕获有效信号
);

parameter VAILD_DATA_NUM_TH = 1;        // 捕获到的有效数据个数门限值
parameter VAILD_DATA_VALUE_TH = 20;     // 捕获到的有效数据数值门限值

wire[7:0] data_abs;
reg [7:0] vaild_cnt;

/* 补码转化为原码 */
assign data_abs = data_i[7] ? ~(data_i - 8'd1) : data_i;

/* 有效数据计数器 */
always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        vaild_cnt <= 8'd0;
    end
    else if(data_abs > VAILD_DATA_VALUE_TH && data_en_i)begin
        vaild_cnt <= vaild_cnt + 8'd1;
    end
    else if(data_en_i)begin
        vaild_cnt <= 8'd0;
    end
    else begin
        vaild_cnt <= vaild_cnt;
    end
end

/* capture_en_o */
always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        capture_en_o <= 1'd0;
    end
    else if(vaild_cnt == VAILD_DATA_NUM_TH)begin
        capture_en_o <= 1'd1;
    end
    else begin
        capture_en_o <= capture_en_o;
    end
end

endmodule
