package vector_pkg;

parameter int VLEN  = 256;
parameter int SEW  = 32;
parameter int LANES = 4;
parameter int MAX_VREG = 32;

typedef logic [VLEN-1:0] vreg_t;
typedef logic [SEW-1:0] elem_t;

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
endpackage