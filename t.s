	.file	"t.c"
	.option pic
	.attribute arch, "rv32e1p9"
	.attribute unaligned_access, 0
	.attribute stack_align, 4
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-4
	sw	s0,0(sp)
	addi	s0,sp,4
	li	a4,0
	li	a2,10
	li	a3,1
	mv	a5,a3
	add	a5,a4,a5
	mv	a4,a5
	j	.L2
.L3:
	mv	a5,a3
	add	a5,a4,a5
	mv	a4,a5
	mv	a5,a3
	addi	a5,a5,1
	mv	a3,a5
.L2:
	mv	a5,a2
	blt	a3,a5,.L3
	li	a5,0
	mv	a0,a5
	lw	s0,0(sp)
	addi	sp,sp,4
	jr	ra
	.size	main, .-main
	.ident	"GCC: (GNU) 12.2.0"
	.section	.note.GNU-stack,"",@progbits
