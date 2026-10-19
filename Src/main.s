.syntax unified
.cpu cortex-m4
.fpu softvfp
.thumb

.global main
.type main, %function
.data
array: .4byte 1848, 1280, 872, 1864, 1360, 1624, 1656, 1792, 1912, 1880
.text
main:

	@Enable PWR Clock at APB1
	LDR r0, =0x40023800
	LDR	r1, [r0, #0x40]
    ORR r1, r1, #(1 << 28)
    STR r1, [r0, #0x40]
    @Enable Backup Domain Access
    LDR r0, =0x40007000
    LDR r1, [r0, #0x00]
    ORR r1, #(1 << 8)
    STR r1, [r0, #0x00]
	@Enable LSE in RCC_BDCR
    LDR r0, =0x40023800
    LDR r1, [r0, #0x70]
    @ Set LSE drive strength to the highest setting
    BIC r1, r1, #(3 << 3)
    ORR r1, r1, #(3 << 3)
    @ Enable LSE (bit 0)
    ORR r1, r1, #1
    STR r1, [r0, #0x70]
    @ Wait for LSE ready (bit 1)
	lse_waiter:
    	LDR r1, [r0, #0x70]
    	TST r1, #(1 << 1)
    	BEQ lse_waiter
	@now set as real time clock, CLEAAR rtcsel, lse, rtc enable
	LDR r0, =0x40023800
	LDR r1, [r0, #0x70]
	BIC r1, r1, #(3 << 8)
	ORR r1, r1, #(1 << 8)
	ORR r1, r1, #(1 << 15)
	STR r1, [r0, #0x70]
	@now read from clock
	LDR r0, =0x40002800
	LDR r1, [r0, #0x00]			@read TR which gives hours minutem seconds
	LDR r2, [r0, #0x28]		@this gets precise
	LDR r3, [r0, #0x04]		@read the DR section which gives months, year, day
	MOVW r6, #0x0000			@this will load 2^31 the modulus of my LCG
	MOVT r6, #0x8000
	SUBS r6, r6, #1
	MOV r9, #0
	ADD r9, r9, r1
	ADD r9, r9, r2
	ADD r9, r9, r3
	AND r9, r9, r6
	MOVW r7, #0xE8A5 		@this will set this register to 1103515245 the multiplier
	MOVT r7, #0x41D8
	MOVW r8, #12345			@this is the adder of 12345
	MOVT r8, #0
	LDR r0, =0x40023830 		@ rcc AHB1ENR base address
	LDR r1, [r0]				@load from ahb1enr address
	ORR r1, r1, #0x06			@ this sets ports B And C for us to use for clokcing
	STR r1, [r0]				@ we set it
	@I will setup the user button here at PORT C pin 13
	LDR r0, =0x40020800 		@at Port C base address
	LDR r1, [r0]				@read GPIOC
	BIC r1, r1, #(0x3 << 26)	@set PC_13 (13*2=26) as input 00
	STR r1, [r0]
	@I will setup pins Port B as ouput in 3,4,5,6,8,9,10
	LDR r0, =0x40020400 		@at PB base address
	LDR r1, [r0]				@read GPIOB
	BIC r1, r1, #(0x3 << 6)		@clear PB _3 (3*2=6) to 00
	ORR r1, r1, #(0x1 << 6)		@set PB_3 (3*2=6) as ouput 01
	BIC r1, r1, #(0x3 << 8)		@clear PB _4 (4*2=8) to 00
	ORR r1, r1, #(0x1 << 8)		@set PA_B (4*2=8) as ouput 01
	BIC r1, r1, #(0x3 << 10)	@clear PB _5 (5*2=10) to 00
	ORR r1, r1, #(0x1 << 10)	@set PB_5 (5*2=10) as ouput 01
	BIC r1, r1, #(0x3 << 12)	@clear PB _6 (6*2=12) to 00
	ORR r1, r1, #(0x1 << 12)	@set PB_6 (6*2=12) as ouput 01
	BIC r1, r1, #(0x3 << 16)	@clear PB _8 (8*2=16) to 00
	ORR r1, r1, #(0x1 << 16)	@set PB_8 (8*2=16) as ouput 01
	BIC r1, r1, #(0x3 << 18)	@clear PB _9 (9*2=18) to 00
	ORR r1, r1, #(0x1 << 18)	@set PB_9 (9*2=18) as ouput 01
	BIC r1, r1, #(0x3 << 20)	@clear PB _10 (10*2=20) to 00
	ORR r1, r1, #(0x1 << 20)	@set PB_10 (10*2=20) as ouput 01
	STR r1, [r0]
	@just setup the r0 and r1 as base adress
	LDR r2, =array
	LDR r1, =0x40020400 @at PB base address
	LDR r0, =0x40020800 @at PC base address
	LDR r3, [r0, #0x10]
   	B    run_loop    @branch to lowercase routine

end:
   WFI
   B     end            @stop here
@----------------------------------------------------------------------
@ my_lowercase routine accepts r0 as a parameter and needs an address to the strings start
run_loop: 	LDR r5, [r0, #0x10] 	@Load current state
			BIC r4, r3, r5			@ Prev AND not Current, this gives us a 1 when a button is pressed!
			MOV r3, r5				@set previous state
			TST r4, #(1 << 13)		@test bit 13
			BEQ run_loop			@ignore if 0
			@run the LCG Linear Congruential Generator https://www.geeksforgeeks.org/dsa/linear-congruence-method-for-generating-pseudo-random-numbers/
			MUL r9, r7, r9		@we start by multiplying and dont worry about overflows
			ADD  r9, r9, r8		@adding by the addder
			AND  r9, r9, r6		@instead of doing a modulo this allows me to use a AND instead for a power of 2
			MOV r5, #10			@we do mod 10 so we get a number from 0 - 9
			UDIV r4, r9, r5
			MLS r4, r5, r4, r9
			@get from arraay precalculated value and set to odr
			LSL r4, r4, #2
			LDR r4, [r2, r4]
			STR r4, [r1, #0x14]
delayer:
    MOVW r4, #0xA42A
    MOVT r4, #0x0008
delay_loop:
    SUBS r4, r4, #1
    BNE delay_loop
    B run_loop
