module LCD_CTRL(clk, reset, cmd, cmd_valid, IROM_Q, IROM_rd, IROM_A, IRAM_valid, IRAM_D, IRAM_A, busy, done);
input clk;
input reset;
input [3:0] cmd;
input cmd_valid;
input [7:0] IROM_Q;
output IROM_rd;
output     [5:0] IROM_A;
output     IRAM_valid;
output     [7:0] IRAM_D;
output reg [5:0] IRAM_A;
output reg busy;
output reg done;

//-----------parameter------------//
parameter Write = 4'd0;
parameter Sh_u = 4'd1;
parameter Sh_d = 4'd2;
parameter Sh_l = 4'd3;
parameter Sh_r = 4'd4;
parameter Max = 4'd5;
parameter Min = 4'd6;
parameter Avg = 4'd7;
parameter Ccw = 4'd8;
parameter Cw = 4'd9;
parameter M_x = 4'd10;
parameter M_y = 4'd11;
parameter rst = 4'd15;
//-----------reg----------------//
reg [3:0] cmd_reg;
reg [6:0] counter;
reg [5:0] op_point;// {y, x}
reg [7:0] img_buffer [63:0];
integer i;//for loop counter
reg [7:0] output_buffer;
//----------wire---------------//
wire [5:0] op_1;
wire [5:0] op_2;
wire [5:0] op_3;
wire [5:0] op_4;
wire [7:0] max_12;
wire [7:0] max_34;
wire [7:0] min_12;
wire [7:0] min_34;
wire [9:0] total;
//counter
always @(posedge clk or posedge reset)begin
  if(reset)
    counter <= 7'b0;
  else if(!busy) 
    counter <= 7'b0;
  else if(cmd_reg == Write || cmd_reg == rst) 
    counter <= counter[6] ? 7'b0: counter + 7'b1;
  else
    counter <= 7'b0;
end


//op_point
always @(posedge clk or posedge reset)begin
  if(reset)begin
    op_point <= 6'b100100;
  end
  else if(busy)
    case(cmd_reg)
      Sh_l: begin
        op_point[2:0] <= op_point[2:0] == 3'd1 ? op_point[2:0]: op_point[2:0] - 3'd1;
        op_point[5:3] <= op_point[5:3];
        end
      Sh_r: begin
        op_point[2:0] <= op_point[2:0] == 3'd7 ? op_point[2:0]: op_point[2:0] + 3'd1;
        op_point[5:3] <= op_point[5:3];
        end
      Sh_u: begin
        op_point[5:3] <= op_point[5:3] == 3'd1 ? op_point[5:3]: op_point[5:3] - 3'd1;
        op_point[2:0] <= op_point[2:0];
        end
      Sh_d: begin 
        op_point[5:3] <= op_point[5:3] == 3'd7 ? op_point[5:3]: op_point[5:3] + 3'd1;
        op_point[2:0] <= op_point[2:0];
        end
      default: op_point <= op_point;
    endcase
  else op_point <= op_point;
end
//io buffer
always @(posedge clk) begin
	if(cmd_reg == rst)
		output_buffer <= IROM_Q;
	else
	  output_buffer <= img_buffer[counter[5:0]];
  IRAM_A <= counter[5:0];
end

assign op_1 = op_point;
assign op_2 = {op_point[5:3], op_point[2:0] - 3'd1};
assign op_3 = {op_point[5:3] - 3'd1, op_point[2:0]};
assign op_4 = {op_point[5:3] - 3'd1, op_point[2:0] - 3'd1};
//IROM addr
assign IROM_A = counter[5:0];


assign IROM_rd = (cmd_reg == rst) && busy;

assign IRAM_valid = (cmd_reg == Write) && busy;

assign IRAM_D = output_buffer;

//cmd_reg

always @(posedge clk or posedge reset)begin
  if(reset) cmd_reg <= rst;
  else if(!busy && cmd_valid) cmd_reg <= cmd;
  else cmd_reg <= cmd_reg;
end

//done

always @(posedge clk or posedge reset)begin
  if(reset) done <= 1'b0;
  else if(cmd_reg == Write && counter[6]) done <= 1'b1;
  else done <= done;
end

//busy

always @(posedge clk or posedge reset)begin
  if(reset) busy <= 1'b1;
  else if (!busy && cmd_valid) busy <= 1'b1;
  else if (done && busy) busy <= 1'b0;
  else if (cmd_reg == rst || cmd_reg == Write) 
    if(counter[6])busy <= 1'b0;
    else busy <= busy;
  else if (busy) busy <= 1'b0;
  else busy <= busy;
end

assign min_12 = img_buffer[op_1] < img_buffer[op_2] ? img_buffer[op_1] : img_buffer[op_2];
assign min_34 = img_buffer[op_3] < img_buffer[op_4] ? img_buffer[op_3] : img_buffer[op_4];
assign max_12 = img_buffer[op_1] > img_buffer[op_2] ? img_buffer[op_1] : img_buffer[op_2];
assign max_34 = img_buffer[op_3] > img_buffer[op_4] ? img_buffer[op_3] : img_buffer[op_4];
assign total = ({2'b0, img_buffer[op_1]} + {2'b0, img_buffer[op_2]} + {2'b0, img_buffer[op_3]} + {2'b0, img_buffer[op_4]});
//img_buffer
always @(posedge clk or posedge reset)begin
  if(reset) begin
    for(i = 0; i <= 6'd63; i=i+6'd1)
      img_buffer[i] <= 8'b0;
  end
  else if(busy)
    if(cmd_reg == rst)begin
      for(i = 0; i <= 6'd63; i=i+6'd1)begin
        if(i == IRAM_A)
          img_buffer[i] <= output_buffer;
        else
          img_buffer[i] <= img_buffer[i];
        end
    end
    else begin
      case(cmd_reg)
      Max: begin
        for(i = 0; i <= 6'd63; i=i+6'd1)
          if(i == op_1 || i == op_2 || i == op_3 || i == op_4)begin
            img_buffer[i] <= max_12 > max_34 ? max_12 : max_34; 
          end
        end
      Min:begin
        for(i = 0; i <= 6'd63; i=i+6'd1)
          if(i == op_1 || i == op_2 || i == op_3 || i == op_4)begin
            img_buffer[i] <= min_12 < min_34 ? min_12 : min_34; 
          end
        end
      Avg:begin
        for(i = 0; i <= 6'd63; i=i+6'd1)
          if(i == op_1 || i == op_2 || i == op_3 || i == op_4)
            img_buffer[i] <= total[9:2];
          else  img_buffer[i] <= img_buffer[i];
        end
      Ccw:begin
        for(i = 0; i <= 6'd63; i=i+6'd1)
          if(i == op_3)
            img_buffer[i] <= img_buffer[op_1];
          else if(i == op_4)
            img_buffer[i] <= img_buffer[op_3];
          else if(i == op_2)
            img_buffer[i] <= img_buffer[op_4];
          else if(i == op_1)
            img_buffer[i] <= img_buffer[op_2];
          else
            img_buffer[i] <= img_buffer[i];
      end
      Cw:begin
        for(i = 0; i <= 6'd63; i=i+6'd1)
          if(i == op_3)
            img_buffer[i] <= img_buffer[op_4];
          else if(i == op_4)
            img_buffer[i] <= img_buffer[op_2];
          else if(i == op_2)
            img_buffer[i] <= img_buffer[op_1];
          else if(i == op_1)
            img_buffer[i] <= img_buffer[op_3];
          else
            img_buffer[i] <= img_buffer[i];
      end
      M_x:
      begin
        for(i = 0; i <= 6'd63; i=i+6'd1)
          if(i == op_3)
            img_buffer[i] <= img_buffer[op_1];
          else if(i == op_1)
            img_buffer[i] <= img_buffer[op_3];
          else if(i == op_4)
            img_buffer[i] <= img_buffer[op_2];
          else if(i == op_2)
            img_buffer[i] <= img_buffer[op_4];
          else
            img_buffer[i] <= img_buffer[i];
      end
      M_y:
      begin
        for(i = 0; i <= 6'd63; i=i+6'd1)
          if(i == op_4)
            img_buffer[i] <= img_buffer[op_3];
          else if(i == op_3)
            img_buffer[i] <= img_buffer[op_4];
          else if(i == op_2)
            img_buffer[i] <= img_buffer[op_1];
          else if(i == op_1)
            img_buffer[i] <= img_buffer[op_2];
          else
            img_buffer[i] <= img_buffer[i];
      end
      default:begin
        for(i = 0; i <= 6'd63; i=i+6'd1)
          img_buffer[i] <= img_buffer[i];
      end
      endcase
    end
  else begin//not busy
    for(i = 0; i <= 6'd63; i=i+6'd1)
      img_buffer[i] <= img_buffer[i];
  end
end




endmodule

