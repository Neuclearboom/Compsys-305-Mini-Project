library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Pipes is
    port (
        clk        : in  std_logic;
        reset      : in  std_logic;
        game_enable : in  std_logic;  -- Only spawn/move pipes when enabled
        frame_tick : in  std_logic;  -- Pulse at 60Hz for frame updates
        pipe_data  : out std_logic_vector(59 downto 0);  -- 20 bits per pipe (10 x + 10 gap_y) x 3 pipes
        num_pipes  : out integer range 0 to 3
    );
end entity Pipes;

architecture behavioral of Pipes is

    -- Types
    type pipe_record is record
        x     : integer range -100 to 800;
        gap_y : integer range 0 to 480;
    end record;
    type pipe_array_type is array (0 to 2) of pipe_record;
    type gap_array_type is array (0 to 4) of integer;

    -- Constants
    constant SCREEN_WIDTH  : integer := 640;
    constant SCREEN_HEIGHT : integer := 480;
    constant PIPE_WIDTH    : integer := 50;
    constant GAP_HEIGHT    : integer := 100;  -- 50px above + 50px below
    constant PIPE_SPACING  : integer := 250;  -- 200px gap + 50px width
    constant SPAWN_X       : integer := SCREEN_WIDTH + PIPE_WIDTH;  -- 690
    constant REMOVE_X      : integer := -PIPE_WIDTH;  -- -50
    constant MAX_PIPES     : integer := 3;
    constant PRE_GAPS      : gap_array_type := (120, 180, 240, 300, 360);  -- Pre-made gap positions

    -- Internal signals
    signal pipe_array    : pipe_array_type;
    signal spawn_counter : integer range 0 to PIPE_SPACING-1 := 0;
    signal spawn_index   : integer range 0 to 2 := 0;
    signal active_count  : integer range 0 to MAX_PIPES := 0;
    signal lfsr          : std_logic_vector(9 downto 0) := "0000000001";  -- LFSR seed

begin

    -- LFSR for random number generation
    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                lfsr <= "0000000001";
            else
                -- 10-bit LFSR with taps at 10 and 7
                lfsr <= lfsr(8 downto 0) & (lfsr(9) xor lfsr(6));
            end if;
        end if;
    end process;

    -- Pipe management process
    process (clk)
        variable index : integer;
        variable new_gap_y : integer;
    begin
        if rising_edge(clk) then
            if reset = '1' or game_enable = '0' then
                spawn_counter <= 0;
                spawn_index <= 0;
                for i in 0 to 2 loop
                    pipe_array(i).x <= -1;  -- Mark as inactive
                    pipe_array(i).gap_y <= 0;
                end loop;
            elsif game_enable = '1' and frame_tick = '1' then
                -- Move all pipes left by 1 pixel
                for i in 0 to 2 loop
                    if pipe_array(i).x > REMOVE_X and pipe_array(i).x /= -1 then
                        pipe_array(i).x <= pipe_array(i).x - 1;
                    end if;
                end loop;

                -- Spawn new pipe if counter reached
                if spawn_counter = PIPE_SPACING - 1 then
                    -- Select random pre-made gap
                    index := to_integer(unsigned(lfsr(4 downto 0))) mod 5;
                    new_gap_y := PRE_GAPS(index);
                    pipe_array(spawn_index).x <= SPAWN_X;
                    pipe_array(spawn_index).gap_y <= new_gap_y;
                    spawn_index <= (spawn_index + 1) mod 3;
                    spawn_counter <= 0;
                else
                    spawn_counter <= spawn_counter + 1;
                end if;
            end if;
        end if;
    end process;

    -- Pack pipe data into output vector
    process (pipe_array)
        variable count : integer := 0;
    begin
        count := 0;
        for i in 0 to 2 loop
            -- 10 bits for x (offset by 100 to handle negative), 10 bits for gap_y
            pipe_data(20*i + 19 downto 20*i + 10) <= std_logic_vector(to_unsigned(pipe_array(i).x + 100, 10));
            pipe_data(20*i + 9 downto 20*i) <= std_logic_vector(to_unsigned(pipe_array(i).gap_y, 10));
            if pipe_array(i).x >= 0 then
                count := count + 1;
            end if;
        end loop;
        active_count <= count;
    end process;

    -- Output assignments
    num_pipes <= active_count;

end architecture behavioral;