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
//----%% File Name        : fifo_2n.sv
//----%% Module Name      : FIFO-2N                                          
//----%% Developer        : Mitu Raj, chip@chipmunklogic.com
//----%% Vendor           : Chipmunk Logic ™ , https://chipmunklogic.com
//----%%
//----%% Description      : Single-clock Synchronous FIFO of depth of order 2^N.
//----%%                    - Configurable Data width, Depth
//----%%
//----%% Tested on        : -
//----%% Last modified on : Nov-2025
//----%% Notes            : -
//----%%                  
//----%% Copyright        : Open-source license, see README.md
//----%%                                                                                             
//----%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

//###################################################################################################################################################
//                                                              F I F O - 2 N                                          
//###################################################################################################################################################
// Module definition
module fifo_2n #(
   // Configurable Parameters
   parameter DATA_W  = 4      ,  // Data width
   parameter DEPTH   = 8      ,  // Depth of FIFO; must be 2^N   

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
logic [DATA_W-1:0] dt_arr_rg [DEPTH] ;  // Data array
logic [PTR_SZ-1:0] wrptr             ;  // Write pointer
logic [PTR_SZ-1:0] rdptr             ;  // Read pointer
logic [PTR_SZ-0:0] wrptr_rg          ;  // Write pointer with wrapover bit
logic [PTR_SZ-0:0] rdptr_rg          ;  // Read pointer with wrapover bit
logic [PTR_SZ-0:0] nxt_wrptr         ;  // Next Write pointer
logic [PTR_SZ-0:0] nxt_rdptr         ;  // Next Read pointer

logic              wren     ;  // Write Enable signal conditioned with Full signal
logic              rden     ;  // Read Enable signal conditioned with Empty signal
logic              wr_wflag ;  // Write wrapover bit
logic              rd_wflag ;  // Read wrapover bit
logic              is_wrap  ;  // Wrapover flag
logic              full     ;  // Full signal
logic              empty    ;  // Empty signal

//---------------------------------------------------------------------------------------------------------------------
// Synchronous logic to write/read from FIFO
//---------------------------------------------------------------------------------------------------------------------
always_ff @(posedge clk) begin
   if (!rstn) begin      
      dt_arr_rg <= '{default: '0} ;
      wrptr_rg  <= 0 ;
      rdptr_rg  <= 0 ;      
   end
   else begin            
      /* FIFO write logic */            
      if (wren) begin             
         dt_arr_rg[wrptr] <= i_wrdata ;  // Data written to FIFO
         wrptr_rg         <= nxt_wrptr;           
      end
      /* FIFO read logic */
      if (rden) begin       
         rdptr_rg <= nxt_rdptr;          
      end
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
assign full  = (wrptr == rdptr) &&  is_wrap ;
assign empty = (wrptr == rdptr) && !is_wrap ;

// Write and Read Enables conditioned
assign wren  = i_wren & !full  ;  // Do not push if FULL
assign rden  = i_rden & !empty ;  // Do not pop if EMPTY

// Next Write & Read pointers
assign nxt_wrptr = wrptr_rg + 1 ;
assign nxt_rdptr = rdptr_rg + 1 ;

// Full and Empty to output
assign o_full  = full  ;
assign o_empty = empty ;

// Read-data to output
assign o_rddata = dt_arr_rg[rdptr];   

endmodule
//###################################################################################################################################################
//                                                              F I F O - 2 N                                          
//###################################################################################################################################################