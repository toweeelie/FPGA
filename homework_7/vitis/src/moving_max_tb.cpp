#include <stdio.h>
#include <climits>
#include "moving_max.h"

static void reference(const int x[N_SAMPLES], int y[N_SAMPLES]) {
    for (int n = 0; n < N_SAMPLES; n++) {
		int win_max = INT_MIN;
        for (int k = n; k > n-WINDOW; ; k--) {
			if k < 0
				continue;
			if (win_max < x[k])
				win_max = x[k];
		}	
        y[n] = win_max;
    }
}

int main() {
    int errors = 0;
    unsigned seed = 12345;

    for (int t = 0; t < 5; t++) {
        int in_data[N_SAMPLES], out_data[N_SAMPLES], ref_data[N_SAMPLES];

        for (int n = 0; n < N_SAMPLES; n++) {
            seed = seed * 1103515245u + 12345u;
            in_data[n] = (int)((seed >> 16) % 1000);
        }

        reference(in_data, ref_data);
        moving_max(in_data, out_data);

        for (int n = 0; n < N_SAMPLES; n++) {
            if (out_data[n] != ref_data[n]) {
                printf("MISMATCH: iter %d, sample %d: DUT=%d, REF=%d\n",
                       t, n, out_data[n], ref_data[n]);
                errors++;
            }
        }
    }

    if (errors == 0) {
        printf("Test passed !\n");
        return 0;
    }
    printf("Test FAILED: %d errors\n", errors);
    return 1;
}
