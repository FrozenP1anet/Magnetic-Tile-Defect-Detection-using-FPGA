module fft_wrapper(
    input               clk_i,
    input               rst_i,
    input [7:0]         data_i,
    input               start_i,
    output reg[31:0]    amp_o,
    output reg          amp_vaild_o
);

parameter NUMBER_OF_DATA = 4096;

wire ipd;
wire opd;
// 最高位代表符号位
reg [7:0] xn_re;
reg [7:0] xn_im;
wire [7:0] xk_re;
wire [7:0] xk_im;

/* xn_re和xn_im逻辑 */
always@(posedge clk_i or posedge rst_i) begin
    if(rst_i) begin
        xn_re <= 8'd0;
        xn_im <= 8'd0;
    end
    else if(ipd || start_i) begin
        xn_re <= data_i;
        xn_im <= data_i;
    end
    else begin
        xn_re <= 8'd0;
        xn_im <= 8'd0;
    end
end

/* amp逻辑 */
wire [7:0] xk_re_abs;
wire [7:0] xk_im_abs;
wire [11:0] idx;
assign xk_re_abs = xk_re[7] ? (8'b1111_1111-xk_re)+1'd1 : xk_re;
assign xk_im_abs = xk_im[7] ? (8'b1111_1111-xk_im)+1'd1 : xk_im;
always@(posedge clk_i or posedge rst_i) begin
    if(rst_i) begin
        amp_o <= 32'd0;
    end
    else if(opd && idx <= 12'd10) begin         // 忽略频域前几个数据点
        amp_o <= 32'd0;
    end
    else if(opd) begin
        amp_o <= xk_re_abs*xk_re_abs + xk_im_abs*xk_im_abs;
    end
    else begin
        amp_o <= 32'd0;
    end
end

always@(posedge clk_i or posedge rst_i) begin
    if(rst_i) begin
        amp_vaild_o <= 1'd0;
    end
    else if(idx >= 12'd0 && idx < NUMBER_OF_DATA/2 && opd) begin
        amp_vaild_o <= 1'd1;
    end
    else begin
        amp_vaild_o <= 1'd0;
    end
end

FFT_Top u_fft(
    .idx(idx), //output [11:0] idx
    .xk_re(xk_re), //output [7:0] xk_re
    .xk_im(xk_im), //output [7:0] xk_im
    .sod(), //output sod
    .ipd(ipd), //output ipd
    .eod(), //output eod
    .busy(), //output busy
    .soud(), //output soud
    .opd(opd), //output opd
    .eoud(), //output eoud
    .xn_re(xn_re), //input [7:0] xn_re
    .xn_im(xn_im), //input [7:0] xn_im
    .start(start_i), //input start
    .clk(clk_i), //input clk
    .rst(rst_i) //input rst
);

endmodule
