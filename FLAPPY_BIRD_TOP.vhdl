-- Top Level
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FLAPPY_BIRD_TOP is
    port (
        -- Clock & Reset
        CLOCK_50 : in  std_logic;                       -- 50MHz OnBoard Clock
        RESET_N  : in  std_logic;                       -- Reset

        -- User Input
        SW       : in  std_logic_vector(9 downto 0);    -- Mode Selection
        KEY      : in  std_logic_vector(3 downto 0);    -- Key: Start & Pause

        -- PS/2 Mouse Interface
        PS2_CLK  : inout std_logic;                     -- Mouse Clock
        PS2_DAT  : inout std_logic;                     -- Mouse Data

        -- VGA Output Interface
        VGA_HS   : out std_logic;                       -- Horizontal Sync
        VGA_VS   : out std_logic;                       -- Vertical Sync
        VGA_R    : out std_logic_vector(3 downto 0);    -- 4bit Red
        VGA_G    : out std_logic_vector(3 downto 0);    -- 4bit Green
        VGA_B    : out std_logic_vector(3 downto 0);    -- 4bit Blue
        
        -- Seven Segements Display
        HEX0     : out std_logic_vector(6 downto 0);
        HEX1     : out std_logic_vector(6 downto 0)
    );
end entity FLAPPY_BIRD_TOP;

architecture structural of FLAPPY_BIRD_TOP is

    -- Internal signals for connecting modules
    signal mouse_x, mouse_y : std_logic_vector(9 downto 0);
    signal left_click       : std_logic;
    signal game_pixel_rgb   : std_logic_vector(11 downto 0);
    signal current_mode     : std_logic; -- 0: Training, 1: Game

begin
    -- Assign mode selection from DIP switch 0
    current_mode <= SW(0); [cite: 37]

    -- PS/2 Mouse Controller (act as component)
    -- Responsible for capturing movement and click data for bird flapping [cite: 17, 111]
    u_mouse : entity work.mouse_controller
        port map (
            clk      => CLOCK_50,
            ps2_clk  => PS2_CLK,
            ps2_dat  => PS2_DAT,
            left_en  => left_click,
            mouse_x  => mouse_x
        );

    -- Game Logic / Finite State Machine (FSM)
    -- Manages game states (Start, Play, Pause, Dead) and object movement
    u_game_logic : entity work.game_engine
        port map (
            clk          => CLOCK_50,
            reset        => not RESET_N,
            mode_select  => current_mode,
            jump_trigger => left_click,
            pause        => not KEY(2),
            pixel_rgb    => game_pixel_rgb
        );

    -- VGA Driver
    -- Generates HSYNC/VSYNC pulses and outputs pixel data to the monitor
    u_vga : entity work.vga_controller
        port map (
            clk_50   => CLOCK_50,
            pixel_in => game_pixel_rgb,
            vga_hs   => VGA_HS,
            vga_vs   => VGA_VS,
            vga_r    => VGA_R,
            vga_g    => VGA_G,
            vga_b    => VGA_B
        );

end architecture structural;