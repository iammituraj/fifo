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
//----%% File Name        : fifo.sv
//----%% Module Name      : FIFO                                            
//----%% Developer        : Mitu Raj, chip@chipmunklogic.com
//----%% Vendor           : Chipmunk Logic ™ , https://chipmunklogic.com
//----%%
//----%% Description      : Single-clock Synchronous FIFO of generic size.
//----%%                    - Configurable Data width, Depth, Almost-full/empty flags
//----%%
//----%% Tested on        : -
//----%% Last modified on : Nov-2025
//----%% Notes            : -
//----%%                  
//----%% Copyright        : Open-source license, see README.md
//----%%                                                                                             
//----%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

//###################################################################################################################################################
//                                                              F I F O                                           
//###################################################################################################################################################
//`define ALMFLAGS   // Define this macro to generate Almost-full/empty flags

// Module definition
module fifo #(
   // Configurable Parameters
   parameter DATA_W  = 4      ,  // Data width
   parameter DEPTH   = 8      ,  // Depth of FIFO   
   `ifdef ALMFLAGS                
   parameter UPP_TH  = 4      ,  // Upper threshold to generate Almost-full
   parameter LOW_TH  = 2      ,  // Lower threshold to generate Almost-empty
   `endif

   // Derived Parameters
   parameter PTR_SZ  = $clog2(DEPTH)   // Write/Read pointer size
)(
   input               clk         ,  // Clock
   input               rstn        ,  // Active-low Synchronous Reset
                   
   input               i_wren      ,  // Write Enable
   input  [DATA_W-1:0] i_wrdata    ,  // Write-data
   `ifdef ALMFLAGS
   output              o_alm_full  ,  // Almost-full signal
   `endif
   output              o_full      ,  // Full signal

   input               i_rden      ,  // Read Enable
   output [DATA_W-1:0] o_rddata    ,  // Read-data
   `ifdef ALMFLAGS
   output              o_alm_empty ,  // Almost-empty signal
   `endif
   output              o_empty        // Empty signal
);

//---------------------------------------------------------------------------------------------------------------------
// Internal Signals/Registers
//---------------------------------------------------------------------------------------------------------------------
logic [DATA_W-1:0] dt_arr_rg [DEPTH] ;  // Data array
logic [PTR_SZ-1:0] wrptr_rg          ;  // Write pointer
logic [PTR_SZ-1:0] rdptr_rg          ;  // Read pointer
logic [PTR_SZ-1:0] nxt_wrptr         ;  // Next Write pointer
logic [PTR_SZ-1:0] nxt_rdptr         ;  // Next Read pointer
logic [PTR_SZ-0:0] dcount_rg         ;  // Data counter
      
logic              wren  ;  // Write Enable signal conditioned with Full signal
logic              rden  ;  // Read Enable signal conditioned with Empty signal
logic              full  ;  // Full signal
logic              empty ;  // Empty signal

//---------------------------------------------------------------------------------------------------------------------
// Synchronous logic to write/read from FIFO
//---------------------------------------------------------------------------------------------------------------------
always_ff @(posedge clk) begin
   if (!rstn) begin      
      dt_arr_rg <= '{default: '0} ;
      wrptr_rg  <= 0 ;
      rdptr_rg  <= 0 ;      
      dcount_rg <= 0 ;
   end
   else begin            
      /* FIFO write logic */            
      if (wren) begin             
         dt_arr_rg[wrptr_rg] <= i_wrdata ;  // Data written to FIFO
         wrptr_rg            <= nxt_wrptr;
      end

      /* FIFO read logic */
      if (rden) begin       
         rdptr_rg <= nxt_rdptr;
      end

      /* FIFO data counter update logic */
      if (wren && !rden) begin          // Write operation
         dcount_rg <= dcount_rg + 1 ;
      end                    
      else if (!wren && rden) begin     // Read operation
         dcount_rg <= dcount_rg - 1 ;         
      end
   end
end

// Full and Empty internal
assign full  = (dcount_rg == DEPTH);
assign empty = (dcount_rg == 0);

// Write and Read Enables conditioned
assign wren  = i_wren & !full  ;  // Do not push if FULL
assign rden  = i_rden & !empty ;  // Do not pop if EMPTY

// Next Write & Read pointers
assign nxt_wrptr = (wrptr_rg == DEPTH-1)? 0 : wrptr_rg + 1 ;
assign nxt_rdptr = (rdptr_rg == DEPTH-1)? 0 : rdptr_rg + 1 ;

// Full and Empty to output
assign o_full  = full  ;
assign o_empty = empty ;

`ifdef ALMFLAGS
// Almost-full and Almost-empty to output
assign o_alm_full  = (dcount_rg > UPP_TH) ? 1'b1 : 0 ;
assign o_alm_empty = (dcount_rg < LOW_TH) ? 1'b1 : 0 ;  
`endif

// Read-data to output
assign o_rddata = dt_arr_rg[rdptr_rg];   

endmodule
//###################################################################################################################################################
//                                                              F I F O                                           
//###################################################################################################################################################