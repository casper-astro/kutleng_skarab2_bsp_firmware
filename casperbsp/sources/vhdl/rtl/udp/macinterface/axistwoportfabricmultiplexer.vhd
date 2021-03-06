--------------------------------------------------------------------------------
-- Company          : Kutleng Dynamic Electronics Systems (Pty) Ltd            -
-- Engineer         : Benjamin Hector Hlophe                                   -
--                                                                             -
-- Design Name      : CASPER BSP                                               -
-- Module Name      : axistwoportfabricmultiplexer - rtl                       -
-- Project Name     : SKARAB2                                                  -
-- Target Devices   : N/A                                                      -
-- Tool Versions    : N/A                                                      -
-- Description      : This multiplexes two AXIS streams to one.                -
--                                                                             -
-- Dependencies     : axisfabricmultiplexer                                    -
-- Revision History : V1.0 - Initial design                                    -
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity axistwoportfabricmultiplexer is
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
end entity axistwoportfabricmultiplexer;

architecture rtl of axistwoportfabricmultiplexer is
    component axisfabricmultiplexer is
        generic(
            G_MAX_PACKET_BLOCKS_SIZE : natural := 64;
            G_MUX_PORTS              : natural := 7;
            G_PRIORITY_WIDTH         : natural := 4;
            G_DATA_WIDTH             : natural := 8
        );
        port(
            axis_clk          : in  STD_LOGIC;
            axis_reset        : in  STD_LOGIC;
            --Outputs to AXIS bus MAC side 
            axis_tx_tpriority : out STD_LOGIC_VECTOR(G_PRIORITY_WIDTH - 1 downto 0);
            axis_tx_tdata     : out STD_LOGIC_VECTOR(G_DATA_WIDTH - 1 downto 0);
            axis_tx_tvalid    : out STD_LOGIC;
            axis_tx_tready    : in  STD_LOGIC;
            axis_tx_tkeep     : out STD_LOGIC_VECTOR((G_DATA_WIDTH / 8) - 1 downto 0);
            axis_tx_tlast     : out STD_LOGIC;
            axis_tx_tuser     : out STD_LOGIC;
            --Inputs from AXIS 
            ------------------------------------------------------------------------------------------------------------------------
            -- The priority signal is interpreted as follows                                  
            -- 0-2**(G_PRIORITY_WIDTH-1)
            -- Where 0 is lowest priority which means no packets of data are available to forward on that specific AXIS stream port
            -- 1-2**(G_PRIORITY_WIDTH-1) is the number of packets on the AXIS stream port waiting to be transmitted
            -- The more the number of ports that are waiting to be transmitted the higher the port priority
            ----------------------------------------------------------------------------------------------------------------------
            axis_rx_tpriority : in  STD_LOGIC_VECTOR((G_MUX_PORTS * G_PRIORITY_WIDTH) - 1 downto 0);
            axis_rx_tdata     : in  STD_LOGIC_VECTOR((G_MUX_PORTS * G_DATA_WIDTH) - 1 downto 0);
            axis_rx_tvalid    : in  STD_LOGIC_VECTOR(G_MUX_PORTS - 1 downto 0);
            axis_rx_tready    : out STD_LOGIC_VECTOR(G_MUX_PORTS - 1 downto 0);
            axis_rx_tkeep     : in  STD_LOGIC_VECTOR((G_MUX_PORTS * (G_DATA_WIDTH / 8)) - 1 downto 0);
            axis_rx_tlast     : in  STD_LOGIC_VECTOR(G_MUX_PORTS - 1 downto 0)
        );
    end component axisfabricmultiplexer;
    constant C_MUX_PORTS      : natural := 2;
    signal laxis_rx_tpriority : STD_LOGIC_VECTOR((C_MUX_PORTS * G_PRIORITY_WIDTH) - 1 downto 0);
    signal laxis_rx_tdata     : STD_LOGIC_VECTOR((C_MUX_PORTS * G_DATA_WIDTH) - 1 downto 0);
    signal laxis_rx_tvalid    : STD_LOGIC_VECTOR(C_MUX_PORTS - 1 downto 0);
    signal laxis_rx_tready    : STD_LOGIC_VECTOR(C_MUX_PORTS - 1 downto 0);
    signal laxis_rx_tkeep     : STD_LOGIC_VECTOR((C_MUX_PORTS * (G_DATA_WIDTH / 8)) - 1 downto 0);
    signal laxis_rx_tlast     : STD_LOGIC_VECTOR(C_MUX_PORTS - 1 downto 0);

begin
    laxis_rx_tlast(0)  <= axis_rx_tlast_1;
    laxis_rx_tlast(1)  <= axis_rx_tlast_2;
    laxis_rx_tvalid(0) <= axis_rx_tvalid_1;
    laxis_rx_tvalid(1) <= axis_rx_tvalid_2;
    axis_rx_tready_1   <= laxis_rx_tready(0);
    axis_rx_tready_2   <= laxis_rx_tready(1);

    laxis_rx_tpriority((1 * G_PRIORITY_WIDTH) - 1 downto G_PRIORITY_WIDTH * (1 - 1)) <= axis_rx_tpriority_1;
    laxis_rx_tpriority((2 * G_PRIORITY_WIDTH) - 1 downto G_PRIORITY_WIDTH * (2 - 1)) <= axis_rx_tpriority_2;

    laxis_rx_tdata((1 * G_DATA_WIDTH) - 1 downto G_DATA_WIDTH * (1 - 1)) <= axis_rx_tdata_1;
    laxis_rx_tdata((2 * G_DATA_WIDTH) - 1 downto G_DATA_WIDTH * (2 - 1)) <= axis_rx_tdata_2;

    laxis_rx_tkeep((1 * (G_DATA_WIDTH / 8)) - 1 downto (G_DATA_WIDTH / 8) * (1 - 1)) <= axis_rx_tkeep_1;
    laxis_rx_tkeep((2 * (G_DATA_WIDTH / 8)) - 1 downto (G_DATA_WIDTH / 8) * (2 - 1)) <= axis_rx_tkeep_2;

    AXISMUX_i : axisfabricmultiplexer
        generic map(
            G_MAX_PACKET_BLOCKS_SIZE => G_MAX_PACKET_BLOCKS_SIZE,
            G_MUX_PORTS              => C_MUX_PORTS,
            G_PRIORITY_WIDTH         => G_PRIORITY_WIDTH,
            G_DATA_WIDTH             => G_DATA_WIDTH
        )
        port map(
            axis_clk          => axis_clk,
            axis_reset        => axis_reset,
            axis_tx_tpriority => open,
            axis_tx_tdata     => axis_tx_tdata,
            axis_tx_tvalid    => axis_tx_tvalid,
            axis_tx_tready    => axis_tx_tready,
            axis_tx_tkeep     => axis_tx_tkeep,
            axis_tx_tlast     => axis_tx_tlast,
            axis_tx_tuser     => axis_tx_tuser,
            axis_rx_tpriority => laxis_rx_tpriority,
            axis_rx_tdata     => laxis_rx_tdata,
            axis_rx_tvalid    => laxis_rx_tvalid,
            axis_rx_tready    => laxis_rx_tready,
            axis_rx_tkeep     => laxis_rx_tkeep,
            axis_rx_tlast     => laxis_rx_tlast
        );
end architecture rtl;
