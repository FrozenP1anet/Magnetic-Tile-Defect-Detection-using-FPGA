/* 将IIS转化为uart发送 */
module uart_conv(
    input       clk_i,              // 27M时钟
    input       rst_i,            
    input       sck_i,              // IIS时钟(2.7M)
    input       ws_i,               // IIS WS位
    input       sd_i,               // IIS 数据    
    output      txd_o               // uart发送
);

parameter CLK_FREQ = 27_000_000;
parameter UART_BPS = 115200;        // uart波特率

wire uart_busy;
reg ws_t0;
reg ws_t1;
wire ws_negedge;
reg [3:0] cnt;
reg cnt_flag;
reg [7:0] uart_din;
wire [7:0] uart_din_abs;
wire uart_en;
reg [3:0] cnt_t0;
reg [3:0] cnt_t1;
wire uart_txd;

/* cnt_flag: 有效时，sck的上升沿会使cnt计数*/
// ws下降沿捕捉
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

always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        cnt_flag <= 1'd0;
    end
    else if(ws_negedge && ~uart_busy)begin
        cnt_flag <= 1'd1;
    end
    else if(cnt == 4'd8)begin
        cnt_flag <= 1'd0;
    end
    else begin
        cnt_flag <= cnt_flag;
    end
end

/* cnt计数 */
always@(posedge sck_i or posedge rst_i)begin
    if(rst_i)begin
        cnt <= 4'd0;
    end
    else if(cnt == 4'd8 && cnt_flag)begin
        cnt <= 4'd0;
    end
    else if(cnt_flag)begin
        cnt <= cnt + 4'd1;
    end
    else begin
        cnt <= 4'd0;
    end
end

/* 
    uart_din: uart输入数据(8位补码形式) 
    uart_din_abs: uart输入数据(绝对值) 
*/
always@(posedge sck_i or posedge rst_i)begin
    if(rst_i)begin
        uart_din <= 8'd0;
    end
    else if(cnt >= 4'd1 && cnt <= 4'd8)begin
        uart_din <= uart_din | (sd_i << (4'd8 - cnt));
    end 
    else begin
        uart_din <= 8'd0;
    end
end

assign uart_din_abs = uart_din[7] ? ~(uart_din - 8'd1) : uart_din;

/* uart_en: 有效时，使能uart传输 */
always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        cnt_t0 <= 4'd0;
        cnt_t1 <= 4'd0;
    end
    else begin
        cnt_t0 <= cnt_t1;
        cnt_t1 <= cnt;
    end
end

assign uart_en = (cnt_t0 == 4'd8 && cnt_t1 == 4'd0) ? 1'd1 : 1'd0;

uart_send #(
    .CLK_FREQ(CLK_FREQ),
    .UART_BPS(UART_BPS)
)u_uart_send(
    .sys_clk(clk_i),             //系统时钟
    .sys_rst_n(~rst_i),           //系统复位，低电平有效
    .uart_en(uart_en),             //发送使能信号
    .uart_din(uart_din_abs),            //待发送数据
    .uart_tx_busy(uart_busy),        //发送忙状态标志 
    .uart_txd(txd_o)             //UART发送端口
);

endmodule
