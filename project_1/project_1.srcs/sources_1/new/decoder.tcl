add_force {/decoder_wrapper/addr} -radix hex \
	{0 100ns} {1 200ns} {2 300ns} {3 400ns} \
	{4 500ns} {5 600ns} {6 700ns} {7 800ns} \
	-cancel_after 900ns

add_force {/decoder_wrapper/idat} -radix hex \
	{00 100ns} {01 150ns} {00 200ns} {02 250ns} \
	{00 300ns} {04 350ns} {00 400ns} {08 450ns} \
	{00 500ns} {10 550ns} {00 600ns} {20 650ns} \
	{00 700ns} {40 750ns} {00 800ns} {80 850ns} \
	-cancel_after 900ns
