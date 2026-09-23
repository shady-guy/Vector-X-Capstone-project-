package vector_pkg;
    localparam int VLEN     = 256;
    localparam int SEW      = 32;
    //localparam int ELEN     = SEW;       // element width (alias for SEW)
    localparam int ELEN     = 64;       
    localparam int LANES    = 8; 
    localparam int MAX_VREG = 32;

    // Memory access modes for LSU
    typedef enum logic [1:0] {
        UNIT_STRIDE,   // consecutive elements
        STRIDE,        // fixed stride between elements
        INDEX          // indexed (scatter/gather)
    } vector_mem_mode_t;

    // Vector opcodes
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

    //RVV vtype fields
    typedef struct packed{
        logic [2:0] vsew;   //3 bit encoding for SEW (0=8-bit, 1=16-bit, 2=32-bit, 3=64-bit)
        logic [1:0] vlmul;   //2 bit encoding for LMUL (0=1, 1=2, 2=4, 3=8)
        logic       vta;    //tail agnostic
        logic       vma;    //mask agnostic
    } vtype_t;

    function automatic int sew_frm_vtype(input vtype_t vtype);
        return 8 << vtype.vsew; //left shift by 8 to get actual SEW
    endfunction

    // LMUL encoding: 00=1, 01=2, 10=4, 11=8
    //how many physical registers grouped together for one vector register
    function automatic int lmul_frm_vtype (input vtype_t vtype);
        case (vtype.vlmul)
            2'b00: return 1;
            2'b01: return 2;
            2'b10: return 4;
            2'b11: return 8;
            default: return 1; //default to LMUL=1
        endcase
    endfunction

    //compute maximum vector length in elements based on VLEN and vtype.
    //vlen_bits =VLEN =256, SEW=8,16,32,64, LMUL=1,2,4,8 
    //=> vlmax = (VLEN/SEW)*LMUL
    function automatic int vlmax(input vlen_bits, input vtype_t vtype);
        return (vlen_bits / sew_frm_vtype(vtype)) * lmul_frm_vtype(vtype);
    endfunction

endpackage