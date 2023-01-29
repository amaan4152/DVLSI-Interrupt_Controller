module INTR_CTRL (
        input   wire            clk,        
        input   wire            rst_in,    
        input   wire    [7:0]   intr_rq,
        inout   wire    [7:0]   intr_bus,
        input   wire            intr_in,
        output  wire            intr_out,
        output  wire            bus_oe
    );
 
    localparam  [3:0]   RESET                 = 4'b0000,  // Reset
                        GET_MODE              = 4'b0001,  // Get mode
                        SET_MODE              = 4'b0010,  // Set mode
                        INIT_NORMAL           = 4'b0011,  // Start normal mode
                        NORMAL_ASSERT_INTR    = 4'b0100,  // Normal Mode: Start handshake w/ processor
                        NORMAL_ACK_INTR       = 4'b0101,  // Normal Mode: Wait processor to respond to handshake
                        DONE_NORMAL           = 4'b0110,  // Normal Mode: Compelte handshake
                        INIT_PRIORITY         = 4'b0111,  // Start priority mode
                        PRIORITY_ASSERT_INTR  = 4'b1000,  // Priority Mode: Start handshake w/ processor
                        PRIORITY_ACK_INTR     = 4'b1001,  // Priority Mode: Wait processor to respond to handshake
                        DONE_PRIORITY         = 4'b1010;  // Priority Mode: Compelte handshake
   
    reg     [3:0]   state_reg, state_next;          
    reg     [1:0]   mode_reg, mode_next;      
    reg     [1:0]   priority_cycle_reg, priority_cycle_next;   
    reg     [2:0]   id_reg, id_next;                
    reg     [2:0]   intrPtr_reg, intrPtr_next;     
    reg     [2:0]   prior_tbl_next [0:7]; 
    reg     [2:0]   prior_tbl_reg [0:7];
    reg             oe_reg, oe_next;                // output enable 
    reg     [7:0]   intrBus_reg, intrBus_next; 
    reg             intrOut_reg, intrOut_next; 

    integer         i;

    always @ (posedge clk or posedge rst_in) begin

        if (rst_in) begin
            state_reg           <=  RESET;
            mode_reg            <=  2'b00;
            priority_cycle_reg  <=  2'b00;
            oe_reg              <=  1'b0;
            intrBus_reg         <=  8'bz;
            intrOut_reg         <=  1'b0;
            id_reg              <=  3'b000;
            intrPtr_reg         <=  3'b000;
            for (i = 0; i < 8; i = i + 1) begin
                prior_tbl_reg[i]  <=  3'b000;
            end
        end
 
        else begin
            state_reg           <=  state_next;
            mode_reg         <=  mode_next;
            priority_cycle_reg        <=  priority_cycle_next;
            intrBus_reg         <=  intrBus_next;
            intrOut_reg         <=  intrOut_next;
            oe_reg              <=  oe_next;
            id_reg       <=  id_next;
            intrPtr_reg         <=  intrPtr_next;
            for (i = 0; i < 8; i = i + 1) begin
                prior_tbl_reg[i]  <=  prior_tbl_next[i];
            end
        end
    end

    always @(*) begin
        state_next          =   state_reg;
        mode_next           =   mode_reg;
        priority_cycle_next =   priority_cycle_reg;
        oe_next             =   oe_reg;
        intrOut_next        =   intrOut_reg;
        intrBus_next        =   intrBus_reg;
        id_next      =   id_reg;
        intrPtr_next        =   intrPtr_reg;
        for (i = 0; i < 8; i = i + 1) begin
            prior_tbl_next[i] =   prior_tbl_reg[i];
        end
 
        case (state_reg)
            RESET: begin
                mode_next        =   2'b00;
                priority_cycle_next       =   2'b00;
                id_next      =   3'b000;
                intrPtr_next        =   3'b000;
                for (i = 0; i < 8; i = i + 1) begin
                    prior_tbl_next[i] =   3'b000;
                end

                oe_next             =   1'b0; 
                state_next  =   GET_MODE;          // Wait for commands.
            end
 
            GET_MODE: begin 
                oe_next =   1'b0;
                case (intr_bus[1:0])
                    2'b01: begin                                                // normal mode.
                        mode_next    =   2'b01;                              
                        state_next      =   SET_MODE;                    
                    end
 
                    2'b10: begin                                                // Priority mode.
                        case (priority_cycle_reg)
                            2'b00: begin
                                prior_tbl_next[0] =   intr_bus[7:5];          
                                prior_tbl_next[1] =   intr_bus[4:2];          
                                state_next          =   GET_MODE;
                                priority_cycle_next       =   priority_cycle_reg + 1'b1;
                            end
                            2'b01: begin
                                prior_tbl_next[2] =   intr_bus[7:5];          
                                prior_tbl_next[3] =   intr_bus[4:2];          
                                state_next          =   GET_MODE;
                                priority_cycle_next       =   priority_cycle_reg + 1'b1;
                            end
                            2'b10: begin
                                prior_tbl_next[4] =   intr_bus[7:5];          
                                prior_tbl_next[5] =   intr_bus[4:2];          
                                state_next          =   GET_MODE;
                                priority_cycle_next       =   priority_cycle_reg + 1'b1;
                            end
                            2'b11: begin
                                prior_tbl_next[6] =   intr_bus[7:5];          
                                prior_tbl_next[7] =   intr_bus[4:2];          
                                state_next          =   SET_MODE;        
                                priority_cycle_next       =   priority_cycle_reg + 1'b1;
                                mode_next        =   2'b10;                
                            end
                            default: begin
                                state_next      =   GET_MODE;
                                priority_cycle_next   =   2'b00;
                                mode_next    =   2'b00;                      
                            end
                        endcase
 
                    end
                    default: begin                                              // Stay in the state till valid commands are entered.
                        state_next  =   GET_MODE;
                    end
                endcase
            end
 
            SET_MODE: begin
                id_next  =   3'b000;
                intrPtr_next    =   3'b000;
 
                case (mode_reg)
                    2'b01:   state_next  =   INIT_NORMAL;
                    2'b10:   state_next  =   INIT_PRIORITY;
                    default: state_next  =   RESET;
                endcase
 
                oe_next         =   1'b0;
            end
 
            INIT_NORMAL: begin
                if (intr_rq[id_reg]) begin
                    intrOut_next    =   1'b1;
                    state_next      =   NORMAL_ASSERT_INTR;
                end
                else begin                                  
                    intrOut_next    =   1'b0;            
                    id_next  =   id_reg + 1;
                end

                oe_next         =   1'b0;                   
            end
 
            NORMAL_ASSERT_INTR: begin 
                if (~intr_in) begin                                
                    intrOut_next    =   1'b0;                       
                    intrBus_next    =   {5'b01011, id_reg}; 
                    oe_next         =   1'b1;                      
                    state_next      =   NORMAL_ACK_INTR;    
                end                                               
                else
                    state_next      =   NORMAL_ASSERT_INTR;
            end

            NORMAL_ACK_INTR: begin
                if (~intr_in) begin                                 
                    oe_next         =   1'b0;                     
                    state_next      =   DONE_NORMAL;        
                end                                                
            end
 
            DONE_NORMAL: begin
                if ((~intr_in) && (intr_bus[7:3] == 5'b10100) && (intr_bus[2:0] == id_reg))
                    state_next  =   INIT_NORMAL;
                else if ((~intr_in) && (intr_bus[7:3] != 5'b10100) && (intr_bus[2:0] != id_reg))
                    state_next  =   RESET;
                else
                    state_next  =   DONE_NORMAL;
            end
 
            INIT_PRIORITY: begin
                if (intr_rq[prior_tbl_reg[0]]) begin              
                    intrPtr_next    =   prior_tbl_reg[0];      
                    intrOut_next    =   1'b1;
                    state_next      =   PRIORITY_ASSERT_INTR;
                end
 
                else if (intr_rq[prior_tbl_reg[1]]) begin
                    intrPtr_next    =   prior_tbl_reg[1];
                    intrOut_next    =   1'b1;
                    state_next      =   PRIORITY_ASSERT_INTR;
                end
 
                else if (intr_rq[prior_tbl_reg[2]]) begin
                    intrPtr_next    =   prior_tbl_reg[2];
                    intrOut_next    =   1'b1;
                    state_next      =   PRIORITY_ASSERT_INTR;
                end
 
                else if (intr_rq[prior_tbl_reg[3]]) begin
                    intrPtr_next    =   prior_tbl_reg[3];
                    intrOut_next    =   1'b1;
                    state_next      =   PRIORITY_ASSERT_INTR;
                end
 
                else if (intr_rq[prior_tbl_reg[4]]) begin
                    intrPtr_next    =   prior_tbl_reg[4];
                    intrOut_next    =   1'b1;
                    state_next      =   PRIORITY_ASSERT_INTR;
                end
 
                else if (intr_rq[prior_tbl_reg[5]]) begin
                    intrPtr_next    =   prior_tbl_reg[5];
                    intrOut_next    =   1'b1;
                    state_next      =   PRIORITY_ASSERT_INTR;
                end
 
                else if (intr_rq[prior_tbl_reg[6]]) begin
                    intrPtr_next    =   prior_tbl_reg[6];
                    intrOut_next    =   1'b1;
                    state_next      =   PRIORITY_ASSERT_INTR;
                end
 
                else if (intr_rq[prior_tbl_reg[7]]) begin
                    intrPtr_next    =   prior_tbl_reg[7];
                    intrOut_next    =   1'b1;
                    state_next      =   PRIORITY_ASSERT_INTR;
                end
 
                else begin
                    state_next  =   INIT_PRIORITY;                
                end

                oe_next         =   1'b0;
            end

            PRIORITY_ASSERT_INTR: begin 
                if (~intr_in) begin                          
                    intrOut_next    =   1'b0;                       
                    intrBus_next    =   {5'b10011, intrPtr_reg};    
                    oe_next         =   1'b1;                       
                    state_next      =   PRIORITY_ACK_INTR;   
                end                                             
            end
            
            PRIORITY_ACK_INTR: begin 
                if (~intr_in) begin                                
                    oe_next         =   1'b0;   
                    state_next      =   DONE_PRIORITY;    
                end
            end
            
            DONE_PRIORITY: begin 
                if ((~intr_in) && (intr_bus[7:3] == 5'b01100) && (intr_bus[2:0] == intrPtr_reg)) begin
                    state_next  =   INIT_PRIORITY;
                end
                else if ((~intr_in) && (intr_bus[7:3] != 5'b01100) && (intr_bus[2:0] != intrPtr_reg)) begin
                    state_next  =   RESET;
                end
                else begin
                    state_next  =   DONE_PRIORITY;
                end
            end
            
            default: begin
                state_next      =   RESET;
                oe_next         =   1'b0;
            end
        endcase
    end

    assign intr_out =   intrOut_reg;
    assign intr_bus =   (oe_reg) ? intrBus_reg : 8'bzzzzzzzz;
    assign bus_oe   =   oe_reg;

endmodule
