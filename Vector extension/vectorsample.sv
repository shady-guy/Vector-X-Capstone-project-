module vector_vadd #(
  parameter LANES = 4, //parallel channels
  parameter SEW   = 32, //element size= 32 bits
  parameter MAX_VL = 64 //max ength of vector
)(
  input  logic clk,
  input  logic rst,

  // instruction control
  input  logic start,
  input  logic [$clog2(MAX_VL)-1:0] vl, //length of vector
  output logic done,

  // vector registers 
  input  logic [SEW-1:0] vs1 [MAX_VL],
  input  logic [SEW-1:0] vs2 [MAX_VL],
  output logic [SEW-1:0] vd  [MAX_VL]
);

  logic [$clog2(MAX_VL)-1:0] elem_idx;
 // FSM states
  typedef enum logic [1:0] {
    IDLE,
    EXEC,
    FINISH
  } state_t;

  state_t state;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      state    <= IDLE;
      elem_idx <= 0;
      done     <= 0;
    end else begin
      case (state)
        IDLE: begin
          done <= 0;
          if (start) begin
            elem_idx <= 0;
            state    <= EXEC;
          end
        end
        EXEC: begin
          for (int lane = 0; lane < LANES; lane++) begin
            if (elem_idx + lane < vl) begin
              vd[elem_idx + lane] <=
                vs1[elem_idx + lane] + vs2[elem_idx + lane];
            end
          end

          elem_idx <= elem_idx + LANES;

          if (elem_idx + LANES >= vl)
            state <= FINISH;
        end
        FINISH: begin
          done  <= 1;
          state <= IDLE;
        end

      endcase
    end
  end

endmodule
