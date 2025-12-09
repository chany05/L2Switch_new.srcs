`timescale 1ps / 1ps
////////////////////////////////////////
module text_lcd(
    input clk, rst,
    input [7:0] payload_in,
    input [7:0] addr_in,
    output lcd_enb,
    output reg lcd_rs, lcd_rw,
    output reg [8-1:0] lcd_data
);

// 3-bit 상태 레지스터
reg [3-1:0] state;

// 상태 파라미터 정의
parameter delay           = 3'b000,
          function_set    = 3'b001,
          entry_mode      = 3'b010,
          display_onoff   = 3'b011,
          line1           = 3'b100,
          line2           = 3'b101,
          delay_t         = 3'b110,
          clear_display   = 3'b111;
    // 주소 값에 따른 ASCII 문자 코드
    // 주소 및 페이로드 값에 따른 ASCII 코드 정의
localparam ASCII_A = 8'h41, ASCII_B = 8'h42, ASCII_C = 8'h43, ASCII_D = 8'h44;
localparam ASCII_0 = 8'h30, ASCII_1 = 8'h31, ASCII_2 = 8'h32, ASCII_3 = 8'h33,
            ASCII_4 = 8'h34, ASCII_5 = 8'h35, ASCII_6 = 8'h36, ASCII_7 = 8'h37,
            ASCII_8 = 8'h38, ASCII_9 = 8'h39;
wire [3:0] dest_addr = addr_in[7:4];
wire [3:0] src_addr  = addr_in[3:0]; // Top 모듈에서 payload가 연결됨
wire [3:0] payload   = payload_in[3:0];
// 카운터 정의
integer counter;

// 카운터 로직 (각 상태별 지연 시간 카운트)
always @ (posedge clk or posedge rst)
begin
    if (rst)
        counter = 0;
    else
        case (state)
            delay:
                begin
                    if (counter == 70)
                        counter = 0;
                    else
                        counter = counter + 1;
                end
            function_set:
                begin
                    if (counter == 30)
                        counter = 0;
                    else
                        counter = counter + 1;
                end
            display_onoff:
                begin
                    if (counter == 30)
                        counter = 0;
                    else
                        counter = counter + 1;
                end
            entry_mode:
                begin
                    if (counter == 30)
                        counter = 0;
                    else
                        counter = counter + 1;
                end
            line1:
                begin
                    if (counter == 20)
                        counter = 0;
                    else
                        counter = counter + 1;
                end
            line2:
                begin
                    if (counter == 20)
                        counter = 0;
                    else
                        counter = counter + 1;
                end
            delay_t:
                begin
                    if (counter == 400)
                        counter = 0;
                    else
                        counter = counter + 1;
                end
            clear_display:
                begin
                    if (counter == 200)
                        counter = 0;
                    else
                        counter = counter + 1;
                end
        endcase
end

// 상태 천이 로직 (State Transition Logic)
always @ (posedge clk or posedge rst) begin
    if (rst)
        state = delay;
    else
        case (state)
            delay:          if (counter == 70) state = function_set;
            function_set:   if (counter == 30) state = display_onoff;
            display_onoff:  if (counter == 30) state = entry_mode;
            entry_mode:     if (counter == 30) state = line1;
            line1:          if (counter == 20) state = line2;
            line2:          if (counter == 20) state = delay_t;
            delay_t:        if (counter == 400) state = clear_display;
            clear_display:  if (counter == 200) state = line1;
        endcase
end

// LCD 제어 신호 및 데이터 출력 로직
always @ (posedge clk or posedge rst) begin
    if (rst) begin
        lcd_rs = 1'b1;
        lcd_rw = 1'b1;
        lcd_data = 8'b0000_0000;
    end
    else begin
        case (state)
            function_set: begin
                lcd_rs = 1'b0; // 명령어 레지스터 선택 (IR)
                lcd_rw = 1'b0; // 쓰기 동작 (Write)
                // DL=1 (8-bit), N=1 (2-line), F=0 (5x8 dots) -> 0011 1100
                lcd_data = 8'b0011_1100;
            end
            display_onoff: begin
                lcd_rs = 1'b0; // IR
                lcd_rw = 1'b0; // Write
                // D=1 (Display ON), C=0 (Cursor OFF), B=0 (Blink OFF) -> 0000 1100
                lcd_data = 8'b0000_1100;
            end
            entry_mode: begin
                lcd_rs = 1'b0; // IR
                lcd_rw = 1'b0; // Write
                // I/D=1 (Increment), S=0 (Shift OFF) -> 0000 0110
                lcd_data = 8'b0000_0110;
            end
            line1: begin 
                lcd_rw = 1'b0; // 데이터 전송 (RS=1)
                case (counter) // 12개의 문자/공백을 출력
                    0: begin lcd_rs <= 1'b0; lcd_data <= 8'b1000_0000; end // 1번째 라인 시작 주소 (0x00)
                    1: begin lcd_rs <= 1'b1; lcd_data <= 8'h73;end // s
                    2: begin lcd_rs <= 1'b1; lcd_data <= 8'h72;end // r                        
                    3: begin lcd_rs <= 1'b1; lcd_data <= 8'h63;end // c
                    4: begin lcd_rs <= 1'b1; lcd_data <= 8'h3A;end // :
                    5: case(src_addr) // src 주소 표시
                                4'hA: begin lcd_rs <= 1'b1; lcd_data <= ASCII_A;end
                                4'hB: begin lcd_rs <= 1'b1; lcd_data <= ASCII_B;end
                                4'hC: begin lcd_rs <= 1'b1; lcd_data <= ASCII_C;end
                                4'hD: begin lcd_rs <= 1'b1; lcd_data <= ASCII_D;end
                                default: begin lcd_rs <= 1'b1; lcd_data <= 8'h3F;end // '?'
                           endcase
                    6: begin lcd_rs <= 1'b1; lcd_data <= 8'h20;end // [공백]
                    7: begin lcd_rs <= 1'b1; lcd_data <= 8'h64;end // d
                    8: begin lcd_rs <= 1'b1; lcd_data <= 8'h73;end // s
                    9: begin lcd_rs <= 1'b1; lcd_data <= 8'h74;end // t                        
                    10: begin lcd_rs <= 1'b1; lcd_data <= 8'h3A;end // :
                    11: case(dest_addr) // dst 주소 표시
                                 4'hA: begin lcd_rs <= 1'b1; lcd_data <= ASCII_A;end
                                 4'hB: begin lcd_rs <= 1'b1; lcd_data <= ASCII_B;end
                                 4'hC: begin lcd_rs <= 1'b1; lcd_data <= ASCII_C;end
                                 4'hD: begin lcd_rs <= 1'b1; lcd_data <= ASCII_D;end
                                 default: begin lcd_rs <= 1'b1; lcd_data <= 8'h3F;end // '?'
                        endcase
                    default: begin lcd_rs = 1'b1; lcd_data = 8'b0010_0000; end
                endcase
            end
                
            // ===================================================
            // Line 2: 'PAYLOAD:' 출력
            // ===================================================
            line2: begin 
                lcd_rw = 1'b0; // 데이터 전송 (RS=1)
                case (counter)
                    0: begin lcd_rs <= 1'b0; lcd_data <= 8'hc0; end // 2번째 라인 시작 주소 (0x40)
                    1: begin lcd_rs <= 1'b1; lcd_data <= 8'h50; end // P
                    2: begin lcd_rs <= 1'b1; lcd_data <= 8'h41; end // A
                    3: begin lcd_rs <= 1'b1; lcd_data <= 8'h59; end // Y
                    4: begin lcd_rs <= 1'b1; lcd_data <= 8'h4C; end // L                        
                    5: begin lcd_rs <= 1'b1; lcd_data <= 8'h4F; end // O
                    6: begin lcd_rs <= 1'b1; lcd_data <= 8'h41; end // A
                    7: begin lcd_rs <= 1'b1; lcd_data <= 8'h44; end // D
                    8: begin lcd_rs <= 1'b1; lcd_data <= 8'h3A; end // :
                    9: case(payload) // 페이로드 값 표시
                                4'h0: begin lcd_rs = 1'b1; lcd_data <= ASCII_0;end 4'h1: begin lcd_rs = 1'b1; lcd_data <= ASCII_1;end
                                4'h2: begin lcd_rs = 1'b1; lcd_data <= ASCII_2;end 4'h3: begin lcd_rs = 1'b1; lcd_data <= ASCII_3;end
                                4'h4: begin lcd_rs = 1'b1; lcd_data <= ASCII_4;end 4'h5: begin lcd_rs = 1'b1; lcd_data <= ASCII_5;end
                                4'h6: begin lcd_rs = 1'b1; lcd_data <= ASCII_6;end 4'h7: begin lcd_rs = 1'b1; lcd_data <= ASCII_7;end
                                4'h8: begin lcd_rs = 1'b1; lcd_data <= ASCII_8;end 4'h9: begin lcd_rs = 1'b1; lcd_data <= ASCII_9;end
                                default: begin lcd_rs = 1'b1; lcd_data <= 8'h3F;end // '?'
                        endcase
                    // 페이로드는 한 자리이므로 나머지 공간은 공백 처리
                    10: begin lcd_rs = 1'b1; lcd_data <= 8'h20; end // [공백]
                    11: begin lcd_rs = 1'b1; lcd_data <= 8'h20; end // [공백]
                    default: begin lcd_rs = 1'b1; lcd_data = 8'b0010_0000; end 
                endcase
             end
            delay_t: begin
                lcd_rs = 1'b0; // IR
                lcd_rw = 1'b0; // Write
                // Return Home (Cursor/Display Home) -> 0000 0010
                lcd_data = 8'b0000_0010;
            end
            clear_display: begin
                lcd_rs = 1'b0; // IR
                lcd_rw = 1'b0; // Write
                // Clear Display -> 0000 0001
                lcd_data = 8'b0000_0001;
            end
            default: begin
                lcd_rs = 1'b1; // 기본값으로 둔 안전 상태
                lcd_rw = 1'b1;
                lcd_data = 8'b0000_0000;
            end
        endcase
    end
end

assign lcd_enb = clk;

endmodule