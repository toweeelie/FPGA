add_force {/counter/reset} -radix bin \
	{1 100ns} {0 110ns} {1 700ns} {0 710ns} \
	-cancel_after 900ns

add_force {/counter/clock} -radix bin {0 0ns} {1 5ns} \
    -repeat_every 10ns -cancel_after 900ns
