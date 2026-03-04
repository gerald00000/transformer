`timescale 1ns/10ps
module transformer (
    input   clk,
    input   reset,
    input   ready,
    input [11:0]     kdata,
    input [11:0]     qdata,
    input [11:0]     vdata,
    input [11:0]     cdata_rd,
    output reg      busy,
    output reg[12:0]    kaddr,
    output reg[12:0]    qaddr,
    output reg[12:0]    vaddr,
    output reg      crd,
    output reg[11:0]    caddr_rd,
    output reg      cwr,
    output reg[11:0]     cdata_wr,
    output reg[12:0]    caddr_wr,
    output reg[2:0]     csel
    );

reg [2:0] cur_state, nx_state;
reg [5:0] cnt_1;
reg [4:0] xq, xk;
reg [7:0] yq, yk;
reg [11:0] reader;
reg[2:0]flag;
reg [5:0] cnt_2;
reg [4:0] xv;
reg [7:0] yv;
wire signed [11:0]carry1;
reg [4:0]finalx;
reg [7:0]finaly;
reg swi;

parameter STATE_IDLE = 3'd0;
parameter STATE_WAIT = 3'd1;
parameter STATE_WRITE = 3'd2;
parameter STATE_L0 = 3'd3;
parameter STATE_L1 = 3'd4;
parameter STATE_FINISH = 3'd5;
parameter STATE_WAIT1 = 3'd6;
parameter STATE_WRITE1 = 3'd7;

    always @( posedge clk or posedge reset ) begin
		if( reset ) busy <= 0;
		else if( cur_state == STATE_FINISH ) busy <= 0;
		else if( cur_state == STATE_IDLE ) busy <= 1;
	end

    always@(posedge clk or posedge reset)begin
        if(reset)cur_state <= STATE_IDLE;
        else cur_state <= nx_state;
    end

    always@(posedge clk or posedge reset)begin
        if(reset)swi <= 0;
        else if(cur_state == STATE_WAIT || cur_state ==STATE_WAIT1)begin
             swi <= swi + 1;
        end
        else swi <= 0;
    end
//Qposition
    always@(posedge clk or posedge reset)begin
        if(reset)begin
            xq <= 0;
            yq <= 0;
        end
        else if(nx_state == STATE_L0)begin
            if( yq >= 'd144 && xq == 'd31)begin
                if(yk >= 'd144)begin
                    xq <= 0;
                    yq <= yq - 'd143;
                end
                else begin
                    xq <= 0;
                    yq <= yq;
                end
            end
            else if( xq == 'd31)begin
                if(xk == 'd31 && yk >= 'd144)begin
                    xq <= 0;
                    yq <= yq + 'd3;
                end
                else begin
                    xq <= 0;
                    yq <= yq;
                end
            end
            else begin
                xq <= xq + 'd1;
                yq <= yq;
            end
        end
    end
//Kposition
    always@(posedge clk or posedge reset)begin
        if(reset)begin
            xk <= 0;
            yk <= 0;
        end
        else if(nx_state == STATE_L0)begin
            if( yk >= 'd144 && xk == 'd31)begin
                if(xq == 'd31 && yq >= 'd144)begin
                    xk <= 0;
                    yk <= yk - 'd143;
                end
                else begin
                    xk <= 0;
                    yk <= yk -'d144;
                end
            end
            else if( xk == 'd31)begin
                xk <= 0;
                yk <= yk + 'd3;
            end
            else begin
                xk <= xk + 'd1;
                yk <= yk;
            end
        end
    end
//L0 function
    always @(posedge clk or posedge reset) begin
        if(reset)cnt_1 <= 0;
        else if(nx_state == STATE_L0)cnt_1 <= cnt_1 + 'd1;
        else cnt_1 <= 0;
    end


    always @(posedge clk or posedge reset) begin
        if(reset)kaddr <= 0 ;
        else if(nx_state == STATE_L0 )begin
            kaddr <= {yk,xk};
        end
    end

    always @(posedge clk or posedge reset) begin
        if(reset)qaddr <= 0 ;
        else if(nx_state == STATE_L0 )begin
            qaddr <= {yq,xq};
        end
    end

reg signed [11:0]rq,rk;

    always@(posedge clk or posedge reset)begin
		if(reset)rq<= 0;
		else if(cnt_1 >= 'd1) rq<=qdata;
        else rq <= 0;
	end

    always@(posedge clk or posedge reset)begin
		if(reset)rk<= 0;
		else if(cnt_1 >= 'd1) rk<=kdata;
        else rk <= 0;
	end
wire signed [23:0]timesqk;
    assign timesqk = rq*rk;

reg signed [23:0] qkdata_buffer;

    always@(posedge clk or posedge reset)begin
        if(reset)qkdata_buffer <=0;
        else if(cur_state == STATE_L0||cur_state == STATE_WAIT)begin
            if(cnt_1 == 'd2)qkdata_buffer <= timesqk;
            else qkdata_buffer <= qkdata_buffer + timesqk;
        end
        else qkdata_buffer <= 0;
    end

wire signed [11:0]carry;
    assign carry = ( qkdata_buffer[7] )? qkdata_buffer[19:8] + 1: qkdata_buffer[19:8];
//L0 function
//L0 write
    
    always@(posedge clk or posedge reset)begin
        if(reset)cwr <=0;
        else if(nx_state == STATE_WRITE )cwr <= 1;
        else if(nx_state == STATE_WRITE1)cwr <= 1;
        else cwr <= 0;
    end
    always@(posedge clk or posedge reset)begin
        if(reset)crd <=0;
        else if(nx_state == STATE_L1)crd <= 1;
        else crd <= 0;
    end
reg [11:0] position_in;

    always@(posedge clk or posedge reset)begin
        if(reset)position_in <= 0;
        else if(nx_state == STATE_WRITE)begin
            if(position_in == 'd2400)position_in <= 0;
            else position_in <= position_in + 'd1;
        end
    end
    always@(posedge clk or posedge reset)begin
        if(reset)caddr_wr <= 0;
        else if(nx_state == STATE_WRITE) caddr_wr <= position_in;
        else if(nx_state == STATE_WRITE1) caddr_wr <= {finaly,finalx};
    end

    always@(posedge clk or posedge reset)begin
        if(reset)cdata_wr <= 0;
        else if(nx_state == STATE_WRITE)begin
            cdata_wr <= carry;
        end
        else if(nx_state == STATE_WRITE1)begin
            cdata_wr <= carry1;
        end
        else cdata_wr <= 0;
    end

    always@(posedge clk or posedge reset)begin
        if(reset)flag <= 'd3;
        else if(yv == 'd1 && xv == 'd0) flag <= 'd4;
        else if(yv == 'd2 && xq == 'd0) flag <= 'd5;
        else if(caddr_wr == 'd4703 && csel == 'd3 && cwr == 'd1) flag <= 'd6;
    end

    always@(posedge clk or posedge reset)begin
        if(reset)csel <=0;       
        else if(yq == 'd1 && xq == 'd1) csel <= 'd1;
        else if(yq == 'd2 && xq == 'd1) csel <= 'd2;
        else if(caddr_wr == 'd2400 && csel == 'd2 && cwr == 'd1) csel <= 'd3;
        else if(nx_state == STATE_WRITE1) csel <= 'd7;
        else if(nx_state == STATE_L1) csel <= flag;
    end
//L1///////////////////////////////////////////////////////////////////////////////////////////////////////////
//xv////////////////////////////////////////////////////////////////////////////////////////////


    always@(posedge clk or posedge reset)begin
        if(reset)reader <= 0;
        else if(nx_state == STATE_L1)begin
            if(reader == 'd2400) reader <= 0;
            else reader <= reader + 'd1;
        end
    end


    always @(posedge clk or posedge reset) begin
        if(reset)cnt_2 <= 0;
        else if(nx_state == STATE_L1)cnt_2 <= cnt_2 + 'd1;
        else cnt_2 <= 0;
    end


    always@(posedge clk or posedge reset)begin
        if(reset)begin
            xv <= 0;
            yv <= 0;
        end
        else if(nx_state == STATE_L1)begin
            if(reader == 'd2400)begin
                if(yv >= 'd144 && xv == 'd31)begin
                    xv <= 0;
                    yv <= yv - 'd143;
                end
                else begin
                    xv <= xv + 'd1;
                    yv <= yv - 'd144;
                end
            end
            else begin
                if(yv >= 'd144)begin
                    xv <= xv;
                    yv <= yv - 'd144;
                end
                else begin
                    xv <= xv;
                    yv <= yv + 'd3;
                end
            end
        end
    end

    always@(posedge clk or posedge reset)begin
        if(reset)caddr_rd <= 0;
        else if(nx_state == STATE_L1) caddr_rd <= reader;
    end

reg signed [11:0] qk,rv;

    always@(posedge clk or posedge reset)begin
		if(reset)qk<= 0;
		else if(cnt_2 >= 'd1) qk<=cdata_rd;
        else qk <= 0;
	end

    always@(posedge clk or posedge reset)begin
		if(reset)rv<= 0;
		else if(cnt_2 >= 'd1) rv<=vdata;
        else rv <= 0;
	end

    always @(posedge clk or posedge reset) begin
        if(reset)vaddr <= 0 ;
        else if(nx_state == STATE_L1 )begin
            vaddr <= {yv,xv};
        end
    end            

wire signed [23:0]finaltimes;
    assign finaltimes = rv*qk;

reg signed [23:0] finaldata_buffer;

    always@(posedge clk or posedge reset)begin
        if(reset)finaldata_buffer <=0;
        else if(nx_state == STATE_L1||nx_state == STATE_WAIT1)begin
            if(cnt_2 == 'd2)finaldata_buffer <= finaltimes;
            else finaldata_buffer <= finaldata_buffer + finaltimes;
        end
        else finaldata_buffer <= 0;
    end

    assign carry1 = ( finaldata_buffer[7] )? finaldata_buffer[19:8] + 1: finaldata_buffer[19:8];

//L1///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//finalpos////////////////////////////////////////////////////////////////////////////////////////////////////

    always@(posedge clk or posedge reset)begin
        if(reset)begin
            finalx <= 0;
            finaly <= 0;
        end
        else if (cur_state == STATE_WRITE1)begin
            if(finaly >= 'd144 && finalx == 'd31)begin
                finalx <= 0;
                finaly <= finaly - 'd143;
            end
            else if(finaly >= 'd144)begin
                finalx <= finalx + 'd1;
                finaly <= finaly - 'd144;
            end
            else begin
                finalx <= finalx ;
                finaly <= finaly + 'd3;
            end
        end
    end


    always@(*)begin
        case(cur_state)
            STATE_IDLE: nx_state = (ready)?STATE_IDLE:STATE_L0;
            STATE_L0: nx_state = (cnt_1 == 'd32)?STATE_WAIT:STATE_L0;
            STATE_WAIT: nx_state =(swi == 'd1)?STATE_WRITE:STATE_WAIT;
            STATE_WRITE:nx_state = (caddr_wr == 'd2400 && csel == 'd2 && cwr == 'd1 )?STATE_L1:STATE_L0;
            STATE_L1:nx_state = (cnt_2 == 'd49)?STATE_WAIT1:STATE_L1;
            STATE_WAIT1: nx_state =(swi == 'd1)?STATE_WRITE1:STATE_WAIT1;
            STATE_WRITE1: nx_state = (finalx == 'd31 && finaly == 'd146)?STATE_FINISH:STATE_L1;
            STATE_FINISH: nx_state = STATE_FINISH;
            default: nx_state = STATE_IDLE;
        endcase
    end
            


endmodule

