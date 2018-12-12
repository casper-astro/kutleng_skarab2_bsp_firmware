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
-- Module Name      : icapwritersm - rtl                                       -
-- Project Name     : SKARAB2                                                  -
-- Target Devices   : N/A                                                      -
-- Tool Versions    : N/A                                                      -
-- Description      : The configcontroller module receives commands and frames -
--                    for partial reconfiguration and writes to the ICAPE3.    -
--                    The module doesn't check for errors or anything,it just  -
--                    writes the DWORD or the FRAME.It responds with a DWORD   -
--                    status that contains all the necessary errors or status  -
--                    of the partial reconfiguration operation.                -
--                                                                             -
-- Dependencies     : N/A                                                      -
-- Revision History : V1.0 - Initial design                                    -
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity icapwritersm is
    generic(
        G_SLOT_WIDTH : natural := 4;
        --G_UDP_SERVER_PORT : natural range 0 to ((2**16) - 1) := 5;
        -- The address width is log2(2048/(512/8))=5 bits wide
        G_ADDR_WIDTH : natural := 5
    );
    port(
        icap_clk                 : in  STD_LOGIC;
        icap_reset               : in  STD_LOGIC;
        -- Packet Write in addressed bus format
        -- Packet Readout in addressed bus format
        RingBufferSlotID         : out STD_LOGIC_VECTOR(G_SLOT_WIDTH - 1 downto 0);
        RingBufferSlotClear      : out STD_LOGIC;
        RingBufferSlotStatus     : in  STD_LOGIC;
        RingBufferSlotTypeStatus : in  STD_LOGIC;
        RingBufferDataRead       : out STD_LOGIC;
        -- Enable[0] is a special bit (we assume always 1 when packet is valid)
        -- we use it to save TLAST
        RingBufferDataEnable     : in  STD_LOGIC_VECTOR(3 downto 0);
        RingBufferDataIn         : in  STD_LOGIC_VECTOR(31 downto 0);
        RingBufferAddress        : out STD_LOGIC_VECTOR(G_ADDR_WIDTH - 1 downto 0);
        -- Handshaking signals
        -- Status signal to show when the packet sender is busy
        SenderBusy               : in  STD_LOGIC;
        -- ICAP Writer Response
        ICAPWriteDone            : out STD_LOGIC;
        ICAPWriteResponseSent    : in  STD_LOGIC;
        ICAPIPIdentification     : out STD_LOGIC_VECTOR(15 downto 0);
        ICAPProtocolID           : out STD_LOGIC_VECTOR(15 downto 0);
        ICAPProtocolSequence     : out STD_LOGIC_VECTOR(31 downto 0);
        --Inputs from AXIS bus of the MAC side
        --ICAPE3 interface
        ICAP_CSIB                : out STD_LOGIC;
        ICAP_RDWRB               : out STD_LOGIC;
        ICAP_PRDONE              : in  STD_LOGIC;
        ICAP_PRERROR             : in  STD_LOGIC;
        ICAP_AVAIL               : in  STD_LOGIC;
        ICAP_DataIn              : out STD_LOGIC_VECTOR(31 downto 0);
        ICAP_DataOut             : in  STD_LOGIC_VECTOR(31 downto 0)
    );
end entity icapwritersm;

architecture rtl of icapwritersm is

    type ConfigurationControllerSM_t is (
        InitialiseSt,                   -- On the reset state
        CheckSlotSt,
        NextSlotSt,
        ComposeResponsePacketSt,
        CheckCommandSt,
        ProcessCommandSt,
        ProcessFrameSt,
        GetICAPStatusSt,
        PrepareResponseHeader,
        GenerateIPCheckSumSt,
        WriteUDPResponceSt,
        ProcessSlotsSt,
        NextSlotsSt,
        SendErrorResponseSt
    );
    signal StateVariable              : ConfigurationControllerSM_t := InitialiseSt;
    constant C_ICAP_NOP_COMMAND   : std_logic_vector(31 downto 0) := X"20000000";

    function bitreverse(DataIn : std_logic_vector) return std_logic_vector is
        alias aDataIn  : std_logic_vector (DataIn'length - 1 downto 0) is DataIn;
        variable RData : std_logic_vector(aDataIn'range);
    begin
        for i in aDataIn'range loop
            RData(i) := aDataIn(aDataIn'left - i);
        end loop;

        return RData;
    end function bitreverse;

    function bitbyteswap(DataIn : in std_logic_vector)
    return std_logic_vector is
        variable RData48 : std_logic_vector(47 downto 0);
        variable RData32 : std_logic_vector(31 downto 0);
        variable RData24 : std_logic_vector(23 downto 0);
        variable RData16 : std_logic_vector(15 downto 0);
    begin
        if (DataIn'length = RData48'length) then
            RData48(7 downto 0)   := bitreverse(DataIn(47 downto 40));
            RData48(15 downto 8)  := bitreverse(DataIn(39 downto 32));
            RData48(23 downto 16) := bitreverse(DataIn(31 downto 24));
            RData48(31 downto 24) := bitreverse(DataIn(23 downto 16));
            RData48(39 downto 32) := bitreverse(DataIn(15 downto 8));
            RData48(47 downto 40) := bitreverse(DataIn(7 downto 0));
            return std_logic_vector(RData48);
        end if;
        if (DataIn'length = RData32'length) then
            RData32(7 downto 0)   := bitreverse(DataIn(31 downto 24));
            RData32(15 downto 8)  := bitreverse(DataIn(23 downto 16));
            RData32(23 downto 16) := bitreverse(DataIn(15 downto 8));
            RData32(31 downto 24) := bitreverse(DataIn(7 downto 0));
            return std_logic_vector(RData32);
        end if;
        if (DataIn'length = RData24'length) then
            RData24(7 downto 0)   := bitreverse(DataIn(23 downto 16));
            RData24(15 downto 8)  := bitreverse(DataIn(15 downto 8));
            RData24(23 downto 16) := bitreverse(DataIn(7 downto 0));
            return std_logic_vector(RData24);
        end if;
        if (DataIn'length = RData16'length) then
            RData16(7 downto 0)  := bitreverse(DataIn(15 downto 8));
            RData16(15 downto 8) := bitreverse(DataIn(7 downto 0));
            return std_logic_vector(RData16);
        else
            return DataIn;
        end if;
    end function bitbyteswap;

begin

    SynchStateProc : process(icap_clk)
    begin
        if rising_edge(icap_clk) then
            if (icap_reset = '1') then
                -- Initialize SM on reset
                ICAP_RDWRB    <= '0';
                ICAP_CSIB     <= '1';
                -- Tie ICAP Data to NOP Command when being initialized
                ICAP_DataIn   <= bitbyteswap(C_ICAP_NOP_COMMAND);
                StateVariable <= InitialiseSt;
            else
                case (StateVariable) is
                    when InitialiseSt =>
                        -- Wait for packet after initialization
                        StateVariable             <= CheckSlotSt;
                        ICAP_CSIB                 <= '1';
                        ICAP_RDWRB                <= '0';
                        -- Tie ICAP Data to NOP Command when being initialized
                        ICAP_DataIn               <= bitbyteswap(C_ICAP_NOP_COMMAND);

                    when CheckSlotSt =>
                        if (RingBufferSlotStatus = '1') then
                            -- The current slot has data 
                            -- Pull the data 
                            RingBufferDataRead <= '1';
                            StateVariable          <= ComposeResponsePacketSt;
                        else
                            RingBufferDataRead <= '0';
                            StateVariable          <= CheckSlotSt;
                        end if;

                    when NextSlotSt =>
                        -- Go to next Slot
                        --lRecvRingBufferSlotID   <= lRecvRingBufferSlotID + 1;
                        RingBufferAddress  <= (others => '0');
                        RingBufferSlotClear <= '0';
                        RingBufferDataRead  <= '0';
                        ICAP_CSIB               <= '1';
                        StateVariable           <= CheckSlotSt;


                    when ProcessCommandSt =>

                        if (ICAP_AVAIL = '1') then
                            -- ICAP is ready write the command
                            -- Set ICAP to Write mode
                            ICAP_RDWRB    <= '0';
                            ICAP_CSIB     <= '0';
                            -- Do the Xilinx bitswapping on bytes, refer to
                            -- UG570(v1.9) April 2,2018,Figure 9-1,Page 140
                            --ICAP_DataIn   <= bitbyteswap(lPRDWordCommand);
                            -- Done with write 
                            StateVariable <= GetICAPStatusSt;
                        else
                            -- Stop writing since the ICAP is not ready
                            ICAP_CSIB     <= '1';
                            -- Wait for the ICAP to be ready
                            StateVariable <= ProcessCommandSt;
                        end if;

                    -- Error processing    
                    when SendErrorResponseSt =>
                        -- Prepare a UDP Error packet
                        StateVariable <= GetICAPStatusSt;

                    -- Response processing    
                    when GetICAPStatusSt =>
                        -- Disselect the ICAP.
                        ICAP_CSIB              <= '1';
                        -- Append the ICAP status on the return bytes
                        -- Update the status bits on the Response Header

                        StateVariable <= PrepareResponseHeader;


                    when WriteUDPResponceSt =>
                        -- Prepare the response packet to the Ringbuffer
                        StateVariable <= ProcessSlotsSt;

                    when ProcessSlotsSt =>
                        -- Set the transmitter slot
                        -- Go to the next slots so that the system
                        -- can progress on the systems slots
                        StateVariable                  <= NextSlotsSt;

                    when NextSlotsSt =>
                        -- Transmitter
                        -- Clear the receiver slot
                        RingBufferSlotClear    <= '1';
                        -- Go to check the next available receiver slot
                        StateVariable              <= NextSlotSt;

                    when others =>
                        StateVariable <= InitialiseSt;
                end case;
            end if;
        end if;
    end process SynchStateProc;

end architecture rtl;
