/* 串口屏控制模块 */
module uart_screen_ctrl(
    input       clk_i,
    input       rst_i,
    input       good_i,         // 磁瓦完好指示脉冲
    input       bad_i,          // 磁瓦缺陷指示脉冲
    output      uart_tx         // 串口发送
);
/* 串口传输参数 */
parameter CLK_FREQ = 27_000_000;
parameter UART_BPS = 9600;

localparam IDLE              = 0;
localparam GOOD_TXT_SEND     = 1;
localparam GOOD_CNT_SEND     = 2;
localparam BAD_TXT_SEND      = 3;
localparam BAD_CNT_SEND      = 4;
localparam TOTAL_TXT_SEND    = 5;
localparam TOTAL_CNT_SEND    = 6;
localparam END_TXT_SEND      = 7;

wire good_posedge;
reg good_t0;
reg good_t1;
wire bad_posedge;
reg bad_t0;
reg bad_t1;
reg [3:0] state;                    // 状态
reg [3:0] state_t0;
reg [3:0] state_t1;
wire state_change;                  // 状态改变脉冲
wire uart_busy;
wire uart_busy_negedge;
reg uart_busy_t0;
reg uart_busy_t1;
reg cnt_finish;                     // 数据发送计数结束
reg [7:0] good_txt [0:28];
reg [7:0] bad_txt [0:28];
reg [7:0] total_txt [0:15];
reg [7:0] end_txt [0:2];
reg [7:0] good_cnt;                 // 良品计数
reg [7:0] bad_cnt;                  // 次品计数
reg [7:0] total_cnt;                // 总计数
wire [7:0] good_cnt_one;            // 良品计数值个位
wire [7:0] good_cnt_ten;            // 良品计数值十位
wire [1:0] good_cnt_num;            // 良品数据发送个数(大于等于10需要发送两个数据)
wire [7:0] bad_cnt_one;             // 次品计数值个位
wire [7:0] bad_cnt_ten;             // 次品计数值十位
wire [1:0] bad_cnt_num;             // 次品数据发送个数(大于等于10需要发送两个数据)
wire [7:0] total_cnt_one;           // 总计数值个位
wire [7:0] total_cnt_ten;           // 总计数值十位
wire [1:0] total_cnt_num;           // 总数据发送个数
reg [7:0] cnt;                      // uart_din数据发送个数计数器
reg [7:0] cnt_t0;
reg [7:0] cnt_t1;
wire cnt_change;                    // cnt改变脉冲
reg [7:0] uart_din;
wire uart_en;

/* good_i和bad_i上升沿捕获 */
always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        good_t0 <= 1'd0;
        good_t1 <= 1'd0;
    end
    else begin
        good_t0 <= good_t1;
        good_t1 <= good_i;
    end
end
assign good_posedge = (good_t0 == 1'd0 && good_t1 == 1'd1) ? 1'd1 : 1'd0;

always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        bad_t0 <= 1'd0;
        bad_t1 <= 1'd0;
    end
    else begin
        bad_t0 <= bad_t1;
        bad_t1 <= bad_i;
    end
end
assign bad_posedge = (bad_t0 == 1'd0 && bad_t1 == 1'd1) ? 1'd1 : 1'd0;

/* uart_busy下降沿捕获 */
always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        uart_busy_t0 <= 1'd0;
        uart_busy_t1 <= 1'd0;
    end
    else begin
        uart_busy_t0 <= uart_busy_t1;
        uart_busy_t1 <= uart_busy;
    end
end
assign uart_busy_negedge = (uart_busy_t1 == 1'd0 && uart_busy_t0 == 1'd1) ? 1'd1 : 1'd0;

/* state状态改变捕获 */
always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        state_t0 <= 4'd0;
        state_t1 <= 4'd0;
    end
    else begin
        state_t0 <= state_t1;
        state_t1 <= state;
    end
end
assign state_change = (state_t0 == state_t1) ? 1'd0 : 1'd1;

/* state数值改变捕获 */
always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        cnt_t0 <= 8'd0;
        cnt_t1 <= 8'd0;
    end
    else begin
        cnt_t0 <= cnt_t1;
        cnt_t1 <= cnt;
    end
end
assign cnt_change = (cnt_t0 == cnt_t1) ? 1'd0 : 1'd1;

/* good_txt, bad_txt, total_txt, end_txt赋初值 */
always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        good_txt[0] <= 8'd0;
        good_txt[1] <= 8'd0;
        good_txt[2] <= 8'd0;
        good_txt[3] <= 8'd0;
        good_txt[4] <= 8'd0;
        good_txt[5] <= 8'd0;
        good_txt[6] <= 8'd0;
        good_txt[7] <= 8'd0;
        good_txt[8] <= 8'd0;
        good_txt[9] <= 8'd0;
        good_txt[10] <= 8'd0;
        good_txt[11] <= 8'd0;
        good_txt[12] <= 8'd0;
        good_txt[13] <= 8'd0;
        good_txt[14] <= 8'd0;
        good_txt[15] <= 8'd0;
        good_txt[16] <= 8'd0;
        good_txt[17] <= 8'd0;
        good_txt[18] <= 8'd0;
        good_txt[19] <= 8'd0;
        good_txt[20] <= 8'd0;
        good_txt[21] <= 8'd0;
        good_txt[22] <= 8'd0;
        good_txt[23] <= 8'd0;
        good_txt[24] <= 8'd0;
        good_txt[25] <= 8'd0;
        good_txt[26] <= 8'd0;
        good_txt[27] <= 8'd0;
        good_txt[28] <= 8'd0;
    end
    else begin
        good_txt[0] <= 8'h74;
        good_txt[1] <= 8'h32;
        good_txt[2] <= 8'h2E;
        good_txt[3] <= 8'h74;
        good_txt[4] <= 8'h78;
        good_txt[5] <= 8'h74;
        good_txt[6] <= 8'h3D;
        good_txt[7] <= 8'h22;
        good_txt[8] <= 8'hC1;
        good_txt[9] <= 8'hBC;
        good_txt[10] <= 8'hC6;
        good_txt[11] <= 8'hB7;
        good_txt[12] <= 8'h22;
        good_txt[13] <= 8'hFF;
        good_txt[14] <= 8'hFF;
        good_txt[15] <= 8'hFF;
        good_txt[16] <= 8'h70;
        good_txt[17] <= 8'h61;
        good_txt[18] <= 8'h67;
        good_txt[19] <= 8'h65;
        good_txt[20] <= 8'h33;
        good_txt[21] <= 8'h2E;
        good_txt[22] <= 8'h6E;
        good_txt[23] <= 8'h37;
        good_txt[24] <= 8'h2E;
        good_txt[25] <= 8'h76;
        good_txt[26] <= 8'h61;
        good_txt[27] <= 8'h6C;
        good_txt[28] <= 8'h3D;
    end
end

always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        bad_txt[0] <= 8'd0;
        bad_txt[1] <= 8'd0;
        bad_txt[2] <= 8'd0;
        bad_txt[3] <= 8'd0;
        bad_txt[4] <= 8'd0;
        bad_txt[5] <= 8'd0;
        bad_txt[6] <= 8'd0;
        bad_txt[7] <= 8'd0;
        bad_txt[8] <= 8'd0;
        bad_txt[9] <= 8'd0;
        bad_txt[10] <= 8'd0;
        bad_txt[11] <= 8'd0;
        bad_txt[12] <= 8'd0;
        bad_txt[13] <= 8'd0;
        bad_txt[14] <= 8'd0;
        bad_txt[15] <= 8'd0;
        bad_txt[16] <= 8'd0;
        bad_txt[17] <= 8'd0;
        bad_txt[18] <= 8'd0;
        bad_txt[19] <= 8'd0;
        bad_txt[20] <= 8'd0;
        bad_txt[21] <= 8'd0;
        bad_txt[22] <= 8'd0;
        bad_txt[23] <= 8'd0;
        bad_txt[24] <= 8'd0;
        bad_txt[25] <= 8'd0;
        bad_txt[26] <= 8'd0;
        bad_txt[27] <= 8'd0;
        bad_txt[28] <= 8'd0;
    end
    else begin
        bad_txt[0] <= 8'h74;
        bad_txt[1] <= 8'h32;
        bad_txt[2] <= 8'h2E;
        bad_txt[3] <= 8'h74;
        bad_txt[4] <= 8'h78;
        bad_txt[5] <= 8'h74;
        bad_txt[6] <= 8'h3D;
        bad_txt[7] <= 8'h22;
        bad_txt[8] <= 8'hB4;
        bad_txt[9] <= 8'hCE;
        bad_txt[10] <= 8'hC6;
        bad_txt[11] <= 8'hB7;
        bad_txt[12] <= 8'h22;
        bad_txt[13] <= 8'hFF;
        bad_txt[14] <= 8'hFF;
        bad_txt[15] <= 8'hFF;
        bad_txt[16] <= 8'h70;
        bad_txt[17] <= 8'h61;
        bad_txt[18] <= 8'h67;
        bad_txt[19] <= 8'h65;
        bad_txt[20] <= 8'h33;
        bad_txt[21] <= 8'h2E;
        bad_txt[22] <= 8'h6E;
        bad_txt[23] <= 8'h38;
        bad_txt[24] <= 8'h2E;
        bad_txt[25] <= 8'h76;
        bad_txt[26] <= 8'h61;
        bad_txt[27] <= 8'h6C;
        bad_txt[28] <= 8'h3D;
    end
end

always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        total_txt[0] <= 8'd0;
        total_txt[1] <= 8'd0;
        total_txt[2] <= 8'd0;
        total_txt[3] <= 8'd0;
        total_txt[4] <= 8'd0;
        total_txt[5] <= 8'd0;
        total_txt[6] <= 8'd0;
        total_txt[7] <= 8'd0;
        total_txt[8] <= 8'd0;
        total_txt[9] <= 8'd0;
        total_txt[10] <= 8'd0;
        total_txt[11] <= 8'd0;
        total_txt[12] <= 8'd0;
        total_txt[13] <= 8'd0;
        total_txt[14] <= 8'd0;
        total_txt[15] <= 8'd0;
    end
    else begin
        total_txt[0] <= 8'hFF;
        total_txt[1] <= 8'hFF;
        total_txt[2] <= 8'hFF;
        total_txt[3] <= 8'h70;
        total_txt[4] <= 8'h61;
        total_txt[5] <= 8'h67;
        total_txt[6] <= 8'h65;
        total_txt[7] <= 8'h33;
        total_txt[8] <= 8'h2E;
        total_txt[9] <= 8'h6E;
        total_txt[10] <= 8'h36;
        total_txt[11] <= 8'h2E;
        total_txt[12] <= 8'h76;
        total_txt[13] <= 8'h61;
        total_txt[14] <= 8'h6C;
        total_txt[15] <= 8'h3D;
    end
end

always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        end_txt[0] <= 8'd0;
        end_txt[1] <= 8'd0;
        end_txt[2] <= 8'd0;
    end
    else begin
        end_txt[0] <= 8'hFF;
        end_txt[1] <= 8'hFF;
        end_txt[2] <= 8'hFF;
    end
end

/* good_cnt: 良品计数器 */
always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        good_cnt <= 8'd0;
    end
    else if(good_posedge && good_cnt == 8'd99)begin
        good_cnt <= 8'd0;
    end
    else if(good_posedge)begin
        good_cnt <= good_cnt + 8'd1;
    end
    else begin
        good_cnt <= good_cnt;
    end
end

assign good_cnt_one = good_cnt % 10;
assign good_cnt_ten = good_cnt / 10;
assign good_cnt_num = good_cnt_ten ? 2'd2 : 2'd1;

/* bad_cnt: 次品计数器 */
always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        bad_cnt <= 8'd0;
    end
    else if(bad_posedge && bad_cnt == 8'd99)begin
        bad_cnt <= 8'd0;
    end
    else if(bad_posedge)begin
        bad_cnt <= bad_cnt + 8'd1;
    end
    else begin
        bad_cnt <= bad_cnt;
    end
end

assign bad_cnt_one = bad_cnt % 10;
assign bad_cnt_ten = bad_cnt / 10;
assign bad_cnt_num = bad_cnt_ten ? 2'd2 : 2'd1;

/* total_cnt: 总计数器 */
always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        total_cnt <= 8'd0;
    end
    else if((bad_posedge || good_posedge) && total_cnt == 8'd99)begin
        total_cnt <= 8'd0;
    end
    else if(bad_posedge || good_posedge)begin
        total_cnt <= total_cnt + 8'd1;
    end
    else begin
        total_cnt <= total_cnt;
    end
end

assign total_cnt_one = total_cnt % 10;
assign total_cnt_ten = total_cnt / 10;
assign total_cnt_num = total_cnt_ten ? 2'd2 : 2'd1;

/* 状态机 */
always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        state <= 4'd0;
    end
    else begin
        case(state)
            IDLE: begin
                if(good_posedge)begin
                    state <= GOOD_TXT_SEND;
                end
                else if(bad_posedge)begin
                    state <= BAD_TXT_SEND;
                end 
                else begin
                    state <= state;
                end
            end
            GOOD_TXT_SEND: begin
                if(cnt_finish)begin
                    state <= GOOD_CNT_SEND;
                end
                else begin
                    state <= state;
                end
            end
            GOOD_CNT_SEND: begin
                if(cnt_finish)begin
                    state <= TOTAL_TXT_SEND;
                end
                else begin
                    state <= state;
                end
            end
            BAD_TXT_SEND: begin
                if(cnt_finish)begin
                    state <= BAD_CNT_SEND;
                end
                else begin
                    state <= state;
                end
            end
            BAD_CNT_SEND: begin
                if(cnt_finish)begin
                    state <= TOTAL_TXT_SEND;
                end
                else begin
                    state <= state;
                end
            end
            TOTAL_TXT_SEND: begin
                if(cnt_finish)begin
                    state <= TOTAL_CNT_SEND;
                end
                else begin
                    state <= state;
                end
            end
            TOTAL_CNT_SEND: begin
                if(cnt_finish)begin
                    state <= END_TXT_SEND;
                end
                else begin
                    state <= state;
                end
            end
            END_TXT_SEND: begin
                if(cnt_finish)begin
                    state <= IDLE;
                end
                else begin
                    state <= state;
                end
            end
            default: begin
                state <= IDLE;
            end
        endcase
    end
end

/* cnt: uart_din数据发送个数计数器 */
always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        cnt <= 8'd0;
    end
    else begin
        case(state)
            IDLE: begin
                cnt <= 8'd0;
            end
            GOOD_TXT_SEND: begin
                if(state_change)begin
                    cnt <= 8'd1;
                end
                else if(uart_busy_negedge && cnt == 8'd29)begin
                    cnt <= 8'd0;
                end
                else if(uart_busy_negedge)begin
                    cnt <= cnt + 8'd1;
                end
                else begin
                    cnt <= cnt;
                end
            end
            BAD_TXT_SEND: begin
                if(state_change)begin
                    cnt <= 8'd1;
                end
                else if(uart_busy_negedge && cnt == 8'd29)begin
                    cnt <= 8'd0;
                end
                else if(uart_busy_negedge)begin
                    cnt <= cnt + 8'd1;
                end
                else begin
                    cnt <= cnt;
                end
            end
            GOOD_CNT_SEND: begin
                if(state_change)begin
                    cnt <= 8'd1;
                end
                else if(uart_busy_negedge && cnt == good_cnt_num)begin
                    cnt <= 8'd0;
                end
                else if(uart_busy_negedge)begin
                    cnt <= cnt + 8'd1;
                end
                else begin
                    cnt <= cnt;
                end
            end
            BAD_CNT_SEND: begin
                if(state_change)begin
                    cnt <= 8'd1;
                end
                else if(uart_busy_negedge && cnt == bad_cnt_num)begin
                    cnt <= 8'd0;
                end
                else if(uart_busy_negedge)begin
                    cnt <= cnt + 8'd1;
                end
                else begin
                    cnt <= cnt;
                end
            end
            TOTAL_TXT_SEND: begin
                if(state_change)begin
                    cnt <= 8'd1;
                end
                else if(uart_busy_negedge && cnt == 8'd16)begin
                    cnt <= 8'd0;
                end
                else if(uart_busy_negedge)begin
                    cnt <= cnt + 8'd1;
                end
                else begin
                    cnt <= cnt;
                end
            end
            TOTAL_CNT_SEND: begin
                if(state_change)begin
                    cnt <= 8'd1;
                end
                else if(uart_busy_negedge && cnt == total_cnt_num)begin
                    cnt <= 8'd0;
                end
                else if(uart_busy_negedge)begin
                    cnt <= cnt + 8'd1;
                end
                else begin
                    cnt <= cnt;
                end
            end
            END_TXT_SEND: begin
                if(state_change)begin
                    cnt <= 8'd1;
                end
                else if(uart_busy_negedge && cnt == 8'd3)begin
                    cnt <= 8'd0;
                end
                else if(uart_busy_negedge)begin
                    cnt <= cnt + 8'd1;
                end
                else begin
                    cnt <= cnt;
                end
            end
        endcase
    end
end

/* uart_din */
always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        uart_din <= 8'd0;
    end
    else begin
        case(state)
            IDLE: begin
                uart_din <= 8'd0;
            end
            GOOD_TXT_SEND: begin
                if(cnt)begin
                    uart_din <= good_txt[cnt - 8'd1];
                end
                else begin
                    uart_din <= 8'd0;
                end
            end
            BAD_TXT_SEND: begin
                if(cnt)begin
                    uart_din <= bad_txt[cnt - 8'd1];
                end
                else begin
                    uart_din <= 8'd0;
                end
            end
            GOOD_CNT_SEND: begin
                if(good_cnt_num == 2'd2)begin
                    if(cnt == 8'd1)begin
                        uart_din <= good_cnt_ten + 8'd48;
                    end
                    else if(cnt == 8'd2)begin
                        uart_din <= good_cnt_one + 8'd48;
                    end
                    else begin
                        uart_din <= 8'd0;
                    end
                end
                else if(good_cnt_num == 2'd1)begin
                    if(cnt == 8'd1)begin
                        uart_din <= good_cnt_one + 8'd48;
                    end
                    else begin
                        uart_din <= 8'd0;
                    end
                end
            end
            BAD_CNT_SEND: begin
                if(bad_cnt_num == 2'd2)begin
                    if(cnt == 8'd1)begin
                        uart_din <= bad_cnt_ten + 8'd48;
                    end
                    else if(cnt == 8'd2)begin
                        uart_din <= bad_cnt_one + 8'd48;
                    end
                    else begin
                        uart_din <= 8'd0;
                    end
                end
                else if(bad_cnt_num == 2'd1)begin
                    if(cnt == 8'd1)begin
                        uart_din <= bad_cnt_one + 8'd48;
                    end
                    else begin
                        uart_din <= 8'd0;
                    end
                end
            end
            TOTAL_TXT_SEND: begin
                if(cnt)begin
                    uart_din <= total_txt[cnt - 8'd1];
                end
                else begin
                    uart_din <= 8'd0;
                end
            end
            TOTAL_CNT_SEND: begin
                if(total_cnt_num == 2'd2)begin
                    if(cnt == 8'd1)begin
                        uart_din <= total_cnt_ten + 8'd48;
                    end
                    else if(cnt == 8'd2)begin
                        uart_din <= total_cnt_one + 8'd48;
                    end
                    else begin
                        uart_din <= 8'd0;
                    end
                end
                else if(total_cnt_num == 2'd1)begin
                    if(cnt == 8'd1)begin
                        uart_din <= total_cnt_one + 8'd48;
                    end
                    else begin
                        uart_din <= 8'd0;
                    end
                end
            end
            END_TXT_SEND: begin
                if(cnt)begin
                    uart_din <= end_txt[cnt - 8'd1];
                end
                else begin
                    uart_din <= 8'd0;
                end
            end
            default: begin  end
        endcase
    end
end

/* uart_en */
assign uart_en = cnt ? cnt_change : 1'd0;

/* cnt_finish: 数据发送计数结束 */
always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        cnt_finish <= 1'd0;
    end
    else begin
        case(state)
            IDLE: begin
                cnt_finish <= 1'd0;
            end
            GOOD_TXT_SEND: begin
                if(uart_busy_negedge && cnt == 8'd29)begin
                    cnt_finish <= 1'd1;
                end
                else begin
                    cnt_finish <= 1'd0;
                end
            end
            BAD_TXT_SEND: begin
                if(uart_busy_negedge && cnt == 8'd29)begin
                    cnt_finish <= 1'd1;
                end
                else begin
                    cnt_finish <= 1'd0;
                end
            end
            GOOD_CNT_SEND: begin
                if(good_cnt_num == 2'd2)begin
                    if(uart_busy_negedge && cnt == 8'd2)begin
                        cnt_finish <= 1'd1;
                    end
                    else begin
                        cnt_finish <= 1'd0;
                    end
                end
                else if(good_cnt_num == 2'd1)begin
                    if(uart_busy_negedge && cnt == 8'd1)begin
                        cnt_finish <= 1'd1;
                    end
                    else begin
                        cnt_finish <= 1'd0;
                    end
                end
            end
            BAD_CNT_SEND: begin
                if(bad_cnt_num == 2'd2)begin
                    if(uart_busy_negedge && cnt == 8'd2)begin
                        cnt_finish <= 1'd1;
                    end
                    else begin
                        cnt_finish <= 1'd0;
                    end
                end
                else if(bad_cnt_num == 2'd1)begin
                    if(uart_busy_negedge && cnt == 8'd1)begin
                        cnt_finish <= 1'd1;
                    end
                    else begin
                        cnt_finish <= 1'd0;
                    end
                end
            end
            TOTAL_TXT_SEND: begin
                if(uart_busy_negedge && cnt == 8'd16)begin
                    cnt_finish <= 1'd1;
                end
                else begin
                    cnt_finish <= 1'd0;
                end
            end
            TOTAL_CNT_SEND: begin
                if(total_cnt_num == 2'd2)begin
                    if(uart_busy_negedge && cnt == 8'd2)begin
                        cnt_finish <= 1'd1;
                    end
                    else begin
                        cnt_finish <= 1'd0;
                    end
                end
                else if(total_cnt_num == 2'd1)begin
                    if(uart_busy_negedge && cnt == 8'd1)begin
                        cnt_finish <= 1'd1;
                    end
                    else begin
                        cnt_finish <= 1'd0;
                    end
                end
            end
            END_TXT_SEND: begin
                if(uart_busy_negedge && cnt == 8'd3)begin
                    cnt_finish <= 1'd1;
                end
                else begin
                    cnt_finish <= 1'd0;
                end
            end
            default: begin  end
        endcase
    end
end

uart_send #(
    .CLK_FREQ(CLK_FREQ),
    .UART_BPS(UART_BPS)
)u_uart_send(
    .sys_clk(clk_i),     
    .sys_rst_n(~rst_i),   
    .uart_en(uart_en),     
    .uart_din(uart_din),    
    .uart_tx_busy(uart_busy),
    .uart_txd(uart_tx)     
);

endmodule
