.syntax unified
.cpu cortex-m4
.fpu softvfp
.thumb

.global main
.type main, %function

.text
main:

	LDR r0, =0x40023830  @ rcc AHB1ENR base address
	LDR r1, [r0]		 @load from ahb1enr address
	ORR r1, r1, #0x03	 @ this sets ports A and B for us to use for clokcing
	STR r1, [r0]		@ we set it
	@we will setup pins PB as input at 3,4,5
	LDR r0, =0x40020400 @at PB base address
	LDR r1, [r0]		@ read GPIOB
	BIC r1, r1, #(0x3 << 6)		@set PB _3 (3*2=6) as input	00
	BIC r1, r1, #(0x3 << 8)		@set PB_4 (4*2=8) to 00
	BIC r1, r1, #(0x3 << 10)	@set PB _5 (5*2=10) as input 00
	STR r1, [r0]
	@I will setup pins PA as ouput in 7,8,9
	LDR r0, =0x40020000 @at PA base address
	LDR r1, [r0]
	BIC r1, r1, #(0x3 << 14)	@clear PA _7 (7*2=14) to 00
	ORR r1, r1, #(0x1 << 14)	@set PA_7 (7*2=14) as ouput 01
	BIC r1, r1, #(0x3 << 16)	@clear PA _8 (8*2=16) to 00
	ORR r1, r1, #(0x1 << 16)	@set PA_8 (8*2=16) as ouput 01
	BIC r1, r1, #(0x3 << 18)	@clear PA _9 (9*2=18) to 00
	ORR r1, r1, #(0x1 << 18)	@set PA_9 (9*2=18) as ouput 01
	STR r1, [r0]
	@just setup the r0 and r1 as base adress
	LDR r1, =0x40020400 @at PB base address
	LDR r0, =0x40020000 @at PA base address
	LDR r3, [r1, #0x10]	@previous_state
	MOV r5, r3			@master
   	B    run_led    @branch to lowercase routine

end:
   WFI
   B     end            @stop here
@----------------------------------------------------------------------
@ my_lowercase routine accepts r0 as a parameter and needs an address to the strings start
run_led: 	LDR r2, [r1, #0x10] 	@Load current state
			BIC r4, r3, r2			@ Prev AND not Current, this gives us a 1 when a button is pressed!
			MOV r3, r2				@set previous state
			EOR r5, r5, r4
			MOV r2, r5
			AND r2, r2, #0x38 @mask everything except bits 0b00111000
			LSL r2, r2, #4 @this will allow me to shift to 7,8,9 which are the pins in port A
			STR r2, [r0, #0x14]			@store what the shifted values from r2 and put in ODR A
			MOVW r2, #0xA42A	@this is a timer based on debounce of button about 20 miliseconds times 85,000 or the 84 mhz added a bit more for error and divided by 3(cycles per loop)
			MOVT r2, #0x0008
			BL delayer
			B run_led
delayer:	SUBS r2, r2, #1
			BPL delayer
			BX lr
