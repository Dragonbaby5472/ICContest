
`timescale 1ns/10ps

module  CONV(
	input		clk,
	input		reset,
	output		busy,	
	input		ready,	
			
	output	[11:0]	iaddr,
	input	[19:0]	idata,	
	
	output	 	cwr,
	output	[11:0] 	caddr_wr,
	output	[19:0]	cdata_wr,
	
	output	 	crd,
	output	[11:0]	caddr_rd,
	input	[19:0]	cdata_rd,
	
	output	[2:0] 	csel
);
//--------------parameter----------------//
parameter kernel_0 = 40'h000000A89E;
parameter kernel_1 = 40'h00000092D5;
parameter kernel_2 = 40'h0000006D43;
parameter kernel_3 = 40'h0000001004;
parameter kernel_4 = 40'hFFFFFF8F71;
parameter kernel_5 = 40'hFFFFFF6E54;
parameter kernel_6 = 40'hFFFFFFA6D7;
parameter kernel_7 = 40'hFFFFFFC834;
parameter kernel_8 = 40'hFFFFFFAC19;
//-----------------reg-------------------//
reg [9:0] pixel;
reg [1:0] block;
reg [3:0] counter;
reg [2:0] csel_reg;
reg cwr_reg;
reg mode;
reg busy_reg;
reg [11:0] iaddr_reg;
reg [39:0] result;
reg [19:0] max_pooling;
reg [19:0] output_buffer;
reg [12:0] caddr_wr_reg;
wire [11:0] pixel_addr;
//-----------------wire------------------//
wire [13:0] pixel_around [8:0];
wire [39:0] pixel_mul [8:0];
wire [19:0] layer0;
//pixel
always @(posedge clk  or posedge reset) begin
	if(reset) pixel <= 10'd0;
	else if(ready) pixel <= 10'd0;
	else if(counter == 4'd8 && block == 2'd3) pixel <= pixel + 10'd1;
	else pixel <= pixel; 
end
//block
always @(posedge clk  or posedge reset) begin
	if(reset) block <= 2'd0;
	else if(ready) block <= 2'd0;
	else if(counter == 4'd8) block <= block + 2'd1;
	else block <= block; 
end

assign pixel_addr = {pixel[9:5], block[1], pixel[4:0], block[0]};

//counter
always @(posedge clk or posedge reset) begin
	if(reset) counter <= 4'd0;
	else if(ready)counter <= 4'd0;
	else if(counter == 4'd8) counter <= 4'd0;
	else counter <= counter + 4'd1;
end
//busy
always @(posedge clk or posedge reset) begin
	if(reset) busy_reg <= 1'b0;
	else if(ready) busy_reg <= 1'd1;
	else if(cwr_reg && pixel_addr == 12'd0 && counter == 4'd8) busy_reg <= 1'd0;
	else busy_reg <= busy_reg;
end

assign busy = busy_reg;
//pixel_around
//x
assign pixel_around[0][6:0] = {1'd0, pixel_addr[5:0]} + 7'd127;
assign pixel_around[1][6:0] = {1'd0, pixel_addr[5:0]};
assign pixel_around[2][6:0] = {1'd0, pixel_addr[5:0]} + 7'd1;
assign pixel_around[3][6:0] = {1'd0, pixel_addr[5:0]} + 7'd127;
assign pixel_around[5][6:0] = {1'd0, pixel_addr[5:0]} + 7'd1;
assign pixel_around[6][6:0] = {1'd0, pixel_addr[5:0]} + 7'd127;
assign pixel_around[7][6:0] = {1'd0, pixel_addr[5:0]};
assign pixel_around[8][6:0] = {1'd0, pixel_addr[5:0]} + 7'd1;
//y
assign pixel_around[0][13:7] = {1'd0, pixel_addr[11:6]} + 7'd127;
assign pixel_around[1][13:7] = {1'd0, pixel_addr[11:6]} + 7'd127;
assign pixel_around[2][13:7] = {1'd0, pixel_addr[11:6]} + 7'd127;
assign pixel_around[3][13:7] = {1'd0, pixel_addr[11:6]};
assign pixel_around[5][13:7] = {1'd0, pixel_addr[11:6]};
assign pixel_around[6][13:7] = {1'd0, pixel_addr[11:6]} + 7'd1;
assign pixel_around[7][13:7] = {1'd0, pixel_addr[11:6]} + 7'd1;
assign pixel_around[8][13:7] = {1'd0, pixel_addr[11:6]} + 7'd1;
//mid
assign pixel_around[4] = {1'd0, pixel_addr[11:6], 1'd0, pixel_addr[5:0]};

reg  temp_px;
always @(posedge clk or posedge reset) begin
	if (reset) temp_px <= 1'd0;
	else if(counter == 4'd4) temp_px <= pixel_around[8][6] | pixel_around[8][13];
	else temp_px <= temp_px;
end
//iaddr
always @(posedge clk or posedge reset) begin
	if(reset) iaddr_reg <= 12'd0;
	else 
		iaddr_reg <= {pixel_around[counter][12:7], pixel_around[counter][5:0]};
end
assign iaddr = iaddr_reg;
//pixel * kernel
assign pixel_mul[0] = pixel_around[0][6] || pixel_around[0][13] ? 0 : $signed({20'd0, idata} * kernel_0);
assign pixel_mul[1] = pixel_around[1][6] || pixel_around[1][13] ? 0 : $signed({20'd0, idata} * kernel_1);
assign pixel_mul[2] = pixel_around[2][6] || pixel_around[2][13] ? 0 : $signed({20'd0, idata} * kernel_2);
assign pixel_mul[3] = pixel_around[3][6] || pixel_around[3][13] ? 0 : $signed({20'd0, idata} * kernel_3);
assign pixel_mul[4] = $signed({20'd0, idata} * kernel_4);//try *08f71 + 20'hfffff
assign pixel_mul[5] = pixel_around[5][6] || pixel_around[5][13] ? 0 : $signed({20'd0, idata} * kernel_5);
assign pixel_mul[6] = pixel_around[6][6] || pixel_around[6][13] ? 0 : $signed({20'd0, idata} * kernel_6);
assign pixel_mul[7] = pixel_around[7][6] || pixel_around[7][13] ? 0 : $signed({20'd0, idata} * kernel_7);
assign pixel_mul[8] = temp_px ? 0 : $signed({20'd0, idata} * kernel_8);

//result
always @(posedge clk or posedge reset) begin
	if(reset) result <= 40'd0;
	else 
		case(counter)
		4'd1: result <= pixel_mul[0] + 40'h0013100000;
		4'd2: result <= result + pixel_mul[1];
		4'd3: result <= result + pixel_mul[2];
		4'd4: result <= result + pixel_mul[3];
		4'd5: result <= result + pixel_mul[4];
		4'd6: result <= result + pixel_mul[5];
		4'd7: result <= result + pixel_mul[6];
		4'd8: result <= result + pixel_mul[7];
		default: result <= result + pixel_mul[8];
		endcase
end

//result round
assign layer0 = result[39] ? 20'd0 : (result[15] ? result[35:16] + 20'd1 : result[35:16]);

//max pooling
always @(posedge clk or posedge reset)begin
	if(reset) max_pooling <= 20'd0;
	else if(block == 2'd0 && counter == 4'd8) max_pooling <= 20'd0;
	else if(counter == 4'd1) max_pooling <= max_pooling >= layer0 ? max_pooling: layer0;
	else max_pooling <= max_pooling;
end

//csel
always @(posedge clk or posedge reset) begin
	if(reset) csel_reg <= 3'b000;
	else if(counter == 4'd1) csel_reg <= 3'b001;
	else if(counter == 4'd5) csel_reg <= 3'b011;
	else csel_reg <= csel_reg;
end
assign csel = csel_reg;

//crd
assign crd = 1'd0;
assign cassr_rd = 12'd0;

//cwr
always @(posedge clk or posedge reset) begin
	if(reset || ready) cwr_reg <= 1'd0;
	else if(!cwr_reg && block[0]) cwr_reg <= 1'd1;
	else cwr_reg <= cwr_reg;
end
assign cwr = cwr_reg;

always @(posedge clk or posedge reset) begin
	if(reset) output_buffer <= 20'd0;
	else if(counter == 4'd1) output_buffer <= layer0;
	else if(counter == 4'd6) output_buffer <= max_pooling;
	else output_buffer <= output_buffer;
end
assign cdata_wr = output_buffer;

always @(posedge clk or posedge reset) begin
	if(reset) caddr_wr_reg <= 12'd0;
	else if(counter == 4'd8) caddr_wr_reg <= pixel_addr;
	else if(counter == 4'd5) caddr_wr_reg <= {2'd0, caddr_wr_reg[11:7], caddr_wr_reg[5:1]};
	else caddr_wr_reg <= caddr_wr_reg;
end
assign caddr_wr = caddr_wr_reg;
endmodule
