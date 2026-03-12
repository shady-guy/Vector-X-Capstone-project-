package vector_pkg;
    localparam int VLEN     = 256;
    localparam int SEW      = 32;
    localparam int LANES    = 8; 
    localparam int MAX_VREG = 32;

    typedef enum logic [3:0] {
        VADD,
        VSUB,
        VAND,
        VOR,
        VXOR,
        VSLL,   
        VSRL,
        VSRA,
        VMIN,
        VMAX,
        VMINU,
        VMAXU,
        VLOAD,
        VSTORE
    } vector_opcode_t;

    typedef enum logic [1:0] {
        UNIT_STRIDE,
        STRIDE,
        INDEX
    } vector_mem_mode_t;
    
endpackage
