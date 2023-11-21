//Copyright (C)2014-2023 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: Template file for instantiation
//GOWIN Version: V1.9.8.11 Education
//Part Number: GW2A-LV18PG256C8/I7
//Device: GW2A-18
//Device Version: C
//Created Time: Sun Oct 29 15:59:18 2023

//Change the instance name and port connections to the signal names
//--------Copy here to design--------

	FFT_Top your_instance_name(
		.idx(idx_o), //output [11:0] idx
		.xk_re(xk_re_o), //output [7:0] xk_re
		.xk_im(xk_im_o), //output [7:0] xk_im
		.sod(sod_o), //output sod
		.ipd(ipd_o), //output ipd
		.eod(eod_o), //output eod
		.busy(busy_o), //output busy
		.soud(soud_o), //output soud
		.opd(opd_o), //output opd
		.eoud(eoud_o), //output eoud
		.xn_re(xn_re_i), //input [7:0] xn_re
		.xn_im(xn_im_i), //input [7:0] xn_im
		.start(start_i), //input start
		.clk(clk_i), //input clk
		.rst(rst_i) //input rst
	);

//--------Copy end-------------------
