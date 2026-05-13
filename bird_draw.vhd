library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bird_draw is
 generic (
   BIRD_W : integer := 24;
   BIRD_H : integer := 18
 );
 port (
   pixel_x : in  unsigned(9 downto 0);
   pixel_y : in  unsigned(9 downto 0);

   bird_x  : in  unsigned(9 downto 0);
   bird_y  : in  unsigned(9 downto 0);

   bird_on : out std_logic;

   bird_r  : out std_logic_vector(3 downto 0);
   bird_g  : out std_logic_vector(3 downto 0);
   bird_b  : out std_logic_vector(3 downto 0)
 );
end bird_draw;

architecture rtl of bird_draw is
begin

 process (pixel_x, pixel_y, bird_x, bird_y)
   variable px : integer;
   variable py : integer;
   variable bx : integer;
   variable by : integer;
 begin
   px := to_integer(pixel_x);
   py := to_integer(pixel_y);
   bx := to_integer(bird_x);
   by := to_integer(bird_y);

   bird_on <= '0';
   bird_r  <= "0000";
   bird_g  <= "0000";
   bird_b  <= "0000";

   if px >= bx and px < bx + BIRD_W and
      py >= by and py < by + BIRD_H then

     bird_on <= '1';

     -- Eye
     if px >= bx + 15 and px < bx + 18 and
        py >= by + 4  and py < by + 7 then
       bird_r <= "0000";
       bird_g <= "0000";
       bird_b <= "0000";

     -- Wing
     elsif px >= bx + 5 and px < bx + 13 and
           py >= by + 9 and py < by + 14 then
       bird_r <= "1111";
       bird_g <= "1000";
       bird_b <= "0000";

     -- Body
     else
       bird_r <= "1111";
       bird_g <= "1111";
       bird_b <= "0000";
     end if;

   end if;
 end process;

end rtl;
