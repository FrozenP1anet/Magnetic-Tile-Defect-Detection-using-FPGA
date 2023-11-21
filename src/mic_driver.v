/* 用于驱动麦克风输出数据 */
module mic_driver(
    input           clk_i,          // 27M时钟
    input           rst_n_i,
    output reg      sck_o,          // 2.7M IIS时钟    
    output reg      ws_o,           // IIS WS位
    output          LR_o            // 左右声道选择
);

parameter CLK_FREQ = 27_000_000;
parameter SCK_FREQ = 27_000_00;
localparam SCK_CNT  = CLK_FREQ / SCK_FREQ;     // IIS时钟计数器的计数值  

assign LR_o = 1'd0;         // 左声道采集数据
assign rst_i = ~rst_n_i;

/* IIS时钟计数器 */
reg [3:0] sck_cnt;
always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        sck_cnt <= 4'd0;
        sck_o <= 1'd0;
    end
    else if(sck_cnt == 4'd5)begin
        sck_cnt <= 4'd1;
        sck_o <= ~sck_o;
    end
    else begin
        sck_cnt <= sck_cnt + 4'd1;
    end
end

/* WS位计数器 */
reg [5:0] ws_cnt;
always@(negedge sck_o or posedge rst_i)begin
    if(rst_i)begin
        ws_o <= 1'd0;
    end
    else if(ws_cnt == 6'd1)begin
        ws_o <= ~ws_o;
    end
    else begin
        ws_o <= ws_o;
    end
end

always@(posedge sck_o or posedge rst_i)begin
    if(rst_i)begin
        ws_cnt <= 6'd0;
    end
    else if(ws_cnt == 6'd32)begin
        ws_cnt <= 6'd1;
    end
    else begin
        ws_cnt <= ws_cnt + 1'd1;
    end
end

endmodule
