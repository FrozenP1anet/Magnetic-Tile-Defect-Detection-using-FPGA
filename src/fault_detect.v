module fault_detect(
    input           clk_i,
    input           rst_i,
    input [31:0]    amp_i,
    input           amp_vaild_i,
    output reg      fault_detected_o,
    output reg      vaild_o
);

parameter NUMBER_OF_DATA = 4096;

/* 输入序号 */
reg [10:0] amp_idx;
always@(posedge clk_i or posedge rst_i) begin
    if(rst_i) begin
        amp_idx <= 11'd0;
    end
    else if(amp_vaild_i && amp_idx == NUMBER_OF_DATA/2 - 1) begin
        amp_idx <= 11'd0;
    end
    else if(amp_vaild_i) begin
        amp_idx <= amp_idx + 11'd1;
    end
    else begin
        amp_idx <= 11'd0;
    end
end

/* 前三个最大值和下标 */
reg [31:0] max_data1;
reg [31:0] max_data2;
reg [31:0] max_data3;
reg [10:0] max_data1_idx;
reg [10:0] max_data2_idx;
reg [10:0] max_data3_idx;
always@(posedge clk_i or posedge rst_i) begin
    if(rst_i || vaild_o) begin
        max_data1 <= 32'd0;
        max_data2 <= 32'd0;
        max_data3 <= 32'd0;
        max_data1_idx <= 11'd0;
        max_data2_idx <= 11'd0;
        max_data3_idx <= 11'd0;
    end
    else if(amp_vaild_i) begin
        if(amp_i > max_data1) begin
            max_data3 <= max_data2;
            max_data2 <= max_data1;
            max_data1 <= amp_i;
            max_data3_idx <= max_data2_idx;
            max_data2_idx <= max_data1_idx;
            max_data1_idx <= amp_idx;
        end
        else if(amp_i > max_data2) begin
            max_data3 <= max_data2;
            max_data2 <= amp_i;
            max_data1 <= max_data1;
            max_data3_idx <= max_data2_idx;
            max_data2_idx <= amp_idx;
            max_data1_idx <= max_data1_idx;
        end
        else if(amp_i > max_data3) begin
            max_data3 <= amp_i;
            max_data2 <= max_data2;
            max_data1 <= max_data1;
            max_data3_idx <= amp_idx;
            max_data2_idx <= max_data2_idx;
            max_data1_idx <= max_data1_idx;
        end
        else begin
            max_data3 <= max_data3;
            max_data2 <= max_data2;
            max_data1 <= max_data1;
            max_data3_idx <= max_data3_idx;
            max_data2_idx <= max_data2_idx;
            max_data1_idx <= max_data1_idx;
        end
    end
    else begin
        max_data3 <= max_data3;
        max_data2 <= max_data2;
        max_data1 <= max_data1;
        max_data3_idx <= max_data3_idx;
        max_data2_idx <= max_data2_idx;
        max_data1_idx <= max_data1_idx;
    end
end

/* amp_vaild下降沿捕捉 */
wire amp_vaild_negedge;
reg amp_vaild_t0;
reg amp_vaild_t1;
always@(posedge clk_i or posedge rst_i) begin
    if(rst_i) begin
        amp_vaild_t0 <= 1'd0;
        amp_vaild_t1 <= 1'd0;
    end
    else begin
        amp_vaild_t0 <= amp_vaild_t1;
        amp_vaild_t1 <= amp_vaild_i;
    end
end

assign amp_vaild_negedge = (amp_vaild_t0==1'd1 && amp_vaild_t1==1'd0) ? 1'd1 : 1'd0;

/* 输出逻辑 */
always@(posedge clk_i or posedge rst_i) begin
    if(rst_i) begin
        vaild_o <= 1'd0;
    end
    else if(amp_vaild_negedge) begin
        vaild_o <= 1'd1;
    end
    else begin
        vaild_o <= 1'd0;
    end
end

/* 表示最大值的下标是否落在合法的区间内，合法的区间(17k-1619 18.5k-1762) */
wire max_data1_vaild;       
assign max_data1_vaild = (max_data1_idx>1619 && max_data1_idx<1762);

always@(posedge clk_i or posedge rst_i) begin
    if(rst_i) begin
        fault_detected_o <= 1'd0;
    end
    else if(amp_vaild_negedge) begin
        fault_detected_o <= ~max_data1_vaild;
    end
    else begin
        fault_detected_o <= 1'd0;
    end
end

endmodule
