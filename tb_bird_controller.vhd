library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_bird_controller is
end tb_bird_controller;

architecture sim of tb_bird_controller is

 constant CLK_PERIOD : time := 20 ns;

 signal clk          : std_logic := '0';
 signal reset        : std_logic := '0';
 signal frame_tick   : std_logic := '0';
 signal game_enable  : std_logic := '0';
 signal pause        : std_logic := '0';
 signal flap         : std_logic := '0';
 signal hit_obstacle : std_logic := '0';

 signal bird_x       : unsigned(9 downto 0);
 signal bird_y       : unsigned(9 downto 0);
 signal bird_dead    : std_logic;

begin

 clk <= not clk after CLK_PERIOD / 2;

 uut: entity work.bird_controller
   port map (
     clk          => clk,
     reset        => reset,
     frame_tick   => frame_tick,
     game_enable  => game_enable,
     pause        => pause,
     flap         => flap,
     hit_obstacle => hit_obstacle,
     bird_x       => bird_x,
     bird_y       => bird_y,
     bird_dead    => bird_dead
   );

 stim_proc: process

   procedure one_frame is
   begin
     frame_tick <= '1';
     wait until rising_edge(clk);
     wait for 1 ns;

     frame_tick <= '0';
     wait until rising_edge(clk);
     wait for 1 ns;
   end procedure;

   variable old_y       : integer;
   variable frame_count : integer;

 begin

   -- Reset
   reset <= '1';
   wait for 100 ns;
   wait until rising_edge(clk);
   reset <= '0';
   wait for 1 ns;

   assert to_integer(bird_x) = 100
     report "Reset failed: bird_x is not 100"
     severity error;

   assert to_integer(bird_y) = 240
     report "Reset failed: bird_y is not 240"
     severity error;

   assert bird_dead = '0'
     report "Reset failed: bird should be alive"
     severity error;

   -- Start game
   game_enable <= '1';
   pause <= '0';
   flap <= '0';
   hit_obstacle <= '0';

   -- Frame 1: no flap, gravity makes bird fall by 1
   one_frame;

   assert to_integer(bird_y) = 241
     report "Gravity test failed after frame 1"
     severity error;

   -- Frame 2: velocity increases, bird falls more
   one_frame;

   assert to_integer(bird_y) = 243
     report "Gravity test failed after frame 2"
     severity error;

   -- Flap: bird should jump upward
   flap <= '1';
   one_frame;
   flap <= '0';

   assert to_integer(bird_y) = 236
     report "Flap test failed: bird did not move upward"
     severity error;

   -- After flap, gravity slowly reduces upward speed
   one_frame;

   assert to_integer(bird_y) = 230
     report "Post-flap movement test failed"
     severity error;

   -- Pause test
   pause <= '1';
   old_y := to_integer(bird_y);

   one_frame;
   one_frame;

   assert to_integer(bird_y) = old_y
     report "Pause test failed: bird moved while paused"
     severity error;

   pause <= '0';

   -- Hit obstacle test
   hit_obstacle <= '1';
   one_frame;
   hit_obstacle <= '0';

   assert bird_dead = '1'
     report "Collision test failed: bird should be dead"
     severity error;

   -- Reset again
   reset <= '1';
   wait until rising_edge(clk);
   wait for 1 ns;
   reset <= '0';
   wait for 1 ns;

   assert bird_dead = '0'
     report "Second reset failed: bird should be alive again"
     severity error;

   assert to_integer(bird_y) = 240
     report "Second reset failed: bird_y is not reset"
     severity error;

   -- Ground death test
   game_enable <= '1';
   pause <= '0';
   flap <= '0';
   hit_obstacle <= '0';

   frame_count := 0;

   while bird_dead = '0' and frame_count < 200 loop
     one_frame;
     frame_count := frame_count + 1;
   end loop;

   assert bird_dead = '1'
     report "Ground death test failed: bird did not die after falling"
     severity error;

   report "All bird_controller tests passed."
     severity note;

   wait;

 end process;

end sim;
