library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity flappy_bird_step2_top is
 port (
   CLOCK_50 : in  std_logic;

   KEY      : in  std_logic_vector(3 downto 0);
   SW       : in  std_logic_vector(9 downto 0);

   VGA_R    : out std_logic_vector(3 downto 0);
   VGA_G    : out std_logic_vector(3 downto 0);
   VGA_B    : out std_logic_vector(3 downto 0);
   VGA_HS   : out std_logic;
   VGA_VS   : out std_logic
 );
end flappy_bird_step2_top;

architecture rtl of flappy_bird_step2_top is

 signal reset      : std_logic;
 signal flap       : std_logic;
 signal pause      : std_logic;
 signal game_enable: std_logic;

 signal pixel_clk  : std_logic := '0';

 signal display_on : std_logic;
 signal pixel_x    : unsigned(9 downto 0);
 signal pixel_y    : unsigned(9 downto 0);
 signal frame_tick : std_logic;

 signal bird_x     : unsigned(9 downto 0);
 signal bird_y     : unsigned(9 downto 0);
 signal bird_dead  : std_logic;

 signal bird_on    : std_logic;
 signal bird_r     : std_logic_vector(3 downto 0);
 signal bird_g     : std_logic_vector(3 downto 0);
 signal bird_b     : std_logic_vector(3 downto 0);

 signal pipe_data  : std_logic_vector(59 downto 0);
 signal num_pipes  : integer range 0 to 3;

begin

 -- DE0-CV KEY buttons are active-low.
 reset       <= not KEY(0);
 flap        <= not KEY(1);
 pause       <= not KEY(2);

 -- Use SW0 as game start / enable.
 game_enable <= SW(0);

 -- 50 MHz to 25 MHz pixel clock.
 process (CLOCK_50)
 begin
   if rising_edge(CLOCK_50) then
     if reset = '1' then
       pixel_clk <= '0';
     else
       pixel_clk <= not pixel_clk;
     end if;
   end if;
 end process;

 vga_unit: entity work.vga_sync
   port map (
     pixel_clk  => pixel_clk,
     reset      => reset,
     hsync      => VGA_HS,
     vsync      => VGA_VS,
     display_on => display_on,
     pixel_x    => pixel_x,
     pixel_y    => pixel_y,
     frame_tick => frame_tick
   );

 bird_unit: entity work.bird_controller
   generic map (
     SCREEN_W => 640,
     SCREEN_H => 480,
     BIRD_W   => 24,
     BIRD_H   => 18,
     INIT_X   => 100,
     INIT_Y   => 240,
     GRAVITY  => 1,
     FLAP_VEL => -7,
     MAX_FALL => 8
   )
   port map (
     clk          => pixel_clk,
     reset        => reset,
     frame_tick   => frame_tick,
     game_enable  => game_enable,
     pause        => pause,
     flap         => flap,
     hit_obstacle => '0',
     bird_x       => bird_x,
     bird_y       => bird_y,
     bird_dead    => bird_dead
   );

 draw_bird_unit: entity work.bird_draw
   generic map (
     BIRD_W => 24,
     BIRD_H => 18
   )
   port map (
     pixel_x => pixel_x,
     pixel_y => pixel_y,
     bird_x  => bird_x,
     bird_y  => bird_y,
     bird_on => bird_on,
     bird_r  => bird_r,
     bird_g  => bird_g,
     bird_b  => bird_b
   );

 process (display_on, pixel_y, bird_on, bird_dead, bird_r, bird_g, bird_b)
 begin
   if display_on = '0' then
     VGA_R <= "0000";
     VGA_G <= "0000";
     VGA_B <= "0000";

   elsif bird_on = '1' then

     -- If the bird is dead, show it as red.
     if bird_dead = '1' then
       VGA_R <= "1111";
       VGA_G <= "0000";
       VGA_B <= "0000";
     else
       VGA_R <= bird_r;
       VGA_G <= bird_g;
       VGA_B <= bird_b;
     end if;

   elsif to_integer(pixel_y) >= 462 then
     -- Ground area
     VGA_R <= "0010";
     VGA_G <= "1111";
     VGA_B <= "0010";

   else
     -- Sky background
     VGA_R <= "0010";
     VGA_G <= "0111";
     VGA_B <= "1111";
   end if;
 end process;

end rtl;
