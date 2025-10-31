//     %%%%%%%%%%%%      %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//  %%%%%%%%%%%%%%%%%%                      
// %%%%%%%%%%%%%%%%%%%% %%                
//    %% %%%%%%%%%%%%%%%%%%                
//        % %%%%%%%%%%%%%%%                 
//           %%%%%%%%%%%%%%                 ////    O P E N - S O U R C E     ////////////////////////////////////////////////////////////
//           %%%%%%%%%%%%%      %%          _________________________________////
//           %%%%%%%%%%%       %%%%                ________    _                             __      __                _     
//          %%%%%%%%%%        %%%%%%              / ____/ /_  (_)___  ____ ___  __  ______  / /__   / /   ____  ____ _(_)____ TM 
//         %%%%%%%    %%%%%%%%%%%%*%%%           / /   / __ \/ / __ \/ __ `__ \/ / / / __ \/ //_/  / /   / __ \/ __ `/ / ___/
//        %%%%% %%%%%%%%%%%%%%%%%%%%%%%         / /___/ / / / / /_/ / / / / / / /_/ / / / / ,<    / /___/ /_/ / /_/ / / /__  
//       %%%%*%%%%%%%%%%%%%  %%%%%%%%%          \____/_/ /_/_/ .___/_/ /_/ /_/\__,_/_/ /_/_/|_|  /_____/\____/\__, /_/\___/
//       %%%%%%%%%%%%%%%%%%%    %%%%%%%%%                   /_/                                              /____/  
//       %%%%%%%%%%%%%%%%                                                             ___________________________________________________               
//       %%%%%%%%%%%%%%                    //////////////////////////////////////////////       c h i p m u n k l o g i c . c o m    //// 
//         %%%%%%%%%                       
//           %%%%%%%%%%%%%%%%               
//    
//----%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
//----%% 
//----%% File Name        : fifo_2n_bram.sv
//----%% Module Name      : FIFO-2N based on Block RAM                                           
//----%% Developer        : Mitu Raj, chip@chipmunklogic.com
//----%% Vendor           : Chipmunk Logic ™ , https://chipmunklogic.com
//----%%
//----%% Description      : Single-clock Synchronous FIFO of depth of order 2^N.
//----%%                    - Configurable Data width, Depth.
//----%%                    - Implements data array on Block RAMs on FPGAs.
//----%%
//----%% Tested on        : -
//----%% Last modified on : Nov-2025
//----%% Notes            : -
//----%%                  
//----%% Copyright        : Open-source license, see README.md
//----%%                                                                                             
//----%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

//###################################################################################################################################################
//                                                              F I F O - 2 N - B R A M                                        
//###################################################################################################################################################
// Module definition
module fifo_2n_bram #(
   // Configurable Parameters
   parameter DATA_W  = 4      ,  // Data width
   parameter DEPTH   = 8      ,  // Depth of FIFO   

   // Derived Parameters
   parameter PTR_SZ  = $clog2(DEPTH)   // Write/Read pointer size
)(
   input               clk         ,  // Clock
   input               rstn        ,  // Active-low Synchronous Reset
                   
   input               i_wren      ,  // Write Enable
   input  [DATA_W-1:0] i_wrdata    ,  // Write-data
   output              o_full      ,  // Full signal

   input               i_rden      ,  // Read Enable
   output [DATA_W-1:0] o_rddata    ,  // Read-data
   output              o_empty        // Empty signal
);

//---------------------------------------------------------------------------------------------------------------------
// Internal Signals/Registers
//---------------------------------------------------------------------------------------------------------------------
logic [PTR_SZ-1:0] wrptr      ;  // Write pointer
logic [PTR_SZ-1:0] rdptr      ;  // Read pointer
logic [PTR_SZ-0:0] wrptr_rg   ;  // Write pointer
logic [PTR_SZ-0:0] rdptr_rg   ;  // Read pointer
logic [PTR_SZ-0:0] nxt_wrptr  ;  // Next Write pointer
logic [PTR_SZ-0:0] nxt_rdptr  ;  // Next Read pointer
logic [PTR_SZ-1:0] rdaddr     ;  // Read-address to RAM
      
logic              wren           ;  // Write Enable signal conditioned with Full signal
logic              rden           ;  // Read Enable signal conditioned with Empty signal
logic              wr_wflag       ;  // Write wrapover bit
logic              rd_wflag       ;  // Read wrapover bit
logic              is_wrap        ;  // Wrapover flag
logic              full           ;  // Full signal
logic              empty          ;  // Empty signal
logic              empty_extnd_rg ;  // Empty extended

//---------------------------------------------------------------------------------------------------------------------
// RAM instance
//---------------------------------------------------------------------------------------------------------------------
bram #(
   .DATA_W  (DATA_W),
   .DEPTH   (DEPTH)
) inst_bram (
   .clk      (clk),

   .i_wren   (wren)     ,
   .i_waddr  (wrptr)    ,
   .i_wdata  (i_wrdata) ,

   .i_raddr  (rdaddr)   ,
   .o_rdata  (o_rddata)
);

//---------------------------------------------------------------------------------------------------------------------
// Synchronous logic to write/read from FIFO
//---------------------------------------------------------------------------------------------------------------------
always_ff @(posedge clk) begin
   if (!rstn) begin      
      wrptr_rg       <= 0 ;
      rdptr_rg       <= 0 ;      
      empty_extnd_rg <= 1'b0;
   end
   else begin            
      /* FIFO write logic */            
      if (wren) begin             
         wrptr_rg <= nxt_wrptr;
      end

      /* FIFO read logic */
      if (rden) begin       
         rdptr_rg <= nxt_rdptr;
      end

      // Empty extend pulse
      // If write and read is requested at same addr, read should be invalidated by asserting empty...
      if (wren && (wrptr == rdaddr)) empty_extnd_rg <= 1'b1;
      else                           empty_extnd_rg <= 1'b0;
   end
end

// Wrapover flags
assign wr_wflag = wrptr_rg[PTR_SZ];
assign rd_wflag = rdptr_rg[PTR_SZ];
assign is_wrap  = (wr_wflag != rd_wflag);

// Pointers used to address FIFO
assign wrptr = wrptr_rg[PTR_SZ-1:0];
assign rdptr = rdptr_rg[PTR_SZ-1:0];

// Full and Empty internal
assign full  = ((wrptr == rdptr) &&  is_wrap) ;
assign empty = ((wrptr == rdptr) && !is_wrap) | empty_extnd_rg ; ;

// Write and Read Enables conditioned
assign wren  = i_wren & !full  ;  // Do not push if FULL
assign rden  = i_rden & !empty ;  // Do not pop if EMPTY

// Next Write pointer
assign nxt_wrptr   = wrptr_rg + 1 ;

// Read-address to RAM
assign nxt_rdptr   = rdptr_rg + 1 ;
assign rdaddr      = rden ? nxt_rdptr[PTR_SZ-1:0] : rdptr ;

// Full and Empty to output
assign o_full  = full  ;
assign o_empty = empty ;

endmodule
//###################################################################################################################################################
//                                                              F I F O - 2 N - B R A M                                        
//###################################################################################################################################################