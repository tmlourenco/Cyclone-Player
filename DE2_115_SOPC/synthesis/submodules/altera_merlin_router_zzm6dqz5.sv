// (C) 2001-2011 Altera Corporation. All rights reserved.
// Your use of Altera Corporation's design tools, logic functions and other 
// software and tools, and its AMPP partner logic functions, and any output 
// files any of the foregoing (including device programming or simulation 
// files), and any associated documentation or information are expressly subject 
// to the terms and conditions of the Altera Program License Subscription 
// Agreement, Altera MegaCore Function License Agreement, or other applicable 
// license agreement, including, without limitation, that your use is for the 
// sole purpose of programming logic devices manufactured by Altera and sold by 
// Altera or its authorized distributors.  Please refer to the applicable 
// agreement for further details.


// $Id: //acds/rel/10.1sp1/ip/merlin/altera_merlin_router/altera_merlin_router.sv.terp#1 $
// $Revision: #1 $
// $Date: 2010/11/11 $
// $Author: max $

// -------------------------------------------------------
// Merlin Router
//
// Asserts the appropriate one-hot encoded channel based on 
// either (a) the address or (b) the dest id. The DECODER_TYPE
// parameter controls this behaviour. 0 means address decoder,
// 1 means dest id decoder.
//
// In the case of (a), it also sets the destination id.
// -------------------------------------------------------

`timescale 1 ns / 1 ns

module altera_merlin_router_zzm6dqz5
(
    // -------------------
    // Clock & Reset
    // -------------------
    input clk,
    input reset,

    // -------------------
    // Command Sink (Input)
    // -------------------
    input                       sink_valid,
    input  [83-1 : 0]    sink_data,
    input                       sink_startofpacket,
    input                       sink_endofpacket,
    output                      sink_ready,

    // -------------------
    // Command Source (Output)
    // -------------------
    output                          src_valid,
    output reg [83-1    : 0] src_data,
    output reg [13-1 : 0] src_channel,
    output                          src_startofpacket,
    output                          src_endofpacket,
    input                           src_ready
);

    // -------------------------------------------------------
    // Local parameters and variables
    // -------------------------------------------------------
    localparam PKT_ADDR_H = 61;
    localparam PKT_ADDR_L = 36;
    localparam PKT_DEST_ID_H = 81;
    localparam PKT_DEST_ID_L = 78;
    localparam ST_DATA_W = 83;
    localparam ST_CHANNEL_W = 13;
    localparam DECODER_TYPE = 0;

    localparam PKT_ADDR_W = PKT_ADDR_H-PKT_ADDR_L + 1;
    localparam PKT_DEST_ID_W = PKT_DEST_ID_H-PKT_DEST_ID_L + 1;

    // -------------------------------------------------------
    // Figure out the number of bits to mask off for each slave span
    // during address decoding
    // -------------------------------------------------------
    localparam PAD0 = log2ceil(32'h3081000 - 32'h3080800);
    localparam PAD1 = log2ceil(32'h3080000 - 32'h3040000);
    localparam PAD2 = log2ceil(32'h1000200 - 32'h1000000);
    localparam PAD3 = log2ceil(32'h3000000 - 32'h2800000);
    localparam PAD4 = log2ceil(32'h3081030 - 32'h3081020);
    localparam PAD5 = log2ceil(32'h3081040 - 32'h3081030);
    localparam PAD6 = log2ceil(32'h3081068 - 32'h3081060);
    localparam PAD7 = log2ceil(32'h3081050 - 32'h3081040);
    localparam PAD8 = log2ceil(32'h3081020 - 32'h3081000);
    localparam PAD9 = log2ceil(32'h3081070 - 32'h3081068);
    localparam PAD10 = log2ceil(32'h3081078 - 32'h3081070);
    localparam PAD11 = log2ceil(32'h3081060 - 32'h3081050);
    localparam PAD12 = log2ceil(32'h308107c - 32'h3081078);

    // -------------------------------------------------------
    // Work out which address bits are significant based on the
    // address range of the slaves. If the required width is too
    // large or too small, we use the address field width instead.
    // -------------------------------------------------------
    localparam ADDR_RANGE = 32'h308107c;
    localparam RANGE_ADDR_WIDTH = log2ceil(ADDR_RANGE);
    localparam OPTIMIZED_ADDR_H = (RANGE_ADDR_WIDTH > PKT_ADDR_W) ||
                                  (RANGE_ADDR_WIDTH == 0) ?
                                        PKT_ADDR_H :
                                        PKT_ADDR_L + RANGE_ADDR_WIDTH - 1;
    localparam RG = RANGE_ADDR_WIDTH-1;

    reg [PKT_ADDR_W-1 : 0] address;

    // -------------------------------------------------------
    // Pass almost everything through, untouched
    // -------------------------------------------------------
    assign sink_ready        = src_ready;
    assign src_valid         = sink_valid;
    assign src_startofpacket = sink_startofpacket;
    assign src_endofpacket   = sink_endofpacket;


    always @* begin
        src_data    = sink_data;
        src_channel = 0;

        // --------------------------------------------------
        // Address Decoder
        // Sets the channel and destination ID based on the address
        // --------------------------------------------------
        address     = sink_data[OPTIMIZED_ADDR_H : PKT_ADDR_L];

        // ( 0x3080800 .. 0x3081000 )
        if ( {address[RG:PAD0],{PAD0{1'b0}}} == 'h3080800 ) begin
            src_channel = 'b0000000000001;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 1;
        end

        // ( 0x3040000 .. 0x3080000 )
        if ( {address[RG:PAD1],{PAD1{1'b0}}} == 'h3040000 ) begin
            src_channel = 'b0000000000010;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 2;
        end

        // ( 0x1000000 .. 0x1000200 )
        if ( {address[RG:PAD2],{PAD2{1'b0}}} == 'h1000000 ) begin
            src_channel = 'b0000000000100;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 3;
        end

        // ( 0x2800000 .. 0x3000000 )
        if ( {address[RG:PAD3],{PAD3{1'b0}}} == 'h2800000 ) begin
            src_channel = 'b0000000001000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 4;
        end

        // ( 0x3081020 .. 0x3081030 )
        if ( {address[RG:PAD4],{PAD4{1'b0}}} == 'h3081020 ) begin
            src_channel = 'b0000000010000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 5;
        end

        // ( 0x3081030 .. 0x3081040 )
        if ( {address[RG:PAD5],{PAD5{1'b0}}} == 'h3081030 ) begin
            src_channel = 'b0000000100000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 6;
        end

        // ( 0x3081060 .. 0x3081068 )
        if ( {address[RG:PAD6],{PAD6{1'b0}}} == 'h3081060 ) begin
            src_channel = 'b0000001000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 7;
        end

        // ( 0x3081040 .. 0x3081050 )
        if ( {address[RG:PAD7],{PAD7{1'b0}}} == 'h3081040 ) begin
            src_channel = 'b0000010000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 8;
        end

        // ( 0x3081000 .. 0x3081020 )
        if ( {address[RG:PAD8],{PAD8{1'b0}}} == 'h3081000 ) begin
            src_channel = 'b0000100000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 9;
        end

        // ( 0x3081068 .. 0x3081070 )
        if ( {address[RG:PAD9],{PAD9{1'b0}}} == 'h3081068 ) begin
            src_channel = 'b0001000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 10;
        end

        // ( 0x3081070 .. 0x3081078 )
        if ( {address[RG:PAD10],{PAD10{1'b0}}} == 'h3081070 ) begin
            src_channel = 'b0010000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 11;
        end

        // ( 0x3081050 .. 0x3081060 )
        if ( {address[RG:PAD11],{PAD11{1'b0}}} == 'h3081050 ) begin
            src_channel = 'b0100000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 12;
        end

        // ( 0x3081078 .. 0x308107c )
        if ( {address[RG:PAD12],{PAD12{1'b0}}} == 'h3081078 ) begin
            src_channel = 'b1000000000000;
            src_data[PKT_DEST_ID_H:PKT_DEST_ID_L] = 13;
        end

    end

    // --------------------------------------------------
    // Ceil(log2()) function
    // --------------------------------------------------
    function integer log2ceil;
        input reg[63:0] val;
        reg [63:0] i;

        begin
            i = 1;
            log2ceil = 0;

            while (i < val) begin
                log2ceil = log2ceil + 1;
                i = i << 1;
            end
        end
    endfunction

endmodule


