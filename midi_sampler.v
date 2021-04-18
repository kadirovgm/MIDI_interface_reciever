module d_latch(d, clk, q, q_bar);
	
	input d, clk;
	output wire q, q_bar;
	wire out1, out2, temp,sd;
	not g2(temp, d);
	nand g1 (out1, d, clk);
	nand g3 (out2, temp, clk);
	nand g4 (q, out1, q_bar);
	nand g5 (q_bar, out2, q);
  
endmodule

module d_ff(d, clk, q, q_bar);
	input d, clk;
	output wire q, q_bar;
	wire clkf,B,C;
	not g6(clkf,clk);
	d_latch ram (d,clkf, B, C);
	d_latch rom (B, clk, q, q_bar);
  
endmodule

module byte_detector(clk, q, signal, info);
	input clk, q;
	output reg signal;
	output wire info;
	reg[11:0] cnt;
	wire[11:0] cnt_nxt;
	assign cnt_nxt = cnt +1'b1;
	always@(posedge clk)begin
		if(!signal)begin
			if(!q)begin
				signal <= 1;
			end
		end
		else begin	
			if(cnt != 11'b10100000000)begin
				cnt = cnt_nxt;
			end
			else begin
				signal <= 0;
				cnt <= 11'b0;
			end
		end
	end
	assign info = q;
endmodule

module sample_timer(clk,signal, stclk);
	input clk,signal;
	output wire stclk;
	wire[6:0]count_nxt;
	reg [6:0]count;
	assign count_nxt = count +7'b1;
	
	always @(posedge clk)begin
		if(signal)begin
			count <= count_nxt;
		end
		else begin
			count <= 7'b0;
		end
	end
	assign stclk =count[6];
endmodule

module Final(clk, rst_n,LED,usart);
	input clk, rst_n,usart;
	output [7:0] LED;
	wire [29:0] regs;
	wire clk,q,info,signal,stclk,q_bar;
	wire [7:0] temp = 8'h80;
	wire [7:0] rt = 8'b0000000;
	reg [7:0] xc;
	d_ff(usart,clk,q,q_bar);
	byte_detector gf (clk,q, signal, info);
	sample_timer hs (clk,signal,stclk);
	sampler gs(info,signal,stclk,regs);
	always @(posedge clk)begin
		if(!regs[25])begin
			xc = rt;
		end
		else begin
			xc = regs[19:12];
			//xc = regs[28:21];
		end
	end
	assign LED = xc;
endmodule 

module sampler(info, signal, stclk, regs);
	input info, signal,stclk;
	output reg [29:0] regs; 
	
	always @(posedge stclk) begin
		if(signal) begin
			regs[0] = info;
			regs[1] <= regs[0];
			regs[2] <= regs[1];
			regs[3] <= regs[2];
			regs[4] <= regs[3];
			regs[5] <= regs[4];
			regs[6] <= regs[5];
			regs[7] <= regs[6];
			regs[8] <= regs[7];
			regs[9] <= regs[8];
			regs[10] <= regs[9];
			regs[11] <= regs[10];
			regs[12] <= regs[11];
			regs[13] <= regs[12];
			regs[14] <= regs[13];
			regs[15] <= regs[14];
			regs[16] <= regs[15];
			regs[17] <= regs[16];
			regs[18] <= regs[17];
			regs[19] <= regs[18];
			regs[20] <= regs[19];
			regs[21] <= regs[20];
			regs[22] <= regs[21];
			regs[23] <= regs[22];
			regs[24] <= regs[23];
			regs[25] <= regs[24];
			regs[26] <= regs[25];
			regs[27] <= regs[26];
			regs[28] <= regs[27];
			regs[29] <= regs[28];
		end
	end
	
	
endmodule
