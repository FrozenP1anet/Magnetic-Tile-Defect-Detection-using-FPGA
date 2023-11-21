/* 舵机控制模块 */
module motor_ctrl(
    input       clk_i,
    input       rst_i,
    input       left_i,     // 输入一个上升沿，舵机向左转，3s后归位
    input       right_i,    // 输入一个上升沿，舵机向右转，3s后归位
    output reg  pwm_o       // 输出PWM
);

/* DUTY_CENTRAL为舵机归位时的计数值，13500为0度，67500为180度 */
parameter DUTY_CENTRAL = 40500;
localparam DUTY_LEFT = DUTY_CENTRAL - 18000;
localparam DUTY_RIGHT = DUTY_CENTRAL + 18000;

wire left_posedge;
wire right_posedge;
reg left_t0;
reg left_t1;
reg right_t0;
reg right_t1;
reg [31:0] pwm_cnt;
reg [31:0] pwm_duty;
reg [31:0] delay_cnt;

/* left_i和right_i上升沿捕获 */
always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        left_t0 <= 1'd0;
        left_t1 <= 1'd0;
    end
    else begin
        left_t0 <= left_t1;
        left_t1 <= left_i;
    end
end
assign left_posedge = (left_t0 == 1'd0 && left_t1 == 1'd1) ? 1'd1 : 1'd0;

always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        right_t0 <= 1'd0;
        right_t1 <= 1'd0;
    end
    else begin
        right_t0 <= right_t1;
        right_t1 <= right_i;
    end
end
assign right_posedge = (right_t0 == 1'd0 && right_t1 == 1'd1) ? 1'd1 : 1'd0;

/* PWM周期计数器 */
always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        pwm_cnt <= 32'd0;
    end
    else if(pwm_cnt == 32'd540_000)begin
        pwm_cnt <= 32'd1;
    end
    else begin
        pwm_cnt <= pwm_cnt + 32'd1;
    end
end

/* pwm_duty: PWM高电平时的计数值 */
always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        pwm_duty <= DUTY_CENTRAL;
    end
    else if(left_posedge)begin
        pwm_duty <= DUTY_LEFT;
    end
    else if(right_posedge)begin
        pwm_duty <= DUTY_RIGHT;
    end
    else if(delay_cnt == 13_000_000)begin           // delay_cnt == 81_000_000
        pwm_duty <= DUTY_CENTRAL;
    end
    else begin
        pwm_duty <= pwm_duty;
    end
end

/* 
delay_cnt: PWM_LEFT和PWM_RIGHT的延时时间计数器
延时3s
*/
always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        delay_cnt <= 32'd0;
    end
    else if(left_posedge || right_posedge)begin
        delay_cnt <= 32'd1;
    end
    else if(delay_cnt && delay_cnt == 13_000_000)begin      // delay_cnt == 81_000_000
        delay_cnt <= 32'd0;
    end
    else if(delay_cnt)begin
        delay_cnt <= delay_cnt + 32'd1;
    end
    else begin
        delay_cnt <= 32'd0;
    end
end

/* pwm_o */
always@(posedge clk_i or posedge rst_i)begin
    if(rst_i)begin
        pwm_o <= 1'd0;
    end
    else if(pwm_cnt >= 32'd1 && pwm_cnt <= pwm_duty)begin
        pwm_o <= 1'd1;
    end
    else begin
        pwm_o <= 1'd0;
    end
end

endmodule
