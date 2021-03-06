--------------------------------------------------------------------------------
-- Company          : Kutleng Dynamic Electronics Systems (Pty) Ltd            -
-- Engineer         : Benjamin Hector Hlophe                                   -
--                                                                             -
-- Design Name      : CASPER BSP                                               -
-- Module Name      : testcomms - rtl                                            -
-- Project Name     : SKARAB2                                                  -
-- Target Devices   : N/A                                                      -
-- Tool Versions    : N/A                                                      -
-- Description      : This module instantiates the ARP,UDP Server for bandiwth -
--                    testing. It implements full line rate testing by echoing -
--                    all UDP data sent to the G_IP_ADDR address and the UDP/IP-
--                    port G_UDP_SERVER_PORT at full line rate.                -
--                    To use it one must first prepare its ARP table on the OS -
--                    by pinging it to populate its ARP entry on the OS and on -
--                    the switch port.                                         -
--                                                                             -
-- Dependencies     : macifudpserver,arpmodule,axistwoportfabricmultiplexer    -
-- Revision History : V1.0 - Initial design                                    -
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testcomms is
    generic(
        G_DATA_WIDTH      : natural                          := 512;
        G_EMAC_ADDR       : std_logic_vector(47 downto 0)    := X"000A_3502_4194";
        G_UDP_SERVER_PORT : natural range 0 to ((2**16) - 1) := 5;
        G_IP_ADDR         : std_logic_vector(31 downto 0)    := X"C0A8_0A0A" --192.168.10.10

    );
    port(
        axis_clk       : in  STD_LOGIC;
        axis_reset     : in  STD_LOGIC;
        --Outputs to AXIS bus MAC side 
        axis_tx_tdata  : out STD_LOGIC_VECTOR(G_DATA_WIDTH - 1 downto 0);
        axis_tx_tvalid : out STD_LOGIC;
        axis_tx_tready : in  STD_LOGIC;
        axis_tx_tkeep  : out STD_LOGIC_VECTOR((G_DATA_WIDTH / 8) - 1 downto 0);
        axis_tx_tlast  : out STD_LOGIC;
        axis_tx_tuser  : out STD_LOGIC;
        --Inputs from AXIS bus of the MAC side
        axis_rx_tdata  : in  STD_LOGIC_VECTOR(G_DATA_WIDTH - 1 downto 0);
        axis_rx_tvalid : in  STD_LOGIC;
        axis_rx_tuser  : in  STD_LOGIC;
        axis_rx_tkeep  : in  STD_LOGIC_VECTOR((G_DATA_WIDTH / 8) - 1 downto 0);
        axis_rx_tlast  : in  STD_LOGIC
    );
end entity testcomms;

architecture rtl of testcomms is

    component macifudpserver is
        generic(
            G_SLOT_WIDTH : natural := 4;
            -- The address width is log2(2048/(512/8))=5 bits wide
            G_ADDR_WIDTH : natural := 5
        );
        port(
            axis_clk                       : in  STD_LOGIC;
            axis_app_clk                   : in  STD_LOGIC;
            axis_reset                     : in  STD_LOGIC;
            -- Setup information
            ServerMACAddress               : in  STD_LOGIC_VECTOR(47 downto 0);
            ServerIPAddress                : in  STD_LOGIC_VECTOR(31 downto 0);
            ServerUDPPort                  : in  STD_LOGIC_VECTOR(15 downto 0);
            -- MAC Statistics
            RXOverFlowCount                : out STD_LOGIC_VECTOR(31 downto 0);
            RXAlmostFullCount              : out STD_LOGIC_VECTOR(31 downto 0);  
            -- Packet Readout in addressed bus format
            RecvRingBufferSlotID           : in  STD_LOGIC_VECTOR(G_SLOT_WIDTH - 1 downto 0);
            RecvRingBufferSlotClear        : in  STD_LOGIC;
            RecvRingBufferSlotStatus       : out STD_LOGIC;
            RecvRingBufferSlotTypeStatus   : out STD_LOGIC;
            RecvRingBufferSlotsFilled      : out STD_LOGIC_VECTOR(G_SLOT_WIDTH - 1 downto 0);
            RecvRingBufferDataRead         : in  STD_LOGIC;
            -- Enable[0] is a special bit (we assume always 1 when packet is valid)
            -- we use it to save TLAST
            RecvRingBufferDataEnable       : out STD_LOGIC_VECTOR(63 downto 0);
            RecvRingBufferDataOut          : out STD_LOGIC_VECTOR(511 downto 0);
            RecvRingBufferAddress          : in  STD_LOGIC_VECTOR(G_ADDR_WIDTH - 1 downto 0);
            -- Packet Readout in addressed bus format
            SenderRingBufferSlotID         : out STD_LOGIC_VECTOR(G_SLOT_WIDTH - 1 downto 0);
            SenderRingBufferSlotClear      : out STD_LOGIC;
            SenderRingBufferSlotStatus     : in  STD_LOGIC;
            SenderRingBufferSlotTypeStatus : in  STD_LOGIC;
            SenderRingBufferSlotsFilled    : in  STD_LOGIC_VECTOR(G_SLOT_WIDTH - 1 downto 0);
            SenderRingBufferDataRead       : out STD_LOGIC;
            -- Enable[0] is a special bit (we assume always 1 when packet is valid)
            -- we use it to save TLAST
            SenderRingBufferDataEnable     : in  STD_LOGIC_VECTOR(63 downto 0);
            SenderRingBufferDataIn         : in  STD_LOGIC_VECTOR(511 downto 0);
            SenderRingBufferAddress        : out STD_LOGIC_VECTOR(G_ADDR_WIDTH - 1 downto 0);
            --Inputs from AXIS bus of the MAC side
            --Outputs to AXIS bus MAC side 
            axis_tx_tpriority              : out STD_LOGIC_VECTOR(3 downto 0);
            axis_tx_tdata                  : out STD_LOGIC_VECTOR(511 downto 0);
            axis_tx_tvalid                 : out STD_LOGIC;
            axis_tx_tready                 : in  STD_LOGIC;
            axis_tx_tkeep                  : out STD_LOGIC_VECTOR(63 downto 0);
            axis_tx_tlast                  : out STD_LOGIC;
            --Inputs from AXIS bus of the MAC side
            axis_rx_tdata                  : in  STD_LOGIC_VECTOR(511 downto 0);
            axis_rx_tvalid                 : in  STD_LOGIC;
            axis_rx_tuser                  : in  STD_LOGIC;
            axis_rx_tkeep                  : in  STD_LOGIC_VECTOR(63 downto 0);
            axis_rx_tlast                  : in  STD_LOGIC
        );
    end component macifudpserver;

    component arpmodule is
        generic(
            G_SLOT_WIDTH : natural := 4
        );
        port(
            axis_clk          : in  STD_LOGIC;
            axis_reset        : in  STD_LOGIC;
            -- Setup information
            ARPMACAddress     : in  STD_LOGIC_VECTOR(47 downto 0);
            ARPIPAddress      : in  STD_LOGIC_VECTOR(31 downto 0);
            --Inputs from AXIS bus 
            axis_rx_tdata     : in  STD_LOGIC_VECTOR(511 downto 0);
            axis_rx_tvalid    : in  STD_LOGIC;
            axis_rx_tuser     : in  STD_LOGIC;
            axis_rx_tkeep     : in  STD_LOGIC_VECTOR(63 downto 0);
            axis_rx_tlast     : in  STD_LOGIC;
            --Outputs to AXIS bus 
            axis_tx_tpriority : out STD_LOGIC_VECTOR(G_SLOT_WIDTH - 1 downto 0);
            axis_tx_tdata     : out STD_LOGIC_VECTOR(511 downto 0);
            axis_tx_tvalid    : out STD_LOGIC;
            axis_tx_tready    : in  STD_LOGIC;
            axis_tx_tkeep     : out STD_LOGIC_VECTOR(63 downto 0);
            axis_tx_tlast     : out STD_LOGIC
        );
    end component arpmodule;

    component axistwoportfabricmultiplexer is
        generic(
            G_MAX_PACKET_BLOCKS_SIZE : natural := 64;
            G_PRIORITY_WIDTH         : natural := 4;
            G_DATA_WIDTH             : natural := 8
        );
        port(
            axis_clk            : in  STD_LOGIC;
            axis_reset          : in  STD_LOGIC;
            --Inputs from AXIS bus of the MAC side
            --Outputs to AXIS bus MAC side 
            axis_tx_tdata       : out STD_LOGIC_VECTOR(G_DATA_WIDTH - 1 downto 0);
            axis_tx_tvalid      : out STD_LOGIC;
            axis_tx_tready      : in  STD_LOGIC;
            axis_tx_tkeep       : out STD_LOGIC_VECTOR((G_DATA_WIDTH / 8) - 1 downto 0);
            axis_tx_tlast       : out STD_LOGIC;
            axis_tx_tuser       : out STD_LOGIC;
            -- Port 1
            axis_rx_tpriority_1 : in  STD_LOGIC_VECTOR(G_PRIORITY_WIDTH - 1 downto 0);
            axis_rx_tdata_1     : in  STD_LOGIC_VECTOR(G_DATA_WIDTH - 1 downto 0);
            axis_rx_tvalid_1    : in  STD_LOGIC;
            axis_rx_tready_1    : out STD_LOGIC;
            axis_rx_tkeep_1     : in  STD_LOGIC_VECTOR((G_DATA_WIDTH / 8) - 1 downto 0);
            axis_rx_tlast_1     : in  STD_LOGIC;
            -- Port 2
            axis_rx_tpriority_2 : in  STD_LOGIC_VECTOR(G_PRIORITY_WIDTH - 1 downto 0);
            axis_rx_tdata_2     : in  STD_LOGIC_VECTOR(G_DATA_WIDTH - 1 downto 0);
            axis_rx_tvalid_2    : in  STD_LOGIC;
            axis_rx_tready_2    : out STD_LOGIC;
            axis_rx_tkeep_2     : in  STD_LOGIC_VECTOR((G_DATA_WIDTH / 8) - 1 downto 0);
            axis_rx_tlast_2     : in  STD_LOGIC
        );
    end component axistwoportfabricmultiplexer;

    constant C_MAX_PACKET_BLOCKS_SIZE : natural := 64;
    constant C_PRIORITY_WIDTH         : natural := 4;

    signal axis_tx_tpriority_1_arp : STD_LOGIC_VECTOR(C_PRIORITY_WIDTH - 1 downto 0);
    signal axis_tx_tdata_1_arp     : STD_LOGIC_VECTOR(511 downto 0);
    signal axis_tx_tvalid_1_arp    : STD_LOGIC;
    signal axis_tx_tkeep_1_arp     : STD_LOGIC_VECTOR(63 downto 0);
    signal axis_tx_tlast_1_arp     : STD_LOGIC;
    signal axis_tx_tready_1_arp    : STD_LOGIC;

    signal axis_tx_tpriority_1_udp : STD_LOGIC_VECTOR(C_PRIORITY_WIDTH - 1 downto 0);
    signal axis_tx_tdata_1_udp     : STD_LOGIC_VECTOR(511 downto 0);
    signal axis_tx_tvalid_1_udp    : STD_LOGIC;
    signal axis_tx_tkeep_1_udp     : STD_LOGIC_VECTOR(63 downto 0);
    signal axis_tx_tlast_1_udp     : STD_LOGIC;
    signal axis_tx_tready_1_udp    : STD_LOGIC;

    signal UDPRingBufferSlotID         : STD_LOGIC_VECTOR(C_PRIORITY_WIDTH - 1 downto 0);
    signal UDPRingBufferSlotClear      : STD_LOGIC;
    signal UDPRingBufferSlotStatus     : STD_LOGIC;
    signal UDPRingBufferSlotTypeStatus : STD_LOGIC;
    signal UDPRingBufferSlotsFilled    : STD_LOGIC_VECTOR(C_PRIORITY_WIDTH - 1 downto 0);
    signal UDPRingBufferDataRead       : STD_LOGIC;
    signal UDPRingBufferDataEnable     : STD_LOGIC_VECTOR(63 downto 0);
    signal UDPRingBufferData           : STD_LOGIC_VECTOR(511 downto 0);
    signal UDPRingBufferAddress        : STD_LOGIC_VECTOR(5 - 1 downto 0);

begin

    ARP1_i : arpmodule
        generic map(
            G_SLOT_WIDTH => C_PRIORITY_WIDTH
        )
        port map(
            axis_clk          => axis_clk,
            axis_reset        => axis_reset,
            ARPMACAddress     => G_EMAC_ADDR,
            ARPIPAddress      => G_IP_ADDR,
            --
            axis_tx_tpriority => axis_tx_tpriority_1_arp,
            axis_tx_tdata     => axis_tx_tdata_1_arp,
            axis_tx_tvalid    => axis_tx_tvalid_1_arp,
            axis_tx_tready    => axis_tx_tready_1_arp,
            axis_tx_tkeep     => axis_tx_tkeep_1_arp,
            axis_tx_tlast     => axis_tx_tlast_1_arp,
            --
            axis_rx_tdata     => axis_rx_tdata,
            axis_rx_tvalid    => axis_rx_tvalid,
            axis_rx_tuser     => axis_rx_tuser,
            axis_rx_tkeep     => axis_rx_tkeep,
            axis_rx_tlast     => axis_rx_tlast
        );

    UDPDATAApp_i : macifudpserver
        generic map(
            G_SLOT_WIDTH => C_PRIORITY_WIDTH,
            G_ADDR_WIDTH => 5
        )
        port map(
            axis_clk                       => axis_clk,
            axis_app_clk                   => axis_clk,
            axis_reset                     => axis_reset,
            -- Setup information
            ServerMACAddress               => G_EMAC_ADDR,
            ServerIPAddress                => G_IP_ADDR,
            ServerUDPPort                  => std_logic_vector(to_unsigned(G_UDP_SERVER_PORT, 16)),
            RXOverFlowCount                => open,
            RXAlmostFullCount              => open, 
            -- Packet Readout in addressed bus format
            RecvRingBufferSlotID           => UDPRingBufferSlotID,
            RecvRingBufferSlotClear        => UDPRingBufferSlotClear,
            RecvRingBufferSlotStatus       => UDPRingBufferSlotStatus,
            RecvRingBufferSlotTypeStatus   => UDPRingBufferSlotTypeStatus,
            RecvRingBufferSlotsFilled      => UDPRingBufferSlotsFilled,
            RecvRingBufferDataRead         => UDPRingBufferDataRead,
            -- Enable[0] is a special bit (we assume always 1 when packet is valid)
            -- we use it to save TLAST
            RecvRingBufferDataEnable       => UDPRingBufferDataEnable,
            RecvRingBufferDataOut          => UDPRingBufferData,
            RecvRingBufferAddress          => UDPRingBufferAddress,
            -- Packet Readout in addressed bus format
            SenderRingBufferSlotID         => UDPRingBufferSlotID,
            SenderRingBufferSlotClear      => UDPRingBufferSlotClear,
            SenderRingBufferSlotStatus     => UDPRingBufferSlotStatus,
            SenderRingBufferSlotTypeStatus => UDPRingBufferSlotTypeStatus,
            SenderRingBufferSlotsFilled    => UDPRingBufferSlotsFilled,
            SenderRingBufferDataRead       => UDPRingBufferDataRead,
            -- Enable[0] is a special bit (we assume always 1 when packet is valid
            -- we use it to save TLAST                                 
            SenderRingBufferDataEnable     => UDPRingBufferDataEnable,
            SenderRingBufferDataIn         => UDPRingBufferData,
            SenderRingBufferAddress        => UDPRingBufferAddress,
            --Inputs from AXIS bus of the MAC side
            --Outputs to AXIS bus MAC side 
            axis_tx_tpriority              => axis_tx_tpriority_1_udp,
            axis_tx_tdata                  => axis_tx_tdata_1_udp,
            axis_tx_tvalid                 => axis_tx_tvalid_1_udp,
            axis_tx_tready                 => axis_tx_tready_1_udp,
            axis_tx_tkeep                  => axis_tx_tkeep_1_udp,
            axis_tx_tlast                  => axis_tx_tlast_1_udp,
            --Inputs from AXIS bus of the MAC side
            axis_rx_tdata                  => axis_rx_tdata,
            axis_rx_tvalid                 => axis_rx_tvalid,
            axis_rx_tuser                  => axis_rx_tuser,
            axis_rx_tkeep                  => axis_rx_tkeep,
            axis_rx_tlast                  => axis_rx_tlast
        );

    AXISMUX_i : axistwoportfabricmultiplexer
        generic map(
            G_MAX_PACKET_BLOCKS_SIZE => C_MAX_PACKET_BLOCKS_SIZE,
            G_PRIORITY_WIDTH         => C_PRIORITY_WIDTH,
            G_DATA_WIDTH             => G_DATA_WIDTH
        )
        port map(
            axis_clk            => axis_clk,
            axis_reset          => axis_reset,
            axis_tx_tdata       => axis_tx_tdata,
            axis_tx_tvalid      => axis_tx_tvalid,
            axis_tx_tready      => axis_tx_tready,
            axis_tx_tkeep       => axis_tx_tkeep,
            axis_tx_tlast       => axis_tx_tlast,
            axis_tx_tuser       => axis_tx_tuser,
            -- Port 1 - ARP Controller Module
            axis_rx_tpriority_1 => axis_tx_tpriority_1_arp,
            axis_rx_tdata_1     => axis_tx_tdata_1_arp,
            axis_rx_tvalid_1    => axis_tx_tvalid_1_arp,
            axis_rx_tready_1    => axis_tx_tready_1_arp,
            axis_rx_tkeep_1     => axis_tx_tkeep_1_arp,
            axis_rx_tlast_1     => axis_tx_tlast_1_arp,
            -- Port 2 - Streaming Data Module
            axis_rx_tpriority_2 => axis_tx_tpriority_1_udp,
            axis_rx_tdata_2     => axis_tx_tdata_1_udp,
            axis_rx_tvalid_2    => axis_tx_tvalid_1_udp,
            axis_rx_tready_2    => axis_tx_tready_1_udp,
            axis_rx_tkeep_2     => axis_tx_tkeep_1_udp,
            axis_rx_tlast_2     => axis_tx_tlast_1_udp
        );

end architecture rtl;
