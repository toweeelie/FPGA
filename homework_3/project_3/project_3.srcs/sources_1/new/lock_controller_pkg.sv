package lock_controller_pkg;
    typedef enum logic [1:0] {
        LOCKED,
        WAIT_D2,
        WAIT_D3,
        UNLOCKED
    } state_t;
endpackage