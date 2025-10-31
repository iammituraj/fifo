# FIFO
Single-clock Synchronous FIFOs designed in Verilog/System Verilog. The source code
includes generic FIFO implementations and FPGA-friendly implementations targetting Block/LUT RAMs.

Source codes included
---------------------
1. Generic
- fifo    - suitable for any depth
- fifo_2n - optimized for 2^N depth


2. BlockRAM_based
- fifo_bram    - suitable for any depth
- fifo_2n_lram - optimized for 2^N depth


3. LUTRAM_based
- fifo_lram    - suitable for any depth
- fifo_2n_lram - optimized for 2^N depth

License
-------
All codes are fully synthesizable and tested. All are open-source codes, free to use, modify and distribute without any conflicts of interest with the original developer.

Developer
---------
Mitu Raj, iammituraj@gmail.com