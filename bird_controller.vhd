library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bird_controller is
 generic (
   SCREEN_W  : integer := 640;
   SCREEN_H  : integer := 480;
   BIRD_W    : integer := 24;
   BIRD_H    : integer := 18;

   INIT_X    : integer := 100;
   INIT_Y    : integer := 240;

   GRAVITY   : integer := 1;
   FLAP_VEL  : integer := -7;
   MAX_FALL  : integer := 8
 );
 port (
   clk          : in  std_logic;
   reset        : in  std_logic;

   -- This should pulse once per VGA frame.
   frame_tick   : in  std_logic;

   -- Game control signals
   game_enable  : in  std_logic;
   pause        : in  std_logic;

   -- For now, flap can come from KEY1.
   -- Later, this can come from mouse left click.
   flap         : in  std_logic;

   -- Later this will come from collision_detector.
   hit_obstacle : in  std_logic;

   bird_x       : out unsigned(9 downto 0);
   bird_y       : out unsigned(9 downto 0);
   bird_dead    : out std_logic
 );
end bird_controller;

architecture rtl of bird_controller is

 signal x_pos : integer range 0 to SCREEN_W - 1 := INIT_X;
 signal y_pos : integer range 0 to SCREEN_H - 1 := INIT_Y;

 signal y_vel : integer range -16 to 16 := 0;

 signal alive : std_logic := '1';

begin

 process (clk, reset)
   variable next_vel : integer;
   variable next_y   : integer;
 begin
   if reset = '1' then
     x_pos <= INIT_X;
     y_pos <= INIT_Y;
     y_vel <= 0;
     alive <= '1';

   elsif rising_edge(clk) then

     -- Only update the bird once per frame.
     if frame_tick = '1' then

       if game_enable = '1' and pause = '0' and alive = '1' then

         if hit_obstacle = '1' then
           alive <= '0';

         else
           -- Flap gives the bird an upward velocity.
           -- In VGA coordinates, smaller y means higher position.
           if flap = '1' then
             next_vel := FLAP_VEL;
           else
             next_vel := y_vel + GRAVITY;

             if next_vel > MAX_FALL then
               next_vel := MAX_FALL;
             end if;
           end if;

           next_y := y_pos + next_vel;

           -- Top boundary
           if next_y < 0 then
             y_pos <= 0;
             y_vel <= 0;

           -- Bottom boundary: bird hits the ground and dies.
           elsif next_y > SCREEN_H - BIRD_H then
             y_pos <= SCREEN_H - BIRD_H;
             y_vel <= 0;
             alive <= '0';

           else
             y_pos <= next_y;
             y_vel <= next_vel;
           end if;

         end if;
       end if;
     end if;
   end if;
 end process;

 bird_x    <= to_unsigned(x_pos, bird_x'length);
 bird_y    <= to_unsigned(y_pos, bird_y'length);
 bird_dead <= not alive;

end rtl;
