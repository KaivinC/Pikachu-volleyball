`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai 
// 
// Create Date: 2018/12/11 16:04:41
// Design Name: 
// Module Name: lab9
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: A circuit that show the animation of a fish swimming in a seabed
//              scene on a screen through the VGA interface of the Arty I/O card.
// 
// Dependencies: vga_sync, clk_divider, sram 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module pika_2P(
    input  clk,
    input  reset_n,
    input  [3:0] usr_btn,
    output [3:0] usr_led,
    
    // VGA specific I/O ports
    output VGA_HSYNC,
    output VGA_VSYNC,
    output [3:0] VGA_RED,
    output [3:0] VGA_GREEN,
    output [3:0] VGA_BLUE
    );

// declare SRAM control signals
wire [16:0] sram_addr;
wire [11:0] data_in;
wire [11:0] data_out;
wire [11:0] data_out_ball;
wire        sram_we, sram_en;

// General VGA control signals
wire vga_clk;         // 50MHz clock for VGA control
wire video_on;        // when video_on is 0, the VGA controller is sending
                      // synchronization signals to the display device.
  
wire pixel_tick;      // when pixel tick is 1, we must update the RGB value
                      // based for the new coordinate (pixel_x, pixel_y)
  
wire [9:0] pixel_x;   // x coordinate of the next pixel (between 0 ~ 639) 
wire [9:0] pixel_y;   // y coordinate of the next pixel (between 0 ~ 479)
  
reg  [11:0] rgb_reg;  // RGB value for the current pixel
reg  [11:0] rgb_next; // RGB value for the next pixel
  
// Application-specific VGA signals
reg  [17:0] pixel_addr;

// Declare the video buffer size
localparam VBUF_W = 320; // video buffer width
localparam VBUF_H = 240; // video buffer height

//---------------------------------------from hereeeeeeeeeeeee-------------------------------
wire        ball_region;
wire [16:0] sram_addr_ball;
reg  [17:0] pixel_addr_ball;

reg [2:0] kill;
reg     right,up;// if the ball is going right(up) or not
reg     touched, touched_net;
wire    ball_change;
reg  [32:0] ball_clock;
wire [32:0] ball_reg_clock;
localparam BALL_W = 20; // ball width
localparam BALL_H = 20; // ball height

reg [9:0] BALL_HPOS  ; // Horizontal location of the ball in the court image.
reg [8:0] BALL_VPOS   ; // Vertical location of the ball in the court image.
//reg a_x;
reg [4:0]a_y;
//reg [17:0] ball_addr[0:3];   // Address array for up to 8 ball images.
reg start;
reg b;//for sram_we


//2P data


localparam PIKA2_W = 50; // ball width
localparam PIKA2_H = 45; // ball height
localparam pika2y = 170;
reg [17:0] pika2_image_addr[0: 7];
wire [16:0] sram_addr_pika2;
reg  [17:0] pixel_addr_pika2;
wire [11:0] data_in_pika2;
wire [11:0] data_out_pika2;
//wire        sram_we_pika2, sram_en_pika2;
reg  [31:0] pika2x_clock,pika2_clock;
wire [9:0] pika2x;
reg  [17:0] pika2_addr;
wire        pika2_region,pika2_ball_region;
reg [7:0] pika2_stop_pos;
initial begin
  pika2_image_addr[ 0] = 18'd0;         /* Addr for fish image #1 */
 pika2_image_addr[ 1] = PIKA2_W*PIKA2_H* 1; /* Addr for fish image #2 */
 pika2_image_addr[ 2] = PIKA2_W*PIKA2_H* 2; /* Addr for fish image #2 */
 pika2_image_addr[ 3] = PIKA2_W*PIKA2_H* 3; /* Addr for fish image #2 */

 pika2x_clock[31:20] = 70;
end
//---------------------------------------done hereeeeeeeeeeeee-------------------------------

// Initializes the fish images starting addresses.
// Note: System Verilog has an easier way to initialize an array,
//       but we are using Verilog 2001 :(

// Instiantiate the VGA sync signal generator
vga_sync vs0(
  .clk(vga_clk), .reset(~reset_n), .oHS(VGA_HSYNC), .oVS(VGA_VSYNC),
  .visible(video_on), .p_tick(pixel_tick),
  .pixel_x(pixel_x), .pixel_y(pixel_y)
);

clk_divider#(2) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(vga_clk)
);

// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores a 320x240 12-bit seabed image, plus two 64x32 fish images.

sram #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(VBUF_W*VBUF_H))
  ram0 (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));

sram_ball #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(BALL_W*BALL_H))
  sramball (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_ball), .data_i(data_in), .data_o(data_out_ball));
        
 sram_pika2 #(.DATA_WIDTH(12), .ADDR_WIDTH(18), .RAM_SIZE(PIKA2_W*PIKA2_H*4))
  pika2sram (.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr_pika2), .data_i(data_in), .data_o(data_out_pika2));

//assign sram_we_pika2 = &usr_btn;                            
//assign sram_en_pika2 = 1;        
assign sram_addr_pika2 = pixel_addr_pika2;
assign data_in_pika2 = 12'h000; // SRAM is read-only so we tie inputs to zeros.


assign sram_we = &usr_btn; // In this demo, we do not write the SRAM. However, if
                             // you set 'sram_we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = 1;          // Here, we always enable the SRAM block.
assign sram_addr = pixel_addr;
assign sram_addr_ball = pixel_addr_ball;

assign data_in = 12'h000; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// VGA color pixel generator
assign {VGA_RED, VGA_GREEN, VGA_BLUE} = rgb_reg;

// ------------------------------------------------------------------------
assign ball_reg_clock=ball_clock-1;
//assign ball_change=(ball_reg_clock[28]!=ball_clock[28]);

always @(posedge clk) begin//單純拿來當clk
  if (~reset_n ||ball_clock[31]==1)
    ball_clock <= 0;
  else
    ball_clock <= ball_clock + 1;
end



always @(posedge clk) begin
  if(!reset_n) begin
    BALL_HPOS   <= 200;
    BALL_VPOS   <= 50;

    up<=0;
    right<=0;
    a_y <=23;
    touched <= 0;
    kill<=1;
    start<=0;
  end
  else begin 
    
    /*if(usr_btn[3]&&touched_p1&&p1不在地上)
        kill<=2;             //調速度
        if(kill==2&&touched_p2)
        kill <=1;    
        
        if(usr_btn[3]&&touched_p2&&p2不在地上)
        kill<=2;             //調速度
        if(kill==2&&touched_p1)
        kill <=1;   
    */
    //xpos處理 剩彈牆,彈網
    //if(touched_p2) start=1;
    if(BALL_VPOS==200) begin//碰到地板 要改成碰到結束遊戲
        touched<=1;                                             
        up<=1;               //加皮卡丘後要刪掉
    end
    else
        touched<=0;
    if(BALL_VPOS==120&&BALL_HPOS>320&&BALL_HPOS<360) begin//碰到網子上面
        touched_net<=1;                                                         
        up<=1;               //加皮卡丘後要刪掉
    end
    else
        touched_net<=0;
     /*碰到player設定
     if(ball_region&&player1_region&&data_out_ball!=12'h0f0&&data_out_player1!=12'h0f0) begin
                right<=0;
                touched_p1<=1;
            end
            else
            touched_p1<=0;
            if(ball_region&&player2_region&data_out_ball!=12'h0f0&&data_out_player2!=12'h0f0)begin 
                right<=1;
                touched_p2<=1;
            end
            else
            touched_p1<=0;
        */
    //if(start) begin
        if(ball_reg_clock[20]!=ball_clock[20]) begin
            //if(touched_p1) right<=0;
            //else if(touched_p2) right<=1;
            //else
            if(right) begin  //一開始直線往下,然後碰到皮卡丘再往右or左開始
                BALL_HPOS <= BALL_HPOS+kill;
                if(BALL_HPOS==640) right<=0;//牆壁
                if(BALL_HPOS==320&&BALL_VPOS>120) right<=0;//網子
            end
            else begin
                BALL_HPOS <= BALL_HPOS-kill;
                if(BALL_HPOS==40) right<=1;//牆壁
                if(BALL_HPOS==360&&BALL_VPOS>120) right<=1;//網子
            end
        end
    //end
    //y_pos處理
    if(ball_reg_clock[a_y]!=ball_clock[a_y]) begin
        if(up) begin
            BALL_VPOS <= BALL_VPOS-1;//a_y from0~128
        end
        else begin
            BALL_VPOS <= BALL_VPOS+1;//a_y from128~0
        end
    end
    if(touched)a_y <=19;
    if(touched_net)a_y <=20;
    else if(BALL_VPOS==50) a_y <=22;
    else if(ball_reg_clock[25]!=ball_clock[25]) begin
        //touched_p2,touched_p1;
            if(up) begin
                a_y <=a_y+1;
                if(a_y==24) up<=0;
            end
            else begin
                if(a_y>19)a_y <=a_y-1;
            end
    end
  end
end

///2P CODE-----------------------------------------------------------------------------------------------------

           
assign pika2x = pika2x_clock[31:20];
always @(posedge clk)begin
if(~reset_n)begin
pika2_stop_pos<=0;
pika2x_clock[31:20] <= 200;
end
else begin
if(BALL_HPOS<320)begin
    if (pika2x < 320&&BALL_HPOS>pika2x)
    	pika2x_clock <= pika2x_clock + 1;
    else if(pika2x >  90&&BALL_HPOS<pika2x)
    	pika2x_clock <= pika2x_clock - 1;
  	else begin
  		pika2x_clock <= pika2x_clock;
  	end
end
end
end

always @(posedge clk)begin

end

always @ (posedge clk) begin
  if (~reset_n)
    pika2_addr <= 0;
  else if (pika2_region)
    pika2_addr <= pika2_addr[pika2_clock[26:23]] +
                  ((pixel_y>>1)-pika2y)*PIKA2_W +
                  ((pixel_x +(PIKA2_W*2-1)-pika2x)>>1);
  else
    pika2_addr <= 0;
end
///2P CODE------------------------------------------------------------------------------------------------------
assign ball_region =
           pixel_y >= (BALL_VPOS<<1) && pixel_y < (BALL_VPOS+BALL_H)<<1 &&
           (pixel_x + 2*BALL_W-1) >= BALL_HPOS && pixel_x < BALL_HPOS + 1;
           
assign pika2_region =
           pixel_y >= (pika2y<<1) && pixel_y < (pika2y+PIKA2_H)<<1 &&
           (pixel_x + 2*PIKA2_W-1) >= pika2x && pixel_x < pika2x + 1;
                      
always @ (posedge clk) begin
  if (~reset_n) begin
    pixel_addr <= 0;
    pixel_addr_ball<=0;
  end
  else begin
    if(ball_region)//ball_addr[ball_clock[26:24]] +//還不用動圖
        pixel_addr_ball <=  ((pixel_y>>1)-BALL_VPOS)*BALL_W +
                      ((pixel_x +(BALL_W*2-1)-BALL_HPOS)>>1);
    if(pika2_region)
     pixel_addr_pika2 <=  ((pixel_y>>1)-pika2x)*PIKA2_W +
                      ((pixel_x +(PIKA2_W*2-1)-pika2y)>>1);                      
    // Scale up a 320x240 image for the 640x480 display.
    // (pixel_x, pixel_y) ranges from (0,0) to (639, 479)
    pixel_addr <= (pixel_y >> 1) * VBUF_W + (pixel_x >> 1);
  end
end
// End of the AGU code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// Send the video data in the sram to the VGA controller
always @(posedge clk) begin
  if (pixel_tick) rgb_reg <= rgb_next;
end

always @(*) begin
  if (~video_on)
    rgb_next = 12'h000; // Synchronization period, must set RGB values to zero.
  else if(ball_region&&data_out_ball!=12'h0f0)
    rgb_next = data_out_ball;
  else if(pika2_region&&data_out_pika2!=12'h0f0)
    rgb_next = data_out_pika2;
  else
    rgb_next = data_out; // RGB value at (pixel_x, pixel_y)
end
// End of the video data display code.
// ------------------------------------------------------------------------

endmodule
