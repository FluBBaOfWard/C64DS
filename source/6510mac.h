#define PSR_N 0x80000000		;@ARM flags
#define PSR_Z 0x40000000
#define PSR_C 0x20000000
#define PSR_V 0x10000000

#define C (1<<0)					;@6502 flags
#define Z (1<<1)
#define I (1<<2)
#define D (1<<3)
#define B (1<<4)			//;@(allways 1 except when IRQ pushes it)
#define R (1<<5)			//;@(locked at 1)
#define V (1<<6)
#define N (1<<7)

encodePC	.macro				;@translate from 6502 PC to rom offset
	and r1,m6502_pc,#0xE000
	add r2,r10,#memmap_tbl
	ldr r0,[r2,r1,lsr#11]
	str r0,[r10,#lastbank]
	add m6502_pc,m6502_pc,r0
	.endm

encodeP	.macro extra			;@pack 6502 flags into r0
	and r0,cycles,#CYC_V+CYC_D+CYC_I+CYC_C
	tst m6502_nz,#PSR_N
	orrne r0,r0,#N				;@N
	tst m6502_nz,#0xff
	orreq r0,r0,#Z				;@Z
	orr r0,r0,#extra			;@R(&B)
	.endm

decodeP	.macro					;@unpack 6502 flags from r0
	bic cycles,cycles,#CYC_V+CYC_D+CYC_I+CYC_C
	and r1,r0,#V+D+I+C
	orr cycles,cycles,r1		;@VDIC
	bic m6502_nz,r0,#0xFD		;@r0 is signed
	eor m6502_nz,m6502_nz,#Z
	.endm

eatcycles	.macro count
	sub cycles,cycles,#count*CYCLE
	.endm

fetch	.macro count
	subs cycles,cycles,#count*CYCLE
	ldrplb r0,[m6502_pc],#1
	ldrpl pc,[m6502_optbl,r0,lsl#2]
	ldr pc,[r10,#nexttimeout]
	.endm

fetch_c	.macro count				;@same as fetch except it adds the Carry (bit 0) also.
	sbcs cycles,cycles,#count*CYCLE
	ldrplb r0,[m6502_pc],#1
	ldrpl pc,[m6502_optbl,r0,lsl#2]
	ldr pc,[r10,#nexttimeout]
	.endm

clearcycles	.macro
	and cycles,cycles,#CYC_MASK		;@Save CPU bits
	.endm

readmemabs	.macro
	and r1,addy,#0xE000
	adr lr,F\@
	ldr pc,[m6502_rmem,r1,lsr#11]	;@in: addy,r1=addy&0xE000 (for rom_R)
F\@									;@out: r0=val (bits 8-31=0 (LSR,ROR,INC,DEC,ASL)), addy preserved for RMW instructions
	.endm

readmemzp	.macro
	bl ram_R
	.endm

readmemzpi	.macro
	bl ram_low_R
	.endm

readmemimm	.macro
	ldrb r0,[m6502_pc],#1
	.endm

readmemimms	.macro
	ldrsb m6502_nz,[m6502_pc],#1
	.endm

readmem	.macro
	.if _type == _ABS
		readmemabs
	.mexit
	.elseif _type == _ZP
		readmemzp
	.mexit
	.elseif _type == _ZPI
		readmemzpi
	.mexit
	.elseif _type == _IMM
		readmemimm
	.mexit
	.endm

readmems	.macro
	.if _type == _ABS
		readmemabs
		orr m6502_nz,r0,r0,lsl#24
	.mexit
	.elseif _type == _ZP
		readmemzp
		orr m6502_nz,r0,r0,lsl#24
	.mexit
	.elseif _type == _IMM
		readmemimms
	.mexit
	.endm


writememabs	.macro
	and r1,addy,#0xE000
;	adr r2,writemem_tbl
	add r2,r10,#writemem_tbl
	adr lr,F\@
	ldr pc,[r2,r1,lsr#11]	;@in: addy,r0=val(bits 8-31=?)
F\@							;@out: r0,r1,r2,addy=?
	.endm

writememzp	.macro
	bl ram_W
	.endm

writememzpi	.macro
	bl ram_low_W
	.endm

writemem	.macro
	.if _type == _ABS
		writememabs
	.mexit
	.elseif _type == _ZP
		writememzp
	.mexit
	.elseif _type == _ZPI
		writememzpi
	.mexit
	.endm
;----------------------------------------------------------------------------

push16	.macro			;@push r0
	mov r1,r0,lsr#8
	ldr r2,[r10,#m6502_s]
	strb r1,[r2],#-1
	orr r2,r2,#0x100
	strb r0,[r2],#-1
	strb r2,[r10,#m6502_s]
	.endm				;@r1,r2=?

push8 	.macro x
	ldr r2,[r10,#m6502_s]
	strb x,[r2],#-1
	strb r2,[r10,#m6502_s]
	.endm				;@r2=?

pop16	.macro			;@pop m6502_pc
	ldr r2,[r10,#m6502_s]
	sub r2,r2,#0xFE
	strb r2,[r10,#m6502_s]
	orr r2,r2,#0x100
	ldrb r0,[r2],#-1
	orr r2,r2,#0x100
	ldrb m6502_pc,[r2]
	orr m6502_pc,m6502_pc,r0,lsl#8
	.endm				;@r0,r1=?

pop8 .macro x
	ldrb r2,[r10,#m6502_s]
	add r2,r2,#1
	strb r2,[r10,#m6502_s]
	orr r2,r2,#0x100
	ldrsb x,[r2,cpu_zpage]		;@signed for PLA & PLP
	.endm				;@r2=?

;----------------------------------------------------------------------------
;@doXXX: load addy, increment m6502_pc

;	GBLA _type

//#define	_IMM	1				;@immediate
//#define	_ZP		2				;@zeropage
//#define	_ZPI	3				;@zeropage indexed
//#define	_ABS	4				;@absolute

_IMM	.set	1				;@immediate
_ZP		.set	2				;@zeropage
_ZPI	.set	3				;@zeropage indexed
_ABS	.set	4				;@absolute


doABS	.macro					;@absolute               $nnnn
_type	.set	_ABS
	ldrb addy,[m6502_pc],#1
	ldrb r0,[m6502_pc],#1
	orr addy,addy,r0,lsl#8
	.endm

doAIX	.macro					;@absolute indexed X     $nnnn,X
_type	.set	_ABS
	ldrb addy,[m6502_pc],#1
	ldrb r0,[m6502_pc],#1
	orr addy,addy,r0,lsl#8
	add addy,addy,m6502_x,lsr#24
	bic addy,addy,#0xff0000
	.endm

doAIY	.macro					;@absolute indexed Y     $nnnn,Y
_type	.set	_ABS
	ldrb addy,[m6502_pc],#1
	ldrb r0,[m6502_pc],#1
	orr addy,addy,r0,lsl#8
	add addy,addy,m6502_y,lsr#24
	bic addy,addy,#0xff0000
	.endm

doIMM	.macro					;@immediate              #$nn
_type	.set	_IMM
	.endm

doIIX	.macro					;@indexed indirect X     ($nn,X)
_type	.set	_ABS
	ldrb r0,[m6502_pc],#1
	add r0,m6502_x,r0,lsl#24
	ldrb addy,[cpu_zpage,r0,lsr#24]
	add r0,r0,#0x01000000
	ldrb r1,[cpu_zpage,r0,lsr#24]
	orr addy,addy,r1,lsl#8
	.endm

doIIY	.macro					;@indirect indexed Y     ($nn),Y
_type	.set	_ABS
	ldrb r0,[m6502_pc],#1
	ldrb addy,[r0,cpu_zpage]!
	ldrb r1,[r0,#1]
	orr addy,addy,r1,lsl#8
	add addy,addy,m6502_y,lsr#24
	bic addy,addy,#0xff0000
	.endm

doZPI	.macro					;@zeropage indirect     ($nn)
_type	.set	_ABS
	ldrb r0,[m6502_pc],#1
	ldrb addy,[r0,cpu_zpage]!
	ldrb r1,[r0,#1]
	orr addy,addy,r1,lsl#8
	.endm

doZ		.macro					;@zeropage              $nn
_type	.set	_ZP
	ldrb addy,[m6502_pc],#1
	.endm

doZIX	.macro					;@zeropage indexed X    $nn,X
_type	.set	_ZP
	ldrb addy,[m6502_pc],#1
	add addy,addy,m6502_x,lsr#24
	and addy,addy,#0xff
	.endm

doZIXf	.macro					;@zeropage indexed X    $nn,X
_type	.set	_ZPI
	ldrb addy,[m6502_pc],#1
	add addy,m6502_x,addy,lsl#24
	.endm

doZIY	.macro					;@zeropage indexed Y    $nn,Y
_type	.set	_ZP
	ldrb addy,[m6502_pc],#1
	add addy,addy,m6502_y,lsr#24
	and addy,addy,#0xff
	.endm

doZIYf	.macro					;@zeropage indexed Y    $nn,Y
_type	.set	_ZPI
	ldrb addy,[m6502_pc],#1
	add addy,m6502_y,addy,lsl#24
	.endm

;----------------------------------------------------------------------------

opADC	.macro
	readmem
	tst cycles,#CYC_D
	bne opADC_Dec

	movs r1,cycles,lsr#1			;@get C
	subcs r0,r0,#0x00000100
	adcs m6502_a,m6502_a,r0,ror#8
	mov m6502_nz,m6502_a,asr#24		;@NZ
	orr cycles,cycles,#CYC_C+CYC_V	;@Prepare C & V
	bicvc cycles,cycles,#CYC_V		;@V
	.endm

opADCD__	.macro
	movs r1,cycles,lsr#1        	;@get C
	adc m6502_nz,r0,m6502_a,lsr#24	;@Z is set with normal addition

	mov r1,r0,lsl#28
	subcs r1,r1,#0xF0000001
	adcs m6502_a,r1,m6502_a,ror#28
	cmncc m6502_a,#0x60000000
	addcs m6502_a,m6502_a,#0x60000000

	orr cycles,cycles,#CYC_C+CYC_V	;@Prepare C & V

	mov r0,r0,lsr#4
	subcs r0,r0,#0x00000010
	mov m6502_a,m6502_a,ror#4
	adcs m6502_a,m6502_a,r0,ror#4
	orrmi m6502_nz,m6502_nz,#PSR_N	;@N & V is set after high addition, before fixup
	bicvc cycles,cycles,#CYC_V		;@V
	cmncc m6502_a,#0x60000000
	addcs m6502_a,m6502_a,#0x60000000
	.endm

opADCD	.macro
	movs r1,cycles,lsr#1			;@get C
	eor r0,r0,#0xFF
	subcc r0,r0,#0x00000100
	sbcs m6502_a,m6502_a,r0,ror#8
	mov m6502_nz,m6502_a,asr#24 	;@NZ
	bic cycles,cycles,#CYC_C+CYC_V	;@Clear C & V
	orrcs cycles,cycles,#CYC_C		;@C
	orrvs cycles,cycles,#CYC_V		;@V
	addcs m6502_a,m6502_a,#0x60000000

	mov m6502_a,m6502_a,ror#28
	mvn r0,r0,ror#31
	cmp m6502_a,r0,lsl#27
	addcc m6502_a,m6502_a,#0x60000000
	mov m6502_a,m6502_a,ror#4
	.endm


opAND	.macro
	readmem
	and m6502_a,m6502_a,r0,lsl#24
	mov m6502_nz,m6502_a,asr#24		;@NZ
	.endm

opARR	.macro
	readmem
	and r1,m6502_a,r0,lsl#24
	tst cycles,cycles,lsr#1			;get C
	orr cycles,cycles,#CYC_C+CYC_V	;@Prepare C & V
	mov m6502_a,r1,rrx
	eor r0,m6502_a,r1
	tst r0,#0x40000000
	biceq cycles,cycles,#CYC_V		;@V
	mov m6502_nz,m6502_a,asr#24	;NZ
	
	tst cycles,#CYC_D
	bne opARR_Dec

	tst m6502_a,m6502_a,lsr#31
	biccc cycles,cycles,#CYC_C		;@C
	b F\@
opARR_Dec
	mov m6502_a,m6502_a,ror#28
	and r0,r1,#0x0F000000
	cmp r0,#0x05000000
	addpl m6502_a,m6502_a,#0x60000000
	mov m6502_a,m6502_a,ror#4
	and r0,r1,#0xF0000000
	cmp r0,#0x50000000
	addcs m6502_a,m6502_a,#0x60000000
	biccc cycles,cycles,#CYC_C		;@C
F\@
	and m6502_a,m6502_a,#0xff000000
	.endm
opASL	.macro
	readmem
	writemem						;@!! Crazy maniacs use this feature !!
	 add r0,r0,r0
	 orrs m6502_nz,r0,r0,lsl#24		;@NZ
	 orr cycles,cycles,#CYC_C		;@Prepare C
	 biccc cycles,cycles,#CYC_C		;@C
	writemem
	.endm

opBIT	.macro
	readmem
	bic cycles,cycles,#CYC_V		;@reset V
	tst r0,#V
	orrne cycles,cycles,#CYC_V		;@V
	and m6502_nz,r0,m6502_a,lsr#24	;@Z
	orr m6502_nz,m6502_nz,r0,lsl#24	;@N
	.endm

opCOMP 	.macro x					;@A,X & Y
	readmem
	subs m6502_nz,x,r0,lsl#24
	mov m6502_nz,m6502_nz,asr#24	;@NZ
	orr cycles,cycles,#CYC_C		;@Prepare C
	.endm

opDCP	.macro						;@Decrease Compare
	readmem
	writemem						;@!! Crazy maniacs use this feature !!
	sub r0,r0,#1
	subs m6502_nz,m6502_a,r0,lsl#24
	mov m6502_nz,m6502_nz,asr#24	;@NZ
	orr cycles,cycles,#CYC_C		;@Prepare C
	biccc cycles,cycles,#CYC_C
	writemem
	.endm

opDEC	.macro
	readmem
	writemem						;@!! Crazy maniacs use this feature !!
	sub r0,r0,#1
	orr m6502_nz,r0,r0,lsl#24		;@NZ
	writemem
	.endm

opEOR	.macro
	readmem
	eor m6502_a,m6502_a,r0,lsl#24
	mov m6502_nz,m6502_a,asr#24		;@NZ
	.endm

opINC	.macro
	readmem
	writemem						;@!! Crazy maniacs use this feature !!
	add r0,r0,#1
	orr m6502_nz,r0,r0,lsl#24		;@NZ
	writemem
	.endm

opISB	.macro
	readmem
	writemem						;@!! Crazy maniacs use this feature !!
	add r0,r0,#0x01
	and r0,r0,#0xFF					;this is only needed for decimal mode.
	writemem

	tst cycles,#CYC_D
	bne opSBC_Dec

	tst cycles,cycles,lsr#1			;@get C
	sbcs m6502_a,m6502_a,r0,lsl#24
	and m6502_a,m6502_a,#0xff000000
	mov m6502_nz,m6502_a,asr#24 	;@NZ
	orr cycles,cycles,#CYC_C+CYC_V	;@Prepare C & V
	bicvc cycles,cycles,#CYC_V		;@V
	.endm

opLAS	.macro
	readmem
	ldrb r1,[r10,#m6502_s]
	and r0,r1,r0
	strb r0,[r10,#m6502_s]
	mov m6502_a,r0,lsl#24
	mov m6502_x,r0,lsl#24
	mov m6502_nz,m6502_x,asr#24
	.endm

opLAX	.macro
	readmems
	mov m6502_a,m6502_nz,lsl#24
	mov m6502_x,m6502_nz,lsl#24
	.endm

opLOAD	.macro x
	readmems
	mov x,m6502_nz,lsl#24
	.endm

opLSR	.macro
	.if _type == _ABS
		readmemabs
		writememabs					;@!! Crazy maniacs use this feature !!
		movs r0,r0,lsr#1
		mov m6502_nz,r0				;@Z, (N=0)
		orr cycles,cycles,#CYC_C	;@Prepare C
		biccc cycles,cycles,#CYC_C	;@C
		writememabs
	.mexit
	.elseif _type == _ZP
		ldrb m6502_nz,[cpu_zpage,addy]
		movs m6502_nz,m6502_nz,lsr#1	;@Z, (N=0)
		orr cycles,cycles,#CYC_C	;@Prepare C
		biccc cycles,cycles,#CYC_C	;@C
		strb m6502_nz,[cpu_zpage,addy]
	.mexit
	.elseif _type == _ZPI
		ldrb m6502_nz,[cpu_zpage,addy,lsr#24]
		movs m6502_nz,m6502_nz,lsr#1	;@Z, (N=0)
		orr cycles,cycles,#CYC_C	;@Prepare C
		biccc cycles,cycles,#CYC_C	;@C
		strb m6502_nz,[cpu_zpage,addy,lsr#24]
	.mexit
	.endm

opLXA	.macro
	readmem
	orr m6502_a,m6502_a,#0xEE000000
	and m6502_a,m6502_a,r0,lsl#24
	mov m6502_x,m6502_a
	mov m6502_nz,m6502_a,asr#24		;@NZ
	.endm

opORA	.macro
	readmem
	orr m6502_a,m6502_a,r0,lsl#24
	mov m6502_nz,m6502_a,asr#24
	.endm

opRLA	.macro
	readmem
	writemem						;@!! Crazy maniacs use this feature !!
	 movs cycles,cycles,lsr#1		;@get C
	 adc r0,r0,r0
	 ands m6502_a,m6502_a,r0,lsl#24
	 mov m6502_nz,m6502_a,asr#24	;@NZ
	 adc cycles,cycles,cycles		;@Set C
	writemem
	.endm

opROL	.macro
	readmem
	writemem						;@!! Crazy maniacs use this feature !!
	 movs cycles,cycles,lsr#1		;@get C
	 adc r0,r0,r0
	 orrs m6502_nz,r0,r0,lsl#24		;@NZ
	 adc cycles,cycles,cycles		;@Set C
	writemem
	.endm

opROR	.macro
	readmem
	writemem						;@!! Crazy maniacs use this feature !!
	 movs cycles,cycles,lsr#1		;@get C
	 orrcs r0,r0,#0x100
	 movs r0,r0,lsr#1
	 orr m6502_nz,r0,r0,lsl#24		;@NZ
	 adc cycles,cycles,cycles		;@Set C
	writemem
	.endm

opRRA	.macro
	readmem
	writemem						;@!! Crazy maniacs use this feature !!
	 movs cycles,cycles,lsr#1		;@get C
	 orrcs r0,r0,#0x100
	 movs r0,r0,lsr#1
	 orr m6502_nz,r0,r0,lsl#24		;@NZ
	 adc cycles,cycles,cycles		;@Set C
	writemem
	tst cycles,#CYC_D
	bne opADC_Dec

	movs r1,cycles,lsr#1			;@get C
	subcs r0,r0,#0x00000100
	adcs m6502_a,m6502_a,r0,ror#8
	mov m6502_nz,m6502_a,asr#24		;@NZ
	orr cycles,cycles,#CYC_C+CYC_V	;@Prepare C & V
	bicvc cycles,cycles,#CYC_V		;@V
	.endm

opSAX	.macro
	and r0,m6502_a,m6502_x
	mov r0,r0,lsr#24
	writemem
	.endm

opSBC	.macro
	readmem
	tst cycles,#CYC_D
	bne opSBC_Dec

	movs r1,cycles,lsr#1			;@get C
	sbcs m6502_a,m6502_a,r0,lsl#24
	and m6502_a,m6502_a,#0xff000000
	mov m6502_nz,m6502_a,asr#24 	;@NZ
	orr cycles,cycles,#CYC_C+CYC_V	;@Prepare C & V
	bicvc cycles,cycles,#CYC_V		;@V
	.endm

opSBCD	.macro
	movs r1,cycles,lsr#1			;@get C
	subcc r0,r0,#0x00000100
	sbcs m6502_a,m6502_a,r0,ror#8
	mov m6502_nz,m6502_a,asr#24 	;@NZ
	bic cycles,cycles,#CYC_C+CYC_V	;@Clear C & V
	orrcs cycles,cycles,#CYC_C		;@C
	orrvs cycles,cycles,#CYC_V		;@V
	subcc m6502_a,m6502_a,#0x60000000

	mov m6502_a,m6502_a,ror#28
	mvn r0,r0,ror#31
	cmp m6502_a,r0,lsl#27
	subcs m6502_a,m6502_a,#0x60000000
	mov m6502_a,m6502_a,ror#4
	.endm

opSBX	.macro
	readmem
	and m6502_x,m6502_x,m6502_a
	subs m6502_x,m6502_x,r0,lsl#24
	mov m6502_nz,m6502_x,asr#24 	;@NZ
	orr cycles,cycles,#CYC_C		;@Prepare C
	.endm

opSHA_ABS_Y	.macro
	ldrb addy,[m6502_pc],#1
	ldrb r1,[m6502_pc],#1
	adds addy,m6502_y,addy,lsl#24

	adc r0,r1,#0x01
	and r0,r0,m6502_x,lsr#24
	and r0,r0,m6502_a,lsr#24

	orrcc addy,addy,r1
	orrcs addy,addy,r0
	mov addy,addy,ror#24
	writemem
	.endm

opSHA_IND_Y	.macro
	ldrb r0,[m6502_pc],#1
	ldrb addy,[r0,cpu_zpage]!
	ldrb r1,[r0,#1]
	adds addy,m6502_y,addy,lsl#24

	adc r0,r1,#0x01
	and r0,r0,m6502_x,lsr#24
	and r0,r0,m6502_a,lsr#24

	orrcc addy,addy,r1
	orrcs addy,addy,r0
	mov addy,addy,ror#24
	writemem
	.endm

opSHS_ABS_Y	.macro
	ldrb addy,[m6502_pc],#1
	ldrb r1,[m6502_pc],#1
	adds addy,m6502_y,addy,lsl#24

	adc r0,r1,#0x01
	and r0,r0,m6502_x,lsr#24
	and r0,r0,m6502_a,lsr#24

	orrcc addy,addy,r1
	orrcs addy,addy,r0
	mov addy,addy,ror#24
	writemem

	mov r0,m6502_x,lsr#24
	and r0,r0,m6502_a,lsr#24
	strb r0,[r10,#m6502_s]
	.endm

opSHX_ABS_Y	.macro
	ldrb addy,[m6502_pc],#1
	ldrb r1,[m6502_pc],#1
	adds addy,m6502_y,addy,lsl#24

	adc r0,r1,#0x01
	and r0,r0,m6502_x,lsr#24

	orrcc addy,addy,r1
	orrcs addy,addy,r0
	mov addy,addy,ror#24
	writemem
	.endm

opSHY_ABS_X	.macro
	ldrb addy,[m6502_pc],#1
	ldrb r1,[m6502_pc],#1
	adds addy,m6502_x,addy,lsl#24

	adc r0,r1,#0x01
	and r0,r0,m6502_y,lsr#24

	orrcc addy,addy,r1
	orrcs addy,addy,r0
	mov addy,addy,ror#24
	writemem
	.endm

opSLO	.macro
	readmem
	writemem						;@!! Crazy maniacs use this feature !!
	 add r0,r0,r0
	 orrs m6502_a,m6502_a,r0,lsl#24
	 mov m6502_nz,m6502_a,asr#24	;@NZ
	 orr cycles,cycles,#CYC_C		;@Prepare C
	 biccc cycles,cycles,#CYC_C		;@C
	writemem
	.endm

opSRE	.macro
	readmem
	writemem						;@!! Crazy maniacs use this feature !!
	movs r0,r0,lsr#1
	eor m6502_a,m6502_a,r0,lsl#24
	mov m6502_nz,m6502_a,asr#24		;@NZ
	orr cycles,cycles,#CYC_C		;@Prepare C
	biccc cycles,cycles,#CYC_C		;@C
	writemem
	.endm

opSTORE	.macro x
	mov r0,x,lsr#24
	writemem
	.endm



;----------------------------------------------------
;	END
