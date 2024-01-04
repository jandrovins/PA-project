.global _boot
.text

_boot:                    /* x0  = 0    0x000 */
    /* Test ADDI */
addi x14,zero,0
addi x12,zero,1010
addi x13,zero,1
add x14,x13,x14
addi x13,x13,1
blt x13,a2,-4
addi x30,x14,-44
bge zero,zero,0 


.data
variable:
	.word 0xdeadbeef
                    
