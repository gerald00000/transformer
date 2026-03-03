`timescale 1ns/10ps
`define CYCLE      20          	  // Modify your clock period here
`define SDFFILE    "transformer_syn.sdf"	  // Modify your sdf file name
`define End_CYCLE  50000000              // Modify cycle times once your design need more cycle times!

`define PAT_EXK       "../SYN_v2/test2/K.txt"                 // Modify your "dat" directory path
`define PAT_EXQ       "../SYN_v2/test2/Q.txt"                 // Modify your "dat" directory path
`define PAT_EXV       "../SYN_v2/test2/V.txt"                 // Modify your "dat" directory path
`define L0_EXP0       "../SYN_v2/test2/QK0.txt"      
`define L0_EXP1       "../SYN_v2/test2/QK1.txt"  
`define L0_EXP2       "../SYN_v2/test2/QK2.txt"     
`define L1_EXP0       "../SYN_v2/test2/QKV.txt"

`define L0_SOFT0      "../SYN_v2/test2/soft0.txt"
`define L0_SOFT1      "../SYN_v2/test2/soft1.txt"
`define L0_SOFT2      "../SYN_v2/test2/soft2.txt"



module testfixture; 


reg	[11:0]	PAT_EXK	[0:4703];
reg	[11:0]	PAT_EXQ	[0:4703];
reg	[11:0]	PAT_EXV	[0:4703];


reg	[11:0]	L0_EXP0	[0:2400];  
reg	[11:0]	L0_EXP1	[0:2400]; 
reg	[11:0]	L0_EXP2	[0:2400]; 
reg	[11:0]	L0_MEM0	[0:2400]; 
reg	[11:0]	L0_MEM1	[0:2400]; 
reg	[11:0]	L0_MEM2	[0:2400]; 

reg [11:0] L0_SOFT0 [0:2400];
reg [11:0] L0_SOFT1 [0:2400];
reg [11:0] L0_SOFT2 [0:2400];

reg	[11:0]	L1_EXP0	[0:4703];
reg	[11:0]	L1_MEM0	[0:4703];



reg		reset = 0;
reg		clk = 0;
reg		ready = 0;

wire		cwr;
wire		crd;
wire	[11:0]	cdata_wr;
reg	[11:0]	cdata_rd;
wire	[2:0]	csel;
wire	[11:0]	caddr_rd;
wire	[12:0]	caddr_wr;

wire	[12:0]	kaddr,qaddr,vaddr;
reg	[11:0]	kdata,qdata,vdata;


integer		p0, p1, p3, p4, p2;
integer		err00, err01, err02, err10;

integer		pat_num;
reg		check0=0, check1=0;

`ifdef SDF
	initial $sdf_annotate(`SDFFILE, u_transformer);
`endif

transformer u_transformer(
			.clk(clk),
			.reset(reset),
			.busy(busy),	
			.ready(ready),	
			.qaddr(qaddr),
			.kaddr(kaddr),
			.vaddr(vaddr),
			.kdata(kdata),
			.qdata(qdata),
			.vdata(vdata),
			.cwr(cwr),
			.caddr_wr(caddr_wr),
			.cdata_wr(cdata_wr),
			.crd(crd),
			.cdata_rd(cdata_rd),
			.caddr_rd(caddr_rd),
			.csel(csel)
			);
			


always begin #(`CYCLE/2) clk = ~clk; end

initial begin
	$fsdbDumpfile("TRANS.fsdb");
	$fsdbDumpvars;
	$fsdbDumpMDA;
end

initial begin  // global control
	$display("-----------------------------------------------------\n");
 	$display("START!!! Simulation Start .....\n");
 	$display("-----------------------------------------------------\n");
	@(negedge clk); #1; reset = 1'b1;  ready = 1'b1;
   	#(`CYCLE*3);  #1;   reset = 1'b0;  
   	wait(busy == 1); #(`CYCLE/4); ready = 1'b0;
end

initial begin // initial pattern and expected result
	wait(reset==1);
	wait ((ready==1) && (busy ==0) ) begin
		$readmemb(`PAT_EXK, PAT_EXK);
		$readmemb(`PAT_EXQ, PAT_EXQ);
		$readmemb(`PAT_EXV, PAT_EXV);
		$readmemb(`L0_SOFT0, L0_SOFT0);
		$readmemb(`L0_SOFT1, L0_SOFT1);
		$readmemb(`L0_SOFT2, L0_SOFT2);
		$readmemb(`L0_EXP0, L0_EXP0);
		$readmemb(`L0_EXP1, L0_EXP1);
		$readmemb(`L0_EXP2, L0_EXP2);
		$readmemb(`L1_EXP0, L1_EXP0);
	end
		
end

always@(negedge clk) begin // generate the stimulus input data
	#1;
	if ((ready == 0) & (busy == 1)) kdata <= PAT_EXK[kaddr];
	else kdata <= 'hx;
	end

always@(negedge clk) begin // generate the stimulus input data
	#1;
	if ((ready == 0) & (busy == 1)) qdata <= PAT_EXQ[qaddr];
	else qdata <= 'hx;
	end

always@(negedge clk) begin // generate the stimulus input data
	#1;
	if ((ready == 0) & (busy == 1)) vdata <= PAT_EXV[vaddr];
	else vdata <= 'hx;
	end


always@(negedge clk) begin
	if (crd == 1) begin
		case(csel)
			3'd3:cdata_rd <= L0_SOFT0[caddr_rd] ;
			3'd4:cdata_rd <= L0_SOFT1[caddr_rd] ;
			3'd5:cdata_rd <= L0_SOFT2[caddr_rd] ;
			3'd6:cdata_rd <= L1_MEM0[caddr_rd] ;
		endcase
	end
end

always@(posedge clk) begin 
	if (cwr == 1) begin
		case(csel)
			3'd0: begin check0 <= 1; L0_MEM0[caddr_wr] <= cdata_wr; end
			3'd1: begin check0 <= 1; L0_MEM1[caddr_wr] <= cdata_wr; end
			3'd2: begin check0 <= 1; L0_MEM2[caddr_wr] <= cdata_wr; end 
			3'd7: begin check1 <= 1; L1_MEM0[caddr_wr] <= cdata_wr; end 
		
		endcase
	end
end


//-------------------------------------------------------------------------------------------------------------------
initial begin  	// layer 0,  QK output
check0<= 0;
wait(busy==1); wait(busy==0);
if (check0 == 1) begin 
	err00 = 0;
	for (p0=0; p0<=2400; p0=p0+1) begin
		if (L0_MEM0[p0] == L0_EXP0[p0]) ;
		/*else if ( (L0_MEM0[p0]+20'h1) == L0_EXP0[p0]) ;
		else if ( (L0_MEM0[p0]-20'h1) == L0_EXP0[p0]) ;
		else if ( (L0_MEM0[p0]+20'h2) == L0_EXP0[p0]) ;
		else if ( (L0_MEM0[p0]-20'h2) == L0_EXP0[p0]) ;
		else if ( (L0_MEM0[p0]+20'h3) == L0_EXP0[p0]) ;
		else if ( (L0_MEM0[p0]-20'h3) == L0_EXP0[p0]) ;*/
		else begin
			err00 = err00 + 1;
			begin 
				$display("WRONG! Layer 0 (transformer Output) with channel 0 , Pixel %d is wrong!", p0);
				$display("               The output data is %h, but the expected data is %h ", L0_MEM0[p0], L0_EXP0[p0]);
			end
		end
	end
	if (err00 == 0) $display("Layer 0 (transformer Output) with channel 0 is correct!");
	else		 $display("Layer 0 (transformer Output) with channel 0 be found %d error !", err00);
	err01 = 0;
	for (p0=0; p0<=2400; p0=p0+1) begin
		if (L0_MEM1[p0] == L0_EXP1[p0]) ;
		/*else if (L0_MEM1[p0]+20'h1 == L0_EXP1[p0]) ;
		else if (L0_MEM1[p0]-20'h1 == L0_EXP1[p0]) ;
		else if (L0_MEM1[p0]+20'h2 == L0_EXP1[p0]) ;
		else if (L0_MEM1[p0]-20'h2 == L0_EXP1[p0]) ;
		else if (L0_MEM1[p0]+20'h3 == L0_EXP1[p0]) ;
		else if (L0_MEM1[p0]-20'h3 == L0_EXP1[p0]) ;*/
		else begin
			err01 = err01 + 1;
			begin 
				$display("WRONG! Layer 0 (transformer Output) with channel 1 , Pixel %d is wrong!", p0);
				$display("               The output data is %h, but the expected data is %h ", L0_MEM1[p0], L0_EXP1[p0]);
			end
		end
	end
	if (err01 == 0) $display("Layer 0 (transformer Output) with channel 1 is correct!");
	else		 $display("Layer 0 (transformer Output) with channel 1 be found %d error !", err01);


	err02 = 0;
	for (p0=0; p0<=2400; p0=p0+1) begin
		if (L0_MEM2[p0] == L0_EXP2[p0]) ;
		else begin
			err02 = err02 + 1;

			begin 
				$display("WRONG! Layer 0 (transformer Output) with channel 2 , Pixel %d is wrong!", p0);
				$display("               The output data is %h, but the expected data is %h ", L0_MEM2[p0], L0_EXP2[p0]);
			end
		end
	end
	if (err02 == 0) $display("Layer 0 (transformer Output) with channel 2 is correct!");
	else		 $display("Layer 0 (transformer Output) with channel 2 be found %d error !", err02);
end
end



//-------------------------------------------------------------------------------------------------------------------
initial begin  	// layer 1,  QKV output
check1<= 0;
wait(busy==1); wait(busy==0);
if(check1 == 1) begin
	err10 = 0;
	for (p1=0; p1<=4703; p1=p1+1) begin
		if (L1_MEM0[p1] == L1_EXP0[p1]) ;
		else begin
			err10 = err10 + 1;
			begin 
				$display("WRONG! Layer 1 (transformer Output) with channel 0 , Pixel %d is wrong!", p1);
				$display("               The output data is %h, but the expected data is %h ", L1_MEM0[p1], L1_EXP0[p1]);
			end
		end
	end
	if (err10 == 0) $display("Layer 1 (transformer Output) with channel 0 is correct!");
	else		 $display("Layer 1 (transformer Output) with channel 0 be found %d error !", err10);
end
end


//-------------------------------------------------------------------------------------------------------------------

//-------------------------------------------------------------------------------------------------------------------
initial  begin
 #`End_CYCLE ;
 	$display("-----------------------------------------------------\n");
 	$display("Error!!! The simulation can't be terminated under normal operation!\n");
 	$display("-------------------------FAIL------------------------\n");
 	$display("-----------------------------------------------------\n");
 	$finish;
end

initial begin
      wait(busy == 1);
      wait(busy == 0);      
    $display(" ");
	$display("-----------------------------------------------------\n");
	$display("--------------------- S U M M A R Y -----------------\n");
	if( (check0==1)&(err00==0)&(err01==0)&(err02==0) ) $display("Congratulations! Layer 0 data have been generated successfully! The result is PASS!!\n");
		else if (check0 == 0) $display("Layer 0 output was fail! \n");
		else $display("FAIL!!!  There are %d errors! in Layer 0 \n", err00+err01+err02);
	if( (check1==1)&(err10==0)) $display("Congratulations! Layer 1 data have been generated successfully! The result is PASS!!\n");
		else if (check1 == 0) $display("Layer 1 output was fail! \n");
		else $display("FAIL!!!  There are %d errors! in Layer 1 \n", err10);
	if ((check0|check1) == 0) $display("FAIL!!! No output data was found!! \n");
	$display("-----------------------------------------------------\n");
      #(`CYCLE/2); $finish;
end



   
endmodule


