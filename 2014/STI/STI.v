module STI (
    clk ,rst, load, pi_data, pi_length, pi_fill, pi_msb, pi_low, pi_end, so_data, so_valid, sti_off
);
input		clk, rst;
input		load, pi_msb, pi_low, pi_end; 
input	[15:0]	pi_data;
input	[1:0]	pi_length;
input		pi_fill;
output	so_data;
output	reg so_valid;
output  sti_off;
reg [4:0] counter;
reg [4:0] data_addr;
reg valid;
reg [31:0] mem;
//counter
always @(posedge clk or posedge rst) begin
    if(rst) counter <= 5'd0;
    else if(!so_valid) counter <= 5'd0;
    else counter <= counter + 1'd1; 
end
always @(*) begin
    case (pi_length)
        2'b00: data_addr = pi_msb ? {2'd0, 3'd7 - counter[2:0]} : counter;
        2'b01: data_addr = pi_msb ? {1'd0, 4'd15 - counter[3:0]} : counter;
        2'b10: data_addr = pi_msb ? 5'd23 - counter : counter;
        2'b11: data_addr = pi_msb ? 5'd31 - counter : counter;
        default: data_addr = pi_msb ? {2'd0, 3'd7 - counter[2:0]} : counter;
    endcase
end

//mem
always @(posedge clk or posedge rst) begin
    if(rst) mem <= 32'd0;
    else if(load) 
        case (pi_length)
            2'b00: mem <= pi_low ? {24'd0, pi_data[15:8]} : {24'd0, pi_data[7:0]};
            2'b01: mem <= {16'd0, pi_data};
            2'b10: mem <= pi_fill ? {8'd0, pi_data, 8'd0} : {16'd0, pi_data};
            2'b11: mem <= pi_fill ? {pi_data, 16'd0} : {16'd0, pi_data};
            default: mem <= {16'd0, pi_data};
    endcase
    //else if(sti_off) mem <= 32'd0;
    else mem <= mem;
end
//so_data
assign so_data = mem[data_addr];
//so_valid
always @(posedge clk or posedge rst) begin
    if(rst) valid <= 1'd0;
    else if(load) valid <= 1'd1;
    else
    case (pi_length)
        2'b00: valid <= counter == 5'd6 ? 1'd0 : valid;
        2'b01: valid <= counter == 5'd14 ? 1'd0 : valid;
        2'b10: valid <= counter == 5'd22 ? 1'd0 : valid;
        2'b11: valid <= counter == 5'd30 ? 1'd0 : valid;
        default: valid <= counter == 5'd6 ? 1'd0 : valid;
    endcase
end
always @(posedge clk or posedge rst) begin
    if(rst) so_valid <= 1'd0;
    //else if(load) so_valid <= 1'd1;
    else so_valid <= valid;
end

//sti_off
assign sti_off = ~load & ~so_valid & pi_end;
endmodule
