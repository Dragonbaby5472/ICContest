module DT(
	input 			clk, 
	input			reset,
	output	reg		done ,
	output	reg		sti_rd ,
	output	reg 	[9:0]	sti_addr ,
	input		    [15:0]	sti_di,
	output	reg		res_wr ,
	output	reg		res_rd ,
	output	reg 	[13:0]	res_addr ,
	output	reg 	[7:0]	res_do,
	input		    [7:0]	res_di
);

//-----------------reg-----------------//
reg [2:0] stage;//every pixel need 5 stage to count DT
reg state;//FP and BP
reg [13:0] position;//(y,x)
reg [7:0] result;
reg [7:0] temp_pixel;
//-----------------wire----------------//

//-------------------------------------//

//position
always @(posedge clk or negedge reset) begin
	if(!reset)
		position <= 14'b0;
	else if(!state && position == 14'd16255)
		position <= 14'd16383;
	else if(position[13:7] == 7'b0|| position[13:7] == 7'd127)//boundary
		position <= state ? position + 14'd16383 : position + 14'b1;
	else if(stage == 3'd4)
		if(!state) position <= position + 14'b1;
		else
			position <= position + 14'd16383;
	else position <= position;
end

//stage
always @(posedge clk or negedge reset) begin
	if(!reset)
		stage <= 3'b0;
	else if(position[13:7] == 7'b0 || position[13:7] == 7'd127)//boundary
		stage <= 3'b0;
	else if(stage == 3'd4)
		stage <= 3'b0;
	else stage <= stage + 3'b1;
end

//state
always @(posedge clk or negedge reset) begin
	if(!reset)
		state <= 1'b0;
	else if(!state && position == 14'd16255)//boundary
		state <= 1'b1;
	else state <= state;
end

//result
always @(posedge clk or negedge reset) begin
	if(!reset)
		result <= 8'b0;
	else if(position[6:0] == 7'd0 || position[13:7] == 7'b0 || position[6:0] == 7'd127 || position[13:7] == 7'd127)
		result <= 8'b0;
	else if(!state)
		case (stage)
			3'd0: result <= result;
			3'd1: result <= result < temp_pixel ? result : temp_pixel;
			3'd4: result <= sti_di[4'd15-position[3:0]] ? result + 8'd1 : 8'd0; 
			default: result <= result < res_di ? result : res_di;
		endcase
	else 
		case (stage)
			3'd0: result <= result == 8'd255 ? result : result + 8'd1;
			3'd4: result <= result < res_di ? result : res_di; 
			3'd1: result <= result < (temp_pixel == 8'd255 ? temp_pixel : temp_pixel + 8'd1) ? result : (temp_pixel == 8'd255 ? temp_pixel : temp_pixel + 8'd1);
			default: result <= result < (res_di == 8'd255 ? res_di : res_di + 8'd1) ? result : (res_di == 8'd255 ? res_di : res_di + 8'd1);
		endcase
end

//sti_rd
always @(posedge clk) begin
	sti_rd <= 1'b1;
end

//sti_addr
always @(position) begin
	sti_addr = position[13:4];
end

//res_wr
always @(posedge clk or negedge reset) begin
	if(!reset)
		res_wr <= 1'b0;
	else if(stage == 3'd0)
		res_wr <= 1'b1;
	else res_wr <= 1'b0;
end

//res_rd
always @(posedge clk) begin
	res_rd <= 1'b1;
end

//res_addr
always @(posedge clk or negedge reset) begin
	if(!reset)
		res_addr <= 1'b0;
	else if(!state)
		case (stage)
			3'd0: res_addr <= position - 14'd1;//previous
			3'd1: res_addr <= position - 14'd128;
			//3'd3:  res_addr <= position;
			default: res_addr <= {res_addr[13:7], res_addr[6:0] + 7'd1};
		endcase
	else
		case (stage)
			3'd0:  res_addr <= position + 14'd1;//previous
			3'd1:  res_addr <= position + 14'd128;
			3'd3:  res_addr <= position;
			default: res_addr <= {res_addr[13:7], res_addr[6:0] + 7'd127};
		endcase	
end

//res_do
always @(posedge clk or negedge reset) begin
	if(!reset)
		res_do <= 8'd0;
	else	res_do <= result;
end
//temp_pixel
always @(posedge clk or negedge reset) begin
	if(!reset)
		temp_pixel <= 17'd0;
	else if(stage == 3'd2)
		temp_pixel <= res_di;
	else temp_pixel <= temp_pixel;
end
//done
always @(posedge clk or negedge reset) begin
	if(!reset)
		done <= 1'd0;
	else if(state && position == 14'd128)
		done <= 1'd1;
	else done <= done;
end
endmodule
