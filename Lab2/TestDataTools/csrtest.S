test_0:
    li x3, 0;
    li x1, 0x0f;
    csrrw x0, 0, x1;    # csr[0] = 0x0f
    csrrc x2, 0, x0;    # x2 = csr[0] = 0x0f
    bne x2, x1, failed;
    csrrci x0, 0, 0x18; # csr[0] = 0x07
    csrrc x2, 0, x0     # x2 = csr[0] = 0x07
    li x1, 0x07;
    bne x2, x1, failed;

test_2:
    li x3, 2;
    li x1, 1;
    csrrw x0, 2, x1;    # csr[2] = 1
    csrrsi x2, 2, 0x18; # x2 = 1, csr[2] = 0x19
    bne x2, x1, failed; # data hazard
    csrrw x2, 2, x0;    # x2 = csr[2] = 0x19
    li x1, 0x19;
    bne x2, x1, failed;
    
test_3:
    li x3, 3;
    csrrwi x0, 3, 0x18; # csr[3] = 0x18
    li x1, 7;
    csrrs x2, 3, x1;    # x2 = 0x18, csr[3] = 0x1f
    li x1, 0x18;
    bne x2, x1, failed;
    csrrw x2, 3, x0;
    li x1, 0x1f;
    bne x2, x1, failed;

success:
    li x3, 1;
    j success;

failed: 
    j failed;
