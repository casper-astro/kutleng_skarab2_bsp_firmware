--------------------------------------------------------------------------------
-- Legal & Copyright:   (c) 2018 Kutleng Engineering Technologies (Pty) Ltd    - 
--                                                                             -
-- This program is the proprietary software of Kutleng Engineering Technologies-
-- and/or its licensors, and may only be used, duplicated, modified or         -
-- distributed pursuant to the terms and conditions of a separate, written     -
-- license agreement executed between you and Kutleng (an "Authorized License")-
-- Except as set forth in an Authorized License, Kutleng grants no license     -
-- (express or implied), right to use, or waiver of any kind with respect to   -
-- the Software, and Kutleng expressly reserves all rights in and to the       -
-- Software and all intellectual property rights therein.  IF YOU HAVE NO      -
-- AUTHORIZED LICENSE, THEN YOU HAVE NO RIGHT TO USE THIS SOFTWARE IN ANY WAY, -
-- AND SHOULD IMMEDIATELY NOTIFY KUTLENG AND DISCONTINUE ALL USE OF THE        -
-- SOFTWARE.                                                                   -
--                                                                             -
-- Except as expressly set forth in the Authorized License,                    -
--                                                                             -
-- 1.     This program, including its structure, sequence and organization,    -
-- constitutes the valuable trade secrets of Kutleng, and you shall use all    -
-- reasonable efforts to protect the confidentiality thereof,and to use this   -
-- information only in connection with South African Radio Astronomy           -
-- Observatory (SARAO) products.                                               -
--                                                                             -
-- 2.     TO THE MAXIMUM EXTENT PERMITTED BY LAW, THE SOFTWARE IS PROVIDED     -
-- "AS IS" AND WITH ALL FAULTS AND KUTLENG MAKES NO PROMISES, REPRESENTATIONS  -
-- OR WARRANTIES, EITHER EXPRESS, IMPLIED, STATUTORY, OR OTHERWISE, WITH       -
-- RESPECT TO THE SOFTWARE.  KUTLENG SPECIFICALLY DISCLAIMS ANY AND ALL IMPLIED-
-- WARRANTIES OF TITLE, MERCHANTABILITY, NONINFRINGEMENT, FITNESS FOR A        -
-- PARTICULAR PURPOSE, LACK OF VIRUSES, ACCURACY OR COMPLETENESS, QUIET        -
-- ENJOYMENT, QUIET POSSESSION OR CORRESPONDENCE TO DESCRIPTION. YOU ASSUME THE-
-- ENJOYMENT, QUIET POSSESSION USE OR PERFORMANCE OF THE SOFTWARE.             -
--                                                                             -
-- 3.     TO THE MAXIMUM EXTENT PERMITTED BY LAW, IN NO EVENT SHALL KUTLENG OR -
-- ITS LICENSORS BE LIABLE FOR (i) CONSEQUENTIAL, INCIDENTAL, SPECIAL, INDIRECT-
-- , OR EXEMPLARY DAMAGES WHATSOEVER ARISING OUT OF OR IN ANY WAY RELATING TO  -
-- YOUR USE OF OR INABILITY TO USE THE SOFTWARE EVEN IF KUTLENG HAS BEEN       -
-- ADVISED OF THE POSSIBILITY OF SUCH DAMAGES; OR (ii) ANY AMOUNT IN EXCESS OF -
-- THE AMOUNT ACTUALLY PAID FOR THE SOFTWARE ITSELF OR ZAR R1, WHICHEVER IS    -
-- GREATER. THESE LIMITATIONS SHALL APPLY NOTWITHSTANDING ANY FAILURE OF       -
-- ESSENTIAL PURPOSE OF ANY LIMITED REMEDY.                                    -
-- --------------------------------------------------------------------------- -
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS                    -
-- PART OF THIS FILE AT ALL TIMES.                                             -
--=============================================================================-
-- Company          : Kutleng Dynamic Electronics Systems (Pty) Ltd            -
-- Engineer         : Benjamin Hector Hlophe                                   -
--                                                                             -
-- Design Name      : CASPER BSP                                               -
-- Module Name      : macifudpsender - rtl                                     -
-- Project Name     : SKARAB2                                                  -
-- Target Devices   : N/A                                                      -
-- Tool Versions    : N/A                                                      -
-- Description      : The macifudpsender module sends UDP/IP data streams, it  -
--                    saves the streams on a packetringbuffer.                 -
--                    TODO                                                     -
--                    Improve handling and framing of UDP data,without needing -
--                    to mirror the UDP data settings. Must calculate CRC,etc  -
--                                                                             -
-- Dependencies     : N/A                                                      -
-- Revision History : V1.0 - Initial design                                    -
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity macaxissender is
    generic(
        G_SLOT_WIDTH : natural := 4;
        --G_UDP_SERVER_PORT : natural range 0 to ((2**16) - 1) := 5;
        -- The address width is log2(2048/(512/8))=5 bits wide
        G_ADDR_WIDTH : natural := 5
    );
    port(
        axis_clk                 : in  STD_LOGIC;
        axis_reset               : in  STD_LOGIC;
        DataRateBackOff          : in  STD_LOGIC;        
        
        -- Packet Write in addressed bus format
        MuxRequestSlot           : out STD_LOGIC;
        MuxAckSlot               : in  STD_LOGIC;
        MuxSlotID                : in  STD_LOGIC_VECTOR(G_SLOT_WIDTH - 1 downto 0);
        -- Packet Readout in addressed bus format
        RingBufferSlotID         : out STD_LOGIC_VECTOR(G_SLOT_WIDTH - 1 downto 0);
        RingBufferSlotClear      : out STD_LOGIC;
        RingBufferSlotStatus     : in  STD_LOGIC;
        RingBufferSlotTypeStatus : in  STD_LOGIC;
        RingBufferDataRead       : out STD_LOGIC;
        -- Enable[0] is a special bit (we assume always 1 when packet is valid)
        -- we use it to save TLAST
        RingBufferDataEnable     : in  STD_LOGIC_VECTOR(63 downto 0);
        RingBufferDataIn         : in  STD_LOGIC_VECTOR(511 downto 0);
        RingBufferAddress        : out STD_LOGIC_VECTOR(G_ADDR_WIDTH - 1 downto 0);
        --Inputs from AXIS bus of the MAC side
        --Outputs to AXIS bus MAC side 
        axis_tx_tdata            : out STD_LOGIC_VECTOR(511 downto 0);
        axis_tx_tvalid           : out STD_LOGIC;
        axis_tx_tready           : in  STD_LOGIC;
        axis_tx_tuser            : out STD_LOGIC;
        axis_tx_tkeep            : out STD_LOGIC_VECTOR(63 downto 0);
        axis_tx_tlast            : out STD_LOGIC
    );
end entity macaxissender;

architecture rtl of macaxissender is

    type AxisSenderSM_t is (
        InitialiseSt,                   -- On the reset state
        RequestSlotSt,
        CheckSlotSt,
        NextSlotSt,
        ProcessPacketSt
    );
    signal StateVariable               : AxisSenderSM_t                      := InitialiseSt;
    -- Maximum address for read ring buffer
    -- In this case terminate the transaction with  tuser error
    constant C_RING_BUFFER_MAX_ADDRESS : unsigned(G_ADDR_WIDTH - 1 downto 0) := (others => '1');
    -- Tuples registers
    signal lRingBufferSlotID           : unsigned(G_SLOT_WIDTH - 1 downto 0);
    signal lRingBufferAddress          : unsigned(G_ADDR_WIDTH - 1 downto 0);
    signal lDataRead                   : std_logic;
begin
    RingBufferSlotID  <= std_logic_vector(lRingBufferSlotID);
    RingBufferAddress <= std_logic_vector(lRingBufferAddress);

    axis_tx_tdata              <= RingBufferDataIn;
    axis_tx_tkeep(63 downto 1) <= RingBufferDataEnable(63 downto 1);
    axis_tx_tkeep(0)           <= (not RingBufferDataEnable(0)) when (RingBufferDataEnable(0) = '0') else '1';
    axis_tx_tlast              <= '1' when ((lRingBufferAddress = C_RING_BUFFER_MAX_ADDRESS) or (RingBufferDataEnable(0) = '1')) else '0';
    axis_tx_tuser              <= '1' when (lRingBufferAddress = C_RING_BUFFER_MAX_ADDRESS) else '0';
    RingBufferDataRead         <= axis_tx_tready and lDataRead;

    SynchStateProc : process(axis_clk)
    begin
        if rising_edge(axis_clk) then
            if (axis_reset = '1') then
                -- Initialize SM on reset
                StateVariable <= InitialiseSt;
            else
                case (StateVariable) is
                    when InitialiseSt =>
                        -- Wait for packet after initialization
                        StateVariable       <= RequestSlotSt;
                        MuxRequestSlot      <= '0';
                        lRingBufferAddress  <= (others => '0');
                        lDataRead           <= '0';
                        RingBufferSlotClear <= '0';
                        lRingBufferSlotID   <= (others => '0');
                        
                    when RequestSlotSt =>
                        if (MuxAckSlot = '1') then
                            lRingBufferSlotID <= unsigned(MuxSlotID);
                            -- Check the slot if it has data
                            StateVariable       <= CheckSlotSt;
                            MuxRequestSlot <= '0';                            
                        else
                            MuxRequestSlot <= '1';                            
                        end if;

                    when CheckSlotSt =>
                        
                        lRingBufferAddress <= (others => '0');
                        axis_tx_tvalid     <= '0';
                        if (RingBufferSlotStatus = '1') then
                            -- The current slot has data and the fifo has emptyness 
                            --  for a complete packet slot
                            -- Pull the data 
                            if (DataRateBackOff = '0') then 
                                lDataRead     <= '1';
                                StateVariable <= ProcessPacketSt;
                            else
                                lDataRead     <= '0';
                                StateVariable <= CheckSlotSt;
                            end if;
                        else
                            lDataRead     <= '0';
                            StateVariable <= NextSlotSt;
                        end if;

                    when NextSlotSt =>
                        lRingBufferAddress  <= (others => '0');
                        axis_tx_tvalid      <= '0';
                        RingBufferSlotClear <= '0';
                        lDataRead           <= '0';
                        StateVariable       <= RequestSlotSt;

                    when ProcessPacketSt =>
                        -- Keep reading the slot till ready

                        if (axis_tx_tready = '1') then
                            lRingBufferAddress <= lRingBufferAddress + 1;
                            if ((RingBufferDataEnable(0) = '1') or (lRingBufferAddress = C_RING_BUFFER_MAX_ADDRESS)) then
                                -- This is the last one, or there was an error
							    RingBufferSlotClear <= RingBufferSlotTypeStatus;
                                axis_tx_tvalid <= '0';
                                -- Go to next slot
                                StateVariable  <= NextSlotSt;
                            else
                                -- read next address
                                axis_tx_tvalid <= '1';
                                -- Keep reading the slot till ready
                                StateVariable  <= ProcessPacketSt;
                            end if;
                        end if;
                    when others =>
                        StateVariable <= InitialiseSt;
                end case;
            end if;
        end if;
    end process SynchStateProc;

end architecture rtl;
