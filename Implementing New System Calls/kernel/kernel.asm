
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8f013103          	ld	sp,-1808(sp) # 800088f0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	8fe70713          	addi	a4,a4,-1794 # 80008950 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	fcc78793          	addi	a5,a5,-52 # 80006030 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc23f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dca78793          	addi	a5,a5,-566 # 80000e78 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	728080e7          	jalr	1832(ra) # 80002854 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	90650513          	addi	a0,a0,-1786 # 80010a90 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8f648493          	addi	s1,s1,-1802 # 80010a90 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	98690913          	addi	s2,s2,-1658 # 80010b28 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	2fc080e7          	jalr	764(ra) # 800024c4 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	e7e080e7          	jalr	-386(ra) # 80002054 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	5ec080e7          	jalr	1516(ra) # 800027fe <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	86a50513          	addi	a0,a0,-1942 # 80010a90 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	85450513          	addi	a0,a0,-1964 # 80010a90 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	8af72b23          	sw	a5,-1866(a4) # 80010b28 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	7c450513          	addi	a0,a0,1988 # 80010a90 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	5b8080e7          	jalr	1464(ra) # 800028aa <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	79650513          	addi	a0,a0,1942 # 80010a90 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	77270713          	addi	a4,a4,1906 # 80010a90 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	74878793          	addi	a5,a5,1864 # 80010a90 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7b27a783          	lw	a5,1970(a5) # 80010b28 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	70670713          	addi	a4,a4,1798 # 80010a90 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6f648493          	addi	s1,s1,1782 # 80010a90 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	6ba70713          	addi	a4,a4,1722 # 80010a90 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	74f72223          	sw	a5,1860(a4) # 80010b30 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	67e78793          	addi	a5,a5,1662 # 80010a90 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6ec7ab23          	sw	a2,1782(a5) # 80010b2c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6ea50513          	addi	a0,a0,1770 # 80010b28 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	c72080e7          	jalr	-910(ra) # 800020b8 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	63050513          	addi	a0,a0,1584 # 80010a90 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	fb078793          	addi	a5,a5,-80 # 80021428 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	6007a323          	sw	zero,1542(a5) # 80010b50 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	38f72923          	sw	a5,914(a4) # 80008910 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	596dad83          	lw	s11,1430(s11) # 80010b50 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	54050513          	addi	a0,a0,1344 # 80010b38 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	3e250513          	addi	a0,a0,994 # 80010b38 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	52c080e7          	jalr	1324(ra) # 80000c8a <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	3c648493          	addi	s1,s1,966 # 80010b38 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	3c2080e7          	jalr	962(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	38650513          	addi	a0,a0,902 # 80010b58 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	36c080e7          	jalr	876(ra) # 80000b46 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	394080e7          	jalr	916(ra) # 80000b8a <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	1127a783          	lw	a5,274(a5) # 80008910 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	406080e7          	jalr	1030(ra) # 80000c2a <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	0e27b783          	ld	a5,226(a5) # 80008918 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	0e273703          	ld	a4,226(a4) # 80008920 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	2f8a0a13          	addi	s4,s4,760 # 80010b58 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	0b048493          	addi	s1,s1,176 # 80008918 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	0b098993          	addi	s3,s3,176 # 80008920 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	826080e7          	jalr	-2010(ra) # 800020b8 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	28a50513          	addi	a0,a0,650 # 80010b58 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	0327a783          	lw	a5,50(a5) # 80008910 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	03873703          	ld	a4,56(a4) # 80008920 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	0287b783          	ld	a5,40(a5) # 80008918 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	25c98993          	addi	s3,s3,604 # 80010b58 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	01448493          	addi	s1,s1,20 # 80008918 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	01490913          	addi	s2,s2,20 # 80008920 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00001097          	auipc	ra,0x1
    80000920:	738080e7          	jalr	1848(ra) # 80002054 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	22648493          	addi	s1,s1,550 # 80010b58 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	fce7bd23          	sd	a4,-38(a5) # 80008920 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	332080e7          	jalr	818(ra) # 80000c8a <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	19c48493          	addi	s1,s1,412 # 80010b58 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00022797          	auipc	a5,0x22
    80000a02:	bc278793          	addi	a5,a5,-1086 # 800225c0 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	17290913          	addi	s2,s2,370 # 80010b90 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	0d650513          	addi	a0,a0,214 # 80010b90 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00022517          	auipc	a0,0x22
    80000ad2:	af250513          	addi	a0,a0,-1294 # 800225c0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	0a048493          	addi	s1,s1,160 # 80010b90 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	08850513          	addi	a0,a0,136 # 80010b90 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	05c50513          	addi	a0,a0,92 # 80010b90 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	fff6c793          	not	a5,a3
    80000e0c:	9fb9                	addw	a5,a5,a4
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	aa070713          	addi	a4,a4,-1376 # 80008928 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	b2c080e7          	jalr	-1236(ra) # 800029ea <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	1aa080e7          	jalr	426(ra) # 80006070 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	fd4080e7          	jalr	-44(ra) # 80001ea2 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88a080e7          	jalr	-1910(ra) # 80000768 <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67a080e7          	jalr	1658(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	a8c080e7          	jalr	-1396(ra) # 800029c2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	aac080e7          	jalr	-1364(ra) # 800029ea <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	114080e7          	jalr	276(ra) # 8000605a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	122080e7          	jalr	290(ra) # 80006070 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	2be080e7          	jalr	702(ra) # 80003214 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	962080e7          	jalr	-1694(ra) # 800038c0 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	900080e7          	jalr	-1792(ra) # 80004866 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	20a080e7          	jalr	522(ra) # 80006178 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d0e080e7          	jalr	-754(ra) # 80001c84 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	9af72223          	sw	a5,-1628(a4) # 80008928 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9987b783          	ld	a5,-1640(a5) # 80008930 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55a080e7          	jalr	1370(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	00a7d513          	srli	a0,a5,0xa
    80001096:	0532                	slli	a0,a0,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	77fd                	lui	a5,0xfffff
    800010bc:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	15fd                	addi	a1,a1,-1
    800010c2:	00c589b3          	add	s3,a1,a2
    800010c6:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010ca:	8952                	mv	s2,s4
    800010cc:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	434080e7          	jalr	1076(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	6ca7be23          	sd	a0,1756(a5) # 80008930 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28c080e7          	jalr	652(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6cc080e7          	jalr	1740(ra) # 800009ea <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	17e080e7          	jalr	382(ra) # 8000053e <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	767d                	lui	a2,0xfffff
    800013e4:	8f71                	and	a4,a4,a2
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff1                	and	a5,a5,a2
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6985                	lui	s3,0x1
    8000142e:	19fd                	addi	s3,s3,-1
    80001430:	95ce                	add	a1,a1,s3
    80001432:	79fd                	lui	s3,0xfffff
    80001434:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	54a080e7          	jalr	1354(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a821                	j	800014f4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014e0:	0532                	slli	a0,a0,0xc
    800014e2:	00000097          	auipc	ra,0x0
    800014e6:	fe0080e7          	jalr	-32(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ea:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ee:	04a1                	addi	s1,s1,8
    800014f0:	03248163          	beq	s1,s2,80001512 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014f4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	00f57793          	andi	a5,a0,15
    800014fa:	ff3782e3          	beq	a5,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014fe:	8905                	andi	a0,a0,1
    80001500:	d57d                	beqz	a0,800014ee <freewalk+0x2c>
      panic("freewalk: leaf");
    80001502:	00007517          	auipc	a0,0x7
    80001506:	c7650513          	addi	a0,a0,-906 # 80008178 <digits+0x138>
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	034080e7          	jalr	52(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001512:	8552                	mv	a0,s4
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	4d6080e7          	jalr	1238(ra) # 800009ea <kfree>
}
    8000151c:	70a2                	ld	ra,40(sp)
    8000151e:	7402                	ld	s0,32(sp)
    80001520:	64e2                	ld	s1,24(sp)
    80001522:	6942                	ld	s2,16(sp)
    80001524:	69a2                	ld	s3,8(sp)
    80001526:	6a02                	ld	s4,0(sp)
    80001528:	6145                	addi	sp,sp,48
    8000152a:	8082                	ret

000000008000152c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152c:	1101                	addi	sp,sp,-32
    8000152e:	ec06                	sd	ra,24(sp)
    80001530:	e822                	sd	s0,16(sp)
    80001532:	e426                	sd	s1,8(sp)
    80001534:	1000                	addi	s0,sp,32
    80001536:	84aa                	mv	s1,a0
  if(sz > 0)
    80001538:	e999                	bnez	a1,8000154e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153a:	8526                	mv	a0,s1
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	f86080e7          	jalr	-122(ra) # 800014c2 <freewalk>
}
    80001544:	60e2                	ld	ra,24(sp)
    80001546:	6442                	ld	s0,16(sp)
    80001548:	64a2                	ld	s1,8(sp)
    8000154a:	6105                	addi	sp,sp,32
    8000154c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000154e:	6605                	lui	a2,0x1
    80001550:	167d                	addi	a2,a2,-1
    80001552:	962e                	add	a2,a2,a1
    80001554:	4685                	li	a3,1
    80001556:	8231                	srli	a2,a2,0xc
    80001558:	4581                	li	a1,0
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	d0a080e7          	jalr	-758(ra) # 80001264 <uvmunmap>
    80001562:	bfe1                	j	8000153a <uvmfree+0xe>

0000000080001564 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001564:	c679                	beqz	a2,80001632 <uvmcopy+0xce>
{
    80001566:	715d                	addi	sp,sp,-80
    80001568:	e486                	sd	ra,72(sp)
    8000156a:	e0a2                	sd	s0,64(sp)
    8000156c:	fc26                	sd	s1,56(sp)
    8000156e:	f84a                	sd	s2,48(sp)
    80001570:	f44e                	sd	s3,40(sp)
    80001572:	f052                	sd	s4,32(sp)
    80001574:	ec56                	sd	s5,24(sp)
    80001576:	e85a                	sd	s6,16(sp)
    80001578:	e45e                	sd	s7,8(sp)
    8000157a:	0880                	addi	s0,sp,80
    8000157c:	8b2a                	mv	s6,a0
    8000157e:	8aae                	mv	s5,a1
    80001580:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001582:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001584:	4601                	li	a2,0
    80001586:	85ce                	mv	a1,s3
    80001588:	855a                	mv	a0,s6
    8000158a:	00000097          	auipc	ra,0x0
    8000158e:	a2c080e7          	jalr	-1492(ra) # 80000fb6 <walk>
    80001592:	c531                	beqz	a0,800015de <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001594:	6118                	ld	a4,0(a0)
    80001596:	00177793          	andi	a5,a4,1
    8000159a:	cbb1                	beqz	a5,800015ee <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000159c:	00a75593          	srli	a1,a4,0xa
    800015a0:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a4:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015a8:	fffff097          	auipc	ra,0xfffff
    800015ac:	53e080e7          	jalr	1342(ra) # 80000ae6 <kalloc>
    800015b0:	892a                	mv	s2,a0
    800015b2:	c939                	beqz	a0,80001608 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b4:	6605                	lui	a2,0x1
    800015b6:	85de                	mv	a1,s7
    800015b8:	fffff097          	auipc	ra,0xfffff
    800015bc:	776080e7          	jalr	1910(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c0:	8726                	mv	a4,s1
    800015c2:	86ca                	mv	a3,s2
    800015c4:	6605                	lui	a2,0x1
    800015c6:	85ce                	mv	a1,s3
    800015c8:	8556                	mv	a0,s5
    800015ca:	00000097          	auipc	ra,0x0
    800015ce:	ad4080e7          	jalr	-1324(ra) # 8000109e <mappages>
    800015d2:	e515                	bnez	a0,800015fe <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d4:	6785                	lui	a5,0x1
    800015d6:	99be                	add	s3,s3,a5
    800015d8:	fb49e6e3          	bltu	s3,s4,80001584 <uvmcopy+0x20>
    800015dc:	a081                	j	8000161c <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015de:	00007517          	auipc	a0,0x7
    800015e2:	baa50513          	addi	a0,a0,-1110 # 80008188 <digits+0x148>
    800015e6:	fffff097          	auipc	ra,0xfffff
    800015ea:	f58080e7          	jalr	-168(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015ee:	00007517          	auipc	a0,0x7
    800015f2:	bba50513          	addi	a0,a0,-1094 # 800081a8 <digits+0x168>
    800015f6:	fffff097          	auipc	ra,0xfffff
    800015fa:	f48080e7          	jalr	-184(ra) # 8000053e <panic>
      kfree(mem);
    800015fe:	854a                	mv	a0,s2
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	3ea080e7          	jalr	1002(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001608:	4685                	li	a3,1
    8000160a:	00c9d613          	srli	a2,s3,0xc
    8000160e:	4581                	li	a1,0
    80001610:	8556                	mv	a0,s5
    80001612:	00000097          	auipc	ra,0x0
    80001616:	c52080e7          	jalr	-942(ra) # 80001264 <uvmunmap>
  return -1;
    8000161a:	557d                	li	a0,-1
}
    8000161c:	60a6                	ld	ra,72(sp)
    8000161e:	6406                	ld	s0,64(sp)
    80001620:	74e2                	ld	s1,56(sp)
    80001622:	7942                	ld	s2,48(sp)
    80001624:	79a2                	ld	s3,40(sp)
    80001626:	7a02                	ld	s4,32(sp)
    80001628:	6ae2                	ld	s5,24(sp)
    8000162a:	6b42                	ld	s6,16(sp)
    8000162c:	6ba2                	ld	s7,8(sp)
    8000162e:	6161                	addi	sp,sp,80
    80001630:	8082                	ret
  return 0;
    80001632:	4501                	li	a0,0
}
    80001634:	8082                	ret

0000000080001636 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001636:	1141                	addi	sp,sp,-16
    80001638:	e406                	sd	ra,8(sp)
    8000163a:	e022                	sd	s0,0(sp)
    8000163c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000163e:	4601                	li	a2,0
    80001640:	00000097          	auipc	ra,0x0
    80001644:	976080e7          	jalr	-1674(ra) # 80000fb6 <walk>
  if(pte == 0)
    80001648:	c901                	beqz	a0,80001658 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164a:	611c                	ld	a5,0(a0)
    8000164c:	9bbd                	andi	a5,a5,-17
    8000164e:	e11c                	sd	a5,0(a0)
}
    80001650:	60a2                	ld	ra,8(sp)
    80001652:	6402                	ld	s0,0(sp)
    80001654:	0141                	addi	sp,sp,16
    80001656:	8082                	ret
    panic("uvmclear");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b7050513          	addi	a0,a0,-1168 # 800081c8 <digits+0x188>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	ede080e7          	jalr	-290(ra) # 8000053e <panic>

0000000080001668 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001668:	c6bd                	beqz	a3,800016d6 <copyout+0x6e>
{
    8000166a:	715d                	addi	sp,sp,-80
    8000166c:	e486                	sd	ra,72(sp)
    8000166e:	e0a2                	sd	s0,64(sp)
    80001670:	fc26                	sd	s1,56(sp)
    80001672:	f84a                	sd	s2,48(sp)
    80001674:	f44e                	sd	s3,40(sp)
    80001676:	f052                	sd	s4,32(sp)
    80001678:	ec56                	sd	s5,24(sp)
    8000167a:	e85a                	sd	s6,16(sp)
    8000167c:	e45e                	sd	s7,8(sp)
    8000167e:	e062                	sd	s8,0(sp)
    80001680:	0880                	addi	s0,sp,80
    80001682:	8b2a                	mv	s6,a0
    80001684:	8c2e                	mv	s8,a1
    80001686:	8a32                	mv	s4,a2
    80001688:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000168c:	6a85                	lui	s5,0x1
    8000168e:	a015                	j	800016b2 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001690:	9562                	add	a0,a0,s8
    80001692:	0004861b          	sext.w	a2,s1
    80001696:	85d2                	mv	a1,s4
    80001698:	41250533          	sub	a0,a0,s2
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	692080e7          	jalr	1682(ra) # 80000d2e <memmove>

    len -= n;
    800016a4:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a8:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016aa:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ae:	02098263          	beqz	s3,800016d2 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b6:	85ca                	mv	a1,s2
    800016b8:	855a                	mv	a0,s6
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	9a2080e7          	jalr	-1630(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c2:	cd01                	beqz	a0,800016da <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c4:	418904b3          	sub	s1,s2,s8
    800016c8:	94d6                	add	s1,s1,s5
    if(n > len)
    800016ca:	fc99f3e3          	bgeu	s3,s1,80001690 <copyout+0x28>
    800016ce:	84ce                	mv	s1,s3
    800016d0:	b7c1                	j	80001690 <copyout+0x28>
  }
  return 0;
    800016d2:	4501                	li	a0,0
    800016d4:	a021                	j	800016dc <copyout+0x74>
    800016d6:	4501                	li	a0,0
}
    800016d8:	8082                	ret
      return -1;
    800016da:	557d                	li	a0,-1
}
    800016dc:	60a6                	ld	ra,72(sp)
    800016de:	6406                	ld	s0,64(sp)
    800016e0:	74e2                	ld	s1,56(sp)
    800016e2:	7942                	ld	s2,48(sp)
    800016e4:	79a2                	ld	s3,40(sp)
    800016e6:	7a02                	ld	s4,32(sp)
    800016e8:	6ae2                	ld	s5,24(sp)
    800016ea:	6b42                	ld	s6,16(sp)
    800016ec:	6ba2                	ld	s7,8(sp)
    800016ee:	6c02                	ld	s8,0(sp)
    800016f0:	6161                	addi	sp,sp,80
    800016f2:	8082                	ret

00000000800016f4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f4:	caa5                	beqz	a3,80001764 <copyin+0x70>
{
    800016f6:	715d                	addi	sp,sp,-80
    800016f8:	e486                	sd	ra,72(sp)
    800016fa:	e0a2                	sd	s0,64(sp)
    800016fc:	fc26                	sd	s1,56(sp)
    800016fe:	f84a                	sd	s2,48(sp)
    80001700:	f44e                	sd	s3,40(sp)
    80001702:	f052                	sd	s4,32(sp)
    80001704:	ec56                	sd	s5,24(sp)
    80001706:	e85a                	sd	s6,16(sp)
    80001708:	e45e                	sd	s7,8(sp)
    8000170a:	e062                	sd	s8,0(sp)
    8000170c:	0880                	addi	s0,sp,80
    8000170e:	8b2a                	mv	s6,a0
    80001710:	8a2e                	mv	s4,a1
    80001712:	8c32                	mv	s8,a2
    80001714:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001716:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001718:	6a85                	lui	s5,0x1
    8000171a:	a01d                	j	80001740 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000171c:	018505b3          	add	a1,a0,s8
    80001720:	0004861b          	sext.w	a2,s1
    80001724:	412585b3          	sub	a1,a1,s2
    80001728:	8552                	mv	a0,s4
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	604080e7          	jalr	1540(ra) # 80000d2e <memmove>

    len -= n;
    80001732:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001736:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001738:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173c:	02098263          	beqz	s3,80001760 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001740:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001744:	85ca                	mv	a1,s2
    80001746:	855a                	mv	a0,s6
    80001748:	00000097          	auipc	ra,0x0
    8000174c:	914080e7          	jalr	-1772(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001750:	cd01                	beqz	a0,80001768 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001752:	418904b3          	sub	s1,s2,s8
    80001756:	94d6                	add	s1,s1,s5
    if(n > len)
    80001758:	fc99f2e3          	bgeu	s3,s1,8000171c <copyin+0x28>
    8000175c:	84ce                	mv	s1,s3
    8000175e:	bf7d                	j	8000171c <copyin+0x28>
  }
  return 0;
    80001760:	4501                	li	a0,0
    80001762:	a021                	j	8000176a <copyin+0x76>
    80001764:	4501                	li	a0,0
}
    80001766:	8082                	ret
      return -1;
    80001768:	557d                	li	a0,-1
}
    8000176a:	60a6                	ld	ra,72(sp)
    8000176c:	6406                	ld	s0,64(sp)
    8000176e:	74e2                	ld	s1,56(sp)
    80001770:	7942                	ld	s2,48(sp)
    80001772:	79a2                	ld	s3,40(sp)
    80001774:	7a02                	ld	s4,32(sp)
    80001776:	6ae2                	ld	s5,24(sp)
    80001778:	6b42                	ld	s6,16(sp)
    8000177a:	6ba2                	ld	s7,8(sp)
    8000177c:	6c02                	ld	s8,0(sp)
    8000177e:	6161                	addi	sp,sp,80
    80001780:	8082                	ret

0000000080001782 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001782:	c6c5                	beqz	a3,8000182a <copyinstr+0xa8>
{
    80001784:	715d                	addi	sp,sp,-80
    80001786:	e486                	sd	ra,72(sp)
    80001788:	e0a2                	sd	s0,64(sp)
    8000178a:	fc26                	sd	s1,56(sp)
    8000178c:	f84a                	sd	s2,48(sp)
    8000178e:	f44e                	sd	s3,40(sp)
    80001790:	f052                	sd	s4,32(sp)
    80001792:	ec56                	sd	s5,24(sp)
    80001794:	e85a                	sd	s6,16(sp)
    80001796:	e45e                	sd	s7,8(sp)
    80001798:	0880                	addi	s0,sp,80
    8000179a:	8a2a                	mv	s4,a0
    8000179c:	8b2e                	mv	s6,a1
    8000179e:	8bb2                	mv	s7,a2
    800017a0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a4:	6985                	lui	s3,0x1
    800017a6:	a035                	j	800017d2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017ac:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ae:	0017b793          	seqz	a5,a5
    800017b2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b6:	60a6                	ld	ra,72(sp)
    800017b8:	6406                	ld	s0,64(sp)
    800017ba:	74e2                	ld	s1,56(sp)
    800017bc:	7942                	ld	s2,48(sp)
    800017be:	79a2                	ld	s3,40(sp)
    800017c0:	7a02                	ld	s4,32(sp)
    800017c2:	6ae2                	ld	s5,24(sp)
    800017c4:	6b42                	ld	s6,16(sp)
    800017c6:	6ba2                	ld	s7,8(sp)
    800017c8:	6161                	addi	sp,sp,80
    800017ca:	8082                	ret
    srcva = va0 + PGSIZE;
    800017cc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d0:	c8a9                	beqz	s1,80001822 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017d2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d6:	85ca                	mv	a1,s2
    800017d8:	8552                	mv	a0,s4
    800017da:	00000097          	auipc	ra,0x0
    800017de:	882080e7          	jalr	-1918(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e2:	c131                	beqz	a0,80001826 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017e4:	41790833          	sub	a6,s2,s7
    800017e8:	984e                	add	a6,a6,s3
    if(n > max)
    800017ea:	0104f363          	bgeu	s1,a6,800017f0 <copyinstr+0x6e>
    800017ee:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f0:	955e                	add	a0,a0,s7
    800017f2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f6:	fc080be3          	beqz	a6,800017cc <copyinstr+0x4a>
    800017fa:	985a                	add	a6,a6,s6
    800017fc:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fe:	41650633          	sub	a2,a0,s6
    80001802:	14fd                	addi	s1,s1,-1
    80001804:	9b26                	add	s6,s6,s1
    80001806:	00f60733          	add	a4,a2,a5
    8000180a:	00074703          	lbu	a4,0(a4)
    8000180e:	df49                	beqz	a4,800017a8 <copyinstr+0x26>
        *dst = *p;
    80001810:	00e78023          	sb	a4,0(a5)
      --max;
    80001814:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001818:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181a:	ff0796e3          	bne	a5,a6,80001806 <copyinstr+0x84>
      dst++;
    8000181e:	8b42                	mv	s6,a6
    80001820:	b775                	j	800017cc <copyinstr+0x4a>
    80001822:	4781                	li	a5,0
    80001824:	b769                	j	800017ae <copyinstr+0x2c>
      return -1;
    80001826:	557d                	li	a0,-1
    80001828:	b779                	j	800017b6 <copyinstr+0x34>
  int got_null = 0;
    8000182a:	4781                	li	a5,0
  if(got_null){
    8000182c:	0017b793          	seqz	a5,a5
    80001830:	40f00533          	neg	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	79448493          	addi	s1,s1,1940 # 80010fe0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1
    80001864:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	00016a17          	auipc	s4,0x16
    8000186a:	97aa0a13          	addi	s4,s4,-1670 # 800171e0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if(pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	858d                	srai	a1,a1,0x3
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a0:	18848493          	addi	s1,s1,392
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7a080e7          	jalr	-902(ra) # 8000053e <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	2c850513          	addi	a0,a0,712 # 80010bb0 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	2c850513          	addi	a0,a0,712 # 80010bc8 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	6d048493          	addi	s1,s1,1744 # 80010fe0 <proc>
      initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1
    80001930:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	00016997          	auipc	s3,0x16
    80001936:	8ae98993          	addi	s3,s3,-1874 # 800171e0 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	878d                	srai	a5,a5,0x3
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001964:	18848493          	addi	s1,s1,392
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	24450513          	addi	a0,a0,580 # 80010be0 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	1ec70713          	addi	a4,a4,492 # 80010bb0 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first) {
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	ea47a783          	lw	a5,-348(a5) # 800088a0 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	ffc080e7          	jalr	-4(ra) # 80002a02 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e807a523          	sw	zero,-374(a5) # 800088a0 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	e20080e7          	jalr	-480(ra) # 80003840 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	17a90913          	addi	s2,s2,378 # 80010bb0 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e5c78793          	addi	a5,a5,-420 # 800088a4 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a52080e7          	jalr	-1454(ra) # 8000152c <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2c080e7          	jalr	-1492(ra) # 8000152c <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e2080e7          	jalr	-1566(ra) # 8000152c <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7c080e7          	jalr	-388(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	41e48493          	addi	s1,s1,1054 # 80010fe0 <proc>
    80001bca:	00015917          	auipc	s2,0x15
    80001bce:	61690913          	addi	s2,s2,1558 # 800171e0 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bea:	18848493          	addi	s1,s1,392
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a889                	j	80001c46 <allocproc+0x90>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	c131                	beqz	a0,80001c54 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c20:	c531                	beqz	a0,80001c6c <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06048513          	addi	a0,s1,96
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	60bc                	ld	a5,64(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f4bc                	sd	a5,104(s1)
}
    80001c46:	8526                	mv	a0,s1
    80001c48:	60e2                	ld	ra,24(sp)
    80001c4a:	6442                	ld	s0,16(sp)
    80001c4c:	64a2                	ld	s1,8(sp)
    80001c4e:	6902                	ld	s2,0(sp)
    80001c50:	6105                	addi	sp,sp,32
    80001c52:	8082                	ret
    freeproc(p);
    80001c54:	8526                	mv	a0,s1
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	f08080e7          	jalr	-248(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	02a080e7          	jalr	42(ra) # 80000c8a <release>
    return 0;
    80001c68:	84ca                	mv	s1,s2
    80001c6a:	bff1                	j	80001c46 <allocproc+0x90>
    freeproc(p);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	00000097          	auipc	ra,0x0
    80001c72:	ef0080e7          	jalr	-272(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	012080e7          	jalr	18(ra) # 80000c8a <release>
    return 0;
    80001c80:	84ca                	mv	s1,s2
    80001c82:	b7d1                	j	80001c46 <allocproc+0x90>

0000000080001c84 <userinit>:
{
    80001c84:	1101                	addi	sp,sp,-32
    80001c86:	ec06                	sd	ra,24(sp)
    80001c88:	e822                	sd	s0,16(sp)
    80001c8a:	e426                	sd	s1,8(sp)
    80001c8c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	f28080e7          	jalr	-216(ra) # 80001bb6 <allocproc>
    80001c96:	84aa                	mv	s1,a0
  initproc = p;
    80001c98:	00007797          	auipc	a5,0x7
    80001c9c:	caa7b023          	sd	a0,-864(a5) # 80008938 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ca0:	03400613          	li	a2,52
    80001ca4:	00007597          	auipc	a1,0x7
    80001ca8:	c0c58593          	addi	a1,a1,-1012 # 800088b0 <initcode>
    80001cac:	6928                	ld	a0,80(a0)
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	6a8080e7          	jalr	1704(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cb6:	6785                	lui	a5,0x1
    80001cb8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cba:	6cb8                	ld	a4,88(s1)
    80001cbc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc0:	6cb8                	ld	a4,88(s1)
    80001cc2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc4:	4641                	li	a2,16
    80001cc6:	00006597          	auipc	a1,0x6
    80001cca:	53a58593          	addi	a1,a1,1338 # 80008200 <digits+0x1c0>
    80001cce:	15848513          	addi	a0,s1,344
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	14a080e7          	jalr	330(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cda:	00006517          	auipc	a0,0x6
    80001cde:	53650513          	addi	a0,a0,1334 # 80008210 <digits+0x1d0>
    80001ce2:	00002097          	auipc	ra,0x2
    80001ce6:	580080e7          	jalr	1408(ra) # 80004262 <namei>
    80001cea:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cee:	478d                	li	a5,3
    80001cf0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	f96080e7          	jalr	-106(ra) # 80000c8a <release>
}
    80001cfc:	60e2                	ld	ra,24(sp)
    80001cfe:	6442                	ld	s0,16(sp)
    80001d00:	64a2                	ld	s1,8(sp)
    80001d02:	6105                	addi	sp,sp,32
    80001d04:	8082                	ret

0000000080001d06 <growproc>:
{
    80001d06:	1101                	addi	sp,sp,-32
    80001d08:	ec06                	sd	ra,24(sp)
    80001d0a:	e822                	sd	s0,16(sp)
    80001d0c:	e426                	sd	s1,8(sp)
    80001d0e:	e04a                	sd	s2,0(sp)
    80001d10:	1000                	addi	s0,sp,32
    80001d12:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	c98080e7          	jalr	-872(ra) # 800019ac <myproc>
    80001d1c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d1e:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d20:	01204c63          	bgtz	s2,80001d38 <growproc+0x32>
  } else if(n < 0){
    80001d24:	02094663          	bltz	s2,80001d50 <growproc+0x4a>
  p->sz = sz;
    80001d28:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d2a:	4501                	li	a0,0
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6902                	ld	s2,0(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d38:	4691                	li	a3,4
    80001d3a:	00b90633          	add	a2,s2,a1
    80001d3e:	6928                	ld	a0,80(a0)
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	6d0080e7          	jalr	1744(ra) # 80001410 <uvmalloc>
    80001d48:	85aa                	mv	a1,a0
    80001d4a:	fd79                	bnez	a0,80001d28 <growproc+0x22>
      return -1;
    80001d4c:	557d                	li	a0,-1
    80001d4e:	bff9                	j	80001d2c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d50:	00b90633          	add	a2,s2,a1
    80001d54:	6928                	ld	a0,80(a0)
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	672080e7          	jalr	1650(ra) # 800013c8 <uvmdealloc>
    80001d5e:	85aa                	mv	a1,a0
    80001d60:	b7e1                	j	80001d28 <growproc+0x22>

0000000080001d62 <fork>:
{
    80001d62:	7139                	addi	sp,sp,-64
    80001d64:	fc06                	sd	ra,56(sp)
    80001d66:	f822                	sd	s0,48(sp)
    80001d68:	f426                	sd	s1,40(sp)
    80001d6a:	f04a                	sd	s2,32(sp)
    80001d6c:	ec4e                	sd	s3,24(sp)
    80001d6e:	e852                	sd	s4,16(sp)
    80001d70:	e456                	sd	s5,8(sp)
    80001d72:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d74:	00000097          	auipc	ra,0x0
    80001d78:	c38080e7          	jalr	-968(ra) # 800019ac <myproc>
    80001d7c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d7e:	00000097          	auipc	ra,0x0
    80001d82:	e38080e7          	jalr	-456(ra) # 80001bb6 <allocproc>
    80001d86:	10050c63          	beqz	a0,80001e9e <fork+0x13c>
    80001d8a:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d8c:	048ab603          	ld	a2,72(s5)
    80001d90:	692c                	ld	a1,80(a0)
    80001d92:	050ab503          	ld	a0,80(s5)
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	7ce080e7          	jalr	1998(ra) # 80001564 <uvmcopy>
    80001d9e:	04054863          	bltz	a0,80001dee <fork+0x8c>
  np->sz = p->sz;
    80001da2:	048ab783          	ld	a5,72(s5)
    80001da6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001daa:	058ab683          	ld	a3,88(s5)
    80001dae:	87b6                	mv	a5,a3
    80001db0:	058a3703          	ld	a4,88(s4)
    80001db4:	12068693          	addi	a3,a3,288
    80001db8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dbc:	6788                	ld	a0,8(a5)
    80001dbe:	6b8c                	ld	a1,16(a5)
    80001dc0:	6f90                	ld	a2,24(a5)
    80001dc2:	01073023          	sd	a6,0(a4)
    80001dc6:	e708                	sd	a0,8(a4)
    80001dc8:	eb0c                	sd	a1,16(a4)
    80001dca:	ef10                	sd	a2,24(a4)
    80001dcc:	02078793          	addi	a5,a5,32
    80001dd0:	02070713          	addi	a4,a4,32
    80001dd4:	fed792e3          	bne	a5,a3,80001db8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001dd8:	058a3783          	ld	a5,88(s4)
    80001ddc:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001de0:	0d0a8493          	addi	s1,s5,208
    80001de4:	0d0a0913          	addi	s2,s4,208
    80001de8:	150a8993          	addi	s3,s5,336
    80001dec:	a00d                	j	80001e0e <fork+0xac>
    freeproc(np);
    80001dee:	8552                	mv	a0,s4
    80001df0:	00000097          	auipc	ra,0x0
    80001df4:	d6e080e7          	jalr	-658(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001df8:	8552                	mv	a0,s4
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	e90080e7          	jalr	-368(ra) # 80000c8a <release>
    return -1;
    80001e02:	597d                	li	s2,-1
    80001e04:	a059                	j	80001e8a <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e06:	04a1                	addi	s1,s1,8
    80001e08:	0921                	addi	s2,s2,8
    80001e0a:	01348b63          	beq	s1,s3,80001e20 <fork+0xbe>
    if(p->ofile[i])
    80001e0e:	6088                	ld	a0,0(s1)
    80001e10:	d97d                	beqz	a0,80001e06 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e12:	00003097          	auipc	ra,0x3
    80001e16:	ae6080e7          	jalr	-1306(ra) # 800048f8 <filedup>
    80001e1a:	00a93023          	sd	a0,0(s2)
    80001e1e:	b7e5                	j	80001e06 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e20:	150ab503          	ld	a0,336(s5)
    80001e24:	00002097          	auipc	ra,0x2
    80001e28:	c5a080e7          	jalr	-934(ra) # 80003a7e <idup>
    80001e2c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e30:	4641                	li	a2,16
    80001e32:	158a8593          	addi	a1,s5,344
    80001e36:	158a0513          	addi	a0,s4,344
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	fe2080e7          	jalr	-30(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e42:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e46:	8552                	mv	a0,s4
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	e42080e7          	jalr	-446(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e50:	0000f497          	auipc	s1,0xf
    80001e54:	d7848493          	addi	s1,s1,-648 # 80010bc8 <wait_lock>
    80001e58:	8526                	mv	a0,s1
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	d7c080e7          	jalr	-644(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e62:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e66:	8526                	mv	a0,s1
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	e22080e7          	jalr	-478(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e70:	8552                	mv	a0,s4
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	d64080e7          	jalr	-668(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e7a:	478d                	li	a5,3
    80001e7c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e80:	8552                	mv	a0,s4
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	e08080e7          	jalr	-504(ra) # 80000c8a <release>
}
    80001e8a:	854a                	mv	a0,s2
    80001e8c:	70e2                	ld	ra,56(sp)
    80001e8e:	7442                	ld	s0,48(sp)
    80001e90:	74a2                	ld	s1,40(sp)
    80001e92:	7902                	ld	s2,32(sp)
    80001e94:	69e2                	ld	s3,24(sp)
    80001e96:	6a42                	ld	s4,16(sp)
    80001e98:	6aa2                	ld	s5,8(sp)
    80001e9a:	6121                	addi	sp,sp,64
    80001e9c:	8082                	ret
    return -1;
    80001e9e:	597d                	li	s2,-1
    80001ea0:	b7ed                	j	80001e8a <fork+0x128>

0000000080001ea2 <scheduler>:
{
    80001ea2:	7139                	addi	sp,sp,-64
    80001ea4:	fc06                	sd	ra,56(sp)
    80001ea6:	f822                	sd	s0,48(sp)
    80001ea8:	f426                	sd	s1,40(sp)
    80001eaa:	f04a                	sd	s2,32(sp)
    80001eac:	ec4e                	sd	s3,24(sp)
    80001eae:	e852                	sd	s4,16(sp)
    80001eb0:	e456                	sd	s5,8(sp)
    80001eb2:	e05a                	sd	s6,0(sp)
    80001eb4:	0080                	addi	s0,sp,64
    80001eb6:	8792                	mv	a5,tp
  int id = r_tp();
    80001eb8:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001eba:	00779a93          	slli	s5,a5,0x7
    80001ebe:	0000f717          	auipc	a4,0xf
    80001ec2:	cf270713          	addi	a4,a4,-782 # 80010bb0 <pid_lock>
    80001ec6:	9756                	add	a4,a4,s5
    80001ec8:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001ecc:	0000f717          	auipc	a4,0xf
    80001ed0:	d1c70713          	addi	a4,a4,-740 # 80010be8 <cpus+0x8>
    80001ed4:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001ed6:	498d                	li	s3,3
        p->state = RUNNING;
    80001ed8:	4b11                	li	s6,4
        c->proc = p;
    80001eda:	079e                	slli	a5,a5,0x7
    80001edc:	0000fa17          	auipc	s4,0xf
    80001ee0:	cd4a0a13          	addi	s4,s4,-812 # 80010bb0 <pid_lock>
    80001ee4:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ee6:	00015917          	auipc	s2,0x15
    80001eea:	2fa90913          	addi	s2,s2,762 # 800171e0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001eee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ef2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ef6:	10079073          	csrw	sstatus,a5
    80001efa:	0000f497          	auipc	s1,0xf
    80001efe:	0e648493          	addi	s1,s1,230 # 80010fe0 <proc>
    80001f02:	a811                	j	80001f16 <scheduler+0x74>
      release(&p->lock);
    80001f04:	8526                	mv	a0,s1
    80001f06:	fffff097          	auipc	ra,0xfffff
    80001f0a:	d84080e7          	jalr	-636(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f0e:	18848493          	addi	s1,s1,392
    80001f12:	fd248ee3          	beq	s1,s2,80001eee <scheduler+0x4c>
      acquire(&p->lock);
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	cbe080e7          	jalr	-834(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001f20:	4c9c                	lw	a5,24(s1)
    80001f22:	ff3791e3          	bne	a5,s3,80001f04 <scheduler+0x62>
        p->state = RUNNING;
    80001f26:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f2a:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f2e:	06048593          	addi	a1,s1,96
    80001f32:	8556                	mv	a0,s5
    80001f34:	00001097          	auipc	ra,0x1
    80001f38:	a24080e7          	jalr	-1500(ra) # 80002958 <swtch>
        c->proc = 0;
    80001f3c:	020a3823          	sd	zero,48(s4)
    80001f40:	b7d1                	j	80001f04 <scheduler+0x62>

0000000080001f42 <sched>:
{
    80001f42:	7179                	addi	sp,sp,-48
    80001f44:	f406                	sd	ra,40(sp)
    80001f46:	f022                	sd	s0,32(sp)
    80001f48:	ec26                	sd	s1,24(sp)
    80001f4a:	e84a                	sd	s2,16(sp)
    80001f4c:	e44e                	sd	s3,8(sp)
    80001f4e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f50:	00000097          	auipc	ra,0x0
    80001f54:	a5c080e7          	jalr	-1444(ra) # 800019ac <myproc>
    80001f58:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f5a:	fffff097          	auipc	ra,0xfffff
    80001f5e:	c02080e7          	jalr	-1022(ra) # 80000b5c <holding>
    80001f62:	c93d                	beqz	a0,80001fd8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f64:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001f66:	2781                	sext.w	a5,a5
    80001f68:	079e                	slli	a5,a5,0x7
    80001f6a:	0000f717          	auipc	a4,0xf
    80001f6e:	c4670713          	addi	a4,a4,-954 # 80010bb0 <pid_lock>
    80001f72:	97ba                	add	a5,a5,a4
    80001f74:	0a87a703          	lw	a4,168(a5)
    80001f78:	4785                	li	a5,1
    80001f7a:	06f71763          	bne	a4,a5,80001fe8 <sched+0xa6>
  if(p->state == RUNNING)
    80001f7e:	4c98                	lw	a4,24(s1)
    80001f80:	4791                	li	a5,4
    80001f82:	06f70b63          	beq	a4,a5,80001ff8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f86:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001f8a:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001f8c:	efb5                	bnez	a5,80002008 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f8e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001f90:	0000f917          	auipc	s2,0xf
    80001f94:	c2090913          	addi	s2,s2,-992 # 80010bb0 <pid_lock>
    80001f98:	2781                	sext.w	a5,a5
    80001f9a:	079e                	slli	a5,a5,0x7
    80001f9c:	97ca                	add	a5,a5,s2
    80001f9e:	0ac7a983          	lw	s3,172(a5)
    80001fa2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fa4:	2781                	sext.w	a5,a5
    80001fa6:	079e                	slli	a5,a5,0x7
    80001fa8:	0000f597          	auipc	a1,0xf
    80001fac:	c4058593          	addi	a1,a1,-960 # 80010be8 <cpus+0x8>
    80001fb0:	95be                	add	a1,a1,a5
    80001fb2:	06048513          	addi	a0,s1,96
    80001fb6:	00001097          	auipc	ra,0x1
    80001fba:	9a2080e7          	jalr	-1630(ra) # 80002958 <swtch>
    80001fbe:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001fc0:	2781                	sext.w	a5,a5
    80001fc2:	079e                	slli	a5,a5,0x7
    80001fc4:	97ca                	add	a5,a5,s2
    80001fc6:	0b37a623          	sw	s3,172(a5)
}
    80001fca:	70a2                	ld	ra,40(sp)
    80001fcc:	7402                	ld	s0,32(sp)
    80001fce:	64e2                	ld	s1,24(sp)
    80001fd0:	6942                	ld	s2,16(sp)
    80001fd2:	69a2                	ld	s3,8(sp)
    80001fd4:	6145                	addi	sp,sp,48
    80001fd6:	8082                	ret
    panic("sched p->lock");
    80001fd8:	00006517          	auipc	a0,0x6
    80001fdc:	24050513          	addi	a0,a0,576 # 80008218 <digits+0x1d8>
    80001fe0:	ffffe097          	auipc	ra,0xffffe
    80001fe4:	55e080e7          	jalr	1374(ra) # 8000053e <panic>
    panic("sched locks");
    80001fe8:	00006517          	auipc	a0,0x6
    80001fec:	24050513          	addi	a0,a0,576 # 80008228 <digits+0x1e8>
    80001ff0:	ffffe097          	auipc	ra,0xffffe
    80001ff4:	54e080e7          	jalr	1358(ra) # 8000053e <panic>
    panic("sched running");
    80001ff8:	00006517          	auipc	a0,0x6
    80001ffc:	24050513          	addi	a0,a0,576 # 80008238 <digits+0x1f8>
    80002000:	ffffe097          	auipc	ra,0xffffe
    80002004:	53e080e7          	jalr	1342(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002008:	00006517          	auipc	a0,0x6
    8000200c:	24050513          	addi	a0,a0,576 # 80008248 <digits+0x208>
    80002010:	ffffe097          	auipc	ra,0xffffe
    80002014:	52e080e7          	jalr	1326(ra) # 8000053e <panic>

0000000080002018 <yield>:
{
    80002018:	1101                	addi	sp,sp,-32
    8000201a:	ec06                	sd	ra,24(sp)
    8000201c:	e822                	sd	s0,16(sp)
    8000201e:	e426                	sd	s1,8(sp)
    80002020:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002022:	00000097          	auipc	ra,0x0
    80002026:	98a080e7          	jalr	-1654(ra) # 800019ac <myproc>
    8000202a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	baa080e7          	jalr	-1110(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002034:	478d                	li	a5,3
    80002036:	cc9c                	sw	a5,24(s1)
  sched();
    80002038:	00000097          	auipc	ra,0x0
    8000203c:	f0a080e7          	jalr	-246(ra) # 80001f42 <sched>
  release(&p->lock);
    80002040:	8526                	mv	a0,s1
    80002042:	fffff097          	auipc	ra,0xfffff
    80002046:	c48080e7          	jalr	-952(ra) # 80000c8a <release>
}
    8000204a:	60e2                	ld	ra,24(sp)
    8000204c:	6442                	ld	s0,16(sp)
    8000204e:	64a2                	ld	s1,8(sp)
    80002050:	6105                	addi	sp,sp,32
    80002052:	8082                	ret

0000000080002054 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002054:	7179                	addi	sp,sp,-48
    80002056:	f406                	sd	ra,40(sp)
    80002058:	f022                	sd	s0,32(sp)
    8000205a:	ec26                	sd	s1,24(sp)
    8000205c:	e84a                	sd	s2,16(sp)
    8000205e:	e44e                	sd	s3,8(sp)
    80002060:	1800                	addi	s0,sp,48
    80002062:	89aa                	mv	s3,a0
    80002064:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	946080e7          	jalr	-1722(ra) # 800019ac <myproc>
    8000206e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002070:	fffff097          	auipc	ra,0xfffff
    80002074:	b66080e7          	jalr	-1178(ra) # 80000bd6 <acquire>
  release(lk);
    80002078:	854a                	mv	a0,s2
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	c10080e7          	jalr	-1008(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002082:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002086:	4789                	li	a5,2
    80002088:	cc9c                	sw	a5,24(s1)

  sched();
    8000208a:	00000097          	auipc	ra,0x0
    8000208e:	eb8080e7          	jalr	-328(ra) # 80001f42 <sched>

  // Tidy up.
  p->chan = 0;
    80002092:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002096:	8526                	mv	a0,s1
    80002098:	fffff097          	auipc	ra,0xfffff
    8000209c:	bf2080e7          	jalr	-1038(ra) # 80000c8a <release>
  acquire(lk);
    800020a0:	854a                	mv	a0,s2
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	b34080e7          	jalr	-1228(ra) # 80000bd6 <acquire>
}
    800020aa:	70a2                	ld	ra,40(sp)
    800020ac:	7402                	ld	s0,32(sp)
    800020ae:	64e2                	ld	s1,24(sp)
    800020b0:	6942                	ld	s2,16(sp)
    800020b2:	69a2                	ld	s3,8(sp)
    800020b4:	6145                	addi	sp,sp,48
    800020b6:	8082                	ret

00000000800020b8 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020b8:	7139                	addi	sp,sp,-64
    800020ba:	fc06                	sd	ra,56(sp)
    800020bc:	f822                	sd	s0,48(sp)
    800020be:	f426                	sd	s1,40(sp)
    800020c0:	f04a                	sd	s2,32(sp)
    800020c2:	ec4e                	sd	s3,24(sp)
    800020c4:	e852                	sd	s4,16(sp)
    800020c6:	e456                	sd	s5,8(sp)
    800020c8:	0080                	addi	s0,sp,64
    800020ca:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800020cc:	0000f497          	auipc	s1,0xf
    800020d0:	f1448493          	addi	s1,s1,-236 # 80010fe0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800020d4:	4989                	li	s3,2
        p->state = RUNNABLE;
    800020d6:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800020d8:	00015917          	auipc	s2,0x15
    800020dc:	10890913          	addi	s2,s2,264 # 800171e0 <tickslock>
    800020e0:	a811                	j	800020f4 <wakeup+0x3c>
      }
      release(&p->lock);
    800020e2:	8526                	mv	a0,s1
    800020e4:	fffff097          	auipc	ra,0xfffff
    800020e8:	ba6080e7          	jalr	-1114(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020ec:	18848493          	addi	s1,s1,392
    800020f0:	03248663          	beq	s1,s2,8000211c <wakeup+0x64>
    if(p != myproc()){
    800020f4:	00000097          	auipc	ra,0x0
    800020f8:	8b8080e7          	jalr	-1864(ra) # 800019ac <myproc>
    800020fc:	fea488e3          	beq	s1,a0,800020ec <wakeup+0x34>
      acquire(&p->lock);
    80002100:	8526                	mv	a0,s1
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	ad4080e7          	jalr	-1324(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000210a:	4c9c                	lw	a5,24(s1)
    8000210c:	fd379be3          	bne	a5,s3,800020e2 <wakeup+0x2a>
    80002110:	709c                	ld	a5,32(s1)
    80002112:	fd4798e3          	bne	a5,s4,800020e2 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002116:	0154ac23          	sw	s5,24(s1)
    8000211a:	b7e1                	j	800020e2 <wakeup+0x2a>
    }
  }
}
    8000211c:	70e2                	ld	ra,56(sp)
    8000211e:	7442                	ld	s0,48(sp)
    80002120:	74a2                	ld	s1,40(sp)
    80002122:	7902                	ld	s2,32(sp)
    80002124:	69e2                	ld	s3,24(sp)
    80002126:	6a42                	ld	s4,16(sp)
    80002128:	6aa2                	ld	s5,8(sp)
    8000212a:	6121                	addi	sp,sp,64
    8000212c:	8082                	ret

000000008000212e <forkn>:
int forkn(int n, int *pids) {
    8000212e:	7119                	addi	sp,sp,-128
    80002130:	fc86                	sd	ra,120(sp)
    80002132:	f8a2                	sd	s0,112(sp)
    80002134:	f4a6                	sd	s1,104(sp)
    80002136:	f0ca                	sd	s2,96(sp)
    80002138:	ecce                	sd	s3,88(sp)
    8000213a:	e8d2                	sd	s4,80(sp)
    8000213c:	e4d6                	sd	s5,72(sp)
    8000213e:	e0da                	sd	s6,64(sp)
    80002140:	fc5e                	sd	s7,56(sp)
    80002142:	f862                	sd	s8,48(sp)
    80002144:	f466                	sd	s9,40(sp)
    80002146:	f06a                	sd	s10,32(sp)
    80002148:	ec6e                	sd	s11,24(sp)
    8000214a:	0100                	addi	s0,sp,128
    8000214c:	84aa                	mv	s1,a0
    8000214e:	8bae                	mv	s7,a1
    struct proc *p = myproc();
    80002150:	00000097          	auipc	ra,0x0
    80002154:	85c080e7          	jalr	-1956(ra) # 800019ac <myproc>
    80002158:	8aaa                	mv	s5,a0
    acquire(&wait_lock); // Ensure parent holds the lock before creating children
    8000215a:	0000f517          	auipc	a0,0xf
    8000215e:	a6e50513          	addi	a0,a0,-1426 # 80010bc8 <wait_lock>
    80002162:	fffff097          	auipc	ra,0xfffff
    80002166:	a74080e7          	jalr	-1420(ra) # 80000bd6 <acquire>
    for (int j = 0; j < n; j++) {
    8000216a:	14905863          	blez	s1,800022ba <forkn+0x18c>
    8000216e:	2485                	addiw	s1,s1,1
    80002170:	02049c13          	slli	s8,s1,0x20
    80002174:	020c5c13          	srli	s8,s8,0x20
    80002178:	4b05                	li	s6,1
    8000217a:	150a8a13          	addi	s4,s5,336
        safestrcpy(np->name, p->name, sizeof(p->name));
    8000217e:	158a8d93          	addi	s11,s5,344
        np->chan = aseelLock;
    80002182:	f8840d13          	addi	s10,s0,-120
        np->state = SLEEPING;
    80002186:	4c89                	li	s9,2
    80002188:	a0d1                	j	8000224c <forkn+0x11e>
            printf("forkn: allocproc() failed at j=%d\n", j);
    8000218a:	85a6                	mv	a1,s1
    8000218c:	00006517          	auipc	a0,0x6
    80002190:	0d450513          	addi	a0,a0,212 # 80008260 <digits+0x220>
    80002194:	ffffe097          	auipc	ra,0xffffe
    80002198:	3f4080e7          	jalr	1012(ra) # 80000588 <printf>
            release(&wait_lock); // Release before returning
    8000219c:	0000f517          	auipc	a0,0xf
    800021a0:	a2c50513          	addi	a0,a0,-1492 # 80010bc8 <wait_lock>
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	ae6080e7          	jalr	-1306(ra) # 80000c8a <release>
            return -1;
    800021ac:	557d                	li	a0,-1
    800021ae:	a22d                	j	800022d8 <forkn+0x1aa>
            freeproc(np);
    800021b0:	854e                	mv	a0,s3
    800021b2:	00000097          	auipc	ra,0x0
    800021b6:	9ac080e7          	jalr	-1620(ra) # 80001b5e <freeproc>
            release(&np->lock);
    800021ba:	854e                	mv	a0,s3
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	ace080e7          	jalr	-1330(ra) # 80000c8a <release>
            release(&wait_lock); // Ensure lock is released
    800021c4:	0000f517          	auipc	a0,0xf
    800021c8:	a0450513          	addi	a0,a0,-1532 # 80010bc8 <wait_lock>
    800021cc:	fffff097          	auipc	ra,0xfffff
    800021d0:	abe080e7          	jalr	-1346(ra) # 80000c8a <release>
            return -1;
    800021d4:	557d                	li	a0,-1
    800021d6:	a209                	j	800022d8 <forkn+0x1aa>
        for (i = 0; i < NOFILE; i++) {
    800021d8:	04a1                	addi	s1,s1,8
    800021da:	0921                	addi	s2,s2,8
    800021dc:	01448b63          	beq	s1,s4,800021f2 <forkn+0xc4>
            if (p->ofile[i]) {
    800021e0:	6088                	ld	a0,0(s1)
    800021e2:	d97d                	beqz	a0,800021d8 <forkn+0xaa>
                np->ofile[i] = filedup(p->ofile[i]);
    800021e4:	00002097          	auipc	ra,0x2
    800021e8:	714080e7          	jalr	1812(ra) # 800048f8 <filedup>
    800021ec:	00a93023          	sd	a0,0(s2)
    800021f0:	b7e5                	j	800021d8 <forkn+0xaa>
        np->cwd = idup(p->cwd);
    800021f2:	150ab503          	ld	a0,336(s5)
    800021f6:	00002097          	auipc	ra,0x2
    800021fa:	888080e7          	jalr	-1912(ra) # 80003a7e <idup>
    800021fe:	14a9b823          	sd	a0,336(s3)
        safestrcpy(np->name, p->name, sizeof(p->name));
    80002202:	4641                	li	a2,16
    80002204:	85ee                	mv	a1,s11
    80002206:	15898513          	addi	a0,s3,344
    8000220a:	fffff097          	auipc	ra,0xfffff
    8000220e:	c12080e7          	jalr	-1006(ra) # 80000e1c <safestrcpy>
        pid = np->pid;
    80002212:	0309a783          	lw	a5,48(s3)
    80002216:	f8f42623          	sw	a5,-116(s0)
        np->parent = p;
    8000221a:	0359bc23          	sd	s5,56(s3)
        copyout(p->pagetable, (uint64)(&pids[j]), (char *)&pid, sizeof(int));
    8000221e:	4691                	li	a3,4
    80002220:	f8c40613          	addi	a2,s0,-116
    80002224:	85de                	mv	a1,s7
    80002226:	050ab503          	ld	a0,80(s5)
    8000222a:	fffff097          	auipc	ra,0xfffff
    8000222e:	43e080e7          	jalr	1086(ra) # 80001668 <copyout>
        np->chan = aseelLock;
    80002232:	03a9b023          	sd	s10,32(s3)
        np->state = SLEEPING;
    80002236:	0199ac23          	sw	s9,24(s3)
        release(&np->lock); // Release before sleeping
    8000223a:	854e                	mv	a0,s3
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	a4e080e7          	jalr	-1458(ra) # 80000c8a <release>
    for (int j = 0; j < n; j++) {
    80002244:	0b91                	addi	s7,s7,4
    80002246:	0b05                	addi	s6,s6,1
    80002248:	078b0963          	beq	s6,s8,800022ba <forkn+0x18c>
    8000224c:	fffb049b          	addiw	s1,s6,-1
        np = allocproc();
    80002250:	00000097          	auipc	ra,0x0
    80002254:	966080e7          	jalr	-1690(ra) # 80001bb6 <allocproc>
    80002258:	89aa                	mv	s3,a0
        if (!np) {
    8000225a:	d905                	beqz	a0,8000218a <forkn+0x5c>
        if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0) {
    8000225c:	048ab603          	ld	a2,72(s5)
    80002260:	692c                	ld	a1,80(a0)
    80002262:	050ab503          	ld	a0,80(s5)
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	2fe080e7          	jalr	766(ra) # 80001564 <uvmcopy>
    8000226e:	f40541e3          	bltz	a0,800021b0 <forkn+0x82>
        np->sz = p->sz;
    80002272:	048ab783          	ld	a5,72(s5)
    80002276:	04f9b423          	sd	a5,72(s3)
        *(np->trapframe) = *(p->trapframe);
    8000227a:	058ab683          	ld	a3,88(s5)
    8000227e:	87b6                	mv	a5,a3
    80002280:	0589b703          	ld	a4,88(s3)
    80002284:	12068693          	addi	a3,a3,288
    80002288:	0007b803          	ld	a6,0(a5)
    8000228c:	6788                	ld	a0,8(a5)
    8000228e:	6b8c                	ld	a1,16(a5)
    80002290:	6f90                	ld	a2,24(a5)
    80002292:	01073023          	sd	a6,0(a4)
    80002296:	e708                	sd	a0,8(a4)
    80002298:	eb0c                	sd	a1,16(a4)
    8000229a:	ef10                	sd	a2,24(a4)
    8000229c:	02078793          	addi	a5,a5,32
    800022a0:	02070713          	addi	a4,a4,32
    800022a4:	fed792e3          	bne	a5,a3,80002288 <forkn+0x15a>
        np->trapframe->a0 = j+1 ; // Set child index in fork operation
    800022a8:	0589b783          	ld	a5,88(s3)
    800022ac:	0767b823          	sd	s6,112(a5)
        for (i = 0; i < NOFILE; i++) {
    800022b0:	0d0a8493          	addi	s1,s5,208
    800022b4:	0d098913          	addi	s2,s3,208
    800022b8:	b725                	j	800021e0 <forkn+0xb2>
    wakeup(aseelLock); // Wake up all processes sleeping on the parent
    800022ba:	f8840513          	addi	a0,s0,-120
    800022be:	00000097          	auipc	ra,0x0
    800022c2:	dfa080e7          	jalr	-518(ra) # 800020b8 <wakeup>
    release(&wait_lock); // Parent releases wait_lock before returning
    800022c6:	0000f517          	auipc	a0,0xf
    800022ca:	90250513          	addi	a0,a0,-1790 # 80010bc8 <wait_lock>
    800022ce:	fffff097          	auipc	ra,0xfffff
    800022d2:	9bc080e7          	jalr	-1604(ra) # 80000c8a <release>
    return 0;
    800022d6:	4501                	li	a0,0
}
    800022d8:	70e6                	ld	ra,120(sp)
    800022da:	7446                	ld	s0,112(sp)
    800022dc:	74a6                	ld	s1,104(sp)
    800022de:	7906                	ld	s2,96(sp)
    800022e0:	69e6                	ld	s3,88(sp)
    800022e2:	6a46                	ld	s4,80(sp)
    800022e4:	6aa6                	ld	s5,72(sp)
    800022e6:	6b06                	ld	s6,64(sp)
    800022e8:	7be2                	ld	s7,56(sp)
    800022ea:	7c42                	ld	s8,48(sp)
    800022ec:	7ca2                	ld	s9,40(sp)
    800022ee:	7d02                	ld	s10,32(sp)
    800022f0:	6de2                	ld	s11,24(sp)
    800022f2:	6109                	addi	sp,sp,128
    800022f4:	8082                	ret

00000000800022f6 <reparent>:
{
    800022f6:	7179                	addi	sp,sp,-48
    800022f8:	f406                	sd	ra,40(sp)
    800022fa:	f022                	sd	s0,32(sp)
    800022fc:	ec26                	sd	s1,24(sp)
    800022fe:	e84a                	sd	s2,16(sp)
    80002300:	e44e                	sd	s3,8(sp)
    80002302:	e052                	sd	s4,0(sp)
    80002304:	1800                	addi	s0,sp,48
    80002306:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002308:	0000f497          	auipc	s1,0xf
    8000230c:	cd848493          	addi	s1,s1,-808 # 80010fe0 <proc>
      pp->parent = initproc;
    80002310:	00006a17          	auipc	s4,0x6
    80002314:	628a0a13          	addi	s4,s4,1576 # 80008938 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002318:	00015997          	auipc	s3,0x15
    8000231c:	ec898993          	addi	s3,s3,-312 # 800171e0 <tickslock>
    80002320:	a029                	j	8000232a <reparent+0x34>
    80002322:	18848493          	addi	s1,s1,392
    80002326:	01348d63          	beq	s1,s3,80002340 <reparent+0x4a>
    if(pp->parent == p){
    8000232a:	7c9c                	ld	a5,56(s1)
    8000232c:	ff279be3          	bne	a5,s2,80002322 <reparent+0x2c>
      pp->parent = initproc;
    80002330:	000a3503          	ld	a0,0(s4)
    80002334:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002336:	00000097          	auipc	ra,0x0
    8000233a:	d82080e7          	jalr	-638(ra) # 800020b8 <wakeup>
    8000233e:	b7d5                	j	80002322 <reparent+0x2c>
}
    80002340:	70a2                	ld	ra,40(sp)
    80002342:	7402                	ld	s0,32(sp)
    80002344:	64e2                	ld	s1,24(sp)
    80002346:	6942                	ld	s2,16(sp)
    80002348:	69a2                	ld	s3,8(sp)
    8000234a:	6a02                	ld	s4,0(sp)
    8000234c:	6145                	addi	sp,sp,48
    8000234e:	8082                	ret

0000000080002350 <exit>:
{
    80002350:	7179                	addi	sp,sp,-48
    80002352:	f406                	sd	ra,40(sp)
    80002354:	f022                	sd	s0,32(sp)
    80002356:	ec26                	sd	s1,24(sp)
    80002358:	e84a                	sd	s2,16(sp)
    8000235a:	e44e                	sd	s3,8(sp)
    8000235c:	e052                	sd	s4,0(sp)
    8000235e:	1800                	addi	s0,sp,48
    80002360:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	64a080e7          	jalr	1610(ra) # 800019ac <myproc>
    8000236a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000236c:	00006797          	auipc	a5,0x6
    80002370:	5cc7b783          	ld	a5,1484(a5) # 80008938 <initproc>
    80002374:	0d050493          	addi	s1,a0,208
    80002378:	15050913          	addi	s2,a0,336
    8000237c:	02a79363          	bne	a5,a0,800023a2 <exit+0x52>
    panic("init exiting");
    80002380:	00006517          	auipc	a0,0x6
    80002384:	f0850513          	addi	a0,a0,-248 # 80008288 <digits+0x248>
    80002388:	ffffe097          	auipc	ra,0xffffe
    8000238c:	1b6080e7          	jalr	438(ra) # 8000053e <panic>
      fileclose(f);
    80002390:	00002097          	auipc	ra,0x2
    80002394:	5ba080e7          	jalr	1466(ra) # 8000494a <fileclose>
      p->ofile[fd] = 0;
    80002398:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000239c:	04a1                	addi	s1,s1,8
    8000239e:	01248563          	beq	s1,s2,800023a8 <exit+0x58>
    if(p->ofile[fd]){
    800023a2:	6088                	ld	a0,0(s1)
    800023a4:	f575                	bnez	a0,80002390 <exit+0x40>
    800023a6:	bfdd                	j	8000239c <exit+0x4c>
  begin_op();
    800023a8:	00002097          	auipc	ra,0x2
    800023ac:	0d6080e7          	jalr	214(ra) # 8000447e <begin_op>
  iput(p->cwd);
    800023b0:	1509b503          	ld	a0,336(s3)
    800023b4:	00002097          	auipc	ra,0x2
    800023b8:	8c2080e7          	jalr	-1854(ra) # 80003c76 <iput>
  end_op();
    800023bc:	00002097          	auipc	ra,0x2
    800023c0:	142080e7          	jalr	322(ra) # 800044fe <end_op>
  p->cwd = 0;
    800023c4:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800023c8:	0000f497          	auipc	s1,0xf
    800023cc:	80048493          	addi	s1,s1,-2048 # 80010bc8 <wait_lock>
    800023d0:	8526                	mv	a0,s1
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	804080e7          	jalr	-2044(ra) # 80000bd6 <acquire>
  reparent(p);
    800023da:	854e                	mv	a0,s3
    800023dc:	00000097          	auipc	ra,0x0
    800023e0:	f1a080e7          	jalr	-230(ra) # 800022f6 <reparent>
  wakeup(p->parent);
    800023e4:	0389b503          	ld	a0,56(s3)
    800023e8:	00000097          	auipc	ra,0x0
    800023ec:	cd0080e7          	jalr	-816(ra) # 800020b8 <wakeup>
  acquire(&p->lock);
    800023f0:	854e                	mv	a0,s3
    800023f2:	ffffe097          	auipc	ra,0xffffe
    800023f6:	7e4080e7          	jalr	2020(ra) # 80000bd6 <acquire>
  p->xstate = status;
    800023fa:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023fe:	4795                	li	a5,5
    80002400:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002404:	8526                	mv	a0,s1
    80002406:	fffff097          	auipc	ra,0xfffff
    8000240a:	884080e7          	jalr	-1916(ra) # 80000c8a <release>
  sched();
    8000240e:	00000097          	auipc	ra,0x0
    80002412:	b34080e7          	jalr	-1228(ra) # 80001f42 <sched>
  panic("zombie exit");
    80002416:	00006517          	auipc	a0,0x6
    8000241a:	e8250513          	addi	a0,a0,-382 # 80008298 <digits+0x258>
    8000241e:	ffffe097          	auipc	ra,0xffffe
    80002422:	120080e7          	jalr	288(ra) # 8000053e <panic>

0000000080002426 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002426:	7179                	addi	sp,sp,-48
    80002428:	f406                	sd	ra,40(sp)
    8000242a:	f022                	sd	s0,32(sp)
    8000242c:	ec26                	sd	s1,24(sp)
    8000242e:	e84a                	sd	s2,16(sp)
    80002430:	e44e                	sd	s3,8(sp)
    80002432:	1800                	addi	s0,sp,48
    80002434:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002436:	0000f497          	auipc	s1,0xf
    8000243a:	baa48493          	addi	s1,s1,-1110 # 80010fe0 <proc>
    8000243e:	00015997          	auipc	s3,0x15
    80002442:	da298993          	addi	s3,s3,-606 # 800171e0 <tickslock>
    acquire(&p->lock);
    80002446:	8526                	mv	a0,s1
    80002448:	ffffe097          	auipc	ra,0xffffe
    8000244c:	78e080e7          	jalr	1934(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002450:	589c                	lw	a5,48(s1)
    80002452:	01278d63          	beq	a5,s2,8000246c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002456:	8526                	mv	a0,s1
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	832080e7          	jalr	-1998(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002460:	18848493          	addi	s1,s1,392
    80002464:	ff3491e3          	bne	s1,s3,80002446 <kill+0x20>
  }
  return -1;
    80002468:	557d                	li	a0,-1
    8000246a:	a829                	j	80002484 <kill+0x5e>
      p->killed = 1;
    8000246c:	4785                	li	a5,1
    8000246e:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002470:	4c98                	lw	a4,24(s1)
    80002472:	4789                	li	a5,2
    80002474:	00f70f63          	beq	a4,a5,80002492 <kill+0x6c>
      release(&p->lock);
    80002478:	8526                	mv	a0,s1
    8000247a:	fffff097          	auipc	ra,0xfffff
    8000247e:	810080e7          	jalr	-2032(ra) # 80000c8a <release>
      return 0;
    80002482:	4501                	li	a0,0
}
    80002484:	70a2                	ld	ra,40(sp)
    80002486:	7402                	ld	s0,32(sp)
    80002488:	64e2                	ld	s1,24(sp)
    8000248a:	6942                	ld	s2,16(sp)
    8000248c:	69a2                	ld	s3,8(sp)
    8000248e:	6145                	addi	sp,sp,48
    80002490:	8082                	ret
        p->state = RUNNABLE;
    80002492:	478d                	li	a5,3
    80002494:	cc9c                	sw	a5,24(s1)
    80002496:	b7cd                	j	80002478 <kill+0x52>

0000000080002498 <setkilled>:

void
setkilled(struct proc *p)
{
    80002498:	1101                	addi	sp,sp,-32
    8000249a:	ec06                	sd	ra,24(sp)
    8000249c:	e822                	sd	s0,16(sp)
    8000249e:	e426                	sd	s1,8(sp)
    800024a0:	1000                	addi	s0,sp,32
    800024a2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800024a4:	ffffe097          	auipc	ra,0xffffe
    800024a8:	732080e7          	jalr	1842(ra) # 80000bd6 <acquire>
  p->killed = 1;
    800024ac:	4785                	li	a5,1
    800024ae:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800024b0:	8526                	mv	a0,s1
    800024b2:	ffffe097          	auipc	ra,0xffffe
    800024b6:	7d8080e7          	jalr	2008(ra) # 80000c8a <release>
}
    800024ba:	60e2                	ld	ra,24(sp)
    800024bc:	6442                	ld	s0,16(sp)
    800024be:	64a2                	ld	s1,8(sp)
    800024c0:	6105                	addi	sp,sp,32
    800024c2:	8082                	ret

00000000800024c4 <killed>:

int
killed(struct proc *p)
{
    800024c4:	1101                	addi	sp,sp,-32
    800024c6:	ec06                	sd	ra,24(sp)
    800024c8:	e822                	sd	s0,16(sp)
    800024ca:	e426                	sd	s1,8(sp)
    800024cc:	e04a                	sd	s2,0(sp)
    800024ce:	1000                	addi	s0,sp,32
    800024d0:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800024d2:	ffffe097          	auipc	ra,0xffffe
    800024d6:	704080e7          	jalr	1796(ra) # 80000bd6 <acquire>
  k = p->killed;
    800024da:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800024de:	8526                	mv	a0,s1
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	7aa080e7          	jalr	1962(ra) # 80000c8a <release>
  return k;
}
    800024e8:	854a                	mv	a0,s2
    800024ea:	60e2                	ld	ra,24(sp)
    800024ec:	6442                	ld	s0,16(sp)
    800024ee:	64a2                	ld	s1,8(sp)
    800024f0:	6902                	ld	s2,0(sp)
    800024f2:	6105                	addi	sp,sp,32
    800024f4:	8082                	ret

00000000800024f6 <wait>:
{
    800024f6:	711d                	addi	sp,sp,-96
    800024f8:	ec86                	sd	ra,88(sp)
    800024fa:	e8a2                	sd	s0,80(sp)
    800024fc:	e4a6                	sd	s1,72(sp)
    800024fe:	e0ca                	sd	s2,64(sp)
    80002500:	fc4e                	sd	s3,56(sp)
    80002502:	f852                	sd	s4,48(sp)
    80002504:	f456                	sd	s5,40(sp)
    80002506:	f05a                	sd	s6,32(sp)
    80002508:	ec5e                	sd	s7,24(sp)
    8000250a:	e862                	sd	s8,16(sp)
    8000250c:	e466                	sd	s9,8(sp)
    8000250e:	1080                	addi	s0,sp,96
    80002510:	8b2a                	mv	s6,a0
    80002512:	8bae                	mv	s7,a1
  struct proc *p = myproc();
    80002514:	fffff097          	auipc	ra,0xfffff
    80002518:	498080e7          	jalr	1176(ra) # 800019ac <myproc>
    8000251c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000251e:	0000e517          	auipc	a0,0xe
    80002522:	6aa50513          	addi	a0,a0,1706 # 80010bc8 <wait_lock>
    80002526:	ffffe097          	auipc	ra,0xffffe
    8000252a:	6b0080e7          	jalr	1712(ra) # 80000bd6 <acquire>
    havekids = 0;
    8000252e:	4c01                	li	s8,0
        if(pp->state == ZOMBIE){
    80002530:	4a15                	li	s4,5
        havekids = 1;
    80002532:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002534:	00015997          	auipc	s3,0x15
    80002538:	cac98993          	addi	s3,s3,-852 # 800171e0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000253c:	0000ec97          	auipc	s9,0xe
    80002540:	68cc8c93          	addi	s9,s9,1676 # 80010bc8 <wait_lock>
    havekids = 0;
    80002544:	8762                	mv	a4,s8
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002546:	0000f497          	auipc	s1,0xf
    8000254a:	a9a48493          	addi	s1,s1,-1382 # 80010fe0 <proc>
    8000254e:	a069                	j	800025d8 <wait+0xe2>
          pid = pp->pid;
    80002550:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002554:	000b0e63          	beqz	s6,80002570 <wait+0x7a>
    80002558:	4691                	li	a3,4
    8000255a:	02c48613          	addi	a2,s1,44
    8000255e:	85da                	mv	a1,s6
    80002560:	05093503          	ld	a0,80(s2)
    80002564:	fffff097          	auipc	ra,0xfffff
    80002568:	104080e7          	jalr	260(ra) # 80001668 <copyout>
    8000256c:	04054363          	bltz	a0,800025b2 <wait+0xbc>
          copyout(myproc()->pagetable, messagePointerAddress, pp->exit_msg, 32);
    80002570:	fffff097          	auipc	ra,0xfffff
    80002574:	43c080e7          	jalr	1084(ra) # 800019ac <myproc>
    80002578:	02000693          	li	a3,32
    8000257c:	16848613          	addi	a2,s1,360
    80002580:	85de                	mv	a1,s7
    80002582:	6928                	ld	a0,80(a0)
    80002584:	fffff097          	auipc	ra,0xfffff
    80002588:	0e4080e7          	jalr	228(ra) # 80001668 <copyout>
          freeproc(pp);
    8000258c:	8526                	mv	a0,s1
    8000258e:	fffff097          	auipc	ra,0xfffff
    80002592:	5d0080e7          	jalr	1488(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    80002596:	8526                	mv	a0,s1
    80002598:	ffffe097          	auipc	ra,0xffffe
    8000259c:	6f2080e7          	jalr	1778(ra) # 80000c8a <release>
          release(&wait_lock);
    800025a0:	0000e517          	auipc	a0,0xe
    800025a4:	62850513          	addi	a0,a0,1576 # 80010bc8 <wait_lock>
    800025a8:	ffffe097          	auipc	ra,0xffffe
    800025ac:	6e2080e7          	jalr	1762(ra) # 80000c8a <release>
          return pid;
    800025b0:	a0b5                	j	8000261c <wait+0x126>
            release(&pp->lock);
    800025b2:	8526                	mv	a0,s1
    800025b4:	ffffe097          	auipc	ra,0xffffe
    800025b8:	6d6080e7          	jalr	1750(ra) # 80000c8a <release>
            release(&wait_lock);
    800025bc:	0000e517          	auipc	a0,0xe
    800025c0:	60c50513          	addi	a0,a0,1548 # 80010bc8 <wait_lock>
    800025c4:	ffffe097          	auipc	ra,0xffffe
    800025c8:	6c6080e7          	jalr	1734(ra) # 80000c8a <release>
            return -1;       
    800025cc:	59fd                	li	s3,-1
    800025ce:	a0b9                	j	8000261c <wait+0x126>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800025d0:	18848493          	addi	s1,s1,392
    800025d4:	03348463          	beq	s1,s3,800025fc <wait+0x106>
      if(pp->parent == p){
    800025d8:	7c9c                	ld	a5,56(s1)
    800025da:	ff279be3          	bne	a5,s2,800025d0 <wait+0xda>
        acquire(&pp->lock);
    800025de:	8526                	mv	a0,s1
    800025e0:	ffffe097          	auipc	ra,0xffffe
    800025e4:	5f6080e7          	jalr	1526(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    800025e8:	4c9c                	lw	a5,24(s1)
    800025ea:	f74783e3          	beq	a5,s4,80002550 <wait+0x5a>
        release(&pp->lock);
    800025ee:	8526                	mv	a0,s1
    800025f0:	ffffe097          	auipc	ra,0xffffe
    800025f4:	69a080e7          	jalr	1690(ra) # 80000c8a <release>
        havekids = 1;
    800025f8:	8756                	mv	a4,s5
    800025fa:	bfd9                	j	800025d0 <wait+0xda>
    if(!havekids || killed(p)){
    800025fc:	c719                	beqz	a4,8000260a <wait+0x114>
    800025fe:	854a                	mv	a0,s2
    80002600:	00000097          	auipc	ra,0x0
    80002604:	ec4080e7          	jalr	-316(ra) # 800024c4 <killed>
    80002608:	c905                	beqz	a0,80002638 <wait+0x142>
      release(&wait_lock);
    8000260a:	0000e517          	auipc	a0,0xe
    8000260e:	5be50513          	addi	a0,a0,1470 # 80010bc8 <wait_lock>
    80002612:	ffffe097          	auipc	ra,0xffffe
    80002616:	678080e7          	jalr	1656(ra) # 80000c8a <release>
      return -1;
    8000261a:	59fd                	li	s3,-1
}
    8000261c:	854e                	mv	a0,s3
    8000261e:	60e6                	ld	ra,88(sp)
    80002620:	6446                	ld	s0,80(sp)
    80002622:	64a6                	ld	s1,72(sp)
    80002624:	6906                	ld	s2,64(sp)
    80002626:	79e2                	ld	s3,56(sp)
    80002628:	7a42                	ld	s4,48(sp)
    8000262a:	7aa2                	ld	s5,40(sp)
    8000262c:	7b02                	ld	s6,32(sp)
    8000262e:	6be2                	ld	s7,24(sp)
    80002630:	6c42                	ld	s8,16(sp)
    80002632:	6ca2                	ld	s9,8(sp)
    80002634:	6125                	addi	sp,sp,96
    80002636:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002638:	85e6                	mv	a1,s9
    8000263a:	854a                	mv	a0,s2
    8000263c:	00000097          	auipc	ra,0x0
    80002640:	a18080e7          	jalr	-1512(ra) # 80002054 <sleep>
    havekids = 0;
    80002644:	b701                	j	80002544 <wait+0x4e>

0000000080002646 <waitall>:
int waitall(uint64 childsAddress, uint64 childsStauts) { 
    80002646:	711d                	addi	sp,sp,-96
    80002648:	ec86                	sd	ra,88(sp)
    8000264a:	e8a2                	sd	s0,80(sp)
    8000264c:	e4a6                	sd	s1,72(sp)
    8000264e:	e0ca                	sd	s2,64(sp)
    80002650:	fc4e                	sd	s3,56(sp)
    80002652:	f852                	sd	s4,48(sp)
    80002654:	f456                	sd	s5,40(sp)
    80002656:	f05a                	sd	s6,32(sp)
    80002658:	ec5e                	sd	s7,24(sp)
    8000265a:	1080                	addi	s0,sp,96
    8000265c:	8baa                	mv	s7,a0
    8000265e:	8aae                	mv	s5,a1
  struct proc *p = myproc();
    80002660:	fffff097          	auipc	ra,0xfffff
    80002664:	34c080e7          	jalr	844(ra) # 800019ac <myproc>
    80002668:	84aa                	mv	s1,a0
  int childsCounter = 0;
    8000266a:	fa042623          	sw	zero,-84(s0)
  acquire(&wait_lock); // ✅ Lock once at the start
    8000266e:	0000e517          	auipc	a0,0xe
    80002672:	55a50513          	addi	a0,a0,1370 # 80010bc8 <wait_lock>
    80002676:	ffffe097          	auipc	ra,0xffffe
    8000267a:	560080e7          	jalr	1376(ra) # 80000bd6 <acquire>
    int number_of_zombies = 0;
    8000267e:	4a01                	li	s4,0
        if (pp->state == ZOMBIE) {
    80002680:	4995                	li	s3,5
    for (pp = proc; pp < &proc[NPROC]; pp++) {
    80002682:	00015917          	auipc	s2,0x15
    80002686:	b5e90913          	addi	s2,s2,-1186 # 800171e0 <tickslock>
      sleep(p, &wait_lock); // ✅ Avoid busy waiting
    8000268a:	0000eb17          	auipc	s6,0xe
    8000268e:	53eb0b13          	addi	s6,s6,1342 # 80010bc8 <wait_lock>
    80002692:	a089                	j	800026d4 <waitall+0x8e>
    for (pp = proc; pp < &proc[NPROC]; pp++) {
    80002694:	18878793          	addi	a5,a5,392
    80002698:	01278b63          	beq	a5,s2,800026ae <waitall+0x68>
      if (pp->parent == p) {
    8000269c:	7f98                	ld	a4,56(a5)
    8000269e:	fe971be3          	bne	a4,s1,80002694 <waitall+0x4e>
        number_of_kids++;
    800026a2:	2685                	addiw	a3,a3,1
        if (pp->state == ZOMBIE) {
    800026a4:	4f98                	lw	a4,24(a5)
    800026a6:	ff3717e3          	bne	a4,s3,80002694 <waitall+0x4e>
          number_of_zombies++;
    800026aa:	2605                	addiw	a2,a2,1
    800026ac:	b7e5                	j	80002694 <waitall+0x4e>
    if (!childAreZombies) {
    800026ae:	00c69d63          	bne	a3,a2,800026c8 <waitall+0x82>
  int i = 0;
    800026b2:	4b01                	li	s6,0
  for (pp = proc; pp < &proc[NPROC]; pp++) {
    800026b4:	0000f917          	auipc	s2,0xf
    800026b8:	92c90913          	addi	s2,s2,-1748 # 80010fe0 <proc>
    if (pp->parent == p && pp->state == ZOMBIE) {
    800026bc:	4a15                	li	s4,5
  for (pp = proc; pp < &proc[NPROC]; pp++) {
    800026be:	00015997          	auipc	s3,0x15
    800026c2:	b2298993          	addi	s3,s3,-1246 # 800171e0 <tickslock>
    800026c6:	a091                	j	8000270a <waitall+0xc4>
      sleep(p, &wait_lock); // ✅ Avoid busy waiting
    800026c8:	85da                	mv	a1,s6
    800026ca:	8526                	mv	a0,s1
    800026cc:	00000097          	auipc	ra,0x0
    800026d0:	988080e7          	jalr	-1656(ra) # 80002054 <sleep>
    int number_of_zombies = 0;
    800026d4:	8652                	mv	a2,s4
    int number_of_kids = 0; 
    800026d6:	86d2                	mv	a3,s4
    for (pp = proc; pp < &proc[NPROC]; pp++) {
    800026d8:	0000f797          	auipc	a5,0xf
    800026dc:	90878793          	addi	a5,a5,-1784 # 80010fe0 <proc>
    800026e0:	bf75                	j	8000269c <waitall+0x56>
      i++;
    800026e2:	2b05                	addiw	s6,s6,1
      childsCounter++;
    800026e4:	fac42783          	lw	a5,-84(s0)
    800026e8:	2785                	addiw	a5,a5,1
    800026ea:	faf42623          	sw	a5,-84(s0)
      freeproc(pp);
    800026ee:	854a                	mv	a0,s2
    800026f0:	fffff097          	auipc	ra,0xfffff
    800026f4:	46e080e7          	jalr	1134(ra) # 80001b5e <freeproc>
      release(&pp->lock);
    800026f8:	854a                	mv	a0,s2
    800026fa:	ffffe097          	auipc	ra,0xffffe
    800026fe:	590080e7          	jalr	1424(ra) # 80000c8a <release>
  for (pp = proc; pp < &proc[NPROC]; pp++) {
    80002702:	18890913          	addi	s2,s2,392
    80002706:	05390d63          	beq	s2,s3,80002760 <waitall+0x11a>
    if (pp->parent == p && pp->state == ZOMBIE) {
    8000270a:	03893783          	ld	a5,56(s2)
    8000270e:	fe979ae3          	bne	a5,s1,80002702 <waitall+0xbc>
    80002712:	01892783          	lw	a5,24(s2)
    80002716:	ff4796e3          	bne	a5,s4,80002702 <waitall+0xbc>
      acquire(&pp->lock);
    8000271a:	854a                	mv	a0,s2
    8000271c:	ffffe097          	auipc	ra,0xffffe
    80002720:	4ba080e7          	jalr	1210(ra) # 80000bd6 <acquire>
      if (childsStauts != 0 &&
    80002724:	fa0a8fe3          	beqz	s5,800026e2 <waitall+0x9c>
          copyout(p->pagetable, childsStauts + i * sizeof(int), 
    80002728:	002b1593          	slli	a1,s6,0x2
    8000272c:	4691                	li	a3,4
    8000272e:	02c90613          	addi	a2,s2,44
    80002732:	95d6                	add	a1,a1,s5
    80002734:	68a8                	ld	a0,80(s1)
    80002736:	fffff097          	auipc	ra,0xfffff
    8000273a:	f32080e7          	jalr	-206(ra) # 80001668 <copyout>
      if (childsStauts != 0 &&
    8000273e:	fa0552e3          	bgez	a0,800026e2 <waitall+0x9c>
        release(&pp->lock);
    80002742:	854a                	mv	a0,s2
    80002744:	ffffe097          	auipc	ra,0xffffe
    80002748:	546080e7          	jalr	1350(ra) # 80000c8a <release>
        release(&wait_lock);
    8000274c:	0000e517          	auipc	a0,0xe
    80002750:	47c50513          	addi	a0,a0,1148 # 80010bc8 <wait_lock>
    80002754:	ffffe097          	auipc	ra,0xffffe
    80002758:	536080e7          	jalr	1334(ra) # 80000c8a <release>
        return -1;
    8000275c:	597d                	li	s2,-1
    8000275e:	a881                	j	800027ae <waitall+0x168>
  printf("(debug) childsCounter: %d\n", childsCounter);
    80002760:	fac42583          	lw	a1,-84(s0)
    80002764:	00006517          	auipc	a0,0x6
    80002768:	b4450513          	addi	a0,a0,-1212 # 800082a8 <digits+0x268>
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	e1c080e7          	jalr	-484(ra) # 80000588 <printf>
  if (!childsCounter || killed(p)) {
    80002774:	fac42783          	lw	a5,-84(s0)
    80002778:	c7b9                	beqz	a5,800027c6 <waitall+0x180>
    8000277a:	8526                	mv	a0,s1
    8000277c:	00000097          	auipc	ra,0x0
    80002780:	d48080e7          	jalr	-696(ra) # 800024c4 <killed>
    80002784:	892a                	mv	s2,a0
    80002786:	e121                	bnez	a0,800027c6 <waitall+0x180>
  if (copyout(p->pagetable, childsAddress, (char *)&childsCounter, sizeof(int)) < 0) {
    80002788:	4691                	li	a3,4
    8000278a:	fac40613          	addi	a2,s0,-84
    8000278e:	85de                	mv	a1,s7
    80002790:	68a8                	ld	a0,80(s1)
    80002792:	fffff097          	auipc	ra,0xfffff
    80002796:	ed6080e7          	jalr	-298(ra) # 80001668 <copyout>
    8000279a:	04054963          	bltz	a0,800027ec <waitall+0x1a6>
  release(&wait_lock); // ✅ Ensure the lock is released before returning
    8000279e:	0000e517          	auipc	a0,0xe
    800027a2:	42a50513          	addi	a0,a0,1066 # 80010bc8 <wait_lock>
    800027a6:	ffffe097          	auipc	ra,0xffffe
    800027aa:	4e4080e7          	jalr	1252(ra) # 80000c8a <release>
}
    800027ae:	854a                	mv	a0,s2
    800027b0:	60e6                	ld	ra,88(sp)
    800027b2:	6446                	ld	s0,80(sp)
    800027b4:	64a6                	ld	s1,72(sp)
    800027b6:	6906                	ld	s2,64(sp)
    800027b8:	79e2                	ld	s3,56(sp)
    800027ba:	7a42                	ld	s4,48(sp)
    800027bc:	7aa2                	ld	s5,40(sp)
    800027be:	7b02                	ld	s6,32(sp)
    800027c0:	6be2                	ld	s7,24(sp)
    800027c2:	6125                	addi	sp,sp,96
    800027c4:	8082                	ret
    release(&wait_lock);
    800027c6:	0000e517          	auipc	a0,0xe
    800027ca:	40250513          	addi	a0,a0,1026 # 80010bc8 <wait_lock>
    800027ce:	ffffe097          	auipc	ra,0xffffe
    800027d2:	4bc080e7          	jalr	1212(ra) # 80000c8a <release>
    copyout(p->pagetable, childsAddress, (char *)&childsCounter, sizeof(int));
    800027d6:	4691                	li	a3,4
    800027d8:	fac40613          	addi	a2,s0,-84
    800027dc:	85de                	mv	a1,s7
    800027de:	68a8                	ld	a0,80(s1)
    800027e0:	fffff097          	auipc	ra,0xfffff
    800027e4:	e88080e7          	jalr	-376(ra) # 80001668 <copyout>
    return -1;
    800027e8:	597d                	li	s2,-1
    800027ea:	b7d1                	j	800027ae <waitall+0x168>
    release(&wait_lock);
    800027ec:	0000e517          	auipc	a0,0xe
    800027f0:	3dc50513          	addi	a0,a0,988 # 80010bc8 <wait_lock>
    800027f4:	ffffe097          	auipc	ra,0xffffe
    800027f8:	496080e7          	jalr	1174(ra) # 80000c8a <release>
    return 0;
    800027fc:	bf4d                	j	800027ae <waitall+0x168>

00000000800027fe <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027fe:	7179                	addi	sp,sp,-48
    80002800:	f406                	sd	ra,40(sp)
    80002802:	f022                	sd	s0,32(sp)
    80002804:	ec26                	sd	s1,24(sp)
    80002806:	e84a                	sd	s2,16(sp)
    80002808:	e44e                	sd	s3,8(sp)
    8000280a:	e052                	sd	s4,0(sp)
    8000280c:	1800                	addi	s0,sp,48
    8000280e:	84aa                	mv	s1,a0
    80002810:	892e                	mv	s2,a1
    80002812:	89b2                	mv	s3,a2
    80002814:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002816:	fffff097          	auipc	ra,0xfffff
    8000281a:	196080e7          	jalr	406(ra) # 800019ac <myproc>
  if(user_dst){
    8000281e:	c08d                	beqz	s1,80002840 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002820:	86d2                	mv	a3,s4
    80002822:	864e                	mv	a2,s3
    80002824:	85ca                	mv	a1,s2
    80002826:	6928                	ld	a0,80(a0)
    80002828:	fffff097          	auipc	ra,0xfffff
    8000282c:	e40080e7          	jalr	-448(ra) # 80001668 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002830:	70a2                	ld	ra,40(sp)
    80002832:	7402                	ld	s0,32(sp)
    80002834:	64e2                	ld	s1,24(sp)
    80002836:	6942                	ld	s2,16(sp)
    80002838:	69a2                	ld	s3,8(sp)
    8000283a:	6a02                	ld	s4,0(sp)
    8000283c:	6145                	addi	sp,sp,48
    8000283e:	8082                	ret
    memmove((char *)dst, src, len);
    80002840:	000a061b          	sext.w	a2,s4
    80002844:	85ce                	mv	a1,s3
    80002846:	854a                	mv	a0,s2
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	4e6080e7          	jalr	1254(ra) # 80000d2e <memmove>
    return 0;
    80002850:	8526                	mv	a0,s1
    80002852:	bff9                	j	80002830 <either_copyout+0x32>

0000000080002854 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002854:	7179                	addi	sp,sp,-48
    80002856:	f406                	sd	ra,40(sp)
    80002858:	f022                	sd	s0,32(sp)
    8000285a:	ec26                	sd	s1,24(sp)
    8000285c:	e84a                	sd	s2,16(sp)
    8000285e:	e44e                	sd	s3,8(sp)
    80002860:	e052                	sd	s4,0(sp)
    80002862:	1800                	addi	s0,sp,48
    80002864:	892a                	mv	s2,a0
    80002866:	84ae                	mv	s1,a1
    80002868:	89b2                	mv	s3,a2
    8000286a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000286c:	fffff097          	auipc	ra,0xfffff
    80002870:	140080e7          	jalr	320(ra) # 800019ac <myproc>
  if(user_src){
    80002874:	c08d                	beqz	s1,80002896 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002876:	86d2                	mv	a3,s4
    80002878:	864e                	mv	a2,s3
    8000287a:	85ca                	mv	a1,s2
    8000287c:	6928                	ld	a0,80(a0)
    8000287e:	fffff097          	auipc	ra,0xfffff
    80002882:	e76080e7          	jalr	-394(ra) # 800016f4 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002886:	70a2                	ld	ra,40(sp)
    80002888:	7402                	ld	s0,32(sp)
    8000288a:	64e2                	ld	s1,24(sp)
    8000288c:	6942                	ld	s2,16(sp)
    8000288e:	69a2                	ld	s3,8(sp)
    80002890:	6a02                	ld	s4,0(sp)
    80002892:	6145                	addi	sp,sp,48
    80002894:	8082                	ret
    memmove(dst, (char*)src, len);
    80002896:	000a061b          	sext.w	a2,s4
    8000289a:	85ce                	mv	a1,s3
    8000289c:	854a                	mv	a0,s2
    8000289e:	ffffe097          	auipc	ra,0xffffe
    800028a2:	490080e7          	jalr	1168(ra) # 80000d2e <memmove>
    return 0;
    800028a6:	8526                	mv	a0,s1
    800028a8:	bff9                	j	80002886 <either_copyin+0x32>

00000000800028aa <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800028aa:	715d                	addi	sp,sp,-80
    800028ac:	e486                	sd	ra,72(sp)
    800028ae:	e0a2                	sd	s0,64(sp)
    800028b0:	fc26                	sd	s1,56(sp)
    800028b2:	f84a                	sd	s2,48(sp)
    800028b4:	f44e                	sd	s3,40(sp)
    800028b6:	f052                	sd	s4,32(sp)
    800028b8:	ec56                	sd	s5,24(sp)
    800028ba:	e85a                	sd	s6,16(sp)
    800028bc:	e45e                	sd	s7,8(sp)
    800028be:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800028c0:	00006517          	auipc	a0,0x6
    800028c4:	80850513          	addi	a0,a0,-2040 # 800080c8 <digits+0x88>
    800028c8:	ffffe097          	auipc	ra,0xffffe
    800028cc:	cc0080e7          	jalr	-832(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028d0:	0000f497          	auipc	s1,0xf
    800028d4:	86848493          	addi	s1,s1,-1944 # 80011138 <proc+0x158>
    800028d8:	00015917          	auipc	s2,0x15
    800028dc:	a6090913          	addi	s2,s2,-1440 # 80017338 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028e0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800028e2:	00006997          	auipc	s3,0x6
    800028e6:	9e698993          	addi	s3,s3,-1562 # 800082c8 <digits+0x288>
    printf("%d %s %s", p->pid, state, p->name);
    800028ea:	00006a97          	auipc	s5,0x6
    800028ee:	9e6a8a93          	addi	s5,s5,-1562 # 800082d0 <digits+0x290>
    printf("\n");
    800028f2:	00005a17          	auipc	s4,0x5
    800028f6:	7d6a0a13          	addi	s4,s4,2006 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028fa:	00006b97          	auipc	s7,0x6
    800028fe:	a16b8b93          	addi	s7,s7,-1514 # 80008310 <states.0>
    80002902:	a00d                	j	80002924 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002904:	ed86a583          	lw	a1,-296(a3)
    80002908:	8556                	mv	a0,s5
    8000290a:	ffffe097          	auipc	ra,0xffffe
    8000290e:	c7e080e7          	jalr	-898(ra) # 80000588 <printf>
    printf("\n");
    80002912:	8552                	mv	a0,s4
    80002914:	ffffe097          	auipc	ra,0xffffe
    80002918:	c74080e7          	jalr	-908(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000291c:	18848493          	addi	s1,s1,392
    80002920:	03248163          	beq	s1,s2,80002942 <procdump+0x98>
    if(p->state == UNUSED)
    80002924:	86a6                	mv	a3,s1
    80002926:	ec04a783          	lw	a5,-320(s1)
    8000292a:	dbed                	beqz	a5,8000291c <procdump+0x72>
      state = "???";
    8000292c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000292e:	fcfb6be3          	bltu	s6,a5,80002904 <procdump+0x5a>
    80002932:	1782                	slli	a5,a5,0x20
    80002934:	9381                	srli	a5,a5,0x20
    80002936:	078e                	slli	a5,a5,0x3
    80002938:	97de                	add	a5,a5,s7
    8000293a:	6390                	ld	a2,0(a5)
    8000293c:	f661                	bnez	a2,80002904 <procdump+0x5a>
      state = "???";
    8000293e:	864e                	mv	a2,s3
    80002940:	b7d1                	j	80002904 <procdump+0x5a>
  }
}
    80002942:	60a6                	ld	ra,72(sp)
    80002944:	6406                	ld	s0,64(sp)
    80002946:	74e2                	ld	s1,56(sp)
    80002948:	7942                	ld	s2,48(sp)
    8000294a:	79a2                	ld	s3,40(sp)
    8000294c:	7a02                	ld	s4,32(sp)
    8000294e:	6ae2                	ld	s5,24(sp)
    80002950:	6b42                	ld	s6,16(sp)
    80002952:	6ba2                	ld	s7,8(sp)
    80002954:	6161                	addi	sp,sp,80
    80002956:	8082                	ret

0000000080002958 <swtch>:
    80002958:	00153023          	sd	ra,0(a0)
    8000295c:	00253423          	sd	sp,8(a0)
    80002960:	e900                	sd	s0,16(a0)
    80002962:	ed04                	sd	s1,24(a0)
    80002964:	03253023          	sd	s2,32(a0)
    80002968:	03353423          	sd	s3,40(a0)
    8000296c:	03453823          	sd	s4,48(a0)
    80002970:	03553c23          	sd	s5,56(a0)
    80002974:	05653023          	sd	s6,64(a0)
    80002978:	05753423          	sd	s7,72(a0)
    8000297c:	05853823          	sd	s8,80(a0)
    80002980:	05953c23          	sd	s9,88(a0)
    80002984:	07a53023          	sd	s10,96(a0)
    80002988:	07b53423          	sd	s11,104(a0)
    8000298c:	0005b083          	ld	ra,0(a1)
    80002990:	0085b103          	ld	sp,8(a1)
    80002994:	6980                	ld	s0,16(a1)
    80002996:	6d84                	ld	s1,24(a1)
    80002998:	0205b903          	ld	s2,32(a1)
    8000299c:	0285b983          	ld	s3,40(a1)
    800029a0:	0305ba03          	ld	s4,48(a1)
    800029a4:	0385ba83          	ld	s5,56(a1)
    800029a8:	0405bb03          	ld	s6,64(a1)
    800029ac:	0485bb83          	ld	s7,72(a1)
    800029b0:	0505bc03          	ld	s8,80(a1)
    800029b4:	0585bc83          	ld	s9,88(a1)
    800029b8:	0605bd03          	ld	s10,96(a1)
    800029bc:	0685bd83          	ld	s11,104(a1)
    800029c0:	8082                	ret

00000000800029c2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800029c2:	1141                	addi	sp,sp,-16
    800029c4:	e406                	sd	ra,8(sp)
    800029c6:	e022                	sd	s0,0(sp)
    800029c8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800029ca:	00006597          	auipc	a1,0x6
    800029ce:	97658593          	addi	a1,a1,-1674 # 80008340 <states.0+0x30>
    800029d2:	00015517          	auipc	a0,0x15
    800029d6:	80e50513          	addi	a0,a0,-2034 # 800171e0 <tickslock>
    800029da:	ffffe097          	auipc	ra,0xffffe
    800029de:	16c080e7          	jalr	364(ra) # 80000b46 <initlock>
}
    800029e2:	60a2                	ld	ra,8(sp)
    800029e4:	6402                	ld	s0,0(sp)
    800029e6:	0141                	addi	sp,sp,16
    800029e8:	8082                	ret

00000000800029ea <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800029ea:	1141                	addi	sp,sp,-16
    800029ec:	e422                	sd	s0,8(sp)
    800029ee:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029f0:	00003797          	auipc	a5,0x3
    800029f4:	5b078793          	addi	a5,a5,1456 # 80005fa0 <kernelvec>
    800029f8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029fc:	6422                	ld	s0,8(sp)
    800029fe:	0141                	addi	sp,sp,16
    80002a00:	8082                	ret

0000000080002a02 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a02:	1141                	addi	sp,sp,-16
    80002a04:	e406                	sd	ra,8(sp)
    80002a06:	e022                	sd	s0,0(sp)
    80002a08:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a0a:	fffff097          	auipc	ra,0xfffff
    80002a0e:	fa2080e7          	jalr	-94(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a12:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a16:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a18:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002a1c:	00004617          	auipc	a2,0x4
    80002a20:	5e460613          	addi	a2,a2,1508 # 80007000 <_trampoline>
    80002a24:	00004697          	auipc	a3,0x4
    80002a28:	5dc68693          	addi	a3,a3,1500 # 80007000 <_trampoline>
    80002a2c:	8e91                	sub	a3,a3,a2
    80002a2e:	040007b7          	lui	a5,0x4000
    80002a32:	17fd                	addi	a5,a5,-1
    80002a34:	07b2                	slli	a5,a5,0xc
    80002a36:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a38:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a3c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a3e:	180026f3          	csrr	a3,satp
    80002a42:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a44:	6d38                	ld	a4,88(a0)
    80002a46:	6134                	ld	a3,64(a0)
    80002a48:	6585                	lui	a1,0x1
    80002a4a:	96ae                	add	a3,a3,a1
    80002a4c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a4e:	6d38                	ld	a4,88(a0)
    80002a50:	00000697          	auipc	a3,0x0
    80002a54:	13068693          	addi	a3,a3,304 # 80002b80 <usertrap>
    80002a58:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a5a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a5c:	8692                	mv	a3,tp
    80002a5e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a60:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a64:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a68:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a6c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a70:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a72:	6f18                	ld	a4,24(a4)
    80002a74:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a78:	6928                	ld	a0,80(a0)
    80002a7a:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002a7c:	00004717          	auipc	a4,0x4
    80002a80:	62070713          	addi	a4,a4,1568 # 8000709c <userret>
    80002a84:	8f11                	sub	a4,a4,a2
    80002a86:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002a88:	577d                	li	a4,-1
    80002a8a:	177e                	slli	a4,a4,0x3f
    80002a8c:	8d59                	or	a0,a0,a4
    80002a8e:	9782                	jalr	a5
}
    80002a90:	60a2                	ld	ra,8(sp)
    80002a92:	6402                	ld	s0,0(sp)
    80002a94:	0141                	addi	sp,sp,16
    80002a96:	8082                	ret

0000000080002a98 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a98:	1101                	addi	sp,sp,-32
    80002a9a:	ec06                	sd	ra,24(sp)
    80002a9c:	e822                	sd	s0,16(sp)
    80002a9e:	e426                	sd	s1,8(sp)
    80002aa0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002aa2:	00014497          	auipc	s1,0x14
    80002aa6:	73e48493          	addi	s1,s1,1854 # 800171e0 <tickslock>
    80002aaa:	8526                	mv	a0,s1
    80002aac:	ffffe097          	auipc	ra,0xffffe
    80002ab0:	12a080e7          	jalr	298(ra) # 80000bd6 <acquire>
  ticks++;
    80002ab4:	00006517          	auipc	a0,0x6
    80002ab8:	e8c50513          	addi	a0,a0,-372 # 80008940 <ticks>
    80002abc:	411c                	lw	a5,0(a0)
    80002abe:	2785                	addiw	a5,a5,1
    80002ac0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002ac2:	fffff097          	auipc	ra,0xfffff
    80002ac6:	5f6080e7          	jalr	1526(ra) # 800020b8 <wakeup>
  release(&tickslock);
    80002aca:	8526                	mv	a0,s1
    80002acc:	ffffe097          	auipc	ra,0xffffe
    80002ad0:	1be080e7          	jalr	446(ra) # 80000c8a <release>
}
    80002ad4:	60e2                	ld	ra,24(sp)
    80002ad6:	6442                	ld	s0,16(sp)
    80002ad8:	64a2                	ld	s1,8(sp)
    80002ada:	6105                	addi	sp,sp,32
    80002adc:	8082                	ret

0000000080002ade <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002ade:	1101                	addi	sp,sp,-32
    80002ae0:	ec06                	sd	ra,24(sp)
    80002ae2:	e822                	sd	s0,16(sp)
    80002ae4:	e426                	sd	s1,8(sp)
    80002ae6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ae8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002aec:	00074d63          	bltz	a4,80002b06 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002af0:	57fd                	li	a5,-1
    80002af2:	17fe                	slli	a5,a5,0x3f
    80002af4:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002af6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002af8:	06f70363          	beq	a4,a5,80002b5e <devintr+0x80>
  }
}
    80002afc:	60e2                	ld	ra,24(sp)
    80002afe:	6442                	ld	s0,16(sp)
    80002b00:	64a2                	ld	s1,8(sp)
    80002b02:	6105                	addi	sp,sp,32
    80002b04:	8082                	ret
     (scause & 0xff) == 9){
    80002b06:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002b0a:	46a5                	li	a3,9
    80002b0c:	fed792e3          	bne	a5,a3,80002af0 <devintr+0x12>
    int irq = plic_claim();
    80002b10:	00003097          	auipc	ra,0x3
    80002b14:	598080e7          	jalr	1432(ra) # 800060a8 <plic_claim>
    80002b18:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b1a:	47a9                	li	a5,10
    80002b1c:	02f50763          	beq	a0,a5,80002b4a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002b20:	4785                	li	a5,1
    80002b22:	02f50963          	beq	a0,a5,80002b54 <devintr+0x76>
    return 1;
    80002b26:	4505                	li	a0,1
    } else if(irq){
    80002b28:	d8f1                	beqz	s1,80002afc <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b2a:	85a6                	mv	a1,s1
    80002b2c:	00006517          	auipc	a0,0x6
    80002b30:	81c50513          	addi	a0,a0,-2020 # 80008348 <states.0+0x38>
    80002b34:	ffffe097          	auipc	ra,0xffffe
    80002b38:	a54080e7          	jalr	-1452(ra) # 80000588 <printf>
      plic_complete(irq);
    80002b3c:	8526                	mv	a0,s1
    80002b3e:	00003097          	auipc	ra,0x3
    80002b42:	58e080e7          	jalr	1422(ra) # 800060cc <plic_complete>
    return 1;
    80002b46:	4505                	li	a0,1
    80002b48:	bf55                	j	80002afc <devintr+0x1e>
      uartintr();
    80002b4a:	ffffe097          	auipc	ra,0xffffe
    80002b4e:	e50080e7          	jalr	-432(ra) # 8000099a <uartintr>
    80002b52:	b7ed                	j	80002b3c <devintr+0x5e>
      virtio_disk_intr();
    80002b54:	00004097          	auipc	ra,0x4
    80002b58:	a44080e7          	jalr	-1468(ra) # 80006598 <virtio_disk_intr>
    80002b5c:	b7c5                	j	80002b3c <devintr+0x5e>
    if(cpuid() == 0){
    80002b5e:	fffff097          	auipc	ra,0xfffff
    80002b62:	e22080e7          	jalr	-478(ra) # 80001980 <cpuid>
    80002b66:	c901                	beqz	a0,80002b76 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b68:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b6c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b6e:	14479073          	csrw	sip,a5
    return 2;
    80002b72:	4509                	li	a0,2
    80002b74:	b761                	j	80002afc <devintr+0x1e>
      clockintr();
    80002b76:	00000097          	auipc	ra,0x0
    80002b7a:	f22080e7          	jalr	-222(ra) # 80002a98 <clockintr>
    80002b7e:	b7ed                	j	80002b68 <devintr+0x8a>

0000000080002b80 <usertrap>:
{
    80002b80:	1101                	addi	sp,sp,-32
    80002b82:	ec06                	sd	ra,24(sp)
    80002b84:	e822                	sd	s0,16(sp)
    80002b86:	e426                	sd	s1,8(sp)
    80002b88:	e04a                	sd	s2,0(sp)
    80002b8a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b8c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b90:	1007f793          	andi	a5,a5,256
    80002b94:	e3b1                	bnez	a5,80002bd8 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b96:	00003797          	auipc	a5,0x3
    80002b9a:	40a78793          	addi	a5,a5,1034 # 80005fa0 <kernelvec>
    80002b9e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ba2:	fffff097          	auipc	ra,0xfffff
    80002ba6:	e0a080e7          	jalr	-502(ra) # 800019ac <myproc>
    80002baa:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002bac:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bae:	14102773          	csrr	a4,sepc
    80002bb2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bb4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002bb8:	47a1                	li	a5,8
    80002bba:	02f70763          	beq	a4,a5,80002be8 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002bbe:	00000097          	auipc	ra,0x0
    80002bc2:	f20080e7          	jalr	-224(ra) # 80002ade <devintr>
    80002bc6:	892a                	mv	s2,a0
    80002bc8:	c151                	beqz	a0,80002c4c <usertrap+0xcc>
  if(killed(p))
    80002bca:	8526                	mv	a0,s1
    80002bcc:	00000097          	auipc	ra,0x0
    80002bd0:	8f8080e7          	jalr	-1800(ra) # 800024c4 <killed>
    80002bd4:	c929                	beqz	a0,80002c26 <usertrap+0xa6>
    80002bd6:	a099                	j	80002c1c <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002bd8:	00005517          	auipc	a0,0x5
    80002bdc:	79050513          	addi	a0,a0,1936 # 80008368 <states.0+0x58>
    80002be0:	ffffe097          	auipc	ra,0xffffe
    80002be4:	95e080e7          	jalr	-1698(ra) # 8000053e <panic>
    if(killed(p))
    80002be8:	00000097          	auipc	ra,0x0
    80002bec:	8dc080e7          	jalr	-1828(ra) # 800024c4 <killed>
    80002bf0:	e921                	bnez	a0,80002c40 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002bf2:	6cb8                	ld	a4,88(s1)
    80002bf4:	6f1c                	ld	a5,24(a4)
    80002bf6:	0791                	addi	a5,a5,4
    80002bf8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bfa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002bfe:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c02:	10079073          	csrw	sstatus,a5
    syscall();
    80002c06:	00000097          	auipc	ra,0x0
    80002c0a:	2d4080e7          	jalr	724(ra) # 80002eda <syscall>
  if(killed(p))
    80002c0e:	8526                	mv	a0,s1
    80002c10:	00000097          	auipc	ra,0x0
    80002c14:	8b4080e7          	jalr	-1868(ra) # 800024c4 <killed>
    80002c18:	c911                	beqz	a0,80002c2c <usertrap+0xac>
    80002c1a:	4901                	li	s2,0
    exit(-1);
    80002c1c:	557d                	li	a0,-1
    80002c1e:	fffff097          	auipc	ra,0xfffff
    80002c22:	732080e7          	jalr	1842(ra) # 80002350 <exit>
  if(which_dev == 2)
    80002c26:	4789                	li	a5,2
    80002c28:	04f90f63          	beq	s2,a5,80002c86 <usertrap+0x106>
  usertrapret();
    80002c2c:	00000097          	auipc	ra,0x0
    80002c30:	dd6080e7          	jalr	-554(ra) # 80002a02 <usertrapret>
}
    80002c34:	60e2                	ld	ra,24(sp)
    80002c36:	6442                	ld	s0,16(sp)
    80002c38:	64a2                	ld	s1,8(sp)
    80002c3a:	6902                	ld	s2,0(sp)
    80002c3c:	6105                	addi	sp,sp,32
    80002c3e:	8082                	ret
      exit(-1);
    80002c40:	557d                	li	a0,-1
    80002c42:	fffff097          	auipc	ra,0xfffff
    80002c46:	70e080e7          	jalr	1806(ra) # 80002350 <exit>
    80002c4a:	b765                	j	80002bf2 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c4c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c50:	5890                	lw	a2,48(s1)
    80002c52:	00005517          	auipc	a0,0x5
    80002c56:	73650513          	addi	a0,a0,1846 # 80008388 <states.0+0x78>
    80002c5a:	ffffe097          	auipc	ra,0xffffe
    80002c5e:	92e080e7          	jalr	-1746(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c62:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c66:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c6a:	00005517          	auipc	a0,0x5
    80002c6e:	74e50513          	addi	a0,a0,1870 # 800083b8 <states.0+0xa8>
    80002c72:	ffffe097          	auipc	ra,0xffffe
    80002c76:	916080e7          	jalr	-1770(ra) # 80000588 <printf>
    setkilled(p);
    80002c7a:	8526                	mv	a0,s1
    80002c7c:	00000097          	auipc	ra,0x0
    80002c80:	81c080e7          	jalr	-2020(ra) # 80002498 <setkilled>
    80002c84:	b769                	j	80002c0e <usertrap+0x8e>
    yield();
    80002c86:	fffff097          	auipc	ra,0xfffff
    80002c8a:	392080e7          	jalr	914(ra) # 80002018 <yield>
    80002c8e:	bf79                	j	80002c2c <usertrap+0xac>

0000000080002c90 <kerneltrap>:
{
    80002c90:	7179                	addi	sp,sp,-48
    80002c92:	f406                	sd	ra,40(sp)
    80002c94:	f022                	sd	s0,32(sp)
    80002c96:	ec26                	sd	s1,24(sp)
    80002c98:	e84a                	sd	s2,16(sp)
    80002c9a:	e44e                	sd	s3,8(sp)
    80002c9c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c9e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ca2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ca6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002caa:	1004f793          	andi	a5,s1,256
    80002cae:	cb85                	beqz	a5,80002cde <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cb0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002cb4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002cb6:	ef85                	bnez	a5,80002cee <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002cb8:	00000097          	auipc	ra,0x0
    80002cbc:	e26080e7          	jalr	-474(ra) # 80002ade <devintr>
    80002cc0:	cd1d                	beqz	a0,80002cfe <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cc2:	4789                	li	a5,2
    80002cc4:	06f50a63          	beq	a0,a5,80002d38 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cc8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ccc:	10049073          	csrw	sstatus,s1
}
    80002cd0:	70a2                	ld	ra,40(sp)
    80002cd2:	7402                	ld	s0,32(sp)
    80002cd4:	64e2                	ld	s1,24(sp)
    80002cd6:	6942                	ld	s2,16(sp)
    80002cd8:	69a2                	ld	s3,8(sp)
    80002cda:	6145                	addi	sp,sp,48
    80002cdc:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002cde:	00005517          	auipc	a0,0x5
    80002ce2:	6fa50513          	addi	a0,a0,1786 # 800083d8 <states.0+0xc8>
    80002ce6:	ffffe097          	auipc	ra,0xffffe
    80002cea:	858080e7          	jalr	-1960(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002cee:	00005517          	auipc	a0,0x5
    80002cf2:	71250513          	addi	a0,a0,1810 # 80008400 <states.0+0xf0>
    80002cf6:	ffffe097          	auipc	ra,0xffffe
    80002cfa:	848080e7          	jalr	-1976(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002cfe:	85ce                	mv	a1,s3
    80002d00:	00005517          	auipc	a0,0x5
    80002d04:	72050513          	addi	a0,a0,1824 # 80008420 <states.0+0x110>
    80002d08:	ffffe097          	auipc	ra,0xffffe
    80002d0c:	880080e7          	jalr	-1920(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d10:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d14:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d18:	00005517          	auipc	a0,0x5
    80002d1c:	71850513          	addi	a0,a0,1816 # 80008430 <states.0+0x120>
    80002d20:	ffffe097          	auipc	ra,0xffffe
    80002d24:	868080e7          	jalr	-1944(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002d28:	00005517          	auipc	a0,0x5
    80002d2c:	72050513          	addi	a0,a0,1824 # 80008448 <states.0+0x138>
    80002d30:	ffffe097          	auipc	ra,0xffffe
    80002d34:	80e080e7          	jalr	-2034(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d38:	fffff097          	auipc	ra,0xfffff
    80002d3c:	c74080e7          	jalr	-908(ra) # 800019ac <myproc>
    80002d40:	d541                	beqz	a0,80002cc8 <kerneltrap+0x38>
    80002d42:	fffff097          	auipc	ra,0xfffff
    80002d46:	c6a080e7          	jalr	-918(ra) # 800019ac <myproc>
    80002d4a:	4d18                	lw	a4,24(a0)
    80002d4c:	4791                	li	a5,4
    80002d4e:	f6f71de3          	bne	a4,a5,80002cc8 <kerneltrap+0x38>
    yield();
    80002d52:	fffff097          	auipc	ra,0xfffff
    80002d56:	2c6080e7          	jalr	710(ra) # 80002018 <yield>
    80002d5a:	b7bd                	j	80002cc8 <kerneltrap+0x38>

0000000080002d5c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d5c:	1101                	addi	sp,sp,-32
    80002d5e:	ec06                	sd	ra,24(sp)
    80002d60:	e822                	sd	s0,16(sp)
    80002d62:	e426                	sd	s1,8(sp)
    80002d64:	1000                	addi	s0,sp,32
    80002d66:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d68:	fffff097          	auipc	ra,0xfffff
    80002d6c:	c44080e7          	jalr	-956(ra) # 800019ac <myproc>
  switch (n) {
    80002d70:	4795                	li	a5,5
    80002d72:	0497e163          	bltu	a5,s1,80002db4 <argraw+0x58>
    80002d76:	048a                	slli	s1,s1,0x2
    80002d78:	00005717          	auipc	a4,0x5
    80002d7c:	70870713          	addi	a4,a4,1800 # 80008480 <states.0+0x170>
    80002d80:	94ba                	add	s1,s1,a4
    80002d82:	409c                	lw	a5,0(s1)
    80002d84:	97ba                	add	a5,a5,a4
    80002d86:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d88:	6d3c                	ld	a5,88(a0)
    80002d8a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d8c:	60e2                	ld	ra,24(sp)
    80002d8e:	6442                	ld	s0,16(sp)
    80002d90:	64a2                	ld	s1,8(sp)
    80002d92:	6105                	addi	sp,sp,32
    80002d94:	8082                	ret
    return p->trapframe->a1;
    80002d96:	6d3c                	ld	a5,88(a0)
    80002d98:	7fa8                	ld	a0,120(a5)
    80002d9a:	bfcd                	j	80002d8c <argraw+0x30>
    return p->trapframe->a2;
    80002d9c:	6d3c                	ld	a5,88(a0)
    80002d9e:	63c8                	ld	a0,128(a5)
    80002da0:	b7f5                	j	80002d8c <argraw+0x30>
    return p->trapframe->a3;
    80002da2:	6d3c                	ld	a5,88(a0)
    80002da4:	67c8                	ld	a0,136(a5)
    80002da6:	b7dd                	j	80002d8c <argraw+0x30>
    return p->trapframe->a4;
    80002da8:	6d3c                	ld	a5,88(a0)
    80002daa:	6bc8                	ld	a0,144(a5)
    80002dac:	b7c5                	j	80002d8c <argraw+0x30>
    return p->trapframe->a5;
    80002dae:	6d3c                	ld	a5,88(a0)
    80002db0:	6fc8                	ld	a0,152(a5)
    80002db2:	bfe9                	j	80002d8c <argraw+0x30>
  panic("argraw");
    80002db4:	00005517          	auipc	a0,0x5
    80002db8:	6a450513          	addi	a0,a0,1700 # 80008458 <states.0+0x148>
    80002dbc:	ffffd097          	auipc	ra,0xffffd
    80002dc0:	782080e7          	jalr	1922(ra) # 8000053e <panic>

0000000080002dc4 <fetchaddr>:
{
    80002dc4:	1101                	addi	sp,sp,-32
    80002dc6:	ec06                	sd	ra,24(sp)
    80002dc8:	e822                	sd	s0,16(sp)
    80002dca:	e426                	sd	s1,8(sp)
    80002dcc:	e04a                	sd	s2,0(sp)
    80002dce:	1000                	addi	s0,sp,32
    80002dd0:	84aa                	mv	s1,a0
    80002dd2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	bd8080e7          	jalr	-1064(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002ddc:	653c                	ld	a5,72(a0)
    80002dde:	02f4f863          	bgeu	s1,a5,80002e0e <fetchaddr+0x4a>
    80002de2:	00848713          	addi	a4,s1,8
    80002de6:	02e7e663          	bltu	a5,a4,80002e12 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002dea:	46a1                	li	a3,8
    80002dec:	8626                	mv	a2,s1
    80002dee:	85ca                	mv	a1,s2
    80002df0:	6928                	ld	a0,80(a0)
    80002df2:	fffff097          	auipc	ra,0xfffff
    80002df6:	902080e7          	jalr	-1790(ra) # 800016f4 <copyin>
    80002dfa:	00a03533          	snez	a0,a0
    80002dfe:	40a00533          	neg	a0,a0
}
    80002e02:	60e2                	ld	ra,24(sp)
    80002e04:	6442                	ld	s0,16(sp)
    80002e06:	64a2                	ld	s1,8(sp)
    80002e08:	6902                	ld	s2,0(sp)
    80002e0a:	6105                	addi	sp,sp,32
    80002e0c:	8082                	ret
    return -1;
    80002e0e:	557d                	li	a0,-1
    80002e10:	bfcd                	j	80002e02 <fetchaddr+0x3e>
    80002e12:	557d                	li	a0,-1
    80002e14:	b7fd                	j	80002e02 <fetchaddr+0x3e>

0000000080002e16 <fetchstr>:
{
    80002e16:	7179                	addi	sp,sp,-48
    80002e18:	f406                	sd	ra,40(sp)
    80002e1a:	f022                	sd	s0,32(sp)
    80002e1c:	ec26                	sd	s1,24(sp)
    80002e1e:	e84a                	sd	s2,16(sp)
    80002e20:	e44e                	sd	s3,8(sp)
    80002e22:	1800                	addi	s0,sp,48
    80002e24:	892a                	mv	s2,a0
    80002e26:	84ae                	mv	s1,a1
    80002e28:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002e2a:	fffff097          	auipc	ra,0xfffff
    80002e2e:	b82080e7          	jalr	-1150(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002e32:	86ce                	mv	a3,s3
    80002e34:	864a                	mv	a2,s2
    80002e36:	85a6                	mv	a1,s1
    80002e38:	6928                	ld	a0,80(a0)
    80002e3a:	fffff097          	auipc	ra,0xfffff
    80002e3e:	948080e7          	jalr	-1720(ra) # 80001782 <copyinstr>
    80002e42:	00054e63          	bltz	a0,80002e5e <fetchstr+0x48>
  return strlen(buf);
    80002e46:	8526                	mv	a0,s1
    80002e48:	ffffe097          	auipc	ra,0xffffe
    80002e4c:	006080e7          	jalr	6(ra) # 80000e4e <strlen>
}
    80002e50:	70a2                	ld	ra,40(sp)
    80002e52:	7402                	ld	s0,32(sp)
    80002e54:	64e2                	ld	s1,24(sp)
    80002e56:	6942                	ld	s2,16(sp)
    80002e58:	69a2                	ld	s3,8(sp)
    80002e5a:	6145                	addi	sp,sp,48
    80002e5c:	8082                	ret
    return -1;
    80002e5e:	557d                	li	a0,-1
    80002e60:	bfc5                	j	80002e50 <fetchstr+0x3a>

0000000080002e62 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002e62:	1101                	addi	sp,sp,-32
    80002e64:	ec06                	sd	ra,24(sp)
    80002e66:	e822                	sd	s0,16(sp)
    80002e68:	e426                	sd	s1,8(sp)
    80002e6a:	1000                	addi	s0,sp,32
    80002e6c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e6e:	00000097          	auipc	ra,0x0
    80002e72:	eee080e7          	jalr	-274(ra) # 80002d5c <argraw>
    80002e76:	c088                	sw	a0,0(s1)
}
    80002e78:	60e2                	ld	ra,24(sp)
    80002e7a:	6442                	ld	s0,16(sp)
    80002e7c:	64a2                	ld	s1,8(sp)
    80002e7e:	6105                	addi	sp,sp,32
    80002e80:	8082                	ret

0000000080002e82 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002e82:	1101                	addi	sp,sp,-32
    80002e84:	ec06                	sd	ra,24(sp)
    80002e86:	e822                	sd	s0,16(sp)
    80002e88:	e426                	sd	s1,8(sp)
    80002e8a:	1000                	addi	s0,sp,32
    80002e8c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e8e:	00000097          	auipc	ra,0x0
    80002e92:	ece080e7          	jalr	-306(ra) # 80002d5c <argraw>
    80002e96:	e088                	sd	a0,0(s1)
}
    80002e98:	60e2                	ld	ra,24(sp)
    80002e9a:	6442                	ld	s0,16(sp)
    80002e9c:	64a2                	ld	s1,8(sp)
    80002e9e:	6105                	addi	sp,sp,32
    80002ea0:	8082                	ret

0000000080002ea2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ea2:	7179                	addi	sp,sp,-48
    80002ea4:	f406                	sd	ra,40(sp)
    80002ea6:	f022                	sd	s0,32(sp)
    80002ea8:	ec26                	sd	s1,24(sp)
    80002eaa:	e84a                	sd	s2,16(sp)
    80002eac:	1800                	addi	s0,sp,48
    80002eae:	84ae                	mv	s1,a1
    80002eb0:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002eb2:	fd840593          	addi	a1,s0,-40
    80002eb6:	00000097          	auipc	ra,0x0
    80002eba:	fcc080e7          	jalr	-52(ra) # 80002e82 <argaddr>
  return fetchstr(addr, buf, max);
    80002ebe:	864a                	mv	a2,s2
    80002ec0:	85a6                	mv	a1,s1
    80002ec2:	fd843503          	ld	a0,-40(s0)
    80002ec6:	00000097          	auipc	ra,0x0
    80002eca:	f50080e7          	jalr	-176(ra) # 80002e16 <fetchstr>
}
    80002ece:	70a2                	ld	ra,40(sp)
    80002ed0:	7402                	ld	s0,32(sp)
    80002ed2:	64e2                	ld	s1,24(sp)
    80002ed4:	6942                	ld	s2,16(sp)
    80002ed6:	6145                	addi	sp,sp,48
    80002ed8:	8082                	ret

0000000080002eda <syscall>:

};

void
syscall(void)
{
    80002eda:	1101                	addi	sp,sp,-32
    80002edc:	ec06                	sd	ra,24(sp)
    80002ede:	e822                	sd	s0,16(sp)
    80002ee0:	e426                	sd	s1,8(sp)
    80002ee2:	e04a                	sd	s2,0(sp)
    80002ee4:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ee6:	fffff097          	auipc	ra,0xfffff
    80002eea:	ac6080e7          	jalr	-1338(ra) # 800019ac <myproc>
    80002eee:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ef0:	05853903          	ld	s2,88(a0)
    80002ef4:	0a893783          	ld	a5,168(s2)
    80002ef8:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002efc:	37fd                	addiw	a5,a5,-1
    80002efe:	475d                	li	a4,23
    80002f00:	00f76f63          	bltu	a4,a5,80002f1e <syscall+0x44>
    80002f04:	00369713          	slli	a4,a3,0x3
    80002f08:	00005797          	auipc	a5,0x5
    80002f0c:	59078793          	addi	a5,a5,1424 # 80008498 <syscalls>
    80002f10:	97ba                	add	a5,a5,a4
    80002f12:	639c                	ld	a5,0(a5)
    80002f14:	c789                	beqz	a5,80002f1e <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002f16:	9782                	jalr	a5
    80002f18:	06a93823          	sd	a0,112(s2)
    80002f1c:	a839                	j	80002f3a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002f1e:	15848613          	addi	a2,s1,344
    80002f22:	588c                	lw	a1,48(s1)
    80002f24:	00005517          	auipc	a0,0x5
    80002f28:	53c50513          	addi	a0,a0,1340 # 80008460 <states.0+0x150>
    80002f2c:	ffffd097          	auipc	ra,0xffffd
    80002f30:	65c080e7          	jalr	1628(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f34:	6cbc                	ld	a5,88(s1)
    80002f36:	577d                	li	a4,-1
    80002f38:	fbb8                	sd	a4,112(a5)
  }
}
    80002f3a:	60e2                	ld	ra,24(sp)
    80002f3c:	6442                	ld	s0,16(sp)
    80002f3e:	64a2                	ld	s1,8(sp)
    80002f40:	6902                	ld	s2,0(sp)
    80002f42:	6105                	addi	sp,sp,32
    80002f44:	8082                	ret

0000000080002f46 <sys_exit>:
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

uint64 sys_exit(void) {
    80002f46:	7139                	addi	sp,sp,-64
    80002f48:	fc06                	sd	ra,56(sp)
    80002f4a:	f822                	sd	s0,48(sp)
    80002f4c:	0080                	addi	s0,sp,64
  int n;
  char exit_msg[32]; // Local buffer for the exit message

  argint(0, &n);
    80002f4e:	fec40593          	addi	a1,s0,-20
    80002f52:	4501                	li	a0,0
    80002f54:	00000097          	auipc	ra,0x0
    80002f58:	f0e080e7          	jalr	-242(ra) # 80002e62 <argint>
  argstr(1, exit_msg, sizeof(exit_msg)); // Copy from userspace to kernelspace
    80002f5c:	02000613          	li	a2,32
    80002f60:	fc840593          	addi	a1,s0,-56
    80002f64:	4505                	li	a0,1
    80002f66:	00000097          	auipc	ra,0x0
    80002f6a:	f3c080e7          	jalr	-196(ra) # 80002ea2 <argstr>

  // Copy the message safely to the process struct
  strncpy(myproc()->exit_msg, exit_msg, 32);
    80002f6e:	fffff097          	auipc	ra,0xfffff
    80002f72:	a3e080e7          	jalr	-1474(ra) # 800019ac <myproc>
    80002f76:	02000613          	li	a2,32
    80002f7a:	fc840593          	addi	a1,s0,-56
    80002f7e:	16850513          	addi	a0,a0,360
    80002f82:	ffffe097          	auipc	ra,0xffffe
    80002f86:	e5c080e7          	jalr	-420(ra) # 80000dde <strncpy>
  myproc()->exit_msg[32] = '\0'; // Ensure null termination
    80002f8a:	fffff097          	auipc	ra,0xfffff
    80002f8e:	a22080e7          	jalr	-1502(ra) # 800019ac <myproc>
    80002f92:	18050423          	sb	zero,392(a0)


  exit(n);
    80002f96:	fec42503          	lw	a0,-20(s0)
    80002f9a:	fffff097          	auipc	ra,0xfffff
    80002f9e:	3b6080e7          	jalr	950(ra) # 80002350 <exit>
  return 0; // Not reached
}
    80002fa2:	4501                	li	a0,0
    80002fa4:	70e2                	ld	ra,56(sp)
    80002fa6:	7442                	ld	s0,48(sp)
    80002fa8:	6121                	addi	sp,sp,64
    80002faa:	8082                	ret

0000000080002fac <sys_getpid>:
uint64
sys_getpid(void)
{
    80002fac:	1141                	addi	sp,sp,-16
    80002fae:	e406                	sd	ra,8(sp)
    80002fb0:	e022                	sd	s0,0(sp)
    80002fb2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002fb4:	fffff097          	auipc	ra,0xfffff
    80002fb8:	9f8080e7          	jalr	-1544(ra) # 800019ac <myproc>
}
    80002fbc:	5908                	lw	a0,48(a0)
    80002fbe:	60a2                	ld	ra,8(sp)
    80002fc0:	6402                	ld	s0,0(sp)
    80002fc2:	0141                	addi	sp,sp,16
    80002fc4:	8082                	ret

0000000080002fc6 <sys_fork>:

uint64
sys_fork(void)
{
    80002fc6:	1141                	addi	sp,sp,-16
    80002fc8:	e406                	sd	ra,8(sp)
    80002fca:	e022                	sd	s0,0(sp)
    80002fcc:	0800                	addi	s0,sp,16
  return fork();
    80002fce:	fffff097          	auipc	ra,0xfffff
    80002fd2:	d94080e7          	jalr	-620(ra) # 80001d62 <fork>
}
    80002fd6:	60a2                	ld	ra,8(sp)
    80002fd8:	6402                	ld	s0,0(sp)
    80002fda:	0141                	addi	sp,sp,16
    80002fdc:	8082                	ret

0000000080002fde <sys_forkn>:


uint64 sys_forkn(void)
{
    80002fde:	1101                	addi	sp,sp,-32
    80002fe0:	ec06                	sd	ra,24(sp)
    80002fe2:	e822                	sd	s0,16(sp)
    80002fe4:	1000                	addi	s0,sp,32
    int n;
    uint64 pids ;  
    argint(0, &n);
    80002fe6:	fec40593          	addi	a1,s0,-20
    80002fea:	4501                	li	a0,0
    80002fec:	00000097          	auipc	ra,0x0
    80002ff0:	e76080e7          	jalr	-394(ra) # 80002e62 <argint>
    argaddr(1,  &pids);  // Get the user-space address for pids
    80002ff4:	fe040593          	addi	a1,s0,-32
    80002ff8:	4505                	li	a0,1
    80002ffa:	00000097          	auipc	ra,0x0
    80002ffe:	e88080e7          	jalr	-376(ra) # 80002e82 <argaddr>
    
    if(n < 1 || n > 16) {
    80003002:	fec42783          	lw	a5,-20(s0)
    80003006:	fff7869b          	addiw	a3,a5,-1
    8000300a:	473d                	li	a4,15
        return -1;  // Invalid number of children
    8000300c:	557d                	li	a0,-1
    if(n < 1 || n > 16) {
    8000300e:	00d76a63          	bltu	a4,a3,80003022 <sys_forkn+0x44>
    }

    // Check if the pids pointer is valid and accessible in user space
    if (pids == 0) {
    80003012:	fe043583          	ld	a1,-32(s0)
    80003016:	c591                	beqz	a1,80003022 <sys_forkn+0x44>
        return -1;  // Invalid address
    }

    return forkn(n, (int*) pids);  // Call the forkn function with the arguments
    80003018:	853e                	mv	a0,a5
    8000301a:	fffff097          	auipc	ra,0xfffff
    8000301e:	114080e7          	jalr	276(ra) # 8000212e <forkn>
}
    80003022:	60e2                	ld	ra,24(sp)
    80003024:	6442                	ld	s0,16(sp)
    80003026:	6105                	addi	sp,sp,32
    80003028:	8082                	ret

000000008000302a <sys_wait>:


uint64 sys_wait(void) {
    8000302a:	1101                	addi	sp,sp,-32
    8000302c:	ec06                	sd	ra,24(sp)
    8000302e:	e822                	sd	s0,16(sp)
    80003030:	1000                	addi	s0,sp,32
    uint64 p;
    uint64 messagePointerAddress;  // Pointer to user-space buffer

    argaddr(0, &p);
    80003032:	fe840593          	addi	a1,s0,-24
    80003036:	4501                	li	a0,0
    80003038:	00000097          	auipc	ra,0x0
    8000303c:	e4a080e7          	jalr	-438(ra) # 80002e82 <argaddr>
    argaddr(1, &messagePointerAddress);
    80003040:	fe040593          	addi	a1,s0,-32
    80003044:	4505                	li	a0,1
    80003046:	00000097          	auipc	ra,0x0
    8000304a:	e3c080e7          	jalr	-452(ra) # 80002e82 <argaddr>

    return  wait(p , messagePointerAddress );  // Wait for child process
    8000304e:	fe043583          	ld	a1,-32(s0)
    80003052:	fe843503          	ld	a0,-24(s0)
    80003056:	fffff097          	auipc	ra,0xfffff
    8000305a:	4a0080e7          	jalr	1184(ra) # 800024f6 <wait>

   }
    8000305e:	60e2                	ld	ra,24(sp)
    80003060:	6442                	ld	s0,16(sp)
    80003062:	6105                	addi	sp,sp,32
    80003064:	8082                	ret

0000000080003066 <sys_waitall>:


uint64 sys_waitall(void) {
    80003066:	1101                	addi	sp,sp,-32
    80003068:	ec06                	sd	ra,24(sp)
    8000306a:	e822                	sd	s0,16(sp)
    8000306c:	1000                	addi	s0,sp,32
    uint64 n;          
    uint64 statuses;  // Pointer to the statuses array 

    argaddr(0, &n);
    8000306e:	fe840593          	addi	a1,s0,-24
    80003072:	4501                	li	a0,0
    80003074:	00000097          	auipc	ra,0x0
    80003078:	e0e080e7          	jalr	-498(ra) # 80002e82 <argaddr>
    argaddr(1, &statuses);
    8000307c:	fe040593          	addi	a1,s0,-32
    80003080:	4505                	li	a0,1
    80003082:	00000097          	auipc	ra,0x0
    80003086:	e00080e7          	jalr	-512(ra) # 80002e82 <argaddr>
    return  waitall(n , statuses );  // Wait for child process
    8000308a:	fe043583          	ld	a1,-32(s0)
    8000308e:	fe843503          	ld	a0,-24(s0)
    80003092:	fffff097          	auipc	ra,0xfffff
    80003096:	5b4080e7          	jalr	1460(ra) # 80002646 <waitall>

   }
    8000309a:	60e2                	ld	ra,24(sp)
    8000309c:	6442                	ld	s0,16(sp)
    8000309e:	6105                	addi	sp,sp,32
    800030a0:	8082                	ret

00000000800030a2 <sys_sbrk>:


uint64
sys_sbrk(void)
{
    800030a2:	7179                	addi	sp,sp,-48
    800030a4:	f406                	sd	ra,40(sp)
    800030a6:	f022                	sd	s0,32(sp)
    800030a8:	ec26                	sd	s1,24(sp)
    800030aa:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    800030ac:	fdc40593          	addi	a1,s0,-36
    800030b0:	4501                	li	a0,0
    800030b2:	00000097          	auipc	ra,0x0
    800030b6:	db0080e7          	jalr	-592(ra) # 80002e62 <argint>
  addr = myproc()->sz;
    800030ba:	fffff097          	auipc	ra,0xfffff
    800030be:	8f2080e7          	jalr	-1806(ra) # 800019ac <myproc>
    800030c2:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    800030c4:	fdc42503          	lw	a0,-36(s0)
    800030c8:	fffff097          	auipc	ra,0xfffff
    800030cc:	c3e080e7          	jalr	-962(ra) # 80001d06 <growproc>
    800030d0:	00054863          	bltz	a0,800030e0 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800030d4:	8526                	mv	a0,s1
    800030d6:	70a2                	ld	ra,40(sp)
    800030d8:	7402                	ld	s0,32(sp)
    800030da:	64e2                	ld	s1,24(sp)
    800030dc:	6145                	addi	sp,sp,48
    800030de:	8082                	ret
    return -1;
    800030e0:	54fd                	li	s1,-1
    800030e2:	bfcd                	j	800030d4 <sys_sbrk+0x32>

00000000800030e4 <sys_sleep>:

uint64
sys_sleep(void)
{
    800030e4:	7139                	addi	sp,sp,-64
    800030e6:	fc06                	sd	ra,56(sp)
    800030e8:	f822                	sd	s0,48(sp)
    800030ea:	f426                	sd	s1,40(sp)
    800030ec:	f04a                	sd	s2,32(sp)
    800030ee:	ec4e                	sd	s3,24(sp)
    800030f0:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800030f2:	fcc40593          	addi	a1,s0,-52
    800030f6:	4501                	li	a0,0
    800030f8:	00000097          	auipc	ra,0x0
    800030fc:	d6a080e7          	jalr	-662(ra) # 80002e62 <argint>
  acquire(&tickslock);
    80003100:	00014517          	auipc	a0,0x14
    80003104:	0e050513          	addi	a0,a0,224 # 800171e0 <tickslock>
    80003108:	ffffe097          	auipc	ra,0xffffe
    8000310c:	ace080e7          	jalr	-1330(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80003110:	00006917          	auipc	s2,0x6
    80003114:	83092903          	lw	s2,-2000(s2) # 80008940 <ticks>
  while (ticks - ticks0 < n)
    80003118:	fcc42783          	lw	a5,-52(s0)
    8000311c:	cf9d                	beqz	a5,8000315a <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000311e:	00014997          	auipc	s3,0x14
    80003122:	0c298993          	addi	s3,s3,194 # 800171e0 <tickslock>
    80003126:	00006497          	auipc	s1,0x6
    8000312a:	81a48493          	addi	s1,s1,-2022 # 80008940 <ticks>
    if (killed(myproc()))
    8000312e:	fffff097          	auipc	ra,0xfffff
    80003132:	87e080e7          	jalr	-1922(ra) # 800019ac <myproc>
    80003136:	fffff097          	auipc	ra,0xfffff
    8000313a:	38e080e7          	jalr	910(ra) # 800024c4 <killed>
    8000313e:	ed15                	bnez	a0,8000317a <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003140:	85ce                	mv	a1,s3
    80003142:	8526                	mv	a0,s1
    80003144:	fffff097          	auipc	ra,0xfffff
    80003148:	f10080e7          	jalr	-240(ra) # 80002054 <sleep>
  while (ticks - ticks0 < n)
    8000314c:	409c                	lw	a5,0(s1)
    8000314e:	412787bb          	subw	a5,a5,s2
    80003152:	fcc42703          	lw	a4,-52(s0)
    80003156:	fce7ece3          	bltu	a5,a4,8000312e <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000315a:	00014517          	auipc	a0,0x14
    8000315e:	08650513          	addi	a0,a0,134 # 800171e0 <tickslock>
    80003162:	ffffe097          	auipc	ra,0xffffe
    80003166:	b28080e7          	jalr	-1240(ra) # 80000c8a <release>
  return 0;
    8000316a:	4501                	li	a0,0
}
    8000316c:	70e2                	ld	ra,56(sp)
    8000316e:	7442                	ld	s0,48(sp)
    80003170:	74a2                	ld	s1,40(sp)
    80003172:	7902                	ld	s2,32(sp)
    80003174:	69e2                	ld	s3,24(sp)
    80003176:	6121                	addi	sp,sp,64
    80003178:	8082                	ret
      release(&tickslock);
    8000317a:	00014517          	auipc	a0,0x14
    8000317e:	06650513          	addi	a0,a0,102 # 800171e0 <tickslock>
    80003182:	ffffe097          	auipc	ra,0xffffe
    80003186:	b08080e7          	jalr	-1272(ra) # 80000c8a <release>
      return -1;
    8000318a:	557d                	li	a0,-1
    8000318c:	b7c5                	j	8000316c <sys_sleep+0x88>

000000008000318e <sys_kill>:

uint64
sys_kill(void)
{
    8000318e:	1101                	addi	sp,sp,-32
    80003190:	ec06                	sd	ra,24(sp)
    80003192:	e822                	sd	s0,16(sp)
    80003194:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003196:	fec40593          	addi	a1,s0,-20
    8000319a:	4501                	li	a0,0
    8000319c:	00000097          	auipc	ra,0x0
    800031a0:	cc6080e7          	jalr	-826(ra) # 80002e62 <argint>
  return kill(pid);
    800031a4:	fec42503          	lw	a0,-20(s0)
    800031a8:	fffff097          	auipc	ra,0xfffff
    800031ac:	27e080e7          	jalr	638(ra) # 80002426 <kill>
}
    800031b0:	60e2                	ld	ra,24(sp)
    800031b2:	6442                	ld	s0,16(sp)
    800031b4:	6105                	addi	sp,sp,32
    800031b6:	8082                	ret

00000000800031b8 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800031b8:	1101                	addi	sp,sp,-32
    800031ba:	ec06                	sd	ra,24(sp)
    800031bc:	e822                	sd	s0,16(sp)
    800031be:	e426                	sd	s1,8(sp)
    800031c0:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800031c2:	00014517          	auipc	a0,0x14
    800031c6:	01e50513          	addi	a0,a0,30 # 800171e0 <tickslock>
    800031ca:	ffffe097          	auipc	ra,0xffffe
    800031ce:	a0c080e7          	jalr	-1524(ra) # 80000bd6 <acquire>
  xticks = ticks;
    800031d2:	00005497          	auipc	s1,0x5
    800031d6:	76e4a483          	lw	s1,1902(s1) # 80008940 <ticks>
  release(&tickslock);
    800031da:	00014517          	auipc	a0,0x14
    800031de:	00650513          	addi	a0,a0,6 # 800171e0 <tickslock>
    800031e2:	ffffe097          	auipc	ra,0xffffe
    800031e6:	aa8080e7          	jalr	-1368(ra) # 80000c8a <release>
  return xticks;
}
    800031ea:	02049513          	slli	a0,s1,0x20
    800031ee:	9101                	srli	a0,a0,0x20
    800031f0:	60e2                	ld	ra,24(sp)
    800031f2:	6442                	ld	s0,16(sp)
    800031f4:	64a2                	ld	s1,8(sp)
    800031f6:	6105                	addi	sp,sp,32
    800031f8:	8082                	ret

00000000800031fa <sys_memsize>:

uint64 sys_memsize(void)
{
    800031fa:	1141                	addi	sp,sp,-16
    800031fc:	e406                	sd	ra,8(sp)
    800031fe:	e022                	sd	s0,0(sp)
    80003200:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80003202:	ffffe097          	auipc	ra,0xffffe
    80003206:	7aa080e7          	jalr	1962(ra) # 800019ac <myproc>
  return p->sz; // Process size in bytes
}
    8000320a:	6528                	ld	a0,72(a0)
    8000320c:	60a2                	ld	ra,8(sp)
    8000320e:	6402                	ld	s0,0(sp)
    80003210:	0141                	addi	sp,sp,16
    80003212:	8082                	ret

0000000080003214 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003214:	7179                	addi	sp,sp,-48
    80003216:	f406                	sd	ra,40(sp)
    80003218:	f022                	sd	s0,32(sp)
    8000321a:	ec26                	sd	s1,24(sp)
    8000321c:	e84a                	sd	s2,16(sp)
    8000321e:	e44e                	sd	s3,8(sp)
    80003220:	e052                	sd	s4,0(sp)
    80003222:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003224:	00005597          	auipc	a1,0x5
    80003228:	33c58593          	addi	a1,a1,828 # 80008560 <syscalls+0xc8>
    8000322c:	00014517          	auipc	a0,0x14
    80003230:	fcc50513          	addi	a0,a0,-52 # 800171f8 <bcache>
    80003234:	ffffe097          	auipc	ra,0xffffe
    80003238:	912080e7          	jalr	-1774(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000323c:	0001c797          	auipc	a5,0x1c
    80003240:	fbc78793          	addi	a5,a5,-68 # 8001f1f8 <bcache+0x8000>
    80003244:	0001c717          	auipc	a4,0x1c
    80003248:	21c70713          	addi	a4,a4,540 # 8001f460 <bcache+0x8268>
    8000324c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003250:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003254:	00014497          	auipc	s1,0x14
    80003258:	fbc48493          	addi	s1,s1,-68 # 80017210 <bcache+0x18>
    b->next = bcache.head.next;
    8000325c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000325e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003260:	00005a17          	auipc	s4,0x5
    80003264:	308a0a13          	addi	s4,s4,776 # 80008568 <syscalls+0xd0>
    b->next = bcache.head.next;
    80003268:	2b893783          	ld	a5,696(s2)
    8000326c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000326e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003272:	85d2                	mv	a1,s4
    80003274:	01048513          	addi	a0,s1,16
    80003278:	00001097          	auipc	ra,0x1
    8000327c:	4c4080e7          	jalr	1220(ra) # 8000473c <initsleeplock>
    bcache.head.next->prev = b;
    80003280:	2b893783          	ld	a5,696(s2)
    80003284:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003286:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000328a:	45848493          	addi	s1,s1,1112
    8000328e:	fd349de3          	bne	s1,s3,80003268 <binit+0x54>
  }
}
    80003292:	70a2                	ld	ra,40(sp)
    80003294:	7402                	ld	s0,32(sp)
    80003296:	64e2                	ld	s1,24(sp)
    80003298:	6942                	ld	s2,16(sp)
    8000329a:	69a2                	ld	s3,8(sp)
    8000329c:	6a02                	ld	s4,0(sp)
    8000329e:	6145                	addi	sp,sp,48
    800032a0:	8082                	ret

00000000800032a2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800032a2:	7179                	addi	sp,sp,-48
    800032a4:	f406                	sd	ra,40(sp)
    800032a6:	f022                	sd	s0,32(sp)
    800032a8:	ec26                	sd	s1,24(sp)
    800032aa:	e84a                	sd	s2,16(sp)
    800032ac:	e44e                	sd	s3,8(sp)
    800032ae:	1800                	addi	s0,sp,48
    800032b0:	892a                	mv	s2,a0
    800032b2:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800032b4:	00014517          	auipc	a0,0x14
    800032b8:	f4450513          	addi	a0,a0,-188 # 800171f8 <bcache>
    800032bc:	ffffe097          	auipc	ra,0xffffe
    800032c0:	91a080e7          	jalr	-1766(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800032c4:	0001c497          	auipc	s1,0x1c
    800032c8:	1ec4b483          	ld	s1,492(s1) # 8001f4b0 <bcache+0x82b8>
    800032cc:	0001c797          	auipc	a5,0x1c
    800032d0:	19478793          	addi	a5,a5,404 # 8001f460 <bcache+0x8268>
    800032d4:	02f48f63          	beq	s1,a5,80003312 <bread+0x70>
    800032d8:	873e                	mv	a4,a5
    800032da:	a021                	j	800032e2 <bread+0x40>
    800032dc:	68a4                	ld	s1,80(s1)
    800032de:	02e48a63          	beq	s1,a4,80003312 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800032e2:	449c                	lw	a5,8(s1)
    800032e4:	ff279ce3          	bne	a5,s2,800032dc <bread+0x3a>
    800032e8:	44dc                	lw	a5,12(s1)
    800032ea:	ff3799e3          	bne	a5,s3,800032dc <bread+0x3a>
      b->refcnt++;
    800032ee:	40bc                	lw	a5,64(s1)
    800032f0:	2785                	addiw	a5,a5,1
    800032f2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800032f4:	00014517          	auipc	a0,0x14
    800032f8:	f0450513          	addi	a0,a0,-252 # 800171f8 <bcache>
    800032fc:	ffffe097          	auipc	ra,0xffffe
    80003300:	98e080e7          	jalr	-1650(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003304:	01048513          	addi	a0,s1,16
    80003308:	00001097          	auipc	ra,0x1
    8000330c:	46e080e7          	jalr	1134(ra) # 80004776 <acquiresleep>
      return b;
    80003310:	a8b9                	j	8000336e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003312:	0001c497          	auipc	s1,0x1c
    80003316:	1964b483          	ld	s1,406(s1) # 8001f4a8 <bcache+0x82b0>
    8000331a:	0001c797          	auipc	a5,0x1c
    8000331e:	14678793          	addi	a5,a5,326 # 8001f460 <bcache+0x8268>
    80003322:	00f48863          	beq	s1,a5,80003332 <bread+0x90>
    80003326:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003328:	40bc                	lw	a5,64(s1)
    8000332a:	cf81                	beqz	a5,80003342 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000332c:	64a4                	ld	s1,72(s1)
    8000332e:	fee49de3          	bne	s1,a4,80003328 <bread+0x86>
  panic("bget: no buffers");
    80003332:	00005517          	auipc	a0,0x5
    80003336:	23e50513          	addi	a0,a0,574 # 80008570 <syscalls+0xd8>
    8000333a:	ffffd097          	auipc	ra,0xffffd
    8000333e:	204080e7          	jalr	516(ra) # 8000053e <panic>
      b->dev = dev;
    80003342:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003346:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000334a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000334e:	4785                	li	a5,1
    80003350:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003352:	00014517          	auipc	a0,0x14
    80003356:	ea650513          	addi	a0,a0,-346 # 800171f8 <bcache>
    8000335a:	ffffe097          	auipc	ra,0xffffe
    8000335e:	930080e7          	jalr	-1744(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003362:	01048513          	addi	a0,s1,16
    80003366:	00001097          	auipc	ra,0x1
    8000336a:	410080e7          	jalr	1040(ra) # 80004776 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000336e:	409c                	lw	a5,0(s1)
    80003370:	cb89                	beqz	a5,80003382 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003372:	8526                	mv	a0,s1
    80003374:	70a2                	ld	ra,40(sp)
    80003376:	7402                	ld	s0,32(sp)
    80003378:	64e2                	ld	s1,24(sp)
    8000337a:	6942                	ld	s2,16(sp)
    8000337c:	69a2                	ld	s3,8(sp)
    8000337e:	6145                	addi	sp,sp,48
    80003380:	8082                	ret
    virtio_disk_rw(b, 0);
    80003382:	4581                	li	a1,0
    80003384:	8526                	mv	a0,s1
    80003386:	00003097          	auipc	ra,0x3
    8000338a:	fde080e7          	jalr	-34(ra) # 80006364 <virtio_disk_rw>
    b->valid = 1;
    8000338e:	4785                	li	a5,1
    80003390:	c09c                	sw	a5,0(s1)
  return b;
    80003392:	b7c5                	j	80003372 <bread+0xd0>

0000000080003394 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003394:	1101                	addi	sp,sp,-32
    80003396:	ec06                	sd	ra,24(sp)
    80003398:	e822                	sd	s0,16(sp)
    8000339a:	e426                	sd	s1,8(sp)
    8000339c:	1000                	addi	s0,sp,32
    8000339e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033a0:	0541                	addi	a0,a0,16
    800033a2:	00001097          	auipc	ra,0x1
    800033a6:	46e080e7          	jalr	1134(ra) # 80004810 <holdingsleep>
    800033aa:	cd01                	beqz	a0,800033c2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800033ac:	4585                	li	a1,1
    800033ae:	8526                	mv	a0,s1
    800033b0:	00003097          	auipc	ra,0x3
    800033b4:	fb4080e7          	jalr	-76(ra) # 80006364 <virtio_disk_rw>
}
    800033b8:	60e2                	ld	ra,24(sp)
    800033ba:	6442                	ld	s0,16(sp)
    800033bc:	64a2                	ld	s1,8(sp)
    800033be:	6105                	addi	sp,sp,32
    800033c0:	8082                	ret
    panic("bwrite");
    800033c2:	00005517          	auipc	a0,0x5
    800033c6:	1c650513          	addi	a0,a0,454 # 80008588 <syscalls+0xf0>
    800033ca:	ffffd097          	auipc	ra,0xffffd
    800033ce:	174080e7          	jalr	372(ra) # 8000053e <panic>

00000000800033d2 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800033d2:	1101                	addi	sp,sp,-32
    800033d4:	ec06                	sd	ra,24(sp)
    800033d6:	e822                	sd	s0,16(sp)
    800033d8:	e426                	sd	s1,8(sp)
    800033da:	e04a                	sd	s2,0(sp)
    800033dc:	1000                	addi	s0,sp,32
    800033de:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033e0:	01050913          	addi	s2,a0,16
    800033e4:	854a                	mv	a0,s2
    800033e6:	00001097          	auipc	ra,0x1
    800033ea:	42a080e7          	jalr	1066(ra) # 80004810 <holdingsleep>
    800033ee:	c92d                	beqz	a0,80003460 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800033f0:	854a                	mv	a0,s2
    800033f2:	00001097          	auipc	ra,0x1
    800033f6:	3da080e7          	jalr	986(ra) # 800047cc <releasesleep>

  acquire(&bcache.lock);
    800033fa:	00014517          	auipc	a0,0x14
    800033fe:	dfe50513          	addi	a0,a0,-514 # 800171f8 <bcache>
    80003402:	ffffd097          	auipc	ra,0xffffd
    80003406:	7d4080e7          	jalr	2004(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000340a:	40bc                	lw	a5,64(s1)
    8000340c:	37fd                	addiw	a5,a5,-1
    8000340e:	0007871b          	sext.w	a4,a5
    80003412:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003414:	eb05                	bnez	a4,80003444 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003416:	68bc                	ld	a5,80(s1)
    80003418:	64b8                	ld	a4,72(s1)
    8000341a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000341c:	64bc                	ld	a5,72(s1)
    8000341e:	68b8                	ld	a4,80(s1)
    80003420:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003422:	0001c797          	auipc	a5,0x1c
    80003426:	dd678793          	addi	a5,a5,-554 # 8001f1f8 <bcache+0x8000>
    8000342a:	2b87b703          	ld	a4,696(a5)
    8000342e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003430:	0001c717          	auipc	a4,0x1c
    80003434:	03070713          	addi	a4,a4,48 # 8001f460 <bcache+0x8268>
    80003438:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000343a:	2b87b703          	ld	a4,696(a5)
    8000343e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003440:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003444:	00014517          	auipc	a0,0x14
    80003448:	db450513          	addi	a0,a0,-588 # 800171f8 <bcache>
    8000344c:	ffffe097          	auipc	ra,0xffffe
    80003450:	83e080e7          	jalr	-1986(ra) # 80000c8a <release>
}
    80003454:	60e2                	ld	ra,24(sp)
    80003456:	6442                	ld	s0,16(sp)
    80003458:	64a2                	ld	s1,8(sp)
    8000345a:	6902                	ld	s2,0(sp)
    8000345c:	6105                	addi	sp,sp,32
    8000345e:	8082                	ret
    panic("brelse");
    80003460:	00005517          	auipc	a0,0x5
    80003464:	13050513          	addi	a0,a0,304 # 80008590 <syscalls+0xf8>
    80003468:	ffffd097          	auipc	ra,0xffffd
    8000346c:	0d6080e7          	jalr	214(ra) # 8000053e <panic>

0000000080003470 <bpin>:

void
bpin(struct buf *b) {
    80003470:	1101                	addi	sp,sp,-32
    80003472:	ec06                	sd	ra,24(sp)
    80003474:	e822                	sd	s0,16(sp)
    80003476:	e426                	sd	s1,8(sp)
    80003478:	1000                	addi	s0,sp,32
    8000347a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000347c:	00014517          	auipc	a0,0x14
    80003480:	d7c50513          	addi	a0,a0,-644 # 800171f8 <bcache>
    80003484:	ffffd097          	auipc	ra,0xffffd
    80003488:	752080e7          	jalr	1874(ra) # 80000bd6 <acquire>
  b->refcnt++;
    8000348c:	40bc                	lw	a5,64(s1)
    8000348e:	2785                	addiw	a5,a5,1
    80003490:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003492:	00014517          	auipc	a0,0x14
    80003496:	d6650513          	addi	a0,a0,-666 # 800171f8 <bcache>
    8000349a:	ffffd097          	auipc	ra,0xffffd
    8000349e:	7f0080e7          	jalr	2032(ra) # 80000c8a <release>
}
    800034a2:	60e2                	ld	ra,24(sp)
    800034a4:	6442                	ld	s0,16(sp)
    800034a6:	64a2                	ld	s1,8(sp)
    800034a8:	6105                	addi	sp,sp,32
    800034aa:	8082                	ret

00000000800034ac <bunpin>:

void
bunpin(struct buf *b) {
    800034ac:	1101                	addi	sp,sp,-32
    800034ae:	ec06                	sd	ra,24(sp)
    800034b0:	e822                	sd	s0,16(sp)
    800034b2:	e426                	sd	s1,8(sp)
    800034b4:	1000                	addi	s0,sp,32
    800034b6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034b8:	00014517          	auipc	a0,0x14
    800034bc:	d4050513          	addi	a0,a0,-704 # 800171f8 <bcache>
    800034c0:	ffffd097          	auipc	ra,0xffffd
    800034c4:	716080e7          	jalr	1814(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800034c8:	40bc                	lw	a5,64(s1)
    800034ca:	37fd                	addiw	a5,a5,-1
    800034cc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034ce:	00014517          	auipc	a0,0x14
    800034d2:	d2a50513          	addi	a0,a0,-726 # 800171f8 <bcache>
    800034d6:	ffffd097          	auipc	ra,0xffffd
    800034da:	7b4080e7          	jalr	1972(ra) # 80000c8a <release>
}
    800034de:	60e2                	ld	ra,24(sp)
    800034e0:	6442                	ld	s0,16(sp)
    800034e2:	64a2                	ld	s1,8(sp)
    800034e4:	6105                	addi	sp,sp,32
    800034e6:	8082                	ret

00000000800034e8 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800034e8:	1101                	addi	sp,sp,-32
    800034ea:	ec06                	sd	ra,24(sp)
    800034ec:	e822                	sd	s0,16(sp)
    800034ee:	e426                	sd	s1,8(sp)
    800034f0:	e04a                	sd	s2,0(sp)
    800034f2:	1000                	addi	s0,sp,32
    800034f4:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800034f6:	00d5d59b          	srliw	a1,a1,0xd
    800034fa:	0001c797          	auipc	a5,0x1c
    800034fe:	3da7a783          	lw	a5,986(a5) # 8001f8d4 <sb+0x1c>
    80003502:	9dbd                	addw	a1,a1,a5
    80003504:	00000097          	auipc	ra,0x0
    80003508:	d9e080e7          	jalr	-610(ra) # 800032a2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000350c:	0074f713          	andi	a4,s1,7
    80003510:	4785                	li	a5,1
    80003512:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003516:	14ce                	slli	s1,s1,0x33
    80003518:	90d9                	srli	s1,s1,0x36
    8000351a:	00950733          	add	a4,a0,s1
    8000351e:	05874703          	lbu	a4,88(a4)
    80003522:	00e7f6b3          	and	a3,a5,a4
    80003526:	c69d                	beqz	a3,80003554 <bfree+0x6c>
    80003528:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000352a:	94aa                	add	s1,s1,a0
    8000352c:	fff7c793          	not	a5,a5
    80003530:	8ff9                	and	a5,a5,a4
    80003532:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003536:	00001097          	auipc	ra,0x1
    8000353a:	120080e7          	jalr	288(ra) # 80004656 <log_write>
  brelse(bp);
    8000353e:	854a                	mv	a0,s2
    80003540:	00000097          	auipc	ra,0x0
    80003544:	e92080e7          	jalr	-366(ra) # 800033d2 <brelse>
}
    80003548:	60e2                	ld	ra,24(sp)
    8000354a:	6442                	ld	s0,16(sp)
    8000354c:	64a2                	ld	s1,8(sp)
    8000354e:	6902                	ld	s2,0(sp)
    80003550:	6105                	addi	sp,sp,32
    80003552:	8082                	ret
    panic("freeing free block");
    80003554:	00005517          	auipc	a0,0x5
    80003558:	04450513          	addi	a0,a0,68 # 80008598 <syscalls+0x100>
    8000355c:	ffffd097          	auipc	ra,0xffffd
    80003560:	fe2080e7          	jalr	-30(ra) # 8000053e <panic>

0000000080003564 <balloc>:
{
    80003564:	711d                	addi	sp,sp,-96
    80003566:	ec86                	sd	ra,88(sp)
    80003568:	e8a2                	sd	s0,80(sp)
    8000356a:	e4a6                	sd	s1,72(sp)
    8000356c:	e0ca                	sd	s2,64(sp)
    8000356e:	fc4e                	sd	s3,56(sp)
    80003570:	f852                	sd	s4,48(sp)
    80003572:	f456                	sd	s5,40(sp)
    80003574:	f05a                	sd	s6,32(sp)
    80003576:	ec5e                	sd	s7,24(sp)
    80003578:	e862                	sd	s8,16(sp)
    8000357a:	e466                	sd	s9,8(sp)
    8000357c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000357e:	0001c797          	auipc	a5,0x1c
    80003582:	33e7a783          	lw	a5,830(a5) # 8001f8bc <sb+0x4>
    80003586:	10078163          	beqz	a5,80003688 <balloc+0x124>
    8000358a:	8baa                	mv	s7,a0
    8000358c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000358e:	0001cb17          	auipc	s6,0x1c
    80003592:	32ab0b13          	addi	s6,s6,810 # 8001f8b8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003596:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003598:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000359a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000359c:	6c89                	lui	s9,0x2
    8000359e:	a061                	j	80003626 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800035a0:	974a                	add	a4,a4,s2
    800035a2:	8fd5                	or	a5,a5,a3
    800035a4:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800035a8:	854a                	mv	a0,s2
    800035aa:	00001097          	auipc	ra,0x1
    800035ae:	0ac080e7          	jalr	172(ra) # 80004656 <log_write>
        brelse(bp);
    800035b2:	854a                	mv	a0,s2
    800035b4:	00000097          	auipc	ra,0x0
    800035b8:	e1e080e7          	jalr	-482(ra) # 800033d2 <brelse>
  bp = bread(dev, bno);
    800035bc:	85a6                	mv	a1,s1
    800035be:	855e                	mv	a0,s7
    800035c0:	00000097          	auipc	ra,0x0
    800035c4:	ce2080e7          	jalr	-798(ra) # 800032a2 <bread>
    800035c8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800035ca:	40000613          	li	a2,1024
    800035ce:	4581                	li	a1,0
    800035d0:	05850513          	addi	a0,a0,88
    800035d4:	ffffd097          	auipc	ra,0xffffd
    800035d8:	6fe080e7          	jalr	1790(ra) # 80000cd2 <memset>
  log_write(bp);
    800035dc:	854a                	mv	a0,s2
    800035de:	00001097          	auipc	ra,0x1
    800035e2:	078080e7          	jalr	120(ra) # 80004656 <log_write>
  brelse(bp);
    800035e6:	854a                	mv	a0,s2
    800035e8:	00000097          	auipc	ra,0x0
    800035ec:	dea080e7          	jalr	-534(ra) # 800033d2 <brelse>
}
    800035f0:	8526                	mv	a0,s1
    800035f2:	60e6                	ld	ra,88(sp)
    800035f4:	6446                	ld	s0,80(sp)
    800035f6:	64a6                	ld	s1,72(sp)
    800035f8:	6906                	ld	s2,64(sp)
    800035fa:	79e2                	ld	s3,56(sp)
    800035fc:	7a42                	ld	s4,48(sp)
    800035fe:	7aa2                	ld	s5,40(sp)
    80003600:	7b02                	ld	s6,32(sp)
    80003602:	6be2                	ld	s7,24(sp)
    80003604:	6c42                	ld	s8,16(sp)
    80003606:	6ca2                	ld	s9,8(sp)
    80003608:	6125                	addi	sp,sp,96
    8000360a:	8082                	ret
    brelse(bp);
    8000360c:	854a                	mv	a0,s2
    8000360e:	00000097          	auipc	ra,0x0
    80003612:	dc4080e7          	jalr	-572(ra) # 800033d2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003616:	015c87bb          	addw	a5,s9,s5
    8000361a:	00078a9b          	sext.w	s5,a5
    8000361e:	004b2703          	lw	a4,4(s6)
    80003622:	06eaf363          	bgeu	s5,a4,80003688 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003626:	41fad79b          	sraiw	a5,s5,0x1f
    8000362a:	0137d79b          	srliw	a5,a5,0x13
    8000362e:	015787bb          	addw	a5,a5,s5
    80003632:	40d7d79b          	sraiw	a5,a5,0xd
    80003636:	01cb2583          	lw	a1,28(s6)
    8000363a:	9dbd                	addw	a1,a1,a5
    8000363c:	855e                	mv	a0,s7
    8000363e:	00000097          	auipc	ra,0x0
    80003642:	c64080e7          	jalr	-924(ra) # 800032a2 <bread>
    80003646:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003648:	004b2503          	lw	a0,4(s6)
    8000364c:	000a849b          	sext.w	s1,s5
    80003650:	8662                	mv	a2,s8
    80003652:	faa4fde3          	bgeu	s1,a0,8000360c <balloc+0xa8>
      m = 1 << (bi % 8);
    80003656:	41f6579b          	sraiw	a5,a2,0x1f
    8000365a:	01d7d69b          	srliw	a3,a5,0x1d
    8000365e:	00c6873b          	addw	a4,a3,a2
    80003662:	00777793          	andi	a5,a4,7
    80003666:	9f95                	subw	a5,a5,a3
    80003668:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000366c:	4037571b          	sraiw	a4,a4,0x3
    80003670:	00e906b3          	add	a3,s2,a4
    80003674:	0586c683          	lbu	a3,88(a3)
    80003678:	00d7f5b3          	and	a1,a5,a3
    8000367c:	d195                	beqz	a1,800035a0 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000367e:	2605                	addiw	a2,a2,1
    80003680:	2485                	addiw	s1,s1,1
    80003682:	fd4618e3          	bne	a2,s4,80003652 <balloc+0xee>
    80003686:	b759                	j	8000360c <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003688:	00005517          	auipc	a0,0x5
    8000368c:	f2850513          	addi	a0,a0,-216 # 800085b0 <syscalls+0x118>
    80003690:	ffffd097          	auipc	ra,0xffffd
    80003694:	ef8080e7          	jalr	-264(ra) # 80000588 <printf>
  return 0;
    80003698:	4481                	li	s1,0
    8000369a:	bf99                	j	800035f0 <balloc+0x8c>

000000008000369c <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000369c:	7179                	addi	sp,sp,-48
    8000369e:	f406                	sd	ra,40(sp)
    800036a0:	f022                	sd	s0,32(sp)
    800036a2:	ec26                	sd	s1,24(sp)
    800036a4:	e84a                	sd	s2,16(sp)
    800036a6:	e44e                	sd	s3,8(sp)
    800036a8:	e052                	sd	s4,0(sp)
    800036aa:	1800                	addi	s0,sp,48
    800036ac:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800036ae:	47ad                	li	a5,11
    800036b0:	02b7e763          	bltu	a5,a1,800036de <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800036b4:	02059493          	slli	s1,a1,0x20
    800036b8:	9081                	srli	s1,s1,0x20
    800036ba:	048a                	slli	s1,s1,0x2
    800036bc:	94aa                	add	s1,s1,a0
    800036be:	0504a903          	lw	s2,80(s1)
    800036c2:	06091e63          	bnez	s2,8000373e <bmap+0xa2>
      addr = balloc(ip->dev);
    800036c6:	4108                	lw	a0,0(a0)
    800036c8:	00000097          	auipc	ra,0x0
    800036cc:	e9c080e7          	jalr	-356(ra) # 80003564 <balloc>
    800036d0:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800036d4:	06090563          	beqz	s2,8000373e <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800036d8:	0524a823          	sw	s2,80(s1)
    800036dc:	a08d                	j	8000373e <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800036de:	ff45849b          	addiw	s1,a1,-12
    800036e2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800036e6:	0ff00793          	li	a5,255
    800036ea:	08e7e563          	bltu	a5,a4,80003774 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800036ee:	08052903          	lw	s2,128(a0)
    800036f2:	00091d63          	bnez	s2,8000370c <bmap+0x70>
      addr = balloc(ip->dev);
    800036f6:	4108                	lw	a0,0(a0)
    800036f8:	00000097          	auipc	ra,0x0
    800036fc:	e6c080e7          	jalr	-404(ra) # 80003564 <balloc>
    80003700:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003704:	02090d63          	beqz	s2,8000373e <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003708:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000370c:	85ca                	mv	a1,s2
    8000370e:	0009a503          	lw	a0,0(s3)
    80003712:	00000097          	auipc	ra,0x0
    80003716:	b90080e7          	jalr	-1136(ra) # 800032a2 <bread>
    8000371a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000371c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003720:	02049593          	slli	a1,s1,0x20
    80003724:	9181                	srli	a1,a1,0x20
    80003726:	058a                	slli	a1,a1,0x2
    80003728:	00b784b3          	add	s1,a5,a1
    8000372c:	0004a903          	lw	s2,0(s1)
    80003730:	02090063          	beqz	s2,80003750 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003734:	8552                	mv	a0,s4
    80003736:	00000097          	auipc	ra,0x0
    8000373a:	c9c080e7          	jalr	-868(ra) # 800033d2 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000373e:	854a                	mv	a0,s2
    80003740:	70a2                	ld	ra,40(sp)
    80003742:	7402                	ld	s0,32(sp)
    80003744:	64e2                	ld	s1,24(sp)
    80003746:	6942                	ld	s2,16(sp)
    80003748:	69a2                	ld	s3,8(sp)
    8000374a:	6a02                	ld	s4,0(sp)
    8000374c:	6145                	addi	sp,sp,48
    8000374e:	8082                	ret
      addr = balloc(ip->dev);
    80003750:	0009a503          	lw	a0,0(s3)
    80003754:	00000097          	auipc	ra,0x0
    80003758:	e10080e7          	jalr	-496(ra) # 80003564 <balloc>
    8000375c:	0005091b          	sext.w	s2,a0
      if(addr){
    80003760:	fc090ae3          	beqz	s2,80003734 <bmap+0x98>
        a[bn] = addr;
    80003764:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003768:	8552                	mv	a0,s4
    8000376a:	00001097          	auipc	ra,0x1
    8000376e:	eec080e7          	jalr	-276(ra) # 80004656 <log_write>
    80003772:	b7c9                	j	80003734 <bmap+0x98>
  panic("bmap: out of range");
    80003774:	00005517          	auipc	a0,0x5
    80003778:	e5450513          	addi	a0,a0,-428 # 800085c8 <syscalls+0x130>
    8000377c:	ffffd097          	auipc	ra,0xffffd
    80003780:	dc2080e7          	jalr	-574(ra) # 8000053e <panic>

0000000080003784 <iget>:
{
    80003784:	7179                	addi	sp,sp,-48
    80003786:	f406                	sd	ra,40(sp)
    80003788:	f022                	sd	s0,32(sp)
    8000378a:	ec26                	sd	s1,24(sp)
    8000378c:	e84a                	sd	s2,16(sp)
    8000378e:	e44e                	sd	s3,8(sp)
    80003790:	e052                	sd	s4,0(sp)
    80003792:	1800                	addi	s0,sp,48
    80003794:	89aa                	mv	s3,a0
    80003796:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003798:	0001c517          	auipc	a0,0x1c
    8000379c:	14050513          	addi	a0,a0,320 # 8001f8d8 <itable>
    800037a0:	ffffd097          	auipc	ra,0xffffd
    800037a4:	436080e7          	jalr	1078(ra) # 80000bd6 <acquire>
  empty = 0;
    800037a8:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037aa:	0001c497          	auipc	s1,0x1c
    800037ae:	14648493          	addi	s1,s1,326 # 8001f8f0 <itable+0x18>
    800037b2:	0001e697          	auipc	a3,0x1e
    800037b6:	bce68693          	addi	a3,a3,-1074 # 80021380 <log>
    800037ba:	a039                	j	800037c8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037bc:	02090b63          	beqz	s2,800037f2 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037c0:	08848493          	addi	s1,s1,136
    800037c4:	02d48a63          	beq	s1,a3,800037f8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800037c8:	449c                	lw	a5,8(s1)
    800037ca:	fef059e3          	blez	a5,800037bc <iget+0x38>
    800037ce:	4098                	lw	a4,0(s1)
    800037d0:	ff3716e3          	bne	a4,s3,800037bc <iget+0x38>
    800037d4:	40d8                	lw	a4,4(s1)
    800037d6:	ff4713e3          	bne	a4,s4,800037bc <iget+0x38>
      ip->ref++;
    800037da:	2785                	addiw	a5,a5,1
    800037dc:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800037de:	0001c517          	auipc	a0,0x1c
    800037e2:	0fa50513          	addi	a0,a0,250 # 8001f8d8 <itable>
    800037e6:	ffffd097          	auipc	ra,0xffffd
    800037ea:	4a4080e7          	jalr	1188(ra) # 80000c8a <release>
      return ip;
    800037ee:	8926                	mv	s2,s1
    800037f0:	a03d                	j	8000381e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037f2:	f7f9                	bnez	a5,800037c0 <iget+0x3c>
    800037f4:	8926                	mv	s2,s1
    800037f6:	b7e9                	j	800037c0 <iget+0x3c>
  if(empty == 0)
    800037f8:	02090c63          	beqz	s2,80003830 <iget+0xac>
  ip->dev = dev;
    800037fc:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003800:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003804:	4785                	li	a5,1
    80003806:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000380a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000380e:	0001c517          	auipc	a0,0x1c
    80003812:	0ca50513          	addi	a0,a0,202 # 8001f8d8 <itable>
    80003816:	ffffd097          	auipc	ra,0xffffd
    8000381a:	474080e7          	jalr	1140(ra) # 80000c8a <release>
}
    8000381e:	854a                	mv	a0,s2
    80003820:	70a2                	ld	ra,40(sp)
    80003822:	7402                	ld	s0,32(sp)
    80003824:	64e2                	ld	s1,24(sp)
    80003826:	6942                	ld	s2,16(sp)
    80003828:	69a2                	ld	s3,8(sp)
    8000382a:	6a02                	ld	s4,0(sp)
    8000382c:	6145                	addi	sp,sp,48
    8000382e:	8082                	ret
    panic("iget: no inodes");
    80003830:	00005517          	auipc	a0,0x5
    80003834:	db050513          	addi	a0,a0,-592 # 800085e0 <syscalls+0x148>
    80003838:	ffffd097          	auipc	ra,0xffffd
    8000383c:	d06080e7          	jalr	-762(ra) # 8000053e <panic>

0000000080003840 <fsinit>:
fsinit(int dev) {
    80003840:	7179                	addi	sp,sp,-48
    80003842:	f406                	sd	ra,40(sp)
    80003844:	f022                	sd	s0,32(sp)
    80003846:	ec26                	sd	s1,24(sp)
    80003848:	e84a                	sd	s2,16(sp)
    8000384a:	e44e                	sd	s3,8(sp)
    8000384c:	1800                	addi	s0,sp,48
    8000384e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003850:	4585                	li	a1,1
    80003852:	00000097          	auipc	ra,0x0
    80003856:	a50080e7          	jalr	-1456(ra) # 800032a2 <bread>
    8000385a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000385c:	0001c997          	auipc	s3,0x1c
    80003860:	05c98993          	addi	s3,s3,92 # 8001f8b8 <sb>
    80003864:	02000613          	li	a2,32
    80003868:	05850593          	addi	a1,a0,88
    8000386c:	854e                	mv	a0,s3
    8000386e:	ffffd097          	auipc	ra,0xffffd
    80003872:	4c0080e7          	jalr	1216(ra) # 80000d2e <memmove>
  brelse(bp);
    80003876:	8526                	mv	a0,s1
    80003878:	00000097          	auipc	ra,0x0
    8000387c:	b5a080e7          	jalr	-1190(ra) # 800033d2 <brelse>
  if(sb.magic != FSMAGIC)
    80003880:	0009a703          	lw	a4,0(s3)
    80003884:	102037b7          	lui	a5,0x10203
    80003888:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000388c:	02f71263          	bne	a4,a5,800038b0 <fsinit+0x70>
  initlog(dev, &sb);
    80003890:	0001c597          	auipc	a1,0x1c
    80003894:	02858593          	addi	a1,a1,40 # 8001f8b8 <sb>
    80003898:	854a                	mv	a0,s2
    8000389a:	00001097          	auipc	ra,0x1
    8000389e:	b40080e7          	jalr	-1216(ra) # 800043da <initlog>
}
    800038a2:	70a2                	ld	ra,40(sp)
    800038a4:	7402                	ld	s0,32(sp)
    800038a6:	64e2                	ld	s1,24(sp)
    800038a8:	6942                	ld	s2,16(sp)
    800038aa:	69a2                	ld	s3,8(sp)
    800038ac:	6145                	addi	sp,sp,48
    800038ae:	8082                	ret
    panic("invalid file system");
    800038b0:	00005517          	auipc	a0,0x5
    800038b4:	d4050513          	addi	a0,a0,-704 # 800085f0 <syscalls+0x158>
    800038b8:	ffffd097          	auipc	ra,0xffffd
    800038bc:	c86080e7          	jalr	-890(ra) # 8000053e <panic>

00000000800038c0 <iinit>:
{
    800038c0:	7179                	addi	sp,sp,-48
    800038c2:	f406                	sd	ra,40(sp)
    800038c4:	f022                	sd	s0,32(sp)
    800038c6:	ec26                	sd	s1,24(sp)
    800038c8:	e84a                	sd	s2,16(sp)
    800038ca:	e44e                	sd	s3,8(sp)
    800038cc:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800038ce:	00005597          	auipc	a1,0x5
    800038d2:	d3a58593          	addi	a1,a1,-710 # 80008608 <syscalls+0x170>
    800038d6:	0001c517          	auipc	a0,0x1c
    800038da:	00250513          	addi	a0,a0,2 # 8001f8d8 <itable>
    800038de:	ffffd097          	auipc	ra,0xffffd
    800038e2:	268080e7          	jalr	616(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800038e6:	0001c497          	auipc	s1,0x1c
    800038ea:	01a48493          	addi	s1,s1,26 # 8001f900 <itable+0x28>
    800038ee:	0001e997          	auipc	s3,0x1e
    800038f2:	aa298993          	addi	s3,s3,-1374 # 80021390 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800038f6:	00005917          	auipc	s2,0x5
    800038fa:	d1a90913          	addi	s2,s2,-742 # 80008610 <syscalls+0x178>
    800038fe:	85ca                	mv	a1,s2
    80003900:	8526                	mv	a0,s1
    80003902:	00001097          	auipc	ra,0x1
    80003906:	e3a080e7          	jalr	-454(ra) # 8000473c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000390a:	08848493          	addi	s1,s1,136
    8000390e:	ff3498e3          	bne	s1,s3,800038fe <iinit+0x3e>
}
    80003912:	70a2                	ld	ra,40(sp)
    80003914:	7402                	ld	s0,32(sp)
    80003916:	64e2                	ld	s1,24(sp)
    80003918:	6942                	ld	s2,16(sp)
    8000391a:	69a2                	ld	s3,8(sp)
    8000391c:	6145                	addi	sp,sp,48
    8000391e:	8082                	ret

0000000080003920 <ialloc>:
{
    80003920:	715d                	addi	sp,sp,-80
    80003922:	e486                	sd	ra,72(sp)
    80003924:	e0a2                	sd	s0,64(sp)
    80003926:	fc26                	sd	s1,56(sp)
    80003928:	f84a                	sd	s2,48(sp)
    8000392a:	f44e                	sd	s3,40(sp)
    8000392c:	f052                	sd	s4,32(sp)
    8000392e:	ec56                	sd	s5,24(sp)
    80003930:	e85a                	sd	s6,16(sp)
    80003932:	e45e                	sd	s7,8(sp)
    80003934:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003936:	0001c717          	auipc	a4,0x1c
    8000393a:	f8e72703          	lw	a4,-114(a4) # 8001f8c4 <sb+0xc>
    8000393e:	4785                	li	a5,1
    80003940:	04e7fa63          	bgeu	a5,a4,80003994 <ialloc+0x74>
    80003944:	8aaa                	mv	s5,a0
    80003946:	8bae                	mv	s7,a1
    80003948:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000394a:	0001ca17          	auipc	s4,0x1c
    8000394e:	f6ea0a13          	addi	s4,s4,-146 # 8001f8b8 <sb>
    80003952:	00048b1b          	sext.w	s6,s1
    80003956:	0044d793          	srli	a5,s1,0x4
    8000395a:	018a2583          	lw	a1,24(s4)
    8000395e:	9dbd                	addw	a1,a1,a5
    80003960:	8556                	mv	a0,s5
    80003962:	00000097          	auipc	ra,0x0
    80003966:	940080e7          	jalr	-1728(ra) # 800032a2 <bread>
    8000396a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000396c:	05850993          	addi	s3,a0,88
    80003970:	00f4f793          	andi	a5,s1,15
    80003974:	079a                	slli	a5,a5,0x6
    80003976:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003978:	00099783          	lh	a5,0(s3)
    8000397c:	c3a1                	beqz	a5,800039bc <ialloc+0x9c>
    brelse(bp);
    8000397e:	00000097          	auipc	ra,0x0
    80003982:	a54080e7          	jalr	-1452(ra) # 800033d2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003986:	0485                	addi	s1,s1,1
    80003988:	00ca2703          	lw	a4,12(s4)
    8000398c:	0004879b          	sext.w	a5,s1
    80003990:	fce7e1e3          	bltu	a5,a4,80003952 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003994:	00005517          	auipc	a0,0x5
    80003998:	c8450513          	addi	a0,a0,-892 # 80008618 <syscalls+0x180>
    8000399c:	ffffd097          	auipc	ra,0xffffd
    800039a0:	bec080e7          	jalr	-1044(ra) # 80000588 <printf>
  return 0;
    800039a4:	4501                	li	a0,0
}
    800039a6:	60a6                	ld	ra,72(sp)
    800039a8:	6406                	ld	s0,64(sp)
    800039aa:	74e2                	ld	s1,56(sp)
    800039ac:	7942                	ld	s2,48(sp)
    800039ae:	79a2                	ld	s3,40(sp)
    800039b0:	7a02                	ld	s4,32(sp)
    800039b2:	6ae2                	ld	s5,24(sp)
    800039b4:	6b42                	ld	s6,16(sp)
    800039b6:	6ba2                	ld	s7,8(sp)
    800039b8:	6161                	addi	sp,sp,80
    800039ba:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800039bc:	04000613          	li	a2,64
    800039c0:	4581                	li	a1,0
    800039c2:	854e                	mv	a0,s3
    800039c4:	ffffd097          	auipc	ra,0xffffd
    800039c8:	30e080e7          	jalr	782(ra) # 80000cd2 <memset>
      dip->type = type;
    800039cc:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800039d0:	854a                	mv	a0,s2
    800039d2:	00001097          	auipc	ra,0x1
    800039d6:	c84080e7          	jalr	-892(ra) # 80004656 <log_write>
      brelse(bp);
    800039da:	854a                	mv	a0,s2
    800039dc:	00000097          	auipc	ra,0x0
    800039e0:	9f6080e7          	jalr	-1546(ra) # 800033d2 <brelse>
      return iget(dev, inum);
    800039e4:	85da                	mv	a1,s6
    800039e6:	8556                	mv	a0,s5
    800039e8:	00000097          	auipc	ra,0x0
    800039ec:	d9c080e7          	jalr	-612(ra) # 80003784 <iget>
    800039f0:	bf5d                	j	800039a6 <ialloc+0x86>

00000000800039f2 <iupdate>:
{
    800039f2:	1101                	addi	sp,sp,-32
    800039f4:	ec06                	sd	ra,24(sp)
    800039f6:	e822                	sd	s0,16(sp)
    800039f8:	e426                	sd	s1,8(sp)
    800039fa:	e04a                	sd	s2,0(sp)
    800039fc:	1000                	addi	s0,sp,32
    800039fe:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a00:	415c                	lw	a5,4(a0)
    80003a02:	0047d79b          	srliw	a5,a5,0x4
    80003a06:	0001c597          	auipc	a1,0x1c
    80003a0a:	eca5a583          	lw	a1,-310(a1) # 8001f8d0 <sb+0x18>
    80003a0e:	9dbd                	addw	a1,a1,a5
    80003a10:	4108                	lw	a0,0(a0)
    80003a12:	00000097          	auipc	ra,0x0
    80003a16:	890080e7          	jalr	-1904(ra) # 800032a2 <bread>
    80003a1a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a1c:	05850793          	addi	a5,a0,88
    80003a20:	40c8                	lw	a0,4(s1)
    80003a22:	893d                	andi	a0,a0,15
    80003a24:	051a                	slli	a0,a0,0x6
    80003a26:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003a28:	04449703          	lh	a4,68(s1)
    80003a2c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003a30:	04649703          	lh	a4,70(s1)
    80003a34:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003a38:	04849703          	lh	a4,72(s1)
    80003a3c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003a40:	04a49703          	lh	a4,74(s1)
    80003a44:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003a48:	44f8                	lw	a4,76(s1)
    80003a4a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a4c:	03400613          	li	a2,52
    80003a50:	05048593          	addi	a1,s1,80
    80003a54:	0531                	addi	a0,a0,12
    80003a56:	ffffd097          	auipc	ra,0xffffd
    80003a5a:	2d8080e7          	jalr	728(ra) # 80000d2e <memmove>
  log_write(bp);
    80003a5e:	854a                	mv	a0,s2
    80003a60:	00001097          	auipc	ra,0x1
    80003a64:	bf6080e7          	jalr	-1034(ra) # 80004656 <log_write>
  brelse(bp);
    80003a68:	854a                	mv	a0,s2
    80003a6a:	00000097          	auipc	ra,0x0
    80003a6e:	968080e7          	jalr	-1688(ra) # 800033d2 <brelse>
}
    80003a72:	60e2                	ld	ra,24(sp)
    80003a74:	6442                	ld	s0,16(sp)
    80003a76:	64a2                	ld	s1,8(sp)
    80003a78:	6902                	ld	s2,0(sp)
    80003a7a:	6105                	addi	sp,sp,32
    80003a7c:	8082                	ret

0000000080003a7e <idup>:
{
    80003a7e:	1101                	addi	sp,sp,-32
    80003a80:	ec06                	sd	ra,24(sp)
    80003a82:	e822                	sd	s0,16(sp)
    80003a84:	e426                	sd	s1,8(sp)
    80003a86:	1000                	addi	s0,sp,32
    80003a88:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a8a:	0001c517          	auipc	a0,0x1c
    80003a8e:	e4e50513          	addi	a0,a0,-434 # 8001f8d8 <itable>
    80003a92:	ffffd097          	auipc	ra,0xffffd
    80003a96:	144080e7          	jalr	324(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003a9a:	449c                	lw	a5,8(s1)
    80003a9c:	2785                	addiw	a5,a5,1
    80003a9e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003aa0:	0001c517          	auipc	a0,0x1c
    80003aa4:	e3850513          	addi	a0,a0,-456 # 8001f8d8 <itable>
    80003aa8:	ffffd097          	auipc	ra,0xffffd
    80003aac:	1e2080e7          	jalr	482(ra) # 80000c8a <release>
}
    80003ab0:	8526                	mv	a0,s1
    80003ab2:	60e2                	ld	ra,24(sp)
    80003ab4:	6442                	ld	s0,16(sp)
    80003ab6:	64a2                	ld	s1,8(sp)
    80003ab8:	6105                	addi	sp,sp,32
    80003aba:	8082                	ret

0000000080003abc <ilock>:
{
    80003abc:	1101                	addi	sp,sp,-32
    80003abe:	ec06                	sd	ra,24(sp)
    80003ac0:	e822                	sd	s0,16(sp)
    80003ac2:	e426                	sd	s1,8(sp)
    80003ac4:	e04a                	sd	s2,0(sp)
    80003ac6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ac8:	c115                	beqz	a0,80003aec <ilock+0x30>
    80003aca:	84aa                	mv	s1,a0
    80003acc:	451c                	lw	a5,8(a0)
    80003ace:	00f05f63          	blez	a5,80003aec <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ad2:	0541                	addi	a0,a0,16
    80003ad4:	00001097          	auipc	ra,0x1
    80003ad8:	ca2080e7          	jalr	-862(ra) # 80004776 <acquiresleep>
  if(ip->valid == 0){
    80003adc:	40bc                	lw	a5,64(s1)
    80003ade:	cf99                	beqz	a5,80003afc <ilock+0x40>
}
    80003ae0:	60e2                	ld	ra,24(sp)
    80003ae2:	6442                	ld	s0,16(sp)
    80003ae4:	64a2                	ld	s1,8(sp)
    80003ae6:	6902                	ld	s2,0(sp)
    80003ae8:	6105                	addi	sp,sp,32
    80003aea:	8082                	ret
    panic("ilock");
    80003aec:	00005517          	auipc	a0,0x5
    80003af0:	b4450513          	addi	a0,a0,-1212 # 80008630 <syscalls+0x198>
    80003af4:	ffffd097          	auipc	ra,0xffffd
    80003af8:	a4a080e7          	jalr	-1462(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003afc:	40dc                	lw	a5,4(s1)
    80003afe:	0047d79b          	srliw	a5,a5,0x4
    80003b02:	0001c597          	auipc	a1,0x1c
    80003b06:	dce5a583          	lw	a1,-562(a1) # 8001f8d0 <sb+0x18>
    80003b0a:	9dbd                	addw	a1,a1,a5
    80003b0c:	4088                	lw	a0,0(s1)
    80003b0e:	fffff097          	auipc	ra,0xfffff
    80003b12:	794080e7          	jalr	1940(ra) # 800032a2 <bread>
    80003b16:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b18:	05850593          	addi	a1,a0,88
    80003b1c:	40dc                	lw	a5,4(s1)
    80003b1e:	8bbd                	andi	a5,a5,15
    80003b20:	079a                	slli	a5,a5,0x6
    80003b22:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b24:	00059783          	lh	a5,0(a1)
    80003b28:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b2c:	00259783          	lh	a5,2(a1)
    80003b30:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b34:	00459783          	lh	a5,4(a1)
    80003b38:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b3c:	00659783          	lh	a5,6(a1)
    80003b40:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b44:	459c                	lw	a5,8(a1)
    80003b46:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b48:	03400613          	li	a2,52
    80003b4c:	05b1                	addi	a1,a1,12
    80003b4e:	05048513          	addi	a0,s1,80
    80003b52:	ffffd097          	auipc	ra,0xffffd
    80003b56:	1dc080e7          	jalr	476(ra) # 80000d2e <memmove>
    brelse(bp);
    80003b5a:	854a                	mv	a0,s2
    80003b5c:	00000097          	auipc	ra,0x0
    80003b60:	876080e7          	jalr	-1930(ra) # 800033d2 <brelse>
    ip->valid = 1;
    80003b64:	4785                	li	a5,1
    80003b66:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003b68:	04449783          	lh	a5,68(s1)
    80003b6c:	fbb5                	bnez	a5,80003ae0 <ilock+0x24>
      panic("ilock: no type");
    80003b6e:	00005517          	auipc	a0,0x5
    80003b72:	aca50513          	addi	a0,a0,-1334 # 80008638 <syscalls+0x1a0>
    80003b76:	ffffd097          	auipc	ra,0xffffd
    80003b7a:	9c8080e7          	jalr	-1592(ra) # 8000053e <panic>

0000000080003b7e <iunlock>:
{
    80003b7e:	1101                	addi	sp,sp,-32
    80003b80:	ec06                	sd	ra,24(sp)
    80003b82:	e822                	sd	s0,16(sp)
    80003b84:	e426                	sd	s1,8(sp)
    80003b86:	e04a                	sd	s2,0(sp)
    80003b88:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003b8a:	c905                	beqz	a0,80003bba <iunlock+0x3c>
    80003b8c:	84aa                	mv	s1,a0
    80003b8e:	01050913          	addi	s2,a0,16
    80003b92:	854a                	mv	a0,s2
    80003b94:	00001097          	auipc	ra,0x1
    80003b98:	c7c080e7          	jalr	-900(ra) # 80004810 <holdingsleep>
    80003b9c:	cd19                	beqz	a0,80003bba <iunlock+0x3c>
    80003b9e:	449c                	lw	a5,8(s1)
    80003ba0:	00f05d63          	blez	a5,80003bba <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ba4:	854a                	mv	a0,s2
    80003ba6:	00001097          	auipc	ra,0x1
    80003baa:	c26080e7          	jalr	-986(ra) # 800047cc <releasesleep>
}
    80003bae:	60e2                	ld	ra,24(sp)
    80003bb0:	6442                	ld	s0,16(sp)
    80003bb2:	64a2                	ld	s1,8(sp)
    80003bb4:	6902                	ld	s2,0(sp)
    80003bb6:	6105                	addi	sp,sp,32
    80003bb8:	8082                	ret
    panic("iunlock");
    80003bba:	00005517          	auipc	a0,0x5
    80003bbe:	a8e50513          	addi	a0,a0,-1394 # 80008648 <syscalls+0x1b0>
    80003bc2:	ffffd097          	auipc	ra,0xffffd
    80003bc6:	97c080e7          	jalr	-1668(ra) # 8000053e <panic>

0000000080003bca <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003bca:	7179                	addi	sp,sp,-48
    80003bcc:	f406                	sd	ra,40(sp)
    80003bce:	f022                	sd	s0,32(sp)
    80003bd0:	ec26                	sd	s1,24(sp)
    80003bd2:	e84a                	sd	s2,16(sp)
    80003bd4:	e44e                	sd	s3,8(sp)
    80003bd6:	e052                	sd	s4,0(sp)
    80003bd8:	1800                	addi	s0,sp,48
    80003bda:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003bdc:	05050493          	addi	s1,a0,80
    80003be0:	08050913          	addi	s2,a0,128
    80003be4:	a021                	j	80003bec <itrunc+0x22>
    80003be6:	0491                	addi	s1,s1,4
    80003be8:	01248d63          	beq	s1,s2,80003c02 <itrunc+0x38>
    if(ip->addrs[i]){
    80003bec:	408c                	lw	a1,0(s1)
    80003bee:	dde5                	beqz	a1,80003be6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003bf0:	0009a503          	lw	a0,0(s3)
    80003bf4:	00000097          	auipc	ra,0x0
    80003bf8:	8f4080e7          	jalr	-1804(ra) # 800034e8 <bfree>
      ip->addrs[i] = 0;
    80003bfc:	0004a023          	sw	zero,0(s1)
    80003c00:	b7dd                	j	80003be6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c02:	0809a583          	lw	a1,128(s3)
    80003c06:	e185                	bnez	a1,80003c26 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c08:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c0c:	854e                	mv	a0,s3
    80003c0e:	00000097          	auipc	ra,0x0
    80003c12:	de4080e7          	jalr	-540(ra) # 800039f2 <iupdate>
}
    80003c16:	70a2                	ld	ra,40(sp)
    80003c18:	7402                	ld	s0,32(sp)
    80003c1a:	64e2                	ld	s1,24(sp)
    80003c1c:	6942                	ld	s2,16(sp)
    80003c1e:	69a2                	ld	s3,8(sp)
    80003c20:	6a02                	ld	s4,0(sp)
    80003c22:	6145                	addi	sp,sp,48
    80003c24:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c26:	0009a503          	lw	a0,0(s3)
    80003c2a:	fffff097          	auipc	ra,0xfffff
    80003c2e:	678080e7          	jalr	1656(ra) # 800032a2 <bread>
    80003c32:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c34:	05850493          	addi	s1,a0,88
    80003c38:	45850913          	addi	s2,a0,1112
    80003c3c:	a021                	j	80003c44 <itrunc+0x7a>
    80003c3e:	0491                	addi	s1,s1,4
    80003c40:	01248b63          	beq	s1,s2,80003c56 <itrunc+0x8c>
      if(a[j])
    80003c44:	408c                	lw	a1,0(s1)
    80003c46:	dde5                	beqz	a1,80003c3e <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003c48:	0009a503          	lw	a0,0(s3)
    80003c4c:	00000097          	auipc	ra,0x0
    80003c50:	89c080e7          	jalr	-1892(ra) # 800034e8 <bfree>
    80003c54:	b7ed                	j	80003c3e <itrunc+0x74>
    brelse(bp);
    80003c56:	8552                	mv	a0,s4
    80003c58:	fffff097          	auipc	ra,0xfffff
    80003c5c:	77a080e7          	jalr	1914(ra) # 800033d2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003c60:	0809a583          	lw	a1,128(s3)
    80003c64:	0009a503          	lw	a0,0(s3)
    80003c68:	00000097          	auipc	ra,0x0
    80003c6c:	880080e7          	jalr	-1920(ra) # 800034e8 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003c70:	0809a023          	sw	zero,128(s3)
    80003c74:	bf51                	j	80003c08 <itrunc+0x3e>

0000000080003c76 <iput>:
{
    80003c76:	1101                	addi	sp,sp,-32
    80003c78:	ec06                	sd	ra,24(sp)
    80003c7a:	e822                	sd	s0,16(sp)
    80003c7c:	e426                	sd	s1,8(sp)
    80003c7e:	e04a                	sd	s2,0(sp)
    80003c80:	1000                	addi	s0,sp,32
    80003c82:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c84:	0001c517          	auipc	a0,0x1c
    80003c88:	c5450513          	addi	a0,a0,-940 # 8001f8d8 <itable>
    80003c8c:	ffffd097          	auipc	ra,0xffffd
    80003c90:	f4a080e7          	jalr	-182(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003c94:	4498                	lw	a4,8(s1)
    80003c96:	4785                	li	a5,1
    80003c98:	02f70363          	beq	a4,a5,80003cbe <iput+0x48>
  ip->ref--;
    80003c9c:	449c                	lw	a5,8(s1)
    80003c9e:	37fd                	addiw	a5,a5,-1
    80003ca0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ca2:	0001c517          	auipc	a0,0x1c
    80003ca6:	c3650513          	addi	a0,a0,-970 # 8001f8d8 <itable>
    80003caa:	ffffd097          	auipc	ra,0xffffd
    80003cae:	fe0080e7          	jalr	-32(ra) # 80000c8a <release>
}
    80003cb2:	60e2                	ld	ra,24(sp)
    80003cb4:	6442                	ld	s0,16(sp)
    80003cb6:	64a2                	ld	s1,8(sp)
    80003cb8:	6902                	ld	s2,0(sp)
    80003cba:	6105                	addi	sp,sp,32
    80003cbc:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cbe:	40bc                	lw	a5,64(s1)
    80003cc0:	dff1                	beqz	a5,80003c9c <iput+0x26>
    80003cc2:	04a49783          	lh	a5,74(s1)
    80003cc6:	fbf9                	bnez	a5,80003c9c <iput+0x26>
    acquiresleep(&ip->lock);
    80003cc8:	01048913          	addi	s2,s1,16
    80003ccc:	854a                	mv	a0,s2
    80003cce:	00001097          	auipc	ra,0x1
    80003cd2:	aa8080e7          	jalr	-1368(ra) # 80004776 <acquiresleep>
    release(&itable.lock);
    80003cd6:	0001c517          	auipc	a0,0x1c
    80003cda:	c0250513          	addi	a0,a0,-1022 # 8001f8d8 <itable>
    80003cde:	ffffd097          	auipc	ra,0xffffd
    80003ce2:	fac080e7          	jalr	-84(ra) # 80000c8a <release>
    itrunc(ip);
    80003ce6:	8526                	mv	a0,s1
    80003ce8:	00000097          	auipc	ra,0x0
    80003cec:	ee2080e7          	jalr	-286(ra) # 80003bca <itrunc>
    ip->type = 0;
    80003cf0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003cf4:	8526                	mv	a0,s1
    80003cf6:	00000097          	auipc	ra,0x0
    80003cfa:	cfc080e7          	jalr	-772(ra) # 800039f2 <iupdate>
    ip->valid = 0;
    80003cfe:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d02:	854a                	mv	a0,s2
    80003d04:	00001097          	auipc	ra,0x1
    80003d08:	ac8080e7          	jalr	-1336(ra) # 800047cc <releasesleep>
    acquire(&itable.lock);
    80003d0c:	0001c517          	auipc	a0,0x1c
    80003d10:	bcc50513          	addi	a0,a0,-1076 # 8001f8d8 <itable>
    80003d14:	ffffd097          	auipc	ra,0xffffd
    80003d18:	ec2080e7          	jalr	-318(ra) # 80000bd6 <acquire>
    80003d1c:	b741                	j	80003c9c <iput+0x26>

0000000080003d1e <iunlockput>:
{
    80003d1e:	1101                	addi	sp,sp,-32
    80003d20:	ec06                	sd	ra,24(sp)
    80003d22:	e822                	sd	s0,16(sp)
    80003d24:	e426                	sd	s1,8(sp)
    80003d26:	1000                	addi	s0,sp,32
    80003d28:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d2a:	00000097          	auipc	ra,0x0
    80003d2e:	e54080e7          	jalr	-428(ra) # 80003b7e <iunlock>
  iput(ip);
    80003d32:	8526                	mv	a0,s1
    80003d34:	00000097          	auipc	ra,0x0
    80003d38:	f42080e7          	jalr	-190(ra) # 80003c76 <iput>
}
    80003d3c:	60e2                	ld	ra,24(sp)
    80003d3e:	6442                	ld	s0,16(sp)
    80003d40:	64a2                	ld	s1,8(sp)
    80003d42:	6105                	addi	sp,sp,32
    80003d44:	8082                	ret

0000000080003d46 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d46:	1141                	addi	sp,sp,-16
    80003d48:	e422                	sd	s0,8(sp)
    80003d4a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d4c:	411c                	lw	a5,0(a0)
    80003d4e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d50:	415c                	lw	a5,4(a0)
    80003d52:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d54:	04451783          	lh	a5,68(a0)
    80003d58:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003d5c:	04a51783          	lh	a5,74(a0)
    80003d60:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d64:	04c56783          	lwu	a5,76(a0)
    80003d68:	e99c                	sd	a5,16(a1)
}
    80003d6a:	6422                	ld	s0,8(sp)
    80003d6c:	0141                	addi	sp,sp,16
    80003d6e:	8082                	ret

0000000080003d70 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d70:	457c                	lw	a5,76(a0)
    80003d72:	0ed7e963          	bltu	a5,a3,80003e64 <readi+0xf4>
{
    80003d76:	7159                	addi	sp,sp,-112
    80003d78:	f486                	sd	ra,104(sp)
    80003d7a:	f0a2                	sd	s0,96(sp)
    80003d7c:	eca6                	sd	s1,88(sp)
    80003d7e:	e8ca                	sd	s2,80(sp)
    80003d80:	e4ce                	sd	s3,72(sp)
    80003d82:	e0d2                	sd	s4,64(sp)
    80003d84:	fc56                	sd	s5,56(sp)
    80003d86:	f85a                	sd	s6,48(sp)
    80003d88:	f45e                	sd	s7,40(sp)
    80003d8a:	f062                	sd	s8,32(sp)
    80003d8c:	ec66                	sd	s9,24(sp)
    80003d8e:	e86a                	sd	s10,16(sp)
    80003d90:	e46e                	sd	s11,8(sp)
    80003d92:	1880                	addi	s0,sp,112
    80003d94:	8b2a                	mv	s6,a0
    80003d96:	8bae                	mv	s7,a1
    80003d98:	8a32                	mv	s4,a2
    80003d9a:	84b6                	mv	s1,a3
    80003d9c:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003d9e:	9f35                	addw	a4,a4,a3
    return 0;
    80003da0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003da2:	0ad76063          	bltu	a4,a3,80003e42 <readi+0xd2>
  if(off + n > ip->size)
    80003da6:	00e7f463          	bgeu	a5,a4,80003dae <readi+0x3e>
    n = ip->size - off;
    80003daa:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003dae:	0a0a8963          	beqz	s5,80003e60 <readi+0xf0>
    80003db2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003db4:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003db8:	5c7d                	li	s8,-1
    80003dba:	a82d                	j	80003df4 <readi+0x84>
    80003dbc:	020d1d93          	slli	s11,s10,0x20
    80003dc0:	020ddd93          	srli	s11,s11,0x20
    80003dc4:	05890793          	addi	a5,s2,88
    80003dc8:	86ee                	mv	a3,s11
    80003dca:	963e                	add	a2,a2,a5
    80003dcc:	85d2                	mv	a1,s4
    80003dce:	855e                	mv	a0,s7
    80003dd0:	fffff097          	auipc	ra,0xfffff
    80003dd4:	a2e080e7          	jalr	-1490(ra) # 800027fe <either_copyout>
    80003dd8:	05850d63          	beq	a0,s8,80003e32 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ddc:	854a                	mv	a0,s2
    80003dde:	fffff097          	auipc	ra,0xfffff
    80003de2:	5f4080e7          	jalr	1524(ra) # 800033d2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003de6:	013d09bb          	addw	s3,s10,s3
    80003dea:	009d04bb          	addw	s1,s10,s1
    80003dee:	9a6e                	add	s4,s4,s11
    80003df0:	0559f763          	bgeu	s3,s5,80003e3e <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003df4:	00a4d59b          	srliw	a1,s1,0xa
    80003df8:	855a                	mv	a0,s6
    80003dfa:	00000097          	auipc	ra,0x0
    80003dfe:	8a2080e7          	jalr	-1886(ra) # 8000369c <bmap>
    80003e02:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e06:	cd85                	beqz	a1,80003e3e <readi+0xce>
    bp = bread(ip->dev, addr);
    80003e08:	000b2503          	lw	a0,0(s6)
    80003e0c:	fffff097          	auipc	ra,0xfffff
    80003e10:	496080e7          	jalr	1174(ra) # 800032a2 <bread>
    80003e14:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e16:	3ff4f613          	andi	a2,s1,1023
    80003e1a:	40cc87bb          	subw	a5,s9,a2
    80003e1e:	413a873b          	subw	a4,s5,s3
    80003e22:	8d3e                	mv	s10,a5
    80003e24:	2781                	sext.w	a5,a5
    80003e26:	0007069b          	sext.w	a3,a4
    80003e2a:	f8f6f9e3          	bgeu	a3,a5,80003dbc <readi+0x4c>
    80003e2e:	8d3a                	mv	s10,a4
    80003e30:	b771                	j	80003dbc <readi+0x4c>
      brelse(bp);
    80003e32:	854a                	mv	a0,s2
    80003e34:	fffff097          	auipc	ra,0xfffff
    80003e38:	59e080e7          	jalr	1438(ra) # 800033d2 <brelse>
      tot = -1;
    80003e3c:	59fd                	li	s3,-1
  }
  return tot;
    80003e3e:	0009851b          	sext.w	a0,s3
}
    80003e42:	70a6                	ld	ra,104(sp)
    80003e44:	7406                	ld	s0,96(sp)
    80003e46:	64e6                	ld	s1,88(sp)
    80003e48:	6946                	ld	s2,80(sp)
    80003e4a:	69a6                	ld	s3,72(sp)
    80003e4c:	6a06                	ld	s4,64(sp)
    80003e4e:	7ae2                	ld	s5,56(sp)
    80003e50:	7b42                	ld	s6,48(sp)
    80003e52:	7ba2                	ld	s7,40(sp)
    80003e54:	7c02                	ld	s8,32(sp)
    80003e56:	6ce2                	ld	s9,24(sp)
    80003e58:	6d42                	ld	s10,16(sp)
    80003e5a:	6da2                	ld	s11,8(sp)
    80003e5c:	6165                	addi	sp,sp,112
    80003e5e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e60:	89d6                	mv	s3,s5
    80003e62:	bff1                	j	80003e3e <readi+0xce>
    return 0;
    80003e64:	4501                	li	a0,0
}
    80003e66:	8082                	ret

0000000080003e68 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e68:	457c                	lw	a5,76(a0)
    80003e6a:	10d7e863          	bltu	a5,a3,80003f7a <writei+0x112>
{
    80003e6e:	7159                	addi	sp,sp,-112
    80003e70:	f486                	sd	ra,104(sp)
    80003e72:	f0a2                	sd	s0,96(sp)
    80003e74:	eca6                	sd	s1,88(sp)
    80003e76:	e8ca                	sd	s2,80(sp)
    80003e78:	e4ce                	sd	s3,72(sp)
    80003e7a:	e0d2                	sd	s4,64(sp)
    80003e7c:	fc56                	sd	s5,56(sp)
    80003e7e:	f85a                	sd	s6,48(sp)
    80003e80:	f45e                	sd	s7,40(sp)
    80003e82:	f062                	sd	s8,32(sp)
    80003e84:	ec66                	sd	s9,24(sp)
    80003e86:	e86a                	sd	s10,16(sp)
    80003e88:	e46e                	sd	s11,8(sp)
    80003e8a:	1880                	addi	s0,sp,112
    80003e8c:	8aaa                	mv	s5,a0
    80003e8e:	8bae                	mv	s7,a1
    80003e90:	8a32                	mv	s4,a2
    80003e92:	8936                	mv	s2,a3
    80003e94:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e96:	00e687bb          	addw	a5,a3,a4
    80003e9a:	0ed7e263          	bltu	a5,a3,80003f7e <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003e9e:	00043737          	lui	a4,0x43
    80003ea2:	0ef76063          	bltu	a4,a5,80003f82 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ea6:	0c0b0863          	beqz	s6,80003f76 <writei+0x10e>
    80003eaa:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eac:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003eb0:	5c7d                	li	s8,-1
    80003eb2:	a091                	j	80003ef6 <writei+0x8e>
    80003eb4:	020d1d93          	slli	s11,s10,0x20
    80003eb8:	020ddd93          	srli	s11,s11,0x20
    80003ebc:	05848793          	addi	a5,s1,88
    80003ec0:	86ee                	mv	a3,s11
    80003ec2:	8652                	mv	a2,s4
    80003ec4:	85de                	mv	a1,s7
    80003ec6:	953e                	add	a0,a0,a5
    80003ec8:	fffff097          	auipc	ra,0xfffff
    80003ecc:	98c080e7          	jalr	-1652(ra) # 80002854 <either_copyin>
    80003ed0:	07850263          	beq	a0,s8,80003f34 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ed4:	8526                	mv	a0,s1
    80003ed6:	00000097          	auipc	ra,0x0
    80003eda:	780080e7          	jalr	1920(ra) # 80004656 <log_write>
    brelse(bp);
    80003ede:	8526                	mv	a0,s1
    80003ee0:	fffff097          	auipc	ra,0xfffff
    80003ee4:	4f2080e7          	jalr	1266(ra) # 800033d2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ee8:	013d09bb          	addw	s3,s10,s3
    80003eec:	012d093b          	addw	s2,s10,s2
    80003ef0:	9a6e                	add	s4,s4,s11
    80003ef2:	0569f663          	bgeu	s3,s6,80003f3e <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003ef6:	00a9559b          	srliw	a1,s2,0xa
    80003efa:	8556                	mv	a0,s5
    80003efc:	fffff097          	auipc	ra,0xfffff
    80003f00:	7a0080e7          	jalr	1952(ra) # 8000369c <bmap>
    80003f04:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f08:	c99d                	beqz	a1,80003f3e <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003f0a:	000aa503          	lw	a0,0(s5)
    80003f0e:	fffff097          	auipc	ra,0xfffff
    80003f12:	394080e7          	jalr	916(ra) # 800032a2 <bread>
    80003f16:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f18:	3ff97513          	andi	a0,s2,1023
    80003f1c:	40ac87bb          	subw	a5,s9,a0
    80003f20:	413b073b          	subw	a4,s6,s3
    80003f24:	8d3e                	mv	s10,a5
    80003f26:	2781                	sext.w	a5,a5
    80003f28:	0007069b          	sext.w	a3,a4
    80003f2c:	f8f6f4e3          	bgeu	a3,a5,80003eb4 <writei+0x4c>
    80003f30:	8d3a                	mv	s10,a4
    80003f32:	b749                	j	80003eb4 <writei+0x4c>
      brelse(bp);
    80003f34:	8526                	mv	a0,s1
    80003f36:	fffff097          	auipc	ra,0xfffff
    80003f3a:	49c080e7          	jalr	1180(ra) # 800033d2 <brelse>
  }

  if(off > ip->size)
    80003f3e:	04caa783          	lw	a5,76(s5)
    80003f42:	0127f463          	bgeu	a5,s2,80003f4a <writei+0xe2>
    ip->size = off;
    80003f46:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f4a:	8556                	mv	a0,s5
    80003f4c:	00000097          	auipc	ra,0x0
    80003f50:	aa6080e7          	jalr	-1370(ra) # 800039f2 <iupdate>

  return tot;
    80003f54:	0009851b          	sext.w	a0,s3
}
    80003f58:	70a6                	ld	ra,104(sp)
    80003f5a:	7406                	ld	s0,96(sp)
    80003f5c:	64e6                	ld	s1,88(sp)
    80003f5e:	6946                	ld	s2,80(sp)
    80003f60:	69a6                	ld	s3,72(sp)
    80003f62:	6a06                	ld	s4,64(sp)
    80003f64:	7ae2                	ld	s5,56(sp)
    80003f66:	7b42                	ld	s6,48(sp)
    80003f68:	7ba2                	ld	s7,40(sp)
    80003f6a:	7c02                	ld	s8,32(sp)
    80003f6c:	6ce2                	ld	s9,24(sp)
    80003f6e:	6d42                	ld	s10,16(sp)
    80003f70:	6da2                	ld	s11,8(sp)
    80003f72:	6165                	addi	sp,sp,112
    80003f74:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f76:	89da                	mv	s3,s6
    80003f78:	bfc9                	j	80003f4a <writei+0xe2>
    return -1;
    80003f7a:	557d                	li	a0,-1
}
    80003f7c:	8082                	ret
    return -1;
    80003f7e:	557d                	li	a0,-1
    80003f80:	bfe1                	j	80003f58 <writei+0xf0>
    return -1;
    80003f82:	557d                	li	a0,-1
    80003f84:	bfd1                	j	80003f58 <writei+0xf0>

0000000080003f86 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003f86:	1141                	addi	sp,sp,-16
    80003f88:	e406                	sd	ra,8(sp)
    80003f8a:	e022                	sd	s0,0(sp)
    80003f8c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003f8e:	4639                	li	a2,14
    80003f90:	ffffd097          	auipc	ra,0xffffd
    80003f94:	e12080e7          	jalr	-494(ra) # 80000da2 <strncmp>
}
    80003f98:	60a2                	ld	ra,8(sp)
    80003f9a:	6402                	ld	s0,0(sp)
    80003f9c:	0141                	addi	sp,sp,16
    80003f9e:	8082                	ret

0000000080003fa0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003fa0:	7139                	addi	sp,sp,-64
    80003fa2:	fc06                	sd	ra,56(sp)
    80003fa4:	f822                	sd	s0,48(sp)
    80003fa6:	f426                	sd	s1,40(sp)
    80003fa8:	f04a                	sd	s2,32(sp)
    80003faa:	ec4e                	sd	s3,24(sp)
    80003fac:	e852                	sd	s4,16(sp)
    80003fae:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003fb0:	04451703          	lh	a4,68(a0)
    80003fb4:	4785                	li	a5,1
    80003fb6:	00f71a63          	bne	a4,a5,80003fca <dirlookup+0x2a>
    80003fba:	892a                	mv	s2,a0
    80003fbc:	89ae                	mv	s3,a1
    80003fbe:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fc0:	457c                	lw	a5,76(a0)
    80003fc2:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003fc4:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fc6:	e79d                	bnez	a5,80003ff4 <dirlookup+0x54>
    80003fc8:	a8a5                	j	80004040 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003fca:	00004517          	auipc	a0,0x4
    80003fce:	68650513          	addi	a0,a0,1670 # 80008650 <syscalls+0x1b8>
    80003fd2:	ffffc097          	auipc	ra,0xffffc
    80003fd6:	56c080e7          	jalr	1388(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003fda:	00004517          	auipc	a0,0x4
    80003fde:	68e50513          	addi	a0,a0,1678 # 80008668 <syscalls+0x1d0>
    80003fe2:	ffffc097          	auipc	ra,0xffffc
    80003fe6:	55c080e7          	jalr	1372(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fea:	24c1                	addiw	s1,s1,16
    80003fec:	04c92783          	lw	a5,76(s2)
    80003ff0:	04f4f763          	bgeu	s1,a5,8000403e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ff4:	4741                	li	a4,16
    80003ff6:	86a6                	mv	a3,s1
    80003ff8:	fc040613          	addi	a2,s0,-64
    80003ffc:	4581                	li	a1,0
    80003ffe:	854a                	mv	a0,s2
    80004000:	00000097          	auipc	ra,0x0
    80004004:	d70080e7          	jalr	-656(ra) # 80003d70 <readi>
    80004008:	47c1                	li	a5,16
    8000400a:	fcf518e3          	bne	a0,a5,80003fda <dirlookup+0x3a>
    if(de.inum == 0)
    8000400e:	fc045783          	lhu	a5,-64(s0)
    80004012:	dfe1                	beqz	a5,80003fea <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004014:	fc240593          	addi	a1,s0,-62
    80004018:	854e                	mv	a0,s3
    8000401a:	00000097          	auipc	ra,0x0
    8000401e:	f6c080e7          	jalr	-148(ra) # 80003f86 <namecmp>
    80004022:	f561                	bnez	a0,80003fea <dirlookup+0x4a>
      if(poff)
    80004024:	000a0463          	beqz	s4,8000402c <dirlookup+0x8c>
        *poff = off;
    80004028:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000402c:	fc045583          	lhu	a1,-64(s0)
    80004030:	00092503          	lw	a0,0(s2)
    80004034:	fffff097          	auipc	ra,0xfffff
    80004038:	750080e7          	jalr	1872(ra) # 80003784 <iget>
    8000403c:	a011                	j	80004040 <dirlookup+0xa0>
  return 0;
    8000403e:	4501                	li	a0,0
}
    80004040:	70e2                	ld	ra,56(sp)
    80004042:	7442                	ld	s0,48(sp)
    80004044:	74a2                	ld	s1,40(sp)
    80004046:	7902                	ld	s2,32(sp)
    80004048:	69e2                	ld	s3,24(sp)
    8000404a:	6a42                	ld	s4,16(sp)
    8000404c:	6121                	addi	sp,sp,64
    8000404e:	8082                	ret

0000000080004050 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004050:	711d                	addi	sp,sp,-96
    80004052:	ec86                	sd	ra,88(sp)
    80004054:	e8a2                	sd	s0,80(sp)
    80004056:	e4a6                	sd	s1,72(sp)
    80004058:	e0ca                	sd	s2,64(sp)
    8000405a:	fc4e                	sd	s3,56(sp)
    8000405c:	f852                	sd	s4,48(sp)
    8000405e:	f456                	sd	s5,40(sp)
    80004060:	f05a                	sd	s6,32(sp)
    80004062:	ec5e                	sd	s7,24(sp)
    80004064:	e862                	sd	s8,16(sp)
    80004066:	e466                	sd	s9,8(sp)
    80004068:	1080                	addi	s0,sp,96
    8000406a:	84aa                	mv	s1,a0
    8000406c:	8aae                	mv	s5,a1
    8000406e:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004070:	00054703          	lbu	a4,0(a0)
    80004074:	02f00793          	li	a5,47
    80004078:	02f70363          	beq	a4,a5,8000409e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000407c:	ffffe097          	auipc	ra,0xffffe
    80004080:	930080e7          	jalr	-1744(ra) # 800019ac <myproc>
    80004084:	15053503          	ld	a0,336(a0)
    80004088:	00000097          	auipc	ra,0x0
    8000408c:	9f6080e7          	jalr	-1546(ra) # 80003a7e <idup>
    80004090:	89aa                	mv	s3,a0
  while(*path == '/')
    80004092:	02f00913          	li	s2,47
  len = path - s;
    80004096:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80004098:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000409a:	4b85                	li	s7,1
    8000409c:	a865                	j	80004154 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    8000409e:	4585                	li	a1,1
    800040a0:	4505                	li	a0,1
    800040a2:	fffff097          	auipc	ra,0xfffff
    800040a6:	6e2080e7          	jalr	1762(ra) # 80003784 <iget>
    800040aa:	89aa                	mv	s3,a0
    800040ac:	b7dd                	j	80004092 <namex+0x42>
      iunlockput(ip);
    800040ae:	854e                	mv	a0,s3
    800040b0:	00000097          	auipc	ra,0x0
    800040b4:	c6e080e7          	jalr	-914(ra) # 80003d1e <iunlockput>
      return 0;
    800040b8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800040ba:	854e                	mv	a0,s3
    800040bc:	60e6                	ld	ra,88(sp)
    800040be:	6446                	ld	s0,80(sp)
    800040c0:	64a6                	ld	s1,72(sp)
    800040c2:	6906                	ld	s2,64(sp)
    800040c4:	79e2                	ld	s3,56(sp)
    800040c6:	7a42                	ld	s4,48(sp)
    800040c8:	7aa2                	ld	s5,40(sp)
    800040ca:	7b02                	ld	s6,32(sp)
    800040cc:	6be2                	ld	s7,24(sp)
    800040ce:	6c42                	ld	s8,16(sp)
    800040d0:	6ca2                	ld	s9,8(sp)
    800040d2:	6125                	addi	sp,sp,96
    800040d4:	8082                	ret
      iunlock(ip);
    800040d6:	854e                	mv	a0,s3
    800040d8:	00000097          	auipc	ra,0x0
    800040dc:	aa6080e7          	jalr	-1370(ra) # 80003b7e <iunlock>
      return ip;
    800040e0:	bfe9                	j	800040ba <namex+0x6a>
      iunlockput(ip);
    800040e2:	854e                	mv	a0,s3
    800040e4:	00000097          	auipc	ra,0x0
    800040e8:	c3a080e7          	jalr	-966(ra) # 80003d1e <iunlockput>
      return 0;
    800040ec:	89e6                	mv	s3,s9
    800040ee:	b7f1                	j	800040ba <namex+0x6a>
  len = path - s;
    800040f0:	40b48633          	sub	a2,s1,a1
    800040f4:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800040f8:	099c5463          	bge	s8,s9,80004180 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800040fc:	4639                	li	a2,14
    800040fe:	8552                	mv	a0,s4
    80004100:	ffffd097          	auipc	ra,0xffffd
    80004104:	c2e080e7          	jalr	-978(ra) # 80000d2e <memmove>
  while(*path == '/')
    80004108:	0004c783          	lbu	a5,0(s1)
    8000410c:	01279763          	bne	a5,s2,8000411a <namex+0xca>
    path++;
    80004110:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004112:	0004c783          	lbu	a5,0(s1)
    80004116:	ff278de3          	beq	a5,s2,80004110 <namex+0xc0>
    ilock(ip);
    8000411a:	854e                	mv	a0,s3
    8000411c:	00000097          	auipc	ra,0x0
    80004120:	9a0080e7          	jalr	-1632(ra) # 80003abc <ilock>
    if(ip->type != T_DIR){
    80004124:	04499783          	lh	a5,68(s3)
    80004128:	f97793e3          	bne	a5,s7,800040ae <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000412c:	000a8563          	beqz	s5,80004136 <namex+0xe6>
    80004130:	0004c783          	lbu	a5,0(s1)
    80004134:	d3cd                	beqz	a5,800040d6 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004136:	865a                	mv	a2,s6
    80004138:	85d2                	mv	a1,s4
    8000413a:	854e                	mv	a0,s3
    8000413c:	00000097          	auipc	ra,0x0
    80004140:	e64080e7          	jalr	-412(ra) # 80003fa0 <dirlookup>
    80004144:	8caa                	mv	s9,a0
    80004146:	dd51                	beqz	a0,800040e2 <namex+0x92>
    iunlockput(ip);
    80004148:	854e                	mv	a0,s3
    8000414a:	00000097          	auipc	ra,0x0
    8000414e:	bd4080e7          	jalr	-1068(ra) # 80003d1e <iunlockput>
    ip = next;
    80004152:	89e6                	mv	s3,s9
  while(*path == '/')
    80004154:	0004c783          	lbu	a5,0(s1)
    80004158:	05279763          	bne	a5,s2,800041a6 <namex+0x156>
    path++;
    8000415c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000415e:	0004c783          	lbu	a5,0(s1)
    80004162:	ff278de3          	beq	a5,s2,8000415c <namex+0x10c>
  if(*path == 0)
    80004166:	c79d                	beqz	a5,80004194 <namex+0x144>
    path++;
    80004168:	85a6                	mv	a1,s1
  len = path - s;
    8000416a:	8cda                	mv	s9,s6
    8000416c:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    8000416e:	01278963          	beq	a5,s2,80004180 <namex+0x130>
    80004172:	dfbd                	beqz	a5,800040f0 <namex+0xa0>
    path++;
    80004174:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004176:	0004c783          	lbu	a5,0(s1)
    8000417a:	ff279ce3          	bne	a5,s2,80004172 <namex+0x122>
    8000417e:	bf8d                	j	800040f0 <namex+0xa0>
    memmove(name, s, len);
    80004180:	2601                	sext.w	a2,a2
    80004182:	8552                	mv	a0,s4
    80004184:	ffffd097          	auipc	ra,0xffffd
    80004188:	baa080e7          	jalr	-1110(ra) # 80000d2e <memmove>
    name[len] = 0;
    8000418c:	9cd2                	add	s9,s9,s4
    8000418e:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004192:	bf9d                	j	80004108 <namex+0xb8>
  if(nameiparent){
    80004194:	f20a83e3          	beqz	s5,800040ba <namex+0x6a>
    iput(ip);
    80004198:	854e                	mv	a0,s3
    8000419a:	00000097          	auipc	ra,0x0
    8000419e:	adc080e7          	jalr	-1316(ra) # 80003c76 <iput>
    return 0;
    800041a2:	4981                	li	s3,0
    800041a4:	bf19                	j	800040ba <namex+0x6a>
  if(*path == 0)
    800041a6:	d7fd                	beqz	a5,80004194 <namex+0x144>
  while(*path != '/' && *path != 0)
    800041a8:	0004c783          	lbu	a5,0(s1)
    800041ac:	85a6                	mv	a1,s1
    800041ae:	b7d1                	j	80004172 <namex+0x122>

00000000800041b0 <dirlink>:
{
    800041b0:	7139                	addi	sp,sp,-64
    800041b2:	fc06                	sd	ra,56(sp)
    800041b4:	f822                	sd	s0,48(sp)
    800041b6:	f426                	sd	s1,40(sp)
    800041b8:	f04a                	sd	s2,32(sp)
    800041ba:	ec4e                	sd	s3,24(sp)
    800041bc:	e852                	sd	s4,16(sp)
    800041be:	0080                	addi	s0,sp,64
    800041c0:	892a                	mv	s2,a0
    800041c2:	8a2e                	mv	s4,a1
    800041c4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800041c6:	4601                	li	a2,0
    800041c8:	00000097          	auipc	ra,0x0
    800041cc:	dd8080e7          	jalr	-552(ra) # 80003fa0 <dirlookup>
    800041d0:	e93d                	bnez	a0,80004246 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041d2:	04c92483          	lw	s1,76(s2)
    800041d6:	c49d                	beqz	s1,80004204 <dirlink+0x54>
    800041d8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041da:	4741                	li	a4,16
    800041dc:	86a6                	mv	a3,s1
    800041de:	fc040613          	addi	a2,s0,-64
    800041e2:	4581                	li	a1,0
    800041e4:	854a                	mv	a0,s2
    800041e6:	00000097          	auipc	ra,0x0
    800041ea:	b8a080e7          	jalr	-1142(ra) # 80003d70 <readi>
    800041ee:	47c1                	li	a5,16
    800041f0:	06f51163          	bne	a0,a5,80004252 <dirlink+0xa2>
    if(de.inum == 0)
    800041f4:	fc045783          	lhu	a5,-64(s0)
    800041f8:	c791                	beqz	a5,80004204 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041fa:	24c1                	addiw	s1,s1,16
    800041fc:	04c92783          	lw	a5,76(s2)
    80004200:	fcf4ede3          	bltu	s1,a5,800041da <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004204:	4639                	li	a2,14
    80004206:	85d2                	mv	a1,s4
    80004208:	fc240513          	addi	a0,s0,-62
    8000420c:	ffffd097          	auipc	ra,0xffffd
    80004210:	bd2080e7          	jalr	-1070(ra) # 80000dde <strncpy>
  de.inum = inum;
    80004214:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004218:	4741                	li	a4,16
    8000421a:	86a6                	mv	a3,s1
    8000421c:	fc040613          	addi	a2,s0,-64
    80004220:	4581                	li	a1,0
    80004222:	854a                	mv	a0,s2
    80004224:	00000097          	auipc	ra,0x0
    80004228:	c44080e7          	jalr	-956(ra) # 80003e68 <writei>
    8000422c:	1541                	addi	a0,a0,-16
    8000422e:	00a03533          	snez	a0,a0
    80004232:	40a00533          	neg	a0,a0
}
    80004236:	70e2                	ld	ra,56(sp)
    80004238:	7442                	ld	s0,48(sp)
    8000423a:	74a2                	ld	s1,40(sp)
    8000423c:	7902                	ld	s2,32(sp)
    8000423e:	69e2                	ld	s3,24(sp)
    80004240:	6a42                	ld	s4,16(sp)
    80004242:	6121                	addi	sp,sp,64
    80004244:	8082                	ret
    iput(ip);
    80004246:	00000097          	auipc	ra,0x0
    8000424a:	a30080e7          	jalr	-1488(ra) # 80003c76 <iput>
    return -1;
    8000424e:	557d                	li	a0,-1
    80004250:	b7dd                	j	80004236 <dirlink+0x86>
      panic("dirlink read");
    80004252:	00004517          	auipc	a0,0x4
    80004256:	42650513          	addi	a0,a0,1062 # 80008678 <syscalls+0x1e0>
    8000425a:	ffffc097          	auipc	ra,0xffffc
    8000425e:	2e4080e7          	jalr	740(ra) # 8000053e <panic>

0000000080004262 <namei>:

struct inode*
namei(char *path)
{
    80004262:	1101                	addi	sp,sp,-32
    80004264:	ec06                	sd	ra,24(sp)
    80004266:	e822                	sd	s0,16(sp)
    80004268:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000426a:	fe040613          	addi	a2,s0,-32
    8000426e:	4581                	li	a1,0
    80004270:	00000097          	auipc	ra,0x0
    80004274:	de0080e7          	jalr	-544(ra) # 80004050 <namex>
}
    80004278:	60e2                	ld	ra,24(sp)
    8000427a:	6442                	ld	s0,16(sp)
    8000427c:	6105                	addi	sp,sp,32
    8000427e:	8082                	ret

0000000080004280 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004280:	1141                	addi	sp,sp,-16
    80004282:	e406                	sd	ra,8(sp)
    80004284:	e022                	sd	s0,0(sp)
    80004286:	0800                	addi	s0,sp,16
    80004288:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000428a:	4585                	li	a1,1
    8000428c:	00000097          	auipc	ra,0x0
    80004290:	dc4080e7          	jalr	-572(ra) # 80004050 <namex>
}
    80004294:	60a2                	ld	ra,8(sp)
    80004296:	6402                	ld	s0,0(sp)
    80004298:	0141                	addi	sp,sp,16
    8000429a:	8082                	ret

000000008000429c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000429c:	1101                	addi	sp,sp,-32
    8000429e:	ec06                	sd	ra,24(sp)
    800042a0:	e822                	sd	s0,16(sp)
    800042a2:	e426                	sd	s1,8(sp)
    800042a4:	e04a                	sd	s2,0(sp)
    800042a6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800042a8:	0001d917          	auipc	s2,0x1d
    800042ac:	0d890913          	addi	s2,s2,216 # 80021380 <log>
    800042b0:	01892583          	lw	a1,24(s2)
    800042b4:	02892503          	lw	a0,40(s2)
    800042b8:	fffff097          	auipc	ra,0xfffff
    800042bc:	fea080e7          	jalr	-22(ra) # 800032a2 <bread>
    800042c0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800042c2:	02c92683          	lw	a3,44(s2)
    800042c6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800042c8:	02d05763          	blez	a3,800042f6 <write_head+0x5a>
    800042cc:	0001d797          	auipc	a5,0x1d
    800042d0:	0e478793          	addi	a5,a5,228 # 800213b0 <log+0x30>
    800042d4:	05c50713          	addi	a4,a0,92
    800042d8:	36fd                	addiw	a3,a3,-1
    800042da:	1682                	slli	a3,a3,0x20
    800042dc:	9281                	srli	a3,a3,0x20
    800042de:	068a                	slli	a3,a3,0x2
    800042e0:	0001d617          	auipc	a2,0x1d
    800042e4:	0d460613          	addi	a2,a2,212 # 800213b4 <log+0x34>
    800042e8:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800042ea:	4390                	lw	a2,0(a5)
    800042ec:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800042ee:	0791                	addi	a5,a5,4
    800042f0:	0711                	addi	a4,a4,4
    800042f2:	fed79ce3          	bne	a5,a3,800042ea <write_head+0x4e>
  }
  bwrite(buf);
    800042f6:	8526                	mv	a0,s1
    800042f8:	fffff097          	auipc	ra,0xfffff
    800042fc:	09c080e7          	jalr	156(ra) # 80003394 <bwrite>
  brelse(buf);
    80004300:	8526                	mv	a0,s1
    80004302:	fffff097          	auipc	ra,0xfffff
    80004306:	0d0080e7          	jalr	208(ra) # 800033d2 <brelse>
}
    8000430a:	60e2                	ld	ra,24(sp)
    8000430c:	6442                	ld	s0,16(sp)
    8000430e:	64a2                	ld	s1,8(sp)
    80004310:	6902                	ld	s2,0(sp)
    80004312:	6105                	addi	sp,sp,32
    80004314:	8082                	ret

0000000080004316 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004316:	0001d797          	auipc	a5,0x1d
    8000431a:	0967a783          	lw	a5,150(a5) # 800213ac <log+0x2c>
    8000431e:	0af05d63          	blez	a5,800043d8 <install_trans+0xc2>
{
    80004322:	7139                	addi	sp,sp,-64
    80004324:	fc06                	sd	ra,56(sp)
    80004326:	f822                	sd	s0,48(sp)
    80004328:	f426                	sd	s1,40(sp)
    8000432a:	f04a                	sd	s2,32(sp)
    8000432c:	ec4e                	sd	s3,24(sp)
    8000432e:	e852                	sd	s4,16(sp)
    80004330:	e456                	sd	s5,8(sp)
    80004332:	e05a                	sd	s6,0(sp)
    80004334:	0080                	addi	s0,sp,64
    80004336:	8b2a                	mv	s6,a0
    80004338:	0001da97          	auipc	s5,0x1d
    8000433c:	078a8a93          	addi	s5,s5,120 # 800213b0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004340:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004342:	0001d997          	auipc	s3,0x1d
    80004346:	03e98993          	addi	s3,s3,62 # 80021380 <log>
    8000434a:	a00d                	j	8000436c <install_trans+0x56>
    brelse(lbuf);
    8000434c:	854a                	mv	a0,s2
    8000434e:	fffff097          	auipc	ra,0xfffff
    80004352:	084080e7          	jalr	132(ra) # 800033d2 <brelse>
    brelse(dbuf);
    80004356:	8526                	mv	a0,s1
    80004358:	fffff097          	auipc	ra,0xfffff
    8000435c:	07a080e7          	jalr	122(ra) # 800033d2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004360:	2a05                	addiw	s4,s4,1
    80004362:	0a91                	addi	s5,s5,4
    80004364:	02c9a783          	lw	a5,44(s3)
    80004368:	04fa5e63          	bge	s4,a5,800043c4 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000436c:	0189a583          	lw	a1,24(s3)
    80004370:	014585bb          	addw	a1,a1,s4
    80004374:	2585                	addiw	a1,a1,1
    80004376:	0289a503          	lw	a0,40(s3)
    8000437a:	fffff097          	auipc	ra,0xfffff
    8000437e:	f28080e7          	jalr	-216(ra) # 800032a2 <bread>
    80004382:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004384:	000aa583          	lw	a1,0(s5)
    80004388:	0289a503          	lw	a0,40(s3)
    8000438c:	fffff097          	auipc	ra,0xfffff
    80004390:	f16080e7          	jalr	-234(ra) # 800032a2 <bread>
    80004394:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004396:	40000613          	li	a2,1024
    8000439a:	05890593          	addi	a1,s2,88
    8000439e:	05850513          	addi	a0,a0,88
    800043a2:	ffffd097          	auipc	ra,0xffffd
    800043a6:	98c080e7          	jalr	-1652(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800043aa:	8526                	mv	a0,s1
    800043ac:	fffff097          	auipc	ra,0xfffff
    800043b0:	fe8080e7          	jalr	-24(ra) # 80003394 <bwrite>
    if(recovering == 0)
    800043b4:	f80b1ce3          	bnez	s6,8000434c <install_trans+0x36>
      bunpin(dbuf);
    800043b8:	8526                	mv	a0,s1
    800043ba:	fffff097          	auipc	ra,0xfffff
    800043be:	0f2080e7          	jalr	242(ra) # 800034ac <bunpin>
    800043c2:	b769                	j	8000434c <install_trans+0x36>
}
    800043c4:	70e2                	ld	ra,56(sp)
    800043c6:	7442                	ld	s0,48(sp)
    800043c8:	74a2                	ld	s1,40(sp)
    800043ca:	7902                	ld	s2,32(sp)
    800043cc:	69e2                	ld	s3,24(sp)
    800043ce:	6a42                	ld	s4,16(sp)
    800043d0:	6aa2                	ld	s5,8(sp)
    800043d2:	6b02                	ld	s6,0(sp)
    800043d4:	6121                	addi	sp,sp,64
    800043d6:	8082                	ret
    800043d8:	8082                	ret

00000000800043da <initlog>:
{
    800043da:	7179                	addi	sp,sp,-48
    800043dc:	f406                	sd	ra,40(sp)
    800043de:	f022                	sd	s0,32(sp)
    800043e0:	ec26                	sd	s1,24(sp)
    800043e2:	e84a                	sd	s2,16(sp)
    800043e4:	e44e                	sd	s3,8(sp)
    800043e6:	1800                	addi	s0,sp,48
    800043e8:	892a                	mv	s2,a0
    800043ea:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800043ec:	0001d497          	auipc	s1,0x1d
    800043f0:	f9448493          	addi	s1,s1,-108 # 80021380 <log>
    800043f4:	00004597          	auipc	a1,0x4
    800043f8:	29458593          	addi	a1,a1,660 # 80008688 <syscalls+0x1f0>
    800043fc:	8526                	mv	a0,s1
    800043fe:	ffffc097          	auipc	ra,0xffffc
    80004402:	748080e7          	jalr	1864(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004406:	0149a583          	lw	a1,20(s3)
    8000440a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000440c:	0109a783          	lw	a5,16(s3)
    80004410:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004412:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004416:	854a                	mv	a0,s2
    80004418:	fffff097          	auipc	ra,0xfffff
    8000441c:	e8a080e7          	jalr	-374(ra) # 800032a2 <bread>
  log.lh.n = lh->n;
    80004420:	4d34                	lw	a3,88(a0)
    80004422:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004424:	02d05563          	blez	a3,8000444e <initlog+0x74>
    80004428:	05c50793          	addi	a5,a0,92
    8000442c:	0001d717          	auipc	a4,0x1d
    80004430:	f8470713          	addi	a4,a4,-124 # 800213b0 <log+0x30>
    80004434:	36fd                	addiw	a3,a3,-1
    80004436:	1682                	slli	a3,a3,0x20
    80004438:	9281                	srli	a3,a3,0x20
    8000443a:	068a                	slli	a3,a3,0x2
    8000443c:	06050613          	addi	a2,a0,96
    80004440:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004442:	4390                	lw	a2,0(a5)
    80004444:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004446:	0791                	addi	a5,a5,4
    80004448:	0711                	addi	a4,a4,4
    8000444a:	fed79ce3          	bne	a5,a3,80004442 <initlog+0x68>
  brelse(buf);
    8000444e:	fffff097          	auipc	ra,0xfffff
    80004452:	f84080e7          	jalr	-124(ra) # 800033d2 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004456:	4505                	li	a0,1
    80004458:	00000097          	auipc	ra,0x0
    8000445c:	ebe080e7          	jalr	-322(ra) # 80004316 <install_trans>
  log.lh.n = 0;
    80004460:	0001d797          	auipc	a5,0x1d
    80004464:	f407a623          	sw	zero,-180(a5) # 800213ac <log+0x2c>
  write_head(); // clear the log
    80004468:	00000097          	auipc	ra,0x0
    8000446c:	e34080e7          	jalr	-460(ra) # 8000429c <write_head>
}
    80004470:	70a2                	ld	ra,40(sp)
    80004472:	7402                	ld	s0,32(sp)
    80004474:	64e2                	ld	s1,24(sp)
    80004476:	6942                	ld	s2,16(sp)
    80004478:	69a2                	ld	s3,8(sp)
    8000447a:	6145                	addi	sp,sp,48
    8000447c:	8082                	ret

000000008000447e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000447e:	1101                	addi	sp,sp,-32
    80004480:	ec06                	sd	ra,24(sp)
    80004482:	e822                	sd	s0,16(sp)
    80004484:	e426                	sd	s1,8(sp)
    80004486:	e04a                	sd	s2,0(sp)
    80004488:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000448a:	0001d517          	auipc	a0,0x1d
    8000448e:	ef650513          	addi	a0,a0,-266 # 80021380 <log>
    80004492:	ffffc097          	auipc	ra,0xffffc
    80004496:	744080e7          	jalr	1860(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    8000449a:	0001d497          	auipc	s1,0x1d
    8000449e:	ee648493          	addi	s1,s1,-282 # 80021380 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044a2:	4979                	li	s2,30
    800044a4:	a039                	j	800044b2 <begin_op+0x34>
      sleep(&log, &log.lock);
    800044a6:	85a6                	mv	a1,s1
    800044a8:	8526                	mv	a0,s1
    800044aa:	ffffe097          	auipc	ra,0xffffe
    800044ae:	baa080e7          	jalr	-1110(ra) # 80002054 <sleep>
    if(log.committing){
    800044b2:	50dc                	lw	a5,36(s1)
    800044b4:	fbed                	bnez	a5,800044a6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044b6:	509c                	lw	a5,32(s1)
    800044b8:	0017871b          	addiw	a4,a5,1
    800044bc:	0007069b          	sext.w	a3,a4
    800044c0:	0027179b          	slliw	a5,a4,0x2
    800044c4:	9fb9                	addw	a5,a5,a4
    800044c6:	0017979b          	slliw	a5,a5,0x1
    800044ca:	54d8                	lw	a4,44(s1)
    800044cc:	9fb9                	addw	a5,a5,a4
    800044ce:	00f95963          	bge	s2,a5,800044e0 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800044d2:	85a6                	mv	a1,s1
    800044d4:	8526                	mv	a0,s1
    800044d6:	ffffe097          	auipc	ra,0xffffe
    800044da:	b7e080e7          	jalr	-1154(ra) # 80002054 <sleep>
    800044de:	bfd1                	j	800044b2 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800044e0:	0001d517          	auipc	a0,0x1d
    800044e4:	ea050513          	addi	a0,a0,-352 # 80021380 <log>
    800044e8:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800044ea:	ffffc097          	auipc	ra,0xffffc
    800044ee:	7a0080e7          	jalr	1952(ra) # 80000c8a <release>
      break;
    }
  }
}
    800044f2:	60e2                	ld	ra,24(sp)
    800044f4:	6442                	ld	s0,16(sp)
    800044f6:	64a2                	ld	s1,8(sp)
    800044f8:	6902                	ld	s2,0(sp)
    800044fa:	6105                	addi	sp,sp,32
    800044fc:	8082                	ret

00000000800044fe <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800044fe:	7139                	addi	sp,sp,-64
    80004500:	fc06                	sd	ra,56(sp)
    80004502:	f822                	sd	s0,48(sp)
    80004504:	f426                	sd	s1,40(sp)
    80004506:	f04a                	sd	s2,32(sp)
    80004508:	ec4e                	sd	s3,24(sp)
    8000450a:	e852                	sd	s4,16(sp)
    8000450c:	e456                	sd	s5,8(sp)
    8000450e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004510:	0001d497          	auipc	s1,0x1d
    80004514:	e7048493          	addi	s1,s1,-400 # 80021380 <log>
    80004518:	8526                	mv	a0,s1
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	6bc080e7          	jalr	1724(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004522:	509c                	lw	a5,32(s1)
    80004524:	37fd                	addiw	a5,a5,-1
    80004526:	0007891b          	sext.w	s2,a5
    8000452a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000452c:	50dc                	lw	a5,36(s1)
    8000452e:	e7b9                	bnez	a5,8000457c <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004530:	04091e63          	bnez	s2,8000458c <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004534:	0001d497          	auipc	s1,0x1d
    80004538:	e4c48493          	addi	s1,s1,-436 # 80021380 <log>
    8000453c:	4785                	li	a5,1
    8000453e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004540:	8526                	mv	a0,s1
    80004542:	ffffc097          	auipc	ra,0xffffc
    80004546:	748080e7          	jalr	1864(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000454a:	54dc                	lw	a5,44(s1)
    8000454c:	06f04763          	bgtz	a5,800045ba <end_op+0xbc>
    acquire(&log.lock);
    80004550:	0001d497          	auipc	s1,0x1d
    80004554:	e3048493          	addi	s1,s1,-464 # 80021380 <log>
    80004558:	8526                	mv	a0,s1
    8000455a:	ffffc097          	auipc	ra,0xffffc
    8000455e:	67c080e7          	jalr	1660(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004562:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004566:	8526                	mv	a0,s1
    80004568:	ffffe097          	auipc	ra,0xffffe
    8000456c:	b50080e7          	jalr	-1200(ra) # 800020b8 <wakeup>
    release(&log.lock);
    80004570:	8526                	mv	a0,s1
    80004572:	ffffc097          	auipc	ra,0xffffc
    80004576:	718080e7          	jalr	1816(ra) # 80000c8a <release>
}
    8000457a:	a03d                	j	800045a8 <end_op+0xaa>
    panic("log.committing");
    8000457c:	00004517          	auipc	a0,0x4
    80004580:	11450513          	addi	a0,a0,276 # 80008690 <syscalls+0x1f8>
    80004584:	ffffc097          	auipc	ra,0xffffc
    80004588:	fba080e7          	jalr	-70(ra) # 8000053e <panic>
    wakeup(&log);
    8000458c:	0001d497          	auipc	s1,0x1d
    80004590:	df448493          	addi	s1,s1,-524 # 80021380 <log>
    80004594:	8526                	mv	a0,s1
    80004596:	ffffe097          	auipc	ra,0xffffe
    8000459a:	b22080e7          	jalr	-1246(ra) # 800020b8 <wakeup>
  release(&log.lock);
    8000459e:	8526                	mv	a0,s1
    800045a0:	ffffc097          	auipc	ra,0xffffc
    800045a4:	6ea080e7          	jalr	1770(ra) # 80000c8a <release>
}
    800045a8:	70e2                	ld	ra,56(sp)
    800045aa:	7442                	ld	s0,48(sp)
    800045ac:	74a2                	ld	s1,40(sp)
    800045ae:	7902                	ld	s2,32(sp)
    800045b0:	69e2                	ld	s3,24(sp)
    800045b2:	6a42                	ld	s4,16(sp)
    800045b4:	6aa2                	ld	s5,8(sp)
    800045b6:	6121                	addi	sp,sp,64
    800045b8:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800045ba:	0001da97          	auipc	s5,0x1d
    800045be:	df6a8a93          	addi	s5,s5,-522 # 800213b0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800045c2:	0001da17          	auipc	s4,0x1d
    800045c6:	dbea0a13          	addi	s4,s4,-578 # 80021380 <log>
    800045ca:	018a2583          	lw	a1,24(s4)
    800045ce:	012585bb          	addw	a1,a1,s2
    800045d2:	2585                	addiw	a1,a1,1
    800045d4:	028a2503          	lw	a0,40(s4)
    800045d8:	fffff097          	auipc	ra,0xfffff
    800045dc:	cca080e7          	jalr	-822(ra) # 800032a2 <bread>
    800045e0:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800045e2:	000aa583          	lw	a1,0(s5)
    800045e6:	028a2503          	lw	a0,40(s4)
    800045ea:	fffff097          	auipc	ra,0xfffff
    800045ee:	cb8080e7          	jalr	-840(ra) # 800032a2 <bread>
    800045f2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800045f4:	40000613          	li	a2,1024
    800045f8:	05850593          	addi	a1,a0,88
    800045fc:	05848513          	addi	a0,s1,88
    80004600:	ffffc097          	auipc	ra,0xffffc
    80004604:	72e080e7          	jalr	1838(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004608:	8526                	mv	a0,s1
    8000460a:	fffff097          	auipc	ra,0xfffff
    8000460e:	d8a080e7          	jalr	-630(ra) # 80003394 <bwrite>
    brelse(from);
    80004612:	854e                	mv	a0,s3
    80004614:	fffff097          	auipc	ra,0xfffff
    80004618:	dbe080e7          	jalr	-578(ra) # 800033d2 <brelse>
    brelse(to);
    8000461c:	8526                	mv	a0,s1
    8000461e:	fffff097          	auipc	ra,0xfffff
    80004622:	db4080e7          	jalr	-588(ra) # 800033d2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004626:	2905                	addiw	s2,s2,1
    80004628:	0a91                	addi	s5,s5,4
    8000462a:	02ca2783          	lw	a5,44(s4)
    8000462e:	f8f94ee3          	blt	s2,a5,800045ca <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004632:	00000097          	auipc	ra,0x0
    80004636:	c6a080e7          	jalr	-918(ra) # 8000429c <write_head>
    install_trans(0); // Now install writes to home locations
    8000463a:	4501                	li	a0,0
    8000463c:	00000097          	auipc	ra,0x0
    80004640:	cda080e7          	jalr	-806(ra) # 80004316 <install_trans>
    log.lh.n = 0;
    80004644:	0001d797          	auipc	a5,0x1d
    80004648:	d607a423          	sw	zero,-664(a5) # 800213ac <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000464c:	00000097          	auipc	ra,0x0
    80004650:	c50080e7          	jalr	-944(ra) # 8000429c <write_head>
    80004654:	bdf5                	j	80004550 <end_op+0x52>

0000000080004656 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004656:	1101                	addi	sp,sp,-32
    80004658:	ec06                	sd	ra,24(sp)
    8000465a:	e822                	sd	s0,16(sp)
    8000465c:	e426                	sd	s1,8(sp)
    8000465e:	e04a                	sd	s2,0(sp)
    80004660:	1000                	addi	s0,sp,32
    80004662:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004664:	0001d917          	auipc	s2,0x1d
    80004668:	d1c90913          	addi	s2,s2,-740 # 80021380 <log>
    8000466c:	854a                	mv	a0,s2
    8000466e:	ffffc097          	auipc	ra,0xffffc
    80004672:	568080e7          	jalr	1384(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004676:	02c92603          	lw	a2,44(s2)
    8000467a:	47f5                	li	a5,29
    8000467c:	06c7c563          	blt	a5,a2,800046e6 <log_write+0x90>
    80004680:	0001d797          	auipc	a5,0x1d
    80004684:	d1c7a783          	lw	a5,-740(a5) # 8002139c <log+0x1c>
    80004688:	37fd                	addiw	a5,a5,-1
    8000468a:	04f65e63          	bge	a2,a5,800046e6 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000468e:	0001d797          	auipc	a5,0x1d
    80004692:	d127a783          	lw	a5,-750(a5) # 800213a0 <log+0x20>
    80004696:	06f05063          	blez	a5,800046f6 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000469a:	4781                	li	a5,0
    8000469c:	06c05563          	blez	a2,80004706 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046a0:	44cc                	lw	a1,12(s1)
    800046a2:	0001d717          	auipc	a4,0x1d
    800046a6:	d0e70713          	addi	a4,a4,-754 # 800213b0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800046aa:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046ac:	4314                	lw	a3,0(a4)
    800046ae:	04b68c63          	beq	a3,a1,80004706 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800046b2:	2785                	addiw	a5,a5,1
    800046b4:	0711                	addi	a4,a4,4
    800046b6:	fef61be3          	bne	a2,a5,800046ac <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800046ba:	0621                	addi	a2,a2,8
    800046bc:	060a                	slli	a2,a2,0x2
    800046be:	0001d797          	auipc	a5,0x1d
    800046c2:	cc278793          	addi	a5,a5,-830 # 80021380 <log>
    800046c6:	963e                	add	a2,a2,a5
    800046c8:	44dc                	lw	a5,12(s1)
    800046ca:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800046cc:	8526                	mv	a0,s1
    800046ce:	fffff097          	auipc	ra,0xfffff
    800046d2:	da2080e7          	jalr	-606(ra) # 80003470 <bpin>
    log.lh.n++;
    800046d6:	0001d717          	auipc	a4,0x1d
    800046da:	caa70713          	addi	a4,a4,-854 # 80021380 <log>
    800046de:	575c                	lw	a5,44(a4)
    800046e0:	2785                	addiw	a5,a5,1
    800046e2:	d75c                	sw	a5,44(a4)
    800046e4:	a835                	j	80004720 <log_write+0xca>
    panic("too big a transaction");
    800046e6:	00004517          	auipc	a0,0x4
    800046ea:	fba50513          	addi	a0,a0,-70 # 800086a0 <syscalls+0x208>
    800046ee:	ffffc097          	auipc	ra,0xffffc
    800046f2:	e50080e7          	jalr	-432(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800046f6:	00004517          	auipc	a0,0x4
    800046fa:	fc250513          	addi	a0,a0,-62 # 800086b8 <syscalls+0x220>
    800046fe:	ffffc097          	auipc	ra,0xffffc
    80004702:	e40080e7          	jalr	-448(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004706:	00878713          	addi	a4,a5,8
    8000470a:	00271693          	slli	a3,a4,0x2
    8000470e:	0001d717          	auipc	a4,0x1d
    80004712:	c7270713          	addi	a4,a4,-910 # 80021380 <log>
    80004716:	9736                	add	a4,a4,a3
    80004718:	44d4                	lw	a3,12(s1)
    8000471a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000471c:	faf608e3          	beq	a2,a5,800046cc <log_write+0x76>
  }
  release(&log.lock);
    80004720:	0001d517          	auipc	a0,0x1d
    80004724:	c6050513          	addi	a0,a0,-928 # 80021380 <log>
    80004728:	ffffc097          	auipc	ra,0xffffc
    8000472c:	562080e7          	jalr	1378(ra) # 80000c8a <release>
}
    80004730:	60e2                	ld	ra,24(sp)
    80004732:	6442                	ld	s0,16(sp)
    80004734:	64a2                	ld	s1,8(sp)
    80004736:	6902                	ld	s2,0(sp)
    80004738:	6105                	addi	sp,sp,32
    8000473a:	8082                	ret

000000008000473c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000473c:	1101                	addi	sp,sp,-32
    8000473e:	ec06                	sd	ra,24(sp)
    80004740:	e822                	sd	s0,16(sp)
    80004742:	e426                	sd	s1,8(sp)
    80004744:	e04a                	sd	s2,0(sp)
    80004746:	1000                	addi	s0,sp,32
    80004748:	84aa                	mv	s1,a0
    8000474a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000474c:	00004597          	auipc	a1,0x4
    80004750:	f8c58593          	addi	a1,a1,-116 # 800086d8 <syscalls+0x240>
    80004754:	0521                	addi	a0,a0,8
    80004756:	ffffc097          	auipc	ra,0xffffc
    8000475a:	3f0080e7          	jalr	1008(ra) # 80000b46 <initlock>
  lk->name = name;
    8000475e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004762:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004766:	0204a423          	sw	zero,40(s1)
}
    8000476a:	60e2                	ld	ra,24(sp)
    8000476c:	6442                	ld	s0,16(sp)
    8000476e:	64a2                	ld	s1,8(sp)
    80004770:	6902                	ld	s2,0(sp)
    80004772:	6105                	addi	sp,sp,32
    80004774:	8082                	ret

0000000080004776 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004776:	1101                	addi	sp,sp,-32
    80004778:	ec06                	sd	ra,24(sp)
    8000477a:	e822                	sd	s0,16(sp)
    8000477c:	e426                	sd	s1,8(sp)
    8000477e:	e04a                	sd	s2,0(sp)
    80004780:	1000                	addi	s0,sp,32
    80004782:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004784:	00850913          	addi	s2,a0,8
    80004788:	854a                	mv	a0,s2
    8000478a:	ffffc097          	auipc	ra,0xffffc
    8000478e:	44c080e7          	jalr	1100(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004792:	409c                	lw	a5,0(s1)
    80004794:	cb89                	beqz	a5,800047a6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004796:	85ca                	mv	a1,s2
    80004798:	8526                	mv	a0,s1
    8000479a:	ffffe097          	auipc	ra,0xffffe
    8000479e:	8ba080e7          	jalr	-1862(ra) # 80002054 <sleep>
  while (lk->locked) {
    800047a2:	409c                	lw	a5,0(s1)
    800047a4:	fbed                	bnez	a5,80004796 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800047a6:	4785                	li	a5,1
    800047a8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800047aa:	ffffd097          	auipc	ra,0xffffd
    800047ae:	202080e7          	jalr	514(ra) # 800019ac <myproc>
    800047b2:	591c                	lw	a5,48(a0)
    800047b4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800047b6:	854a                	mv	a0,s2
    800047b8:	ffffc097          	auipc	ra,0xffffc
    800047bc:	4d2080e7          	jalr	1234(ra) # 80000c8a <release>
}
    800047c0:	60e2                	ld	ra,24(sp)
    800047c2:	6442                	ld	s0,16(sp)
    800047c4:	64a2                	ld	s1,8(sp)
    800047c6:	6902                	ld	s2,0(sp)
    800047c8:	6105                	addi	sp,sp,32
    800047ca:	8082                	ret

00000000800047cc <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800047cc:	1101                	addi	sp,sp,-32
    800047ce:	ec06                	sd	ra,24(sp)
    800047d0:	e822                	sd	s0,16(sp)
    800047d2:	e426                	sd	s1,8(sp)
    800047d4:	e04a                	sd	s2,0(sp)
    800047d6:	1000                	addi	s0,sp,32
    800047d8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047da:	00850913          	addi	s2,a0,8
    800047de:	854a                	mv	a0,s2
    800047e0:	ffffc097          	auipc	ra,0xffffc
    800047e4:	3f6080e7          	jalr	1014(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800047e8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047ec:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800047f0:	8526                	mv	a0,s1
    800047f2:	ffffe097          	auipc	ra,0xffffe
    800047f6:	8c6080e7          	jalr	-1850(ra) # 800020b8 <wakeup>
  release(&lk->lk);
    800047fa:	854a                	mv	a0,s2
    800047fc:	ffffc097          	auipc	ra,0xffffc
    80004800:	48e080e7          	jalr	1166(ra) # 80000c8a <release>
}
    80004804:	60e2                	ld	ra,24(sp)
    80004806:	6442                	ld	s0,16(sp)
    80004808:	64a2                	ld	s1,8(sp)
    8000480a:	6902                	ld	s2,0(sp)
    8000480c:	6105                	addi	sp,sp,32
    8000480e:	8082                	ret

0000000080004810 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004810:	7179                	addi	sp,sp,-48
    80004812:	f406                	sd	ra,40(sp)
    80004814:	f022                	sd	s0,32(sp)
    80004816:	ec26                	sd	s1,24(sp)
    80004818:	e84a                	sd	s2,16(sp)
    8000481a:	e44e                	sd	s3,8(sp)
    8000481c:	1800                	addi	s0,sp,48
    8000481e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004820:	00850913          	addi	s2,a0,8
    80004824:	854a                	mv	a0,s2
    80004826:	ffffc097          	auipc	ra,0xffffc
    8000482a:	3b0080e7          	jalr	944(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000482e:	409c                	lw	a5,0(s1)
    80004830:	ef99                	bnez	a5,8000484e <holdingsleep+0x3e>
    80004832:	4481                	li	s1,0
  release(&lk->lk);
    80004834:	854a                	mv	a0,s2
    80004836:	ffffc097          	auipc	ra,0xffffc
    8000483a:	454080e7          	jalr	1108(ra) # 80000c8a <release>
  return r;
}
    8000483e:	8526                	mv	a0,s1
    80004840:	70a2                	ld	ra,40(sp)
    80004842:	7402                	ld	s0,32(sp)
    80004844:	64e2                	ld	s1,24(sp)
    80004846:	6942                	ld	s2,16(sp)
    80004848:	69a2                	ld	s3,8(sp)
    8000484a:	6145                	addi	sp,sp,48
    8000484c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000484e:	0284a983          	lw	s3,40(s1)
    80004852:	ffffd097          	auipc	ra,0xffffd
    80004856:	15a080e7          	jalr	346(ra) # 800019ac <myproc>
    8000485a:	5904                	lw	s1,48(a0)
    8000485c:	413484b3          	sub	s1,s1,s3
    80004860:	0014b493          	seqz	s1,s1
    80004864:	bfc1                	j	80004834 <holdingsleep+0x24>

0000000080004866 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004866:	1141                	addi	sp,sp,-16
    80004868:	e406                	sd	ra,8(sp)
    8000486a:	e022                	sd	s0,0(sp)
    8000486c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000486e:	00004597          	auipc	a1,0x4
    80004872:	e7a58593          	addi	a1,a1,-390 # 800086e8 <syscalls+0x250>
    80004876:	0001d517          	auipc	a0,0x1d
    8000487a:	c5250513          	addi	a0,a0,-942 # 800214c8 <ftable>
    8000487e:	ffffc097          	auipc	ra,0xffffc
    80004882:	2c8080e7          	jalr	712(ra) # 80000b46 <initlock>
}
    80004886:	60a2                	ld	ra,8(sp)
    80004888:	6402                	ld	s0,0(sp)
    8000488a:	0141                	addi	sp,sp,16
    8000488c:	8082                	ret

000000008000488e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000488e:	1101                	addi	sp,sp,-32
    80004890:	ec06                	sd	ra,24(sp)
    80004892:	e822                	sd	s0,16(sp)
    80004894:	e426                	sd	s1,8(sp)
    80004896:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004898:	0001d517          	auipc	a0,0x1d
    8000489c:	c3050513          	addi	a0,a0,-976 # 800214c8 <ftable>
    800048a0:	ffffc097          	auipc	ra,0xffffc
    800048a4:	336080e7          	jalr	822(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048a8:	0001d497          	auipc	s1,0x1d
    800048ac:	c3848493          	addi	s1,s1,-968 # 800214e0 <ftable+0x18>
    800048b0:	0001e717          	auipc	a4,0x1e
    800048b4:	bd070713          	addi	a4,a4,-1072 # 80022480 <disk>
    if(f->ref == 0){
    800048b8:	40dc                	lw	a5,4(s1)
    800048ba:	cf99                	beqz	a5,800048d8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048bc:	02848493          	addi	s1,s1,40
    800048c0:	fee49ce3          	bne	s1,a4,800048b8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800048c4:	0001d517          	auipc	a0,0x1d
    800048c8:	c0450513          	addi	a0,a0,-1020 # 800214c8 <ftable>
    800048cc:	ffffc097          	auipc	ra,0xffffc
    800048d0:	3be080e7          	jalr	958(ra) # 80000c8a <release>
  return 0;
    800048d4:	4481                	li	s1,0
    800048d6:	a819                	j	800048ec <filealloc+0x5e>
      f->ref = 1;
    800048d8:	4785                	li	a5,1
    800048da:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800048dc:	0001d517          	auipc	a0,0x1d
    800048e0:	bec50513          	addi	a0,a0,-1044 # 800214c8 <ftable>
    800048e4:	ffffc097          	auipc	ra,0xffffc
    800048e8:	3a6080e7          	jalr	934(ra) # 80000c8a <release>
}
    800048ec:	8526                	mv	a0,s1
    800048ee:	60e2                	ld	ra,24(sp)
    800048f0:	6442                	ld	s0,16(sp)
    800048f2:	64a2                	ld	s1,8(sp)
    800048f4:	6105                	addi	sp,sp,32
    800048f6:	8082                	ret

00000000800048f8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800048f8:	1101                	addi	sp,sp,-32
    800048fa:	ec06                	sd	ra,24(sp)
    800048fc:	e822                	sd	s0,16(sp)
    800048fe:	e426                	sd	s1,8(sp)
    80004900:	1000                	addi	s0,sp,32
    80004902:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004904:	0001d517          	auipc	a0,0x1d
    80004908:	bc450513          	addi	a0,a0,-1084 # 800214c8 <ftable>
    8000490c:	ffffc097          	auipc	ra,0xffffc
    80004910:	2ca080e7          	jalr	714(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004914:	40dc                	lw	a5,4(s1)
    80004916:	02f05263          	blez	a5,8000493a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000491a:	2785                	addiw	a5,a5,1
    8000491c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000491e:	0001d517          	auipc	a0,0x1d
    80004922:	baa50513          	addi	a0,a0,-1110 # 800214c8 <ftable>
    80004926:	ffffc097          	auipc	ra,0xffffc
    8000492a:	364080e7          	jalr	868(ra) # 80000c8a <release>
  return f;
}
    8000492e:	8526                	mv	a0,s1
    80004930:	60e2                	ld	ra,24(sp)
    80004932:	6442                	ld	s0,16(sp)
    80004934:	64a2                	ld	s1,8(sp)
    80004936:	6105                	addi	sp,sp,32
    80004938:	8082                	ret
    panic("filedup");
    8000493a:	00004517          	auipc	a0,0x4
    8000493e:	db650513          	addi	a0,a0,-586 # 800086f0 <syscalls+0x258>
    80004942:	ffffc097          	auipc	ra,0xffffc
    80004946:	bfc080e7          	jalr	-1028(ra) # 8000053e <panic>

000000008000494a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000494a:	7139                	addi	sp,sp,-64
    8000494c:	fc06                	sd	ra,56(sp)
    8000494e:	f822                	sd	s0,48(sp)
    80004950:	f426                	sd	s1,40(sp)
    80004952:	f04a                	sd	s2,32(sp)
    80004954:	ec4e                	sd	s3,24(sp)
    80004956:	e852                	sd	s4,16(sp)
    80004958:	e456                	sd	s5,8(sp)
    8000495a:	0080                	addi	s0,sp,64
    8000495c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000495e:	0001d517          	auipc	a0,0x1d
    80004962:	b6a50513          	addi	a0,a0,-1174 # 800214c8 <ftable>
    80004966:	ffffc097          	auipc	ra,0xffffc
    8000496a:	270080e7          	jalr	624(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000496e:	40dc                	lw	a5,4(s1)
    80004970:	06f05163          	blez	a5,800049d2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004974:	37fd                	addiw	a5,a5,-1
    80004976:	0007871b          	sext.w	a4,a5
    8000497a:	c0dc                	sw	a5,4(s1)
    8000497c:	06e04363          	bgtz	a4,800049e2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004980:	0004a903          	lw	s2,0(s1)
    80004984:	0094ca83          	lbu	s5,9(s1)
    80004988:	0104ba03          	ld	s4,16(s1)
    8000498c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004990:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004994:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004998:	0001d517          	auipc	a0,0x1d
    8000499c:	b3050513          	addi	a0,a0,-1232 # 800214c8 <ftable>
    800049a0:	ffffc097          	auipc	ra,0xffffc
    800049a4:	2ea080e7          	jalr	746(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800049a8:	4785                	li	a5,1
    800049aa:	04f90d63          	beq	s2,a5,80004a04 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800049ae:	3979                	addiw	s2,s2,-2
    800049b0:	4785                	li	a5,1
    800049b2:	0527e063          	bltu	a5,s2,800049f2 <fileclose+0xa8>
    begin_op();
    800049b6:	00000097          	auipc	ra,0x0
    800049ba:	ac8080e7          	jalr	-1336(ra) # 8000447e <begin_op>
    iput(ff.ip);
    800049be:	854e                	mv	a0,s3
    800049c0:	fffff097          	auipc	ra,0xfffff
    800049c4:	2b6080e7          	jalr	694(ra) # 80003c76 <iput>
    end_op();
    800049c8:	00000097          	auipc	ra,0x0
    800049cc:	b36080e7          	jalr	-1226(ra) # 800044fe <end_op>
    800049d0:	a00d                	j	800049f2 <fileclose+0xa8>
    panic("fileclose");
    800049d2:	00004517          	auipc	a0,0x4
    800049d6:	d2650513          	addi	a0,a0,-730 # 800086f8 <syscalls+0x260>
    800049da:	ffffc097          	auipc	ra,0xffffc
    800049de:	b64080e7          	jalr	-1180(ra) # 8000053e <panic>
    release(&ftable.lock);
    800049e2:	0001d517          	auipc	a0,0x1d
    800049e6:	ae650513          	addi	a0,a0,-1306 # 800214c8 <ftable>
    800049ea:	ffffc097          	auipc	ra,0xffffc
    800049ee:	2a0080e7          	jalr	672(ra) # 80000c8a <release>
  }
}
    800049f2:	70e2                	ld	ra,56(sp)
    800049f4:	7442                	ld	s0,48(sp)
    800049f6:	74a2                	ld	s1,40(sp)
    800049f8:	7902                	ld	s2,32(sp)
    800049fa:	69e2                	ld	s3,24(sp)
    800049fc:	6a42                	ld	s4,16(sp)
    800049fe:	6aa2                	ld	s5,8(sp)
    80004a00:	6121                	addi	sp,sp,64
    80004a02:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a04:	85d6                	mv	a1,s5
    80004a06:	8552                	mv	a0,s4
    80004a08:	00000097          	auipc	ra,0x0
    80004a0c:	34c080e7          	jalr	844(ra) # 80004d54 <pipeclose>
    80004a10:	b7cd                	j	800049f2 <fileclose+0xa8>

0000000080004a12 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a12:	715d                	addi	sp,sp,-80
    80004a14:	e486                	sd	ra,72(sp)
    80004a16:	e0a2                	sd	s0,64(sp)
    80004a18:	fc26                	sd	s1,56(sp)
    80004a1a:	f84a                	sd	s2,48(sp)
    80004a1c:	f44e                	sd	s3,40(sp)
    80004a1e:	0880                	addi	s0,sp,80
    80004a20:	84aa                	mv	s1,a0
    80004a22:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a24:	ffffd097          	auipc	ra,0xffffd
    80004a28:	f88080e7          	jalr	-120(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a2c:	409c                	lw	a5,0(s1)
    80004a2e:	37f9                	addiw	a5,a5,-2
    80004a30:	4705                	li	a4,1
    80004a32:	04f76763          	bltu	a4,a5,80004a80 <filestat+0x6e>
    80004a36:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a38:	6c88                	ld	a0,24(s1)
    80004a3a:	fffff097          	auipc	ra,0xfffff
    80004a3e:	082080e7          	jalr	130(ra) # 80003abc <ilock>
    stati(f->ip, &st);
    80004a42:	fb840593          	addi	a1,s0,-72
    80004a46:	6c88                	ld	a0,24(s1)
    80004a48:	fffff097          	auipc	ra,0xfffff
    80004a4c:	2fe080e7          	jalr	766(ra) # 80003d46 <stati>
    iunlock(f->ip);
    80004a50:	6c88                	ld	a0,24(s1)
    80004a52:	fffff097          	auipc	ra,0xfffff
    80004a56:	12c080e7          	jalr	300(ra) # 80003b7e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004a5a:	46e1                	li	a3,24
    80004a5c:	fb840613          	addi	a2,s0,-72
    80004a60:	85ce                	mv	a1,s3
    80004a62:	05093503          	ld	a0,80(s2)
    80004a66:	ffffd097          	auipc	ra,0xffffd
    80004a6a:	c02080e7          	jalr	-1022(ra) # 80001668 <copyout>
    80004a6e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004a72:	60a6                	ld	ra,72(sp)
    80004a74:	6406                	ld	s0,64(sp)
    80004a76:	74e2                	ld	s1,56(sp)
    80004a78:	7942                	ld	s2,48(sp)
    80004a7a:	79a2                	ld	s3,40(sp)
    80004a7c:	6161                	addi	sp,sp,80
    80004a7e:	8082                	ret
  return -1;
    80004a80:	557d                	li	a0,-1
    80004a82:	bfc5                	j	80004a72 <filestat+0x60>

0000000080004a84 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004a84:	7179                	addi	sp,sp,-48
    80004a86:	f406                	sd	ra,40(sp)
    80004a88:	f022                	sd	s0,32(sp)
    80004a8a:	ec26                	sd	s1,24(sp)
    80004a8c:	e84a                	sd	s2,16(sp)
    80004a8e:	e44e                	sd	s3,8(sp)
    80004a90:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004a92:	00854783          	lbu	a5,8(a0)
    80004a96:	c3d5                	beqz	a5,80004b3a <fileread+0xb6>
    80004a98:	84aa                	mv	s1,a0
    80004a9a:	89ae                	mv	s3,a1
    80004a9c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a9e:	411c                	lw	a5,0(a0)
    80004aa0:	4705                	li	a4,1
    80004aa2:	04e78963          	beq	a5,a4,80004af4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004aa6:	470d                	li	a4,3
    80004aa8:	04e78d63          	beq	a5,a4,80004b02 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004aac:	4709                	li	a4,2
    80004aae:	06e79e63          	bne	a5,a4,80004b2a <fileread+0xa6>
    ilock(f->ip);
    80004ab2:	6d08                	ld	a0,24(a0)
    80004ab4:	fffff097          	auipc	ra,0xfffff
    80004ab8:	008080e7          	jalr	8(ra) # 80003abc <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004abc:	874a                	mv	a4,s2
    80004abe:	5094                	lw	a3,32(s1)
    80004ac0:	864e                	mv	a2,s3
    80004ac2:	4585                	li	a1,1
    80004ac4:	6c88                	ld	a0,24(s1)
    80004ac6:	fffff097          	auipc	ra,0xfffff
    80004aca:	2aa080e7          	jalr	682(ra) # 80003d70 <readi>
    80004ace:	892a                	mv	s2,a0
    80004ad0:	00a05563          	blez	a0,80004ada <fileread+0x56>
      f->off += r;
    80004ad4:	509c                	lw	a5,32(s1)
    80004ad6:	9fa9                	addw	a5,a5,a0
    80004ad8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004ada:	6c88                	ld	a0,24(s1)
    80004adc:	fffff097          	auipc	ra,0xfffff
    80004ae0:	0a2080e7          	jalr	162(ra) # 80003b7e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004ae4:	854a                	mv	a0,s2
    80004ae6:	70a2                	ld	ra,40(sp)
    80004ae8:	7402                	ld	s0,32(sp)
    80004aea:	64e2                	ld	s1,24(sp)
    80004aec:	6942                	ld	s2,16(sp)
    80004aee:	69a2                	ld	s3,8(sp)
    80004af0:	6145                	addi	sp,sp,48
    80004af2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004af4:	6908                	ld	a0,16(a0)
    80004af6:	00000097          	auipc	ra,0x0
    80004afa:	3c6080e7          	jalr	966(ra) # 80004ebc <piperead>
    80004afe:	892a                	mv	s2,a0
    80004b00:	b7d5                	j	80004ae4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b02:	02451783          	lh	a5,36(a0)
    80004b06:	03079693          	slli	a3,a5,0x30
    80004b0a:	92c1                	srli	a3,a3,0x30
    80004b0c:	4725                	li	a4,9
    80004b0e:	02d76863          	bltu	a4,a3,80004b3e <fileread+0xba>
    80004b12:	0792                	slli	a5,a5,0x4
    80004b14:	0001d717          	auipc	a4,0x1d
    80004b18:	91470713          	addi	a4,a4,-1772 # 80021428 <devsw>
    80004b1c:	97ba                	add	a5,a5,a4
    80004b1e:	639c                	ld	a5,0(a5)
    80004b20:	c38d                	beqz	a5,80004b42 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b22:	4505                	li	a0,1
    80004b24:	9782                	jalr	a5
    80004b26:	892a                	mv	s2,a0
    80004b28:	bf75                	j	80004ae4 <fileread+0x60>
    panic("fileread");
    80004b2a:	00004517          	auipc	a0,0x4
    80004b2e:	bde50513          	addi	a0,a0,-1058 # 80008708 <syscalls+0x270>
    80004b32:	ffffc097          	auipc	ra,0xffffc
    80004b36:	a0c080e7          	jalr	-1524(ra) # 8000053e <panic>
    return -1;
    80004b3a:	597d                	li	s2,-1
    80004b3c:	b765                	j	80004ae4 <fileread+0x60>
      return -1;
    80004b3e:	597d                	li	s2,-1
    80004b40:	b755                	j	80004ae4 <fileread+0x60>
    80004b42:	597d                	li	s2,-1
    80004b44:	b745                	j	80004ae4 <fileread+0x60>

0000000080004b46 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004b46:	715d                	addi	sp,sp,-80
    80004b48:	e486                	sd	ra,72(sp)
    80004b4a:	e0a2                	sd	s0,64(sp)
    80004b4c:	fc26                	sd	s1,56(sp)
    80004b4e:	f84a                	sd	s2,48(sp)
    80004b50:	f44e                	sd	s3,40(sp)
    80004b52:	f052                	sd	s4,32(sp)
    80004b54:	ec56                	sd	s5,24(sp)
    80004b56:	e85a                	sd	s6,16(sp)
    80004b58:	e45e                	sd	s7,8(sp)
    80004b5a:	e062                	sd	s8,0(sp)
    80004b5c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004b5e:	00954783          	lbu	a5,9(a0)
    80004b62:	10078663          	beqz	a5,80004c6e <filewrite+0x128>
    80004b66:	892a                	mv	s2,a0
    80004b68:	8aae                	mv	s5,a1
    80004b6a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b6c:	411c                	lw	a5,0(a0)
    80004b6e:	4705                	li	a4,1
    80004b70:	02e78263          	beq	a5,a4,80004b94 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b74:	470d                	li	a4,3
    80004b76:	02e78663          	beq	a5,a4,80004ba2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b7a:	4709                	li	a4,2
    80004b7c:	0ee79163          	bne	a5,a4,80004c5e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004b80:	0ac05d63          	blez	a2,80004c3a <filewrite+0xf4>
    int i = 0;
    80004b84:	4981                	li	s3,0
    80004b86:	6b05                	lui	s6,0x1
    80004b88:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004b8c:	6b85                	lui	s7,0x1
    80004b8e:	c00b8b9b          	addiw	s7,s7,-1024
    80004b92:	a861                	j	80004c2a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004b94:	6908                	ld	a0,16(a0)
    80004b96:	00000097          	auipc	ra,0x0
    80004b9a:	22e080e7          	jalr	558(ra) # 80004dc4 <pipewrite>
    80004b9e:	8a2a                	mv	s4,a0
    80004ba0:	a045                	j	80004c40 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004ba2:	02451783          	lh	a5,36(a0)
    80004ba6:	03079693          	slli	a3,a5,0x30
    80004baa:	92c1                	srli	a3,a3,0x30
    80004bac:	4725                	li	a4,9
    80004bae:	0cd76263          	bltu	a4,a3,80004c72 <filewrite+0x12c>
    80004bb2:	0792                	slli	a5,a5,0x4
    80004bb4:	0001d717          	auipc	a4,0x1d
    80004bb8:	87470713          	addi	a4,a4,-1932 # 80021428 <devsw>
    80004bbc:	97ba                	add	a5,a5,a4
    80004bbe:	679c                	ld	a5,8(a5)
    80004bc0:	cbdd                	beqz	a5,80004c76 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004bc2:	4505                	li	a0,1
    80004bc4:	9782                	jalr	a5
    80004bc6:	8a2a                	mv	s4,a0
    80004bc8:	a8a5                	j	80004c40 <filewrite+0xfa>
    80004bca:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004bce:	00000097          	auipc	ra,0x0
    80004bd2:	8b0080e7          	jalr	-1872(ra) # 8000447e <begin_op>
      ilock(f->ip);
    80004bd6:	01893503          	ld	a0,24(s2)
    80004bda:	fffff097          	auipc	ra,0xfffff
    80004bde:	ee2080e7          	jalr	-286(ra) # 80003abc <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004be2:	8762                	mv	a4,s8
    80004be4:	02092683          	lw	a3,32(s2)
    80004be8:	01598633          	add	a2,s3,s5
    80004bec:	4585                	li	a1,1
    80004bee:	01893503          	ld	a0,24(s2)
    80004bf2:	fffff097          	auipc	ra,0xfffff
    80004bf6:	276080e7          	jalr	630(ra) # 80003e68 <writei>
    80004bfa:	84aa                	mv	s1,a0
    80004bfc:	00a05763          	blez	a0,80004c0a <filewrite+0xc4>
        f->off += r;
    80004c00:	02092783          	lw	a5,32(s2)
    80004c04:	9fa9                	addw	a5,a5,a0
    80004c06:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c0a:	01893503          	ld	a0,24(s2)
    80004c0e:	fffff097          	auipc	ra,0xfffff
    80004c12:	f70080e7          	jalr	-144(ra) # 80003b7e <iunlock>
      end_op();
    80004c16:	00000097          	auipc	ra,0x0
    80004c1a:	8e8080e7          	jalr	-1816(ra) # 800044fe <end_op>

      if(r != n1){
    80004c1e:	009c1f63          	bne	s8,s1,80004c3c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c22:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c26:	0149db63          	bge	s3,s4,80004c3c <filewrite+0xf6>
      int n1 = n - i;
    80004c2a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004c2e:	84be                	mv	s1,a5
    80004c30:	2781                	sext.w	a5,a5
    80004c32:	f8fb5ce3          	bge	s6,a5,80004bca <filewrite+0x84>
    80004c36:	84de                	mv	s1,s7
    80004c38:	bf49                	j	80004bca <filewrite+0x84>
    int i = 0;
    80004c3a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004c3c:	013a1f63          	bne	s4,s3,80004c5a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004c40:	8552                	mv	a0,s4
    80004c42:	60a6                	ld	ra,72(sp)
    80004c44:	6406                	ld	s0,64(sp)
    80004c46:	74e2                	ld	s1,56(sp)
    80004c48:	7942                	ld	s2,48(sp)
    80004c4a:	79a2                	ld	s3,40(sp)
    80004c4c:	7a02                	ld	s4,32(sp)
    80004c4e:	6ae2                	ld	s5,24(sp)
    80004c50:	6b42                	ld	s6,16(sp)
    80004c52:	6ba2                	ld	s7,8(sp)
    80004c54:	6c02                	ld	s8,0(sp)
    80004c56:	6161                	addi	sp,sp,80
    80004c58:	8082                	ret
    ret = (i == n ? n : -1);
    80004c5a:	5a7d                	li	s4,-1
    80004c5c:	b7d5                	j	80004c40 <filewrite+0xfa>
    panic("filewrite");
    80004c5e:	00004517          	auipc	a0,0x4
    80004c62:	aba50513          	addi	a0,a0,-1350 # 80008718 <syscalls+0x280>
    80004c66:	ffffc097          	auipc	ra,0xffffc
    80004c6a:	8d8080e7          	jalr	-1832(ra) # 8000053e <panic>
    return -1;
    80004c6e:	5a7d                	li	s4,-1
    80004c70:	bfc1                	j	80004c40 <filewrite+0xfa>
      return -1;
    80004c72:	5a7d                	li	s4,-1
    80004c74:	b7f1                	j	80004c40 <filewrite+0xfa>
    80004c76:	5a7d                	li	s4,-1
    80004c78:	b7e1                	j	80004c40 <filewrite+0xfa>

0000000080004c7a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004c7a:	7179                	addi	sp,sp,-48
    80004c7c:	f406                	sd	ra,40(sp)
    80004c7e:	f022                	sd	s0,32(sp)
    80004c80:	ec26                	sd	s1,24(sp)
    80004c82:	e84a                	sd	s2,16(sp)
    80004c84:	e44e                	sd	s3,8(sp)
    80004c86:	e052                	sd	s4,0(sp)
    80004c88:	1800                	addi	s0,sp,48
    80004c8a:	84aa                	mv	s1,a0
    80004c8c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004c8e:	0005b023          	sd	zero,0(a1)
    80004c92:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004c96:	00000097          	auipc	ra,0x0
    80004c9a:	bf8080e7          	jalr	-1032(ra) # 8000488e <filealloc>
    80004c9e:	e088                	sd	a0,0(s1)
    80004ca0:	c551                	beqz	a0,80004d2c <pipealloc+0xb2>
    80004ca2:	00000097          	auipc	ra,0x0
    80004ca6:	bec080e7          	jalr	-1044(ra) # 8000488e <filealloc>
    80004caa:	00aa3023          	sd	a0,0(s4)
    80004cae:	c92d                	beqz	a0,80004d20 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004cb0:	ffffc097          	auipc	ra,0xffffc
    80004cb4:	e36080e7          	jalr	-458(ra) # 80000ae6 <kalloc>
    80004cb8:	892a                	mv	s2,a0
    80004cba:	c125                	beqz	a0,80004d1a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004cbc:	4985                	li	s3,1
    80004cbe:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004cc2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004cc6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004cca:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004cce:	00004597          	auipc	a1,0x4
    80004cd2:	a5a58593          	addi	a1,a1,-1446 # 80008728 <syscalls+0x290>
    80004cd6:	ffffc097          	auipc	ra,0xffffc
    80004cda:	e70080e7          	jalr	-400(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004cde:	609c                	ld	a5,0(s1)
    80004ce0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ce4:	609c                	ld	a5,0(s1)
    80004ce6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004cea:	609c                	ld	a5,0(s1)
    80004cec:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004cf0:	609c                	ld	a5,0(s1)
    80004cf2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004cf6:	000a3783          	ld	a5,0(s4)
    80004cfa:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004cfe:	000a3783          	ld	a5,0(s4)
    80004d02:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d06:	000a3783          	ld	a5,0(s4)
    80004d0a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d0e:	000a3783          	ld	a5,0(s4)
    80004d12:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d16:	4501                	li	a0,0
    80004d18:	a025                	j	80004d40 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d1a:	6088                	ld	a0,0(s1)
    80004d1c:	e501                	bnez	a0,80004d24 <pipealloc+0xaa>
    80004d1e:	a039                	j	80004d2c <pipealloc+0xb2>
    80004d20:	6088                	ld	a0,0(s1)
    80004d22:	c51d                	beqz	a0,80004d50 <pipealloc+0xd6>
    fileclose(*f0);
    80004d24:	00000097          	auipc	ra,0x0
    80004d28:	c26080e7          	jalr	-986(ra) # 8000494a <fileclose>
  if(*f1)
    80004d2c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d30:	557d                	li	a0,-1
  if(*f1)
    80004d32:	c799                	beqz	a5,80004d40 <pipealloc+0xc6>
    fileclose(*f1);
    80004d34:	853e                	mv	a0,a5
    80004d36:	00000097          	auipc	ra,0x0
    80004d3a:	c14080e7          	jalr	-1004(ra) # 8000494a <fileclose>
  return -1;
    80004d3e:	557d                	li	a0,-1
}
    80004d40:	70a2                	ld	ra,40(sp)
    80004d42:	7402                	ld	s0,32(sp)
    80004d44:	64e2                	ld	s1,24(sp)
    80004d46:	6942                	ld	s2,16(sp)
    80004d48:	69a2                	ld	s3,8(sp)
    80004d4a:	6a02                	ld	s4,0(sp)
    80004d4c:	6145                	addi	sp,sp,48
    80004d4e:	8082                	ret
  return -1;
    80004d50:	557d                	li	a0,-1
    80004d52:	b7fd                	j	80004d40 <pipealloc+0xc6>

0000000080004d54 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004d54:	1101                	addi	sp,sp,-32
    80004d56:	ec06                	sd	ra,24(sp)
    80004d58:	e822                	sd	s0,16(sp)
    80004d5a:	e426                	sd	s1,8(sp)
    80004d5c:	e04a                	sd	s2,0(sp)
    80004d5e:	1000                	addi	s0,sp,32
    80004d60:	84aa                	mv	s1,a0
    80004d62:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004d64:	ffffc097          	auipc	ra,0xffffc
    80004d68:	e72080e7          	jalr	-398(ra) # 80000bd6 <acquire>
  if(writable){
    80004d6c:	02090d63          	beqz	s2,80004da6 <pipeclose+0x52>
    pi->writeopen = 0;
    80004d70:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004d74:	21848513          	addi	a0,s1,536
    80004d78:	ffffd097          	auipc	ra,0xffffd
    80004d7c:	340080e7          	jalr	832(ra) # 800020b8 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004d80:	2204b783          	ld	a5,544(s1)
    80004d84:	eb95                	bnez	a5,80004db8 <pipeclose+0x64>
    release(&pi->lock);
    80004d86:	8526                	mv	a0,s1
    80004d88:	ffffc097          	auipc	ra,0xffffc
    80004d8c:	f02080e7          	jalr	-254(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004d90:	8526                	mv	a0,s1
    80004d92:	ffffc097          	auipc	ra,0xffffc
    80004d96:	c58080e7          	jalr	-936(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80004d9a:	60e2                	ld	ra,24(sp)
    80004d9c:	6442                	ld	s0,16(sp)
    80004d9e:	64a2                	ld	s1,8(sp)
    80004da0:	6902                	ld	s2,0(sp)
    80004da2:	6105                	addi	sp,sp,32
    80004da4:	8082                	ret
    pi->readopen = 0;
    80004da6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004daa:	21c48513          	addi	a0,s1,540
    80004dae:	ffffd097          	auipc	ra,0xffffd
    80004db2:	30a080e7          	jalr	778(ra) # 800020b8 <wakeup>
    80004db6:	b7e9                	j	80004d80 <pipeclose+0x2c>
    release(&pi->lock);
    80004db8:	8526                	mv	a0,s1
    80004dba:	ffffc097          	auipc	ra,0xffffc
    80004dbe:	ed0080e7          	jalr	-304(ra) # 80000c8a <release>
}
    80004dc2:	bfe1                	j	80004d9a <pipeclose+0x46>

0000000080004dc4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004dc4:	711d                	addi	sp,sp,-96
    80004dc6:	ec86                	sd	ra,88(sp)
    80004dc8:	e8a2                	sd	s0,80(sp)
    80004dca:	e4a6                	sd	s1,72(sp)
    80004dcc:	e0ca                	sd	s2,64(sp)
    80004dce:	fc4e                	sd	s3,56(sp)
    80004dd0:	f852                	sd	s4,48(sp)
    80004dd2:	f456                	sd	s5,40(sp)
    80004dd4:	f05a                	sd	s6,32(sp)
    80004dd6:	ec5e                	sd	s7,24(sp)
    80004dd8:	e862                	sd	s8,16(sp)
    80004dda:	1080                	addi	s0,sp,96
    80004ddc:	84aa                	mv	s1,a0
    80004dde:	8aae                	mv	s5,a1
    80004de0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004de2:	ffffd097          	auipc	ra,0xffffd
    80004de6:	bca080e7          	jalr	-1078(ra) # 800019ac <myproc>
    80004dea:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004dec:	8526                	mv	a0,s1
    80004dee:	ffffc097          	auipc	ra,0xffffc
    80004df2:	de8080e7          	jalr	-536(ra) # 80000bd6 <acquire>
  while(i < n){
    80004df6:	0b405663          	blez	s4,80004ea2 <pipewrite+0xde>
  int i = 0;
    80004dfa:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004dfc:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004dfe:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e02:	21c48b93          	addi	s7,s1,540
    80004e06:	a089                	j	80004e48 <pipewrite+0x84>
      release(&pi->lock);
    80004e08:	8526                	mv	a0,s1
    80004e0a:	ffffc097          	auipc	ra,0xffffc
    80004e0e:	e80080e7          	jalr	-384(ra) # 80000c8a <release>
      return -1;
    80004e12:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e14:	854a                	mv	a0,s2
    80004e16:	60e6                	ld	ra,88(sp)
    80004e18:	6446                	ld	s0,80(sp)
    80004e1a:	64a6                	ld	s1,72(sp)
    80004e1c:	6906                	ld	s2,64(sp)
    80004e1e:	79e2                	ld	s3,56(sp)
    80004e20:	7a42                	ld	s4,48(sp)
    80004e22:	7aa2                	ld	s5,40(sp)
    80004e24:	7b02                	ld	s6,32(sp)
    80004e26:	6be2                	ld	s7,24(sp)
    80004e28:	6c42                	ld	s8,16(sp)
    80004e2a:	6125                	addi	sp,sp,96
    80004e2c:	8082                	ret
      wakeup(&pi->nread);
    80004e2e:	8562                	mv	a0,s8
    80004e30:	ffffd097          	auipc	ra,0xffffd
    80004e34:	288080e7          	jalr	648(ra) # 800020b8 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e38:	85a6                	mv	a1,s1
    80004e3a:	855e                	mv	a0,s7
    80004e3c:	ffffd097          	auipc	ra,0xffffd
    80004e40:	218080e7          	jalr	536(ra) # 80002054 <sleep>
  while(i < n){
    80004e44:	07495063          	bge	s2,s4,80004ea4 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004e48:	2204a783          	lw	a5,544(s1)
    80004e4c:	dfd5                	beqz	a5,80004e08 <pipewrite+0x44>
    80004e4e:	854e                	mv	a0,s3
    80004e50:	ffffd097          	auipc	ra,0xffffd
    80004e54:	674080e7          	jalr	1652(ra) # 800024c4 <killed>
    80004e58:	f945                	bnez	a0,80004e08 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004e5a:	2184a783          	lw	a5,536(s1)
    80004e5e:	21c4a703          	lw	a4,540(s1)
    80004e62:	2007879b          	addiw	a5,a5,512
    80004e66:	fcf704e3          	beq	a4,a5,80004e2e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e6a:	4685                	li	a3,1
    80004e6c:	01590633          	add	a2,s2,s5
    80004e70:	faf40593          	addi	a1,s0,-81
    80004e74:	0509b503          	ld	a0,80(s3)
    80004e78:	ffffd097          	auipc	ra,0xffffd
    80004e7c:	87c080e7          	jalr	-1924(ra) # 800016f4 <copyin>
    80004e80:	03650263          	beq	a0,s6,80004ea4 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004e84:	21c4a783          	lw	a5,540(s1)
    80004e88:	0017871b          	addiw	a4,a5,1
    80004e8c:	20e4ae23          	sw	a4,540(s1)
    80004e90:	1ff7f793          	andi	a5,a5,511
    80004e94:	97a6                	add	a5,a5,s1
    80004e96:	faf44703          	lbu	a4,-81(s0)
    80004e9a:	00e78c23          	sb	a4,24(a5)
      i++;
    80004e9e:	2905                	addiw	s2,s2,1
    80004ea0:	b755                	j	80004e44 <pipewrite+0x80>
  int i = 0;
    80004ea2:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004ea4:	21848513          	addi	a0,s1,536
    80004ea8:	ffffd097          	auipc	ra,0xffffd
    80004eac:	210080e7          	jalr	528(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004eb0:	8526                	mv	a0,s1
    80004eb2:	ffffc097          	auipc	ra,0xffffc
    80004eb6:	dd8080e7          	jalr	-552(ra) # 80000c8a <release>
  return i;
    80004eba:	bfa9                	j	80004e14 <pipewrite+0x50>

0000000080004ebc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ebc:	715d                	addi	sp,sp,-80
    80004ebe:	e486                	sd	ra,72(sp)
    80004ec0:	e0a2                	sd	s0,64(sp)
    80004ec2:	fc26                	sd	s1,56(sp)
    80004ec4:	f84a                	sd	s2,48(sp)
    80004ec6:	f44e                	sd	s3,40(sp)
    80004ec8:	f052                	sd	s4,32(sp)
    80004eca:	ec56                	sd	s5,24(sp)
    80004ecc:	e85a                	sd	s6,16(sp)
    80004ece:	0880                	addi	s0,sp,80
    80004ed0:	84aa                	mv	s1,a0
    80004ed2:	892e                	mv	s2,a1
    80004ed4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ed6:	ffffd097          	auipc	ra,0xffffd
    80004eda:	ad6080e7          	jalr	-1322(ra) # 800019ac <myproc>
    80004ede:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ee0:	8526                	mv	a0,s1
    80004ee2:	ffffc097          	auipc	ra,0xffffc
    80004ee6:	cf4080e7          	jalr	-780(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004eea:	2184a703          	lw	a4,536(s1)
    80004eee:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ef2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ef6:	02f71763          	bne	a4,a5,80004f24 <piperead+0x68>
    80004efa:	2244a783          	lw	a5,548(s1)
    80004efe:	c39d                	beqz	a5,80004f24 <piperead+0x68>
    if(killed(pr)){
    80004f00:	8552                	mv	a0,s4
    80004f02:	ffffd097          	auipc	ra,0xffffd
    80004f06:	5c2080e7          	jalr	1474(ra) # 800024c4 <killed>
    80004f0a:	e941                	bnez	a0,80004f9a <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f0c:	85a6                	mv	a1,s1
    80004f0e:	854e                	mv	a0,s3
    80004f10:	ffffd097          	auipc	ra,0xffffd
    80004f14:	144080e7          	jalr	324(ra) # 80002054 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f18:	2184a703          	lw	a4,536(s1)
    80004f1c:	21c4a783          	lw	a5,540(s1)
    80004f20:	fcf70de3          	beq	a4,a5,80004efa <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f24:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f26:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f28:	05505363          	blez	s5,80004f6e <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80004f2c:	2184a783          	lw	a5,536(s1)
    80004f30:	21c4a703          	lw	a4,540(s1)
    80004f34:	02f70d63          	beq	a4,a5,80004f6e <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f38:	0017871b          	addiw	a4,a5,1
    80004f3c:	20e4ac23          	sw	a4,536(s1)
    80004f40:	1ff7f793          	andi	a5,a5,511
    80004f44:	97a6                	add	a5,a5,s1
    80004f46:	0187c783          	lbu	a5,24(a5)
    80004f4a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f4e:	4685                	li	a3,1
    80004f50:	fbf40613          	addi	a2,s0,-65
    80004f54:	85ca                	mv	a1,s2
    80004f56:	050a3503          	ld	a0,80(s4)
    80004f5a:	ffffc097          	auipc	ra,0xffffc
    80004f5e:	70e080e7          	jalr	1806(ra) # 80001668 <copyout>
    80004f62:	01650663          	beq	a0,s6,80004f6e <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f66:	2985                	addiw	s3,s3,1
    80004f68:	0905                	addi	s2,s2,1
    80004f6a:	fd3a91e3          	bne	s5,s3,80004f2c <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004f6e:	21c48513          	addi	a0,s1,540
    80004f72:	ffffd097          	auipc	ra,0xffffd
    80004f76:	146080e7          	jalr	326(ra) # 800020b8 <wakeup>
  release(&pi->lock);
    80004f7a:	8526                	mv	a0,s1
    80004f7c:	ffffc097          	auipc	ra,0xffffc
    80004f80:	d0e080e7          	jalr	-754(ra) # 80000c8a <release>
  return i;
}
    80004f84:	854e                	mv	a0,s3
    80004f86:	60a6                	ld	ra,72(sp)
    80004f88:	6406                	ld	s0,64(sp)
    80004f8a:	74e2                	ld	s1,56(sp)
    80004f8c:	7942                	ld	s2,48(sp)
    80004f8e:	79a2                	ld	s3,40(sp)
    80004f90:	7a02                	ld	s4,32(sp)
    80004f92:	6ae2                	ld	s5,24(sp)
    80004f94:	6b42                	ld	s6,16(sp)
    80004f96:	6161                	addi	sp,sp,80
    80004f98:	8082                	ret
      release(&pi->lock);
    80004f9a:	8526                	mv	a0,s1
    80004f9c:	ffffc097          	auipc	ra,0xffffc
    80004fa0:	cee080e7          	jalr	-786(ra) # 80000c8a <release>
      return -1;
    80004fa4:	59fd                	li	s3,-1
    80004fa6:	bff9                	j	80004f84 <piperead+0xc8>

0000000080004fa8 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004fa8:	1141                	addi	sp,sp,-16
    80004faa:	e422                	sd	s0,8(sp)
    80004fac:	0800                	addi	s0,sp,16
    80004fae:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004fb0:	8905                	andi	a0,a0,1
    80004fb2:	c111                	beqz	a0,80004fb6 <flags2perm+0xe>
      perm = PTE_X;
    80004fb4:	4521                	li	a0,8
    if(flags & 0x2)
    80004fb6:	8b89                	andi	a5,a5,2
    80004fb8:	c399                	beqz	a5,80004fbe <flags2perm+0x16>
      perm |= PTE_W;
    80004fba:	00456513          	ori	a0,a0,4
    return perm;
}
    80004fbe:	6422                	ld	s0,8(sp)
    80004fc0:	0141                	addi	sp,sp,16
    80004fc2:	8082                	ret

0000000080004fc4 <exec>:

int
exec(char *path, char **argv)
{
    80004fc4:	de010113          	addi	sp,sp,-544
    80004fc8:	20113c23          	sd	ra,536(sp)
    80004fcc:	20813823          	sd	s0,528(sp)
    80004fd0:	20913423          	sd	s1,520(sp)
    80004fd4:	21213023          	sd	s2,512(sp)
    80004fd8:	ffce                	sd	s3,504(sp)
    80004fda:	fbd2                	sd	s4,496(sp)
    80004fdc:	f7d6                	sd	s5,488(sp)
    80004fde:	f3da                	sd	s6,480(sp)
    80004fe0:	efde                	sd	s7,472(sp)
    80004fe2:	ebe2                	sd	s8,464(sp)
    80004fe4:	e7e6                	sd	s9,456(sp)
    80004fe6:	e3ea                	sd	s10,448(sp)
    80004fe8:	ff6e                	sd	s11,440(sp)
    80004fea:	1400                	addi	s0,sp,544
    80004fec:	892a                	mv	s2,a0
    80004fee:	dea43423          	sd	a0,-536(s0)
    80004ff2:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ff6:	ffffd097          	auipc	ra,0xffffd
    80004ffa:	9b6080e7          	jalr	-1610(ra) # 800019ac <myproc>
    80004ffe:	84aa                	mv	s1,a0

  begin_op();
    80005000:	fffff097          	auipc	ra,0xfffff
    80005004:	47e080e7          	jalr	1150(ra) # 8000447e <begin_op>

  if((ip = namei(path)) == 0){
    80005008:	854a                	mv	a0,s2
    8000500a:	fffff097          	auipc	ra,0xfffff
    8000500e:	258080e7          	jalr	600(ra) # 80004262 <namei>
    80005012:	c93d                	beqz	a0,80005088 <exec+0xc4>
    80005014:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005016:	fffff097          	auipc	ra,0xfffff
    8000501a:	aa6080e7          	jalr	-1370(ra) # 80003abc <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000501e:	04000713          	li	a4,64
    80005022:	4681                	li	a3,0
    80005024:	e5040613          	addi	a2,s0,-432
    80005028:	4581                	li	a1,0
    8000502a:	8556                	mv	a0,s5
    8000502c:	fffff097          	auipc	ra,0xfffff
    80005030:	d44080e7          	jalr	-700(ra) # 80003d70 <readi>
    80005034:	04000793          	li	a5,64
    80005038:	00f51a63          	bne	a0,a5,8000504c <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    8000503c:	e5042703          	lw	a4,-432(s0)
    80005040:	464c47b7          	lui	a5,0x464c4
    80005044:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005048:	04f70663          	beq	a4,a5,80005094 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000504c:	8556                	mv	a0,s5
    8000504e:	fffff097          	auipc	ra,0xfffff
    80005052:	cd0080e7          	jalr	-816(ra) # 80003d1e <iunlockput>
    end_op();
    80005056:	fffff097          	auipc	ra,0xfffff
    8000505a:	4a8080e7          	jalr	1192(ra) # 800044fe <end_op>
  }
  return -1;
    8000505e:	557d                	li	a0,-1
}
    80005060:	21813083          	ld	ra,536(sp)
    80005064:	21013403          	ld	s0,528(sp)
    80005068:	20813483          	ld	s1,520(sp)
    8000506c:	20013903          	ld	s2,512(sp)
    80005070:	79fe                	ld	s3,504(sp)
    80005072:	7a5e                	ld	s4,496(sp)
    80005074:	7abe                	ld	s5,488(sp)
    80005076:	7b1e                	ld	s6,480(sp)
    80005078:	6bfe                	ld	s7,472(sp)
    8000507a:	6c5e                	ld	s8,464(sp)
    8000507c:	6cbe                	ld	s9,456(sp)
    8000507e:	6d1e                	ld	s10,448(sp)
    80005080:	7dfa                	ld	s11,440(sp)
    80005082:	22010113          	addi	sp,sp,544
    80005086:	8082                	ret
    end_op();
    80005088:	fffff097          	auipc	ra,0xfffff
    8000508c:	476080e7          	jalr	1142(ra) # 800044fe <end_op>
    return -1;
    80005090:	557d                	li	a0,-1
    80005092:	b7f9                	j	80005060 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005094:	8526                	mv	a0,s1
    80005096:	ffffd097          	auipc	ra,0xffffd
    8000509a:	9da080e7          	jalr	-1574(ra) # 80001a70 <proc_pagetable>
    8000509e:	8b2a                	mv	s6,a0
    800050a0:	d555                	beqz	a0,8000504c <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050a2:	e7042783          	lw	a5,-400(s0)
    800050a6:	e8845703          	lhu	a4,-376(s0)
    800050aa:	c735                	beqz	a4,80005116 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050ac:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050ae:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800050b2:	6a05                	lui	s4,0x1
    800050b4:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800050b8:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800050bc:	6d85                	lui	s11,0x1
    800050be:	7d7d                	lui	s10,0xfffff
    800050c0:	a481                	j	80005300 <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800050c2:	00003517          	auipc	a0,0x3
    800050c6:	66e50513          	addi	a0,a0,1646 # 80008730 <syscalls+0x298>
    800050ca:	ffffb097          	auipc	ra,0xffffb
    800050ce:	474080e7          	jalr	1140(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800050d2:	874a                	mv	a4,s2
    800050d4:	009c86bb          	addw	a3,s9,s1
    800050d8:	4581                	li	a1,0
    800050da:	8556                	mv	a0,s5
    800050dc:	fffff097          	auipc	ra,0xfffff
    800050e0:	c94080e7          	jalr	-876(ra) # 80003d70 <readi>
    800050e4:	2501                	sext.w	a0,a0
    800050e6:	1aa91a63          	bne	s2,a0,8000529a <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    800050ea:	009d84bb          	addw	s1,s11,s1
    800050ee:	013d09bb          	addw	s3,s10,s3
    800050f2:	1f74f763          	bgeu	s1,s7,800052e0 <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    800050f6:	02049593          	slli	a1,s1,0x20
    800050fa:	9181                	srli	a1,a1,0x20
    800050fc:	95e2                	add	a1,a1,s8
    800050fe:	855a                	mv	a0,s6
    80005100:	ffffc097          	auipc	ra,0xffffc
    80005104:	f5c080e7          	jalr	-164(ra) # 8000105c <walkaddr>
    80005108:	862a                	mv	a2,a0
    if(pa == 0)
    8000510a:	dd45                	beqz	a0,800050c2 <exec+0xfe>
      n = PGSIZE;
    8000510c:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000510e:	fd49f2e3          	bgeu	s3,s4,800050d2 <exec+0x10e>
      n = sz - i;
    80005112:	894e                	mv	s2,s3
    80005114:	bf7d                	j	800050d2 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005116:	4901                	li	s2,0
  iunlockput(ip);
    80005118:	8556                	mv	a0,s5
    8000511a:	fffff097          	auipc	ra,0xfffff
    8000511e:	c04080e7          	jalr	-1020(ra) # 80003d1e <iunlockput>
  end_op();
    80005122:	fffff097          	auipc	ra,0xfffff
    80005126:	3dc080e7          	jalr	988(ra) # 800044fe <end_op>
  p = myproc();
    8000512a:	ffffd097          	auipc	ra,0xffffd
    8000512e:	882080e7          	jalr	-1918(ra) # 800019ac <myproc>
    80005132:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005134:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005138:	6785                	lui	a5,0x1
    8000513a:	17fd                	addi	a5,a5,-1
    8000513c:	993e                	add	s2,s2,a5
    8000513e:	77fd                	lui	a5,0xfffff
    80005140:	00f977b3          	and	a5,s2,a5
    80005144:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005148:	4691                	li	a3,4
    8000514a:	6609                	lui	a2,0x2
    8000514c:	963e                	add	a2,a2,a5
    8000514e:	85be                	mv	a1,a5
    80005150:	855a                	mv	a0,s6
    80005152:	ffffc097          	auipc	ra,0xffffc
    80005156:	2be080e7          	jalr	702(ra) # 80001410 <uvmalloc>
    8000515a:	8c2a                	mv	s8,a0
  ip = 0;
    8000515c:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000515e:	12050e63          	beqz	a0,8000529a <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005162:	75f9                	lui	a1,0xffffe
    80005164:	95aa                	add	a1,a1,a0
    80005166:	855a                	mv	a0,s6
    80005168:	ffffc097          	auipc	ra,0xffffc
    8000516c:	4ce080e7          	jalr	1230(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    80005170:	7afd                	lui	s5,0xfffff
    80005172:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005174:	df043783          	ld	a5,-528(s0)
    80005178:	6388                	ld	a0,0(a5)
    8000517a:	c925                	beqz	a0,800051ea <exec+0x226>
    8000517c:	e9040993          	addi	s3,s0,-368
    80005180:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005184:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005186:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005188:	ffffc097          	auipc	ra,0xffffc
    8000518c:	cc6080e7          	jalr	-826(ra) # 80000e4e <strlen>
    80005190:	0015079b          	addiw	a5,a0,1
    80005194:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005198:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000519c:	13596663          	bltu	s2,s5,800052c8 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800051a0:	df043d83          	ld	s11,-528(s0)
    800051a4:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800051a8:	8552                	mv	a0,s4
    800051aa:	ffffc097          	auipc	ra,0xffffc
    800051ae:	ca4080e7          	jalr	-860(ra) # 80000e4e <strlen>
    800051b2:	0015069b          	addiw	a3,a0,1
    800051b6:	8652                	mv	a2,s4
    800051b8:	85ca                	mv	a1,s2
    800051ba:	855a                	mv	a0,s6
    800051bc:	ffffc097          	auipc	ra,0xffffc
    800051c0:	4ac080e7          	jalr	1196(ra) # 80001668 <copyout>
    800051c4:	10054663          	bltz	a0,800052d0 <exec+0x30c>
    ustack[argc] = sp;
    800051c8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800051cc:	0485                	addi	s1,s1,1
    800051ce:	008d8793          	addi	a5,s11,8
    800051d2:	def43823          	sd	a5,-528(s0)
    800051d6:	008db503          	ld	a0,8(s11)
    800051da:	c911                	beqz	a0,800051ee <exec+0x22a>
    if(argc >= MAXARG)
    800051dc:	09a1                	addi	s3,s3,8
    800051de:	fb3c95e3          	bne	s9,s3,80005188 <exec+0x1c4>
  sz = sz1;
    800051e2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800051e6:	4a81                	li	s5,0
    800051e8:	a84d                	j	8000529a <exec+0x2d6>
  sp = sz;
    800051ea:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800051ec:	4481                	li	s1,0
  ustack[argc] = 0;
    800051ee:	00349793          	slli	a5,s1,0x3
    800051f2:	f9040713          	addi	a4,s0,-112
    800051f6:	97ba                	add	a5,a5,a4
    800051f8:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffdc940>
  sp -= (argc+1) * sizeof(uint64);
    800051fc:	00148693          	addi	a3,s1,1
    80005200:	068e                	slli	a3,a3,0x3
    80005202:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005206:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000520a:	01597663          	bgeu	s2,s5,80005216 <exec+0x252>
  sz = sz1;
    8000520e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005212:	4a81                	li	s5,0
    80005214:	a059                	j	8000529a <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005216:	e9040613          	addi	a2,s0,-368
    8000521a:	85ca                	mv	a1,s2
    8000521c:	855a                	mv	a0,s6
    8000521e:	ffffc097          	auipc	ra,0xffffc
    80005222:	44a080e7          	jalr	1098(ra) # 80001668 <copyout>
    80005226:	0a054963          	bltz	a0,800052d8 <exec+0x314>
  p->trapframe->a1 = sp;
    8000522a:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    8000522e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005232:	de843783          	ld	a5,-536(s0)
    80005236:	0007c703          	lbu	a4,0(a5)
    8000523a:	cf11                	beqz	a4,80005256 <exec+0x292>
    8000523c:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000523e:	02f00693          	li	a3,47
    80005242:	a039                	j	80005250 <exec+0x28c>
      last = s+1;
    80005244:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005248:	0785                	addi	a5,a5,1
    8000524a:	fff7c703          	lbu	a4,-1(a5)
    8000524e:	c701                	beqz	a4,80005256 <exec+0x292>
    if(*s == '/')
    80005250:	fed71ce3          	bne	a4,a3,80005248 <exec+0x284>
    80005254:	bfc5                	j	80005244 <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80005256:	4641                	li	a2,16
    80005258:	de843583          	ld	a1,-536(s0)
    8000525c:	158b8513          	addi	a0,s7,344
    80005260:	ffffc097          	auipc	ra,0xffffc
    80005264:	bbc080e7          	jalr	-1092(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80005268:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    8000526c:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005270:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005274:	058bb783          	ld	a5,88(s7)
    80005278:	e6843703          	ld	a4,-408(s0)
    8000527c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000527e:	058bb783          	ld	a5,88(s7)
    80005282:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005286:	85ea                	mv	a1,s10
    80005288:	ffffd097          	auipc	ra,0xffffd
    8000528c:	884080e7          	jalr	-1916(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005290:	0004851b          	sext.w	a0,s1
    80005294:	b3f1                	j	80005060 <exec+0x9c>
    80005296:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    8000529a:	df843583          	ld	a1,-520(s0)
    8000529e:	855a                	mv	a0,s6
    800052a0:	ffffd097          	auipc	ra,0xffffd
    800052a4:	86c080e7          	jalr	-1940(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    800052a8:	da0a92e3          	bnez	s5,8000504c <exec+0x88>
  return -1;
    800052ac:	557d                	li	a0,-1
    800052ae:	bb4d                	j	80005060 <exec+0x9c>
    800052b0:	df243c23          	sd	s2,-520(s0)
    800052b4:	b7dd                	j	8000529a <exec+0x2d6>
    800052b6:	df243c23          	sd	s2,-520(s0)
    800052ba:	b7c5                	j	8000529a <exec+0x2d6>
    800052bc:	df243c23          	sd	s2,-520(s0)
    800052c0:	bfe9                	j	8000529a <exec+0x2d6>
    800052c2:	df243c23          	sd	s2,-520(s0)
    800052c6:	bfd1                	j	8000529a <exec+0x2d6>
  sz = sz1;
    800052c8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052cc:	4a81                	li	s5,0
    800052ce:	b7f1                	j	8000529a <exec+0x2d6>
  sz = sz1;
    800052d0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052d4:	4a81                	li	s5,0
    800052d6:	b7d1                	j	8000529a <exec+0x2d6>
  sz = sz1;
    800052d8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800052dc:	4a81                	li	s5,0
    800052de:	bf75                	j	8000529a <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800052e0:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052e4:	e0843783          	ld	a5,-504(s0)
    800052e8:	0017869b          	addiw	a3,a5,1
    800052ec:	e0d43423          	sd	a3,-504(s0)
    800052f0:	e0043783          	ld	a5,-512(s0)
    800052f4:	0387879b          	addiw	a5,a5,56
    800052f8:	e8845703          	lhu	a4,-376(s0)
    800052fc:	e0e6dee3          	bge	a3,a4,80005118 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005300:	2781                	sext.w	a5,a5
    80005302:	e0f43023          	sd	a5,-512(s0)
    80005306:	03800713          	li	a4,56
    8000530a:	86be                	mv	a3,a5
    8000530c:	e1840613          	addi	a2,s0,-488
    80005310:	4581                	li	a1,0
    80005312:	8556                	mv	a0,s5
    80005314:	fffff097          	auipc	ra,0xfffff
    80005318:	a5c080e7          	jalr	-1444(ra) # 80003d70 <readi>
    8000531c:	03800793          	li	a5,56
    80005320:	f6f51be3          	bne	a0,a5,80005296 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    80005324:	e1842783          	lw	a5,-488(s0)
    80005328:	4705                	li	a4,1
    8000532a:	fae79de3          	bne	a5,a4,800052e4 <exec+0x320>
    if(ph.memsz < ph.filesz)
    8000532e:	e4043483          	ld	s1,-448(s0)
    80005332:	e3843783          	ld	a5,-456(s0)
    80005336:	f6f4ede3          	bltu	s1,a5,800052b0 <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000533a:	e2843783          	ld	a5,-472(s0)
    8000533e:	94be                	add	s1,s1,a5
    80005340:	f6f4ebe3          	bltu	s1,a5,800052b6 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    80005344:	de043703          	ld	a4,-544(s0)
    80005348:	8ff9                	and	a5,a5,a4
    8000534a:	fbad                	bnez	a5,800052bc <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000534c:	e1c42503          	lw	a0,-484(s0)
    80005350:	00000097          	auipc	ra,0x0
    80005354:	c58080e7          	jalr	-936(ra) # 80004fa8 <flags2perm>
    80005358:	86aa                	mv	a3,a0
    8000535a:	8626                	mv	a2,s1
    8000535c:	85ca                	mv	a1,s2
    8000535e:	855a                	mv	a0,s6
    80005360:	ffffc097          	auipc	ra,0xffffc
    80005364:	0b0080e7          	jalr	176(ra) # 80001410 <uvmalloc>
    80005368:	dea43c23          	sd	a0,-520(s0)
    8000536c:	d939                	beqz	a0,800052c2 <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000536e:	e2843c03          	ld	s8,-472(s0)
    80005372:	e2042c83          	lw	s9,-480(s0)
    80005376:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000537a:	f60b83e3          	beqz	s7,800052e0 <exec+0x31c>
    8000537e:	89de                	mv	s3,s7
    80005380:	4481                	li	s1,0
    80005382:	bb95                	j	800050f6 <exec+0x132>

0000000080005384 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005384:	7179                	addi	sp,sp,-48
    80005386:	f406                	sd	ra,40(sp)
    80005388:	f022                	sd	s0,32(sp)
    8000538a:	ec26                	sd	s1,24(sp)
    8000538c:	e84a                	sd	s2,16(sp)
    8000538e:	1800                	addi	s0,sp,48
    80005390:	892e                	mv	s2,a1
    80005392:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005394:	fdc40593          	addi	a1,s0,-36
    80005398:	ffffe097          	auipc	ra,0xffffe
    8000539c:	aca080e7          	jalr	-1334(ra) # 80002e62 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800053a0:	fdc42703          	lw	a4,-36(s0)
    800053a4:	47bd                	li	a5,15
    800053a6:	02e7eb63          	bltu	a5,a4,800053dc <argfd+0x58>
    800053aa:	ffffc097          	auipc	ra,0xffffc
    800053ae:	602080e7          	jalr	1538(ra) # 800019ac <myproc>
    800053b2:	fdc42703          	lw	a4,-36(s0)
    800053b6:	01a70793          	addi	a5,a4,26
    800053ba:	078e                	slli	a5,a5,0x3
    800053bc:	953e                	add	a0,a0,a5
    800053be:	611c                	ld	a5,0(a0)
    800053c0:	c385                	beqz	a5,800053e0 <argfd+0x5c>
    return -1;
  if(pfd)
    800053c2:	00090463          	beqz	s2,800053ca <argfd+0x46>
    *pfd = fd;
    800053c6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800053ca:	4501                	li	a0,0
  if(pf)
    800053cc:	c091                	beqz	s1,800053d0 <argfd+0x4c>
    *pf = f;
    800053ce:	e09c                	sd	a5,0(s1)
}
    800053d0:	70a2                	ld	ra,40(sp)
    800053d2:	7402                	ld	s0,32(sp)
    800053d4:	64e2                	ld	s1,24(sp)
    800053d6:	6942                	ld	s2,16(sp)
    800053d8:	6145                	addi	sp,sp,48
    800053da:	8082                	ret
    return -1;
    800053dc:	557d                	li	a0,-1
    800053de:	bfcd                	j	800053d0 <argfd+0x4c>
    800053e0:	557d                	li	a0,-1
    800053e2:	b7fd                	j	800053d0 <argfd+0x4c>

00000000800053e4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800053e4:	1101                	addi	sp,sp,-32
    800053e6:	ec06                	sd	ra,24(sp)
    800053e8:	e822                	sd	s0,16(sp)
    800053ea:	e426                	sd	s1,8(sp)
    800053ec:	1000                	addi	s0,sp,32
    800053ee:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800053f0:	ffffc097          	auipc	ra,0xffffc
    800053f4:	5bc080e7          	jalr	1468(ra) # 800019ac <myproc>
    800053f8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800053fa:	0d050793          	addi	a5,a0,208
    800053fe:	4501                	li	a0,0
    80005400:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005402:	6398                	ld	a4,0(a5)
    80005404:	cb19                	beqz	a4,8000541a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005406:	2505                	addiw	a0,a0,1
    80005408:	07a1                	addi	a5,a5,8
    8000540a:	fed51ce3          	bne	a0,a3,80005402 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000540e:	557d                	li	a0,-1
}
    80005410:	60e2                	ld	ra,24(sp)
    80005412:	6442                	ld	s0,16(sp)
    80005414:	64a2                	ld	s1,8(sp)
    80005416:	6105                	addi	sp,sp,32
    80005418:	8082                	ret
      p->ofile[fd] = f;
    8000541a:	01a50793          	addi	a5,a0,26
    8000541e:	078e                	slli	a5,a5,0x3
    80005420:	963e                	add	a2,a2,a5
    80005422:	e204                	sd	s1,0(a2)
      return fd;
    80005424:	b7f5                	j	80005410 <fdalloc+0x2c>

0000000080005426 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005426:	715d                	addi	sp,sp,-80
    80005428:	e486                	sd	ra,72(sp)
    8000542a:	e0a2                	sd	s0,64(sp)
    8000542c:	fc26                	sd	s1,56(sp)
    8000542e:	f84a                	sd	s2,48(sp)
    80005430:	f44e                	sd	s3,40(sp)
    80005432:	f052                	sd	s4,32(sp)
    80005434:	ec56                	sd	s5,24(sp)
    80005436:	e85a                	sd	s6,16(sp)
    80005438:	0880                	addi	s0,sp,80
    8000543a:	8b2e                	mv	s6,a1
    8000543c:	89b2                	mv	s3,a2
    8000543e:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005440:	fb040593          	addi	a1,s0,-80
    80005444:	fffff097          	auipc	ra,0xfffff
    80005448:	e3c080e7          	jalr	-452(ra) # 80004280 <nameiparent>
    8000544c:	84aa                	mv	s1,a0
    8000544e:	14050f63          	beqz	a0,800055ac <create+0x186>
    return 0;

  ilock(dp);
    80005452:	ffffe097          	auipc	ra,0xffffe
    80005456:	66a080e7          	jalr	1642(ra) # 80003abc <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000545a:	4601                	li	a2,0
    8000545c:	fb040593          	addi	a1,s0,-80
    80005460:	8526                	mv	a0,s1
    80005462:	fffff097          	auipc	ra,0xfffff
    80005466:	b3e080e7          	jalr	-1218(ra) # 80003fa0 <dirlookup>
    8000546a:	8aaa                	mv	s5,a0
    8000546c:	c931                	beqz	a0,800054c0 <create+0x9a>
    iunlockput(dp);
    8000546e:	8526                	mv	a0,s1
    80005470:	fffff097          	auipc	ra,0xfffff
    80005474:	8ae080e7          	jalr	-1874(ra) # 80003d1e <iunlockput>
    ilock(ip);
    80005478:	8556                	mv	a0,s5
    8000547a:	ffffe097          	auipc	ra,0xffffe
    8000547e:	642080e7          	jalr	1602(ra) # 80003abc <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005482:	000b059b          	sext.w	a1,s6
    80005486:	4789                	li	a5,2
    80005488:	02f59563          	bne	a1,a5,800054b2 <create+0x8c>
    8000548c:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdca84>
    80005490:	37f9                	addiw	a5,a5,-2
    80005492:	17c2                	slli	a5,a5,0x30
    80005494:	93c1                	srli	a5,a5,0x30
    80005496:	4705                	li	a4,1
    80005498:	00f76d63          	bltu	a4,a5,800054b2 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000549c:	8556                	mv	a0,s5
    8000549e:	60a6                	ld	ra,72(sp)
    800054a0:	6406                	ld	s0,64(sp)
    800054a2:	74e2                	ld	s1,56(sp)
    800054a4:	7942                	ld	s2,48(sp)
    800054a6:	79a2                	ld	s3,40(sp)
    800054a8:	7a02                	ld	s4,32(sp)
    800054aa:	6ae2                	ld	s5,24(sp)
    800054ac:	6b42                	ld	s6,16(sp)
    800054ae:	6161                	addi	sp,sp,80
    800054b0:	8082                	ret
    iunlockput(ip);
    800054b2:	8556                	mv	a0,s5
    800054b4:	fffff097          	auipc	ra,0xfffff
    800054b8:	86a080e7          	jalr	-1942(ra) # 80003d1e <iunlockput>
    return 0;
    800054bc:	4a81                	li	s5,0
    800054be:	bff9                	j	8000549c <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800054c0:	85da                	mv	a1,s6
    800054c2:	4088                	lw	a0,0(s1)
    800054c4:	ffffe097          	auipc	ra,0xffffe
    800054c8:	45c080e7          	jalr	1116(ra) # 80003920 <ialloc>
    800054cc:	8a2a                	mv	s4,a0
    800054ce:	c539                	beqz	a0,8000551c <create+0xf6>
  ilock(ip);
    800054d0:	ffffe097          	auipc	ra,0xffffe
    800054d4:	5ec080e7          	jalr	1516(ra) # 80003abc <ilock>
  ip->major = major;
    800054d8:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800054dc:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800054e0:	4905                	li	s2,1
    800054e2:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800054e6:	8552                	mv	a0,s4
    800054e8:	ffffe097          	auipc	ra,0xffffe
    800054ec:	50a080e7          	jalr	1290(ra) # 800039f2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800054f0:	000b059b          	sext.w	a1,s6
    800054f4:	03258b63          	beq	a1,s2,8000552a <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800054f8:	004a2603          	lw	a2,4(s4)
    800054fc:	fb040593          	addi	a1,s0,-80
    80005500:	8526                	mv	a0,s1
    80005502:	fffff097          	auipc	ra,0xfffff
    80005506:	cae080e7          	jalr	-850(ra) # 800041b0 <dirlink>
    8000550a:	06054f63          	bltz	a0,80005588 <create+0x162>
  iunlockput(dp);
    8000550e:	8526                	mv	a0,s1
    80005510:	fffff097          	auipc	ra,0xfffff
    80005514:	80e080e7          	jalr	-2034(ra) # 80003d1e <iunlockput>
  return ip;
    80005518:	8ad2                	mv	s5,s4
    8000551a:	b749                	j	8000549c <create+0x76>
    iunlockput(dp);
    8000551c:	8526                	mv	a0,s1
    8000551e:	fffff097          	auipc	ra,0xfffff
    80005522:	800080e7          	jalr	-2048(ra) # 80003d1e <iunlockput>
    return 0;
    80005526:	8ad2                	mv	s5,s4
    80005528:	bf95                	j	8000549c <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000552a:	004a2603          	lw	a2,4(s4)
    8000552e:	00003597          	auipc	a1,0x3
    80005532:	22258593          	addi	a1,a1,546 # 80008750 <syscalls+0x2b8>
    80005536:	8552                	mv	a0,s4
    80005538:	fffff097          	auipc	ra,0xfffff
    8000553c:	c78080e7          	jalr	-904(ra) # 800041b0 <dirlink>
    80005540:	04054463          	bltz	a0,80005588 <create+0x162>
    80005544:	40d0                	lw	a2,4(s1)
    80005546:	00003597          	auipc	a1,0x3
    8000554a:	21258593          	addi	a1,a1,530 # 80008758 <syscalls+0x2c0>
    8000554e:	8552                	mv	a0,s4
    80005550:	fffff097          	auipc	ra,0xfffff
    80005554:	c60080e7          	jalr	-928(ra) # 800041b0 <dirlink>
    80005558:	02054863          	bltz	a0,80005588 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    8000555c:	004a2603          	lw	a2,4(s4)
    80005560:	fb040593          	addi	a1,s0,-80
    80005564:	8526                	mv	a0,s1
    80005566:	fffff097          	auipc	ra,0xfffff
    8000556a:	c4a080e7          	jalr	-950(ra) # 800041b0 <dirlink>
    8000556e:	00054d63          	bltz	a0,80005588 <create+0x162>
    dp->nlink++;  // for ".."
    80005572:	04a4d783          	lhu	a5,74(s1)
    80005576:	2785                	addiw	a5,a5,1
    80005578:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000557c:	8526                	mv	a0,s1
    8000557e:	ffffe097          	auipc	ra,0xffffe
    80005582:	474080e7          	jalr	1140(ra) # 800039f2 <iupdate>
    80005586:	b761                	j	8000550e <create+0xe8>
  ip->nlink = 0;
    80005588:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000558c:	8552                	mv	a0,s4
    8000558e:	ffffe097          	auipc	ra,0xffffe
    80005592:	464080e7          	jalr	1124(ra) # 800039f2 <iupdate>
  iunlockput(ip);
    80005596:	8552                	mv	a0,s4
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	786080e7          	jalr	1926(ra) # 80003d1e <iunlockput>
  iunlockput(dp);
    800055a0:	8526                	mv	a0,s1
    800055a2:	ffffe097          	auipc	ra,0xffffe
    800055a6:	77c080e7          	jalr	1916(ra) # 80003d1e <iunlockput>
  return 0;
    800055aa:	bdcd                	j	8000549c <create+0x76>
    return 0;
    800055ac:	8aaa                	mv	s5,a0
    800055ae:	b5fd                	j	8000549c <create+0x76>

00000000800055b0 <sys_dup>:
{
    800055b0:	7179                	addi	sp,sp,-48
    800055b2:	f406                	sd	ra,40(sp)
    800055b4:	f022                	sd	s0,32(sp)
    800055b6:	ec26                	sd	s1,24(sp)
    800055b8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800055ba:	fd840613          	addi	a2,s0,-40
    800055be:	4581                	li	a1,0
    800055c0:	4501                	li	a0,0
    800055c2:	00000097          	auipc	ra,0x0
    800055c6:	dc2080e7          	jalr	-574(ra) # 80005384 <argfd>
    return -1;
    800055ca:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800055cc:	02054363          	bltz	a0,800055f2 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800055d0:	fd843503          	ld	a0,-40(s0)
    800055d4:	00000097          	auipc	ra,0x0
    800055d8:	e10080e7          	jalr	-496(ra) # 800053e4 <fdalloc>
    800055dc:	84aa                	mv	s1,a0
    return -1;
    800055de:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800055e0:	00054963          	bltz	a0,800055f2 <sys_dup+0x42>
  filedup(f);
    800055e4:	fd843503          	ld	a0,-40(s0)
    800055e8:	fffff097          	auipc	ra,0xfffff
    800055ec:	310080e7          	jalr	784(ra) # 800048f8 <filedup>
  return fd;
    800055f0:	87a6                	mv	a5,s1
}
    800055f2:	853e                	mv	a0,a5
    800055f4:	70a2                	ld	ra,40(sp)
    800055f6:	7402                	ld	s0,32(sp)
    800055f8:	64e2                	ld	s1,24(sp)
    800055fa:	6145                	addi	sp,sp,48
    800055fc:	8082                	ret

00000000800055fe <sys_read>:
{
    800055fe:	7179                	addi	sp,sp,-48
    80005600:	f406                	sd	ra,40(sp)
    80005602:	f022                	sd	s0,32(sp)
    80005604:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005606:	fd840593          	addi	a1,s0,-40
    8000560a:	4505                	li	a0,1
    8000560c:	ffffe097          	auipc	ra,0xffffe
    80005610:	876080e7          	jalr	-1930(ra) # 80002e82 <argaddr>
  argint(2, &n);
    80005614:	fe440593          	addi	a1,s0,-28
    80005618:	4509                	li	a0,2
    8000561a:	ffffe097          	auipc	ra,0xffffe
    8000561e:	848080e7          	jalr	-1976(ra) # 80002e62 <argint>
  if(argfd(0, 0, &f) < 0)
    80005622:	fe840613          	addi	a2,s0,-24
    80005626:	4581                	li	a1,0
    80005628:	4501                	li	a0,0
    8000562a:	00000097          	auipc	ra,0x0
    8000562e:	d5a080e7          	jalr	-678(ra) # 80005384 <argfd>
    80005632:	87aa                	mv	a5,a0
    return -1;
    80005634:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005636:	0007cc63          	bltz	a5,8000564e <sys_read+0x50>
  return fileread(f, p, n);
    8000563a:	fe442603          	lw	a2,-28(s0)
    8000563e:	fd843583          	ld	a1,-40(s0)
    80005642:	fe843503          	ld	a0,-24(s0)
    80005646:	fffff097          	auipc	ra,0xfffff
    8000564a:	43e080e7          	jalr	1086(ra) # 80004a84 <fileread>
}
    8000564e:	70a2                	ld	ra,40(sp)
    80005650:	7402                	ld	s0,32(sp)
    80005652:	6145                	addi	sp,sp,48
    80005654:	8082                	ret

0000000080005656 <sys_write>:
{
    80005656:	7179                	addi	sp,sp,-48
    80005658:	f406                	sd	ra,40(sp)
    8000565a:	f022                	sd	s0,32(sp)
    8000565c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000565e:	fd840593          	addi	a1,s0,-40
    80005662:	4505                	li	a0,1
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	81e080e7          	jalr	-2018(ra) # 80002e82 <argaddr>
  argint(2, &n);
    8000566c:	fe440593          	addi	a1,s0,-28
    80005670:	4509                	li	a0,2
    80005672:	ffffd097          	auipc	ra,0xffffd
    80005676:	7f0080e7          	jalr	2032(ra) # 80002e62 <argint>
  if(argfd(0, 0, &f) < 0)
    8000567a:	fe840613          	addi	a2,s0,-24
    8000567e:	4581                	li	a1,0
    80005680:	4501                	li	a0,0
    80005682:	00000097          	auipc	ra,0x0
    80005686:	d02080e7          	jalr	-766(ra) # 80005384 <argfd>
    8000568a:	87aa                	mv	a5,a0
    return -1;
    8000568c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000568e:	0007cc63          	bltz	a5,800056a6 <sys_write+0x50>
  return filewrite(f, p, n);
    80005692:	fe442603          	lw	a2,-28(s0)
    80005696:	fd843583          	ld	a1,-40(s0)
    8000569a:	fe843503          	ld	a0,-24(s0)
    8000569e:	fffff097          	auipc	ra,0xfffff
    800056a2:	4a8080e7          	jalr	1192(ra) # 80004b46 <filewrite>
}
    800056a6:	70a2                	ld	ra,40(sp)
    800056a8:	7402                	ld	s0,32(sp)
    800056aa:	6145                	addi	sp,sp,48
    800056ac:	8082                	ret

00000000800056ae <sys_close>:
{
    800056ae:	1101                	addi	sp,sp,-32
    800056b0:	ec06                	sd	ra,24(sp)
    800056b2:	e822                	sd	s0,16(sp)
    800056b4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800056b6:	fe040613          	addi	a2,s0,-32
    800056ba:	fec40593          	addi	a1,s0,-20
    800056be:	4501                	li	a0,0
    800056c0:	00000097          	auipc	ra,0x0
    800056c4:	cc4080e7          	jalr	-828(ra) # 80005384 <argfd>
    return -1;
    800056c8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800056ca:	02054463          	bltz	a0,800056f2 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800056ce:	ffffc097          	auipc	ra,0xffffc
    800056d2:	2de080e7          	jalr	734(ra) # 800019ac <myproc>
    800056d6:	fec42783          	lw	a5,-20(s0)
    800056da:	07e9                	addi	a5,a5,26
    800056dc:	078e                	slli	a5,a5,0x3
    800056de:	97aa                	add	a5,a5,a0
    800056e0:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800056e4:	fe043503          	ld	a0,-32(s0)
    800056e8:	fffff097          	auipc	ra,0xfffff
    800056ec:	262080e7          	jalr	610(ra) # 8000494a <fileclose>
  return 0;
    800056f0:	4781                	li	a5,0
}
    800056f2:	853e                	mv	a0,a5
    800056f4:	60e2                	ld	ra,24(sp)
    800056f6:	6442                	ld	s0,16(sp)
    800056f8:	6105                	addi	sp,sp,32
    800056fa:	8082                	ret

00000000800056fc <sys_fstat>:
{
    800056fc:	1101                	addi	sp,sp,-32
    800056fe:	ec06                	sd	ra,24(sp)
    80005700:	e822                	sd	s0,16(sp)
    80005702:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005704:	fe040593          	addi	a1,s0,-32
    80005708:	4505                	li	a0,1
    8000570a:	ffffd097          	auipc	ra,0xffffd
    8000570e:	778080e7          	jalr	1912(ra) # 80002e82 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005712:	fe840613          	addi	a2,s0,-24
    80005716:	4581                	li	a1,0
    80005718:	4501                	li	a0,0
    8000571a:	00000097          	auipc	ra,0x0
    8000571e:	c6a080e7          	jalr	-918(ra) # 80005384 <argfd>
    80005722:	87aa                	mv	a5,a0
    return -1;
    80005724:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005726:	0007ca63          	bltz	a5,8000573a <sys_fstat+0x3e>
  return filestat(f, st);
    8000572a:	fe043583          	ld	a1,-32(s0)
    8000572e:	fe843503          	ld	a0,-24(s0)
    80005732:	fffff097          	auipc	ra,0xfffff
    80005736:	2e0080e7          	jalr	736(ra) # 80004a12 <filestat>
}
    8000573a:	60e2                	ld	ra,24(sp)
    8000573c:	6442                	ld	s0,16(sp)
    8000573e:	6105                	addi	sp,sp,32
    80005740:	8082                	ret

0000000080005742 <sys_link>:
{
    80005742:	7169                	addi	sp,sp,-304
    80005744:	f606                	sd	ra,296(sp)
    80005746:	f222                	sd	s0,288(sp)
    80005748:	ee26                	sd	s1,280(sp)
    8000574a:	ea4a                	sd	s2,272(sp)
    8000574c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000574e:	08000613          	li	a2,128
    80005752:	ed040593          	addi	a1,s0,-304
    80005756:	4501                	li	a0,0
    80005758:	ffffd097          	auipc	ra,0xffffd
    8000575c:	74a080e7          	jalr	1866(ra) # 80002ea2 <argstr>
    return -1;
    80005760:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005762:	10054e63          	bltz	a0,8000587e <sys_link+0x13c>
    80005766:	08000613          	li	a2,128
    8000576a:	f5040593          	addi	a1,s0,-176
    8000576e:	4505                	li	a0,1
    80005770:	ffffd097          	auipc	ra,0xffffd
    80005774:	732080e7          	jalr	1842(ra) # 80002ea2 <argstr>
    return -1;
    80005778:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000577a:	10054263          	bltz	a0,8000587e <sys_link+0x13c>
  begin_op();
    8000577e:	fffff097          	auipc	ra,0xfffff
    80005782:	d00080e7          	jalr	-768(ra) # 8000447e <begin_op>
  if((ip = namei(old)) == 0){
    80005786:	ed040513          	addi	a0,s0,-304
    8000578a:	fffff097          	auipc	ra,0xfffff
    8000578e:	ad8080e7          	jalr	-1320(ra) # 80004262 <namei>
    80005792:	84aa                	mv	s1,a0
    80005794:	c551                	beqz	a0,80005820 <sys_link+0xde>
  ilock(ip);
    80005796:	ffffe097          	auipc	ra,0xffffe
    8000579a:	326080e7          	jalr	806(ra) # 80003abc <ilock>
  if(ip->type == T_DIR){
    8000579e:	04449703          	lh	a4,68(s1)
    800057a2:	4785                	li	a5,1
    800057a4:	08f70463          	beq	a4,a5,8000582c <sys_link+0xea>
  ip->nlink++;
    800057a8:	04a4d783          	lhu	a5,74(s1)
    800057ac:	2785                	addiw	a5,a5,1
    800057ae:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057b2:	8526                	mv	a0,s1
    800057b4:	ffffe097          	auipc	ra,0xffffe
    800057b8:	23e080e7          	jalr	574(ra) # 800039f2 <iupdate>
  iunlock(ip);
    800057bc:	8526                	mv	a0,s1
    800057be:	ffffe097          	auipc	ra,0xffffe
    800057c2:	3c0080e7          	jalr	960(ra) # 80003b7e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800057c6:	fd040593          	addi	a1,s0,-48
    800057ca:	f5040513          	addi	a0,s0,-176
    800057ce:	fffff097          	auipc	ra,0xfffff
    800057d2:	ab2080e7          	jalr	-1358(ra) # 80004280 <nameiparent>
    800057d6:	892a                	mv	s2,a0
    800057d8:	c935                	beqz	a0,8000584c <sys_link+0x10a>
  ilock(dp);
    800057da:	ffffe097          	auipc	ra,0xffffe
    800057de:	2e2080e7          	jalr	738(ra) # 80003abc <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800057e2:	00092703          	lw	a4,0(s2)
    800057e6:	409c                	lw	a5,0(s1)
    800057e8:	04f71d63          	bne	a4,a5,80005842 <sys_link+0x100>
    800057ec:	40d0                	lw	a2,4(s1)
    800057ee:	fd040593          	addi	a1,s0,-48
    800057f2:	854a                	mv	a0,s2
    800057f4:	fffff097          	auipc	ra,0xfffff
    800057f8:	9bc080e7          	jalr	-1604(ra) # 800041b0 <dirlink>
    800057fc:	04054363          	bltz	a0,80005842 <sys_link+0x100>
  iunlockput(dp);
    80005800:	854a                	mv	a0,s2
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	51c080e7          	jalr	1308(ra) # 80003d1e <iunlockput>
  iput(ip);
    8000580a:	8526                	mv	a0,s1
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	46a080e7          	jalr	1130(ra) # 80003c76 <iput>
  end_op();
    80005814:	fffff097          	auipc	ra,0xfffff
    80005818:	cea080e7          	jalr	-790(ra) # 800044fe <end_op>
  return 0;
    8000581c:	4781                	li	a5,0
    8000581e:	a085                	j	8000587e <sys_link+0x13c>
    end_op();
    80005820:	fffff097          	auipc	ra,0xfffff
    80005824:	cde080e7          	jalr	-802(ra) # 800044fe <end_op>
    return -1;
    80005828:	57fd                	li	a5,-1
    8000582a:	a891                	j	8000587e <sys_link+0x13c>
    iunlockput(ip);
    8000582c:	8526                	mv	a0,s1
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	4f0080e7          	jalr	1264(ra) # 80003d1e <iunlockput>
    end_op();
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	cc8080e7          	jalr	-824(ra) # 800044fe <end_op>
    return -1;
    8000583e:	57fd                	li	a5,-1
    80005840:	a83d                	j	8000587e <sys_link+0x13c>
    iunlockput(dp);
    80005842:	854a                	mv	a0,s2
    80005844:	ffffe097          	auipc	ra,0xffffe
    80005848:	4da080e7          	jalr	1242(ra) # 80003d1e <iunlockput>
  ilock(ip);
    8000584c:	8526                	mv	a0,s1
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	26e080e7          	jalr	622(ra) # 80003abc <ilock>
  ip->nlink--;
    80005856:	04a4d783          	lhu	a5,74(s1)
    8000585a:	37fd                	addiw	a5,a5,-1
    8000585c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005860:	8526                	mv	a0,s1
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	190080e7          	jalr	400(ra) # 800039f2 <iupdate>
  iunlockput(ip);
    8000586a:	8526                	mv	a0,s1
    8000586c:	ffffe097          	auipc	ra,0xffffe
    80005870:	4b2080e7          	jalr	1202(ra) # 80003d1e <iunlockput>
  end_op();
    80005874:	fffff097          	auipc	ra,0xfffff
    80005878:	c8a080e7          	jalr	-886(ra) # 800044fe <end_op>
  return -1;
    8000587c:	57fd                	li	a5,-1
}
    8000587e:	853e                	mv	a0,a5
    80005880:	70b2                	ld	ra,296(sp)
    80005882:	7412                	ld	s0,288(sp)
    80005884:	64f2                	ld	s1,280(sp)
    80005886:	6952                	ld	s2,272(sp)
    80005888:	6155                	addi	sp,sp,304
    8000588a:	8082                	ret

000000008000588c <sys_unlink>:
{
    8000588c:	7151                	addi	sp,sp,-240
    8000588e:	f586                	sd	ra,232(sp)
    80005890:	f1a2                	sd	s0,224(sp)
    80005892:	eda6                	sd	s1,216(sp)
    80005894:	e9ca                	sd	s2,208(sp)
    80005896:	e5ce                	sd	s3,200(sp)
    80005898:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000589a:	08000613          	li	a2,128
    8000589e:	f3040593          	addi	a1,s0,-208
    800058a2:	4501                	li	a0,0
    800058a4:	ffffd097          	auipc	ra,0xffffd
    800058a8:	5fe080e7          	jalr	1534(ra) # 80002ea2 <argstr>
    800058ac:	18054163          	bltz	a0,80005a2e <sys_unlink+0x1a2>
  begin_op();
    800058b0:	fffff097          	auipc	ra,0xfffff
    800058b4:	bce080e7          	jalr	-1074(ra) # 8000447e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800058b8:	fb040593          	addi	a1,s0,-80
    800058bc:	f3040513          	addi	a0,s0,-208
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	9c0080e7          	jalr	-1600(ra) # 80004280 <nameiparent>
    800058c8:	84aa                	mv	s1,a0
    800058ca:	c979                	beqz	a0,800059a0 <sys_unlink+0x114>
  ilock(dp);
    800058cc:	ffffe097          	auipc	ra,0xffffe
    800058d0:	1f0080e7          	jalr	496(ra) # 80003abc <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800058d4:	00003597          	auipc	a1,0x3
    800058d8:	e7c58593          	addi	a1,a1,-388 # 80008750 <syscalls+0x2b8>
    800058dc:	fb040513          	addi	a0,s0,-80
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	6a6080e7          	jalr	1702(ra) # 80003f86 <namecmp>
    800058e8:	14050a63          	beqz	a0,80005a3c <sys_unlink+0x1b0>
    800058ec:	00003597          	auipc	a1,0x3
    800058f0:	e6c58593          	addi	a1,a1,-404 # 80008758 <syscalls+0x2c0>
    800058f4:	fb040513          	addi	a0,s0,-80
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	68e080e7          	jalr	1678(ra) # 80003f86 <namecmp>
    80005900:	12050e63          	beqz	a0,80005a3c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005904:	f2c40613          	addi	a2,s0,-212
    80005908:	fb040593          	addi	a1,s0,-80
    8000590c:	8526                	mv	a0,s1
    8000590e:	ffffe097          	auipc	ra,0xffffe
    80005912:	692080e7          	jalr	1682(ra) # 80003fa0 <dirlookup>
    80005916:	892a                	mv	s2,a0
    80005918:	12050263          	beqz	a0,80005a3c <sys_unlink+0x1b0>
  ilock(ip);
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	1a0080e7          	jalr	416(ra) # 80003abc <ilock>
  if(ip->nlink < 1)
    80005924:	04a91783          	lh	a5,74(s2)
    80005928:	08f05263          	blez	a5,800059ac <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000592c:	04491703          	lh	a4,68(s2)
    80005930:	4785                	li	a5,1
    80005932:	08f70563          	beq	a4,a5,800059bc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005936:	4641                	li	a2,16
    80005938:	4581                	li	a1,0
    8000593a:	fc040513          	addi	a0,s0,-64
    8000593e:	ffffb097          	auipc	ra,0xffffb
    80005942:	394080e7          	jalr	916(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005946:	4741                	li	a4,16
    80005948:	f2c42683          	lw	a3,-212(s0)
    8000594c:	fc040613          	addi	a2,s0,-64
    80005950:	4581                	li	a1,0
    80005952:	8526                	mv	a0,s1
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	514080e7          	jalr	1300(ra) # 80003e68 <writei>
    8000595c:	47c1                	li	a5,16
    8000595e:	0af51563          	bne	a0,a5,80005a08 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005962:	04491703          	lh	a4,68(s2)
    80005966:	4785                	li	a5,1
    80005968:	0af70863          	beq	a4,a5,80005a18 <sys_unlink+0x18c>
  iunlockput(dp);
    8000596c:	8526                	mv	a0,s1
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	3b0080e7          	jalr	944(ra) # 80003d1e <iunlockput>
  ip->nlink--;
    80005976:	04a95783          	lhu	a5,74(s2)
    8000597a:	37fd                	addiw	a5,a5,-1
    8000597c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005980:	854a                	mv	a0,s2
    80005982:	ffffe097          	auipc	ra,0xffffe
    80005986:	070080e7          	jalr	112(ra) # 800039f2 <iupdate>
  iunlockput(ip);
    8000598a:	854a                	mv	a0,s2
    8000598c:	ffffe097          	auipc	ra,0xffffe
    80005990:	392080e7          	jalr	914(ra) # 80003d1e <iunlockput>
  end_op();
    80005994:	fffff097          	auipc	ra,0xfffff
    80005998:	b6a080e7          	jalr	-1174(ra) # 800044fe <end_op>
  return 0;
    8000599c:	4501                	li	a0,0
    8000599e:	a84d                	j	80005a50 <sys_unlink+0x1c4>
    end_op();
    800059a0:	fffff097          	auipc	ra,0xfffff
    800059a4:	b5e080e7          	jalr	-1186(ra) # 800044fe <end_op>
    return -1;
    800059a8:	557d                	li	a0,-1
    800059aa:	a05d                	j	80005a50 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800059ac:	00003517          	auipc	a0,0x3
    800059b0:	db450513          	addi	a0,a0,-588 # 80008760 <syscalls+0x2c8>
    800059b4:	ffffb097          	auipc	ra,0xffffb
    800059b8:	b8a080e7          	jalr	-1142(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059bc:	04c92703          	lw	a4,76(s2)
    800059c0:	02000793          	li	a5,32
    800059c4:	f6e7f9e3          	bgeu	a5,a4,80005936 <sys_unlink+0xaa>
    800059c8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059cc:	4741                	li	a4,16
    800059ce:	86ce                	mv	a3,s3
    800059d0:	f1840613          	addi	a2,s0,-232
    800059d4:	4581                	li	a1,0
    800059d6:	854a                	mv	a0,s2
    800059d8:	ffffe097          	auipc	ra,0xffffe
    800059dc:	398080e7          	jalr	920(ra) # 80003d70 <readi>
    800059e0:	47c1                	li	a5,16
    800059e2:	00f51b63          	bne	a0,a5,800059f8 <sys_unlink+0x16c>
    if(de.inum != 0)
    800059e6:	f1845783          	lhu	a5,-232(s0)
    800059ea:	e7a1                	bnez	a5,80005a32 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800059ec:	29c1                	addiw	s3,s3,16
    800059ee:	04c92783          	lw	a5,76(s2)
    800059f2:	fcf9ede3          	bltu	s3,a5,800059cc <sys_unlink+0x140>
    800059f6:	b781                	j	80005936 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800059f8:	00003517          	auipc	a0,0x3
    800059fc:	d8050513          	addi	a0,a0,-640 # 80008778 <syscalls+0x2e0>
    80005a00:	ffffb097          	auipc	ra,0xffffb
    80005a04:	b3e080e7          	jalr	-1218(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005a08:	00003517          	auipc	a0,0x3
    80005a0c:	d8850513          	addi	a0,a0,-632 # 80008790 <syscalls+0x2f8>
    80005a10:	ffffb097          	auipc	ra,0xffffb
    80005a14:	b2e080e7          	jalr	-1234(ra) # 8000053e <panic>
    dp->nlink--;
    80005a18:	04a4d783          	lhu	a5,74(s1)
    80005a1c:	37fd                	addiw	a5,a5,-1
    80005a1e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a22:	8526                	mv	a0,s1
    80005a24:	ffffe097          	auipc	ra,0xffffe
    80005a28:	fce080e7          	jalr	-50(ra) # 800039f2 <iupdate>
    80005a2c:	b781                	j	8000596c <sys_unlink+0xe0>
    return -1;
    80005a2e:	557d                	li	a0,-1
    80005a30:	a005                	j	80005a50 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a32:	854a                	mv	a0,s2
    80005a34:	ffffe097          	auipc	ra,0xffffe
    80005a38:	2ea080e7          	jalr	746(ra) # 80003d1e <iunlockput>
  iunlockput(dp);
    80005a3c:	8526                	mv	a0,s1
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	2e0080e7          	jalr	736(ra) # 80003d1e <iunlockput>
  end_op();
    80005a46:	fffff097          	auipc	ra,0xfffff
    80005a4a:	ab8080e7          	jalr	-1352(ra) # 800044fe <end_op>
  return -1;
    80005a4e:	557d                	li	a0,-1
}
    80005a50:	70ae                	ld	ra,232(sp)
    80005a52:	740e                	ld	s0,224(sp)
    80005a54:	64ee                	ld	s1,216(sp)
    80005a56:	694e                	ld	s2,208(sp)
    80005a58:	69ae                	ld	s3,200(sp)
    80005a5a:	616d                	addi	sp,sp,240
    80005a5c:	8082                	ret

0000000080005a5e <sys_open>:

uint64
sys_open(void)
{
    80005a5e:	7131                	addi	sp,sp,-192
    80005a60:	fd06                	sd	ra,184(sp)
    80005a62:	f922                	sd	s0,176(sp)
    80005a64:	f526                	sd	s1,168(sp)
    80005a66:	f14a                	sd	s2,160(sp)
    80005a68:	ed4e                	sd	s3,152(sp)
    80005a6a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005a6c:	f4c40593          	addi	a1,s0,-180
    80005a70:	4505                	li	a0,1
    80005a72:	ffffd097          	auipc	ra,0xffffd
    80005a76:	3f0080e7          	jalr	1008(ra) # 80002e62 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005a7a:	08000613          	li	a2,128
    80005a7e:	f5040593          	addi	a1,s0,-176
    80005a82:	4501                	li	a0,0
    80005a84:	ffffd097          	auipc	ra,0xffffd
    80005a88:	41e080e7          	jalr	1054(ra) # 80002ea2 <argstr>
    80005a8c:	87aa                	mv	a5,a0
    return -1;
    80005a8e:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005a90:	0a07c963          	bltz	a5,80005b42 <sys_open+0xe4>

  begin_op();
    80005a94:	fffff097          	auipc	ra,0xfffff
    80005a98:	9ea080e7          	jalr	-1558(ra) # 8000447e <begin_op>

  if(omode & O_CREATE){
    80005a9c:	f4c42783          	lw	a5,-180(s0)
    80005aa0:	2007f793          	andi	a5,a5,512
    80005aa4:	cfc5                	beqz	a5,80005b5c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005aa6:	4681                	li	a3,0
    80005aa8:	4601                	li	a2,0
    80005aaa:	4589                	li	a1,2
    80005aac:	f5040513          	addi	a0,s0,-176
    80005ab0:	00000097          	auipc	ra,0x0
    80005ab4:	976080e7          	jalr	-1674(ra) # 80005426 <create>
    80005ab8:	84aa                	mv	s1,a0
    if(ip == 0){
    80005aba:	c959                	beqz	a0,80005b50 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005abc:	04449703          	lh	a4,68(s1)
    80005ac0:	478d                	li	a5,3
    80005ac2:	00f71763          	bne	a4,a5,80005ad0 <sys_open+0x72>
    80005ac6:	0464d703          	lhu	a4,70(s1)
    80005aca:	47a5                	li	a5,9
    80005acc:	0ce7ed63          	bltu	a5,a4,80005ba6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005ad0:	fffff097          	auipc	ra,0xfffff
    80005ad4:	dbe080e7          	jalr	-578(ra) # 8000488e <filealloc>
    80005ad8:	89aa                	mv	s3,a0
    80005ada:	10050363          	beqz	a0,80005be0 <sys_open+0x182>
    80005ade:	00000097          	auipc	ra,0x0
    80005ae2:	906080e7          	jalr	-1786(ra) # 800053e4 <fdalloc>
    80005ae6:	892a                	mv	s2,a0
    80005ae8:	0e054763          	bltz	a0,80005bd6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005aec:	04449703          	lh	a4,68(s1)
    80005af0:	478d                	li	a5,3
    80005af2:	0cf70563          	beq	a4,a5,80005bbc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005af6:	4789                	li	a5,2
    80005af8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005afc:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b00:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b04:	f4c42783          	lw	a5,-180(s0)
    80005b08:	0017c713          	xori	a4,a5,1
    80005b0c:	8b05                	andi	a4,a4,1
    80005b0e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b12:	0037f713          	andi	a4,a5,3
    80005b16:	00e03733          	snez	a4,a4
    80005b1a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b1e:	4007f793          	andi	a5,a5,1024
    80005b22:	c791                	beqz	a5,80005b2e <sys_open+0xd0>
    80005b24:	04449703          	lh	a4,68(s1)
    80005b28:	4789                	li	a5,2
    80005b2a:	0af70063          	beq	a4,a5,80005bca <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b2e:	8526                	mv	a0,s1
    80005b30:	ffffe097          	auipc	ra,0xffffe
    80005b34:	04e080e7          	jalr	78(ra) # 80003b7e <iunlock>
  end_op();
    80005b38:	fffff097          	auipc	ra,0xfffff
    80005b3c:	9c6080e7          	jalr	-1594(ra) # 800044fe <end_op>

  return fd;
    80005b40:	854a                	mv	a0,s2
}
    80005b42:	70ea                	ld	ra,184(sp)
    80005b44:	744a                	ld	s0,176(sp)
    80005b46:	74aa                	ld	s1,168(sp)
    80005b48:	790a                	ld	s2,160(sp)
    80005b4a:	69ea                	ld	s3,152(sp)
    80005b4c:	6129                	addi	sp,sp,192
    80005b4e:	8082                	ret
      end_op();
    80005b50:	fffff097          	auipc	ra,0xfffff
    80005b54:	9ae080e7          	jalr	-1618(ra) # 800044fe <end_op>
      return -1;
    80005b58:	557d                	li	a0,-1
    80005b5a:	b7e5                	j	80005b42 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005b5c:	f5040513          	addi	a0,s0,-176
    80005b60:	ffffe097          	auipc	ra,0xffffe
    80005b64:	702080e7          	jalr	1794(ra) # 80004262 <namei>
    80005b68:	84aa                	mv	s1,a0
    80005b6a:	c905                	beqz	a0,80005b9a <sys_open+0x13c>
    ilock(ip);
    80005b6c:	ffffe097          	auipc	ra,0xffffe
    80005b70:	f50080e7          	jalr	-176(ra) # 80003abc <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005b74:	04449703          	lh	a4,68(s1)
    80005b78:	4785                	li	a5,1
    80005b7a:	f4f711e3          	bne	a4,a5,80005abc <sys_open+0x5e>
    80005b7e:	f4c42783          	lw	a5,-180(s0)
    80005b82:	d7b9                	beqz	a5,80005ad0 <sys_open+0x72>
      iunlockput(ip);
    80005b84:	8526                	mv	a0,s1
    80005b86:	ffffe097          	auipc	ra,0xffffe
    80005b8a:	198080e7          	jalr	408(ra) # 80003d1e <iunlockput>
      end_op();
    80005b8e:	fffff097          	auipc	ra,0xfffff
    80005b92:	970080e7          	jalr	-1680(ra) # 800044fe <end_op>
      return -1;
    80005b96:	557d                	li	a0,-1
    80005b98:	b76d                	j	80005b42 <sys_open+0xe4>
      end_op();
    80005b9a:	fffff097          	auipc	ra,0xfffff
    80005b9e:	964080e7          	jalr	-1692(ra) # 800044fe <end_op>
      return -1;
    80005ba2:	557d                	li	a0,-1
    80005ba4:	bf79                	j	80005b42 <sys_open+0xe4>
    iunlockput(ip);
    80005ba6:	8526                	mv	a0,s1
    80005ba8:	ffffe097          	auipc	ra,0xffffe
    80005bac:	176080e7          	jalr	374(ra) # 80003d1e <iunlockput>
    end_op();
    80005bb0:	fffff097          	auipc	ra,0xfffff
    80005bb4:	94e080e7          	jalr	-1714(ra) # 800044fe <end_op>
    return -1;
    80005bb8:	557d                	li	a0,-1
    80005bba:	b761                	j	80005b42 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005bbc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005bc0:	04649783          	lh	a5,70(s1)
    80005bc4:	02f99223          	sh	a5,36(s3)
    80005bc8:	bf25                	j	80005b00 <sys_open+0xa2>
    itrunc(ip);
    80005bca:	8526                	mv	a0,s1
    80005bcc:	ffffe097          	auipc	ra,0xffffe
    80005bd0:	ffe080e7          	jalr	-2(ra) # 80003bca <itrunc>
    80005bd4:	bfa9                	j	80005b2e <sys_open+0xd0>
      fileclose(f);
    80005bd6:	854e                	mv	a0,s3
    80005bd8:	fffff097          	auipc	ra,0xfffff
    80005bdc:	d72080e7          	jalr	-654(ra) # 8000494a <fileclose>
    iunlockput(ip);
    80005be0:	8526                	mv	a0,s1
    80005be2:	ffffe097          	auipc	ra,0xffffe
    80005be6:	13c080e7          	jalr	316(ra) # 80003d1e <iunlockput>
    end_op();
    80005bea:	fffff097          	auipc	ra,0xfffff
    80005bee:	914080e7          	jalr	-1772(ra) # 800044fe <end_op>
    return -1;
    80005bf2:	557d                	li	a0,-1
    80005bf4:	b7b9                	j	80005b42 <sys_open+0xe4>

0000000080005bf6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005bf6:	7175                	addi	sp,sp,-144
    80005bf8:	e506                	sd	ra,136(sp)
    80005bfa:	e122                	sd	s0,128(sp)
    80005bfc:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005bfe:	fffff097          	auipc	ra,0xfffff
    80005c02:	880080e7          	jalr	-1920(ra) # 8000447e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c06:	08000613          	li	a2,128
    80005c0a:	f7040593          	addi	a1,s0,-144
    80005c0e:	4501                	li	a0,0
    80005c10:	ffffd097          	auipc	ra,0xffffd
    80005c14:	292080e7          	jalr	658(ra) # 80002ea2 <argstr>
    80005c18:	02054963          	bltz	a0,80005c4a <sys_mkdir+0x54>
    80005c1c:	4681                	li	a3,0
    80005c1e:	4601                	li	a2,0
    80005c20:	4585                	li	a1,1
    80005c22:	f7040513          	addi	a0,s0,-144
    80005c26:	00000097          	auipc	ra,0x0
    80005c2a:	800080e7          	jalr	-2048(ra) # 80005426 <create>
    80005c2e:	cd11                	beqz	a0,80005c4a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c30:	ffffe097          	auipc	ra,0xffffe
    80005c34:	0ee080e7          	jalr	238(ra) # 80003d1e <iunlockput>
  end_op();
    80005c38:	fffff097          	auipc	ra,0xfffff
    80005c3c:	8c6080e7          	jalr	-1850(ra) # 800044fe <end_op>
  return 0;
    80005c40:	4501                	li	a0,0
}
    80005c42:	60aa                	ld	ra,136(sp)
    80005c44:	640a                	ld	s0,128(sp)
    80005c46:	6149                	addi	sp,sp,144
    80005c48:	8082                	ret
    end_op();
    80005c4a:	fffff097          	auipc	ra,0xfffff
    80005c4e:	8b4080e7          	jalr	-1868(ra) # 800044fe <end_op>
    return -1;
    80005c52:	557d                	li	a0,-1
    80005c54:	b7fd                	j	80005c42 <sys_mkdir+0x4c>

0000000080005c56 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005c56:	7135                	addi	sp,sp,-160
    80005c58:	ed06                	sd	ra,152(sp)
    80005c5a:	e922                	sd	s0,144(sp)
    80005c5c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005c5e:	fffff097          	auipc	ra,0xfffff
    80005c62:	820080e7          	jalr	-2016(ra) # 8000447e <begin_op>
  argint(1, &major);
    80005c66:	f6c40593          	addi	a1,s0,-148
    80005c6a:	4505                	li	a0,1
    80005c6c:	ffffd097          	auipc	ra,0xffffd
    80005c70:	1f6080e7          	jalr	502(ra) # 80002e62 <argint>
  argint(2, &minor);
    80005c74:	f6840593          	addi	a1,s0,-152
    80005c78:	4509                	li	a0,2
    80005c7a:	ffffd097          	auipc	ra,0xffffd
    80005c7e:	1e8080e7          	jalr	488(ra) # 80002e62 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005c82:	08000613          	li	a2,128
    80005c86:	f7040593          	addi	a1,s0,-144
    80005c8a:	4501                	li	a0,0
    80005c8c:	ffffd097          	auipc	ra,0xffffd
    80005c90:	216080e7          	jalr	534(ra) # 80002ea2 <argstr>
    80005c94:	02054b63          	bltz	a0,80005cca <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005c98:	f6841683          	lh	a3,-152(s0)
    80005c9c:	f6c41603          	lh	a2,-148(s0)
    80005ca0:	458d                	li	a1,3
    80005ca2:	f7040513          	addi	a0,s0,-144
    80005ca6:	fffff097          	auipc	ra,0xfffff
    80005caa:	780080e7          	jalr	1920(ra) # 80005426 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cae:	cd11                	beqz	a0,80005cca <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cb0:	ffffe097          	auipc	ra,0xffffe
    80005cb4:	06e080e7          	jalr	110(ra) # 80003d1e <iunlockput>
  end_op();
    80005cb8:	fffff097          	auipc	ra,0xfffff
    80005cbc:	846080e7          	jalr	-1978(ra) # 800044fe <end_op>
  return 0;
    80005cc0:	4501                	li	a0,0
}
    80005cc2:	60ea                	ld	ra,152(sp)
    80005cc4:	644a                	ld	s0,144(sp)
    80005cc6:	610d                	addi	sp,sp,160
    80005cc8:	8082                	ret
    end_op();
    80005cca:	fffff097          	auipc	ra,0xfffff
    80005cce:	834080e7          	jalr	-1996(ra) # 800044fe <end_op>
    return -1;
    80005cd2:	557d                	li	a0,-1
    80005cd4:	b7fd                	j	80005cc2 <sys_mknod+0x6c>

0000000080005cd6 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005cd6:	7135                	addi	sp,sp,-160
    80005cd8:	ed06                	sd	ra,152(sp)
    80005cda:	e922                	sd	s0,144(sp)
    80005cdc:	e526                	sd	s1,136(sp)
    80005cde:	e14a                	sd	s2,128(sp)
    80005ce0:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ce2:	ffffc097          	auipc	ra,0xffffc
    80005ce6:	cca080e7          	jalr	-822(ra) # 800019ac <myproc>
    80005cea:	892a                	mv	s2,a0
  
  begin_op();
    80005cec:	ffffe097          	auipc	ra,0xffffe
    80005cf0:	792080e7          	jalr	1938(ra) # 8000447e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005cf4:	08000613          	li	a2,128
    80005cf8:	f6040593          	addi	a1,s0,-160
    80005cfc:	4501                	li	a0,0
    80005cfe:	ffffd097          	auipc	ra,0xffffd
    80005d02:	1a4080e7          	jalr	420(ra) # 80002ea2 <argstr>
    80005d06:	04054b63          	bltz	a0,80005d5c <sys_chdir+0x86>
    80005d0a:	f6040513          	addi	a0,s0,-160
    80005d0e:	ffffe097          	auipc	ra,0xffffe
    80005d12:	554080e7          	jalr	1364(ra) # 80004262 <namei>
    80005d16:	84aa                	mv	s1,a0
    80005d18:	c131                	beqz	a0,80005d5c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d1a:	ffffe097          	auipc	ra,0xffffe
    80005d1e:	da2080e7          	jalr	-606(ra) # 80003abc <ilock>
  if(ip->type != T_DIR){
    80005d22:	04449703          	lh	a4,68(s1)
    80005d26:	4785                	li	a5,1
    80005d28:	04f71063          	bne	a4,a5,80005d68 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d2c:	8526                	mv	a0,s1
    80005d2e:	ffffe097          	auipc	ra,0xffffe
    80005d32:	e50080e7          	jalr	-432(ra) # 80003b7e <iunlock>
  iput(p->cwd);
    80005d36:	15093503          	ld	a0,336(s2)
    80005d3a:	ffffe097          	auipc	ra,0xffffe
    80005d3e:	f3c080e7          	jalr	-196(ra) # 80003c76 <iput>
  end_op();
    80005d42:	ffffe097          	auipc	ra,0xffffe
    80005d46:	7bc080e7          	jalr	1980(ra) # 800044fe <end_op>
  p->cwd = ip;
    80005d4a:	14993823          	sd	s1,336(s2)
  return 0;
    80005d4e:	4501                	li	a0,0
}
    80005d50:	60ea                	ld	ra,152(sp)
    80005d52:	644a                	ld	s0,144(sp)
    80005d54:	64aa                	ld	s1,136(sp)
    80005d56:	690a                	ld	s2,128(sp)
    80005d58:	610d                	addi	sp,sp,160
    80005d5a:	8082                	ret
    end_op();
    80005d5c:	ffffe097          	auipc	ra,0xffffe
    80005d60:	7a2080e7          	jalr	1954(ra) # 800044fe <end_op>
    return -1;
    80005d64:	557d                	li	a0,-1
    80005d66:	b7ed                	j	80005d50 <sys_chdir+0x7a>
    iunlockput(ip);
    80005d68:	8526                	mv	a0,s1
    80005d6a:	ffffe097          	auipc	ra,0xffffe
    80005d6e:	fb4080e7          	jalr	-76(ra) # 80003d1e <iunlockput>
    end_op();
    80005d72:	ffffe097          	auipc	ra,0xffffe
    80005d76:	78c080e7          	jalr	1932(ra) # 800044fe <end_op>
    return -1;
    80005d7a:	557d                	li	a0,-1
    80005d7c:	bfd1                	j	80005d50 <sys_chdir+0x7a>

0000000080005d7e <sys_exec>:

uint64
sys_exec(void)
{
    80005d7e:	7145                	addi	sp,sp,-464
    80005d80:	e786                	sd	ra,456(sp)
    80005d82:	e3a2                	sd	s0,448(sp)
    80005d84:	ff26                	sd	s1,440(sp)
    80005d86:	fb4a                	sd	s2,432(sp)
    80005d88:	f74e                	sd	s3,424(sp)
    80005d8a:	f352                	sd	s4,416(sp)
    80005d8c:	ef56                	sd	s5,408(sp)
    80005d8e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005d90:	e3840593          	addi	a1,s0,-456
    80005d94:	4505                	li	a0,1
    80005d96:	ffffd097          	auipc	ra,0xffffd
    80005d9a:	0ec080e7          	jalr	236(ra) # 80002e82 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005d9e:	08000613          	li	a2,128
    80005da2:	f4040593          	addi	a1,s0,-192
    80005da6:	4501                	li	a0,0
    80005da8:	ffffd097          	auipc	ra,0xffffd
    80005dac:	0fa080e7          	jalr	250(ra) # 80002ea2 <argstr>
    80005db0:	87aa                	mv	a5,a0
    return -1;
    80005db2:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005db4:	0c07c263          	bltz	a5,80005e78 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005db8:	10000613          	li	a2,256
    80005dbc:	4581                	li	a1,0
    80005dbe:	e4040513          	addi	a0,s0,-448
    80005dc2:	ffffb097          	auipc	ra,0xffffb
    80005dc6:	f10080e7          	jalr	-240(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005dca:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005dce:	89a6                	mv	s3,s1
    80005dd0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005dd2:	02000a13          	li	s4,32
    80005dd6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005dda:	00391793          	slli	a5,s2,0x3
    80005dde:	e3040593          	addi	a1,s0,-464
    80005de2:	e3843503          	ld	a0,-456(s0)
    80005de6:	953e                	add	a0,a0,a5
    80005de8:	ffffd097          	auipc	ra,0xffffd
    80005dec:	fdc080e7          	jalr	-36(ra) # 80002dc4 <fetchaddr>
    80005df0:	02054a63          	bltz	a0,80005e24 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005df4:	e3043783          	ld	a5,-464(s0)
    80005df8:	c3b9                	beqz	a5,80005e3e <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005dfa:	ffffb097          	auipc	ra,0xffffb
    80005dfe:	cec080e7          	jalr	-788(ra) # 80000ae6 <kalloc>
    80005e02:	85aa                	mv	a1,a0
    80005e04:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e08:	cd11                	beqz	a0,80005e24 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e0a:	6605                	lui	a2,0x1
    80005e0c:	e3043503          	ld	a0,-464(s0)
    80005e10:	ffffd097          	auipc	ra,0xffffd
    80005e14:	006080e7          	jalr	6(ra) # 80002e16 <fetchstr>
    80005e18:	00054663          	bltz	a0,80005e24 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005e1c:	0905                	addi	s2,s2,1
    80005e1e:	09a1                	addi	s3,s3,8
    80005e20:	fb491be3          	bne	s2,s4,80005dd6 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e24:	10048913          	addi	s2,s1,256
    80005e28:	6088                	ld	a0,0(s1)
    80005e2a:	c531                	beqz	a0,80005e76 <sys_exec+0xf8>
    kfree(argv[i]);
    80005e2c:	ffffb097          	auipc	ra,0xffffb
    80005e30:	bbe080e7          	jalr	-1090(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e34:	04a1                	addi	s1,s1,8
    80005e36:	ff2499e3          	bne	s1,s2,80005e28 <sys_exec+0xaa>
  return -1;
    80005e3a:	557d                	li	a0,-1
    80005e3c:	a835                	j	80005e78 <sys_exec+0xfa>
      argv[i] = 0;
    80005e3e:	0a8e                	slli	s5,s5,0x3
    80005e40:	fc040793          	addi	a5,s0,-64
    80005e44:	9abe                	add	s5,s5,a5
    80005e46:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005e4a:	e4040593          	addi	a1,s0,-448
    80005e4e:	f4040513          	addi	a0,s0,-192
    80005e52:	fffff097          	auipc	ra,0xfffff
    80005e56:	172080e7          	jalr	370(ra) # 80004fc4 <exec>
    80005e5a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e5c:	10048993          	addi	s3,s1,256
    80005e60:	6088                	ld	a0,0(s1)
    80005e62:	c901                	beqz	a0,80005e72 <sys_exec+0xf4>
    kfree(argv[i]);
    80005e64:	ffffb097          	auipc	ra,0xffffb
    80005e68:	b86080e7          	jalr	-1146(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e6c:	04a1                	addi	s1,s1,8
    80005e6e:	ff3499e3          	bne	s1,s3,80005e60 <sys_exec+0xe2>
  return ret;
    80005e72:	854a                	mv	a0,s2
    80005e74:	a011                	j	80005e78 <sys_exec+0xfa>
  return -1;
    80005e76:	557d                	li	a0,-1
}
    80005e78:	60be                	ld	ra,456(sp)
    80005e7a:	641e                	ld	s0,448(sp)
    80005e7c:	74fa                	ld	s1,440(sp)
    80005e7e:	795a                	ld	s2,432(sp)
    80005e80:	79ba                	ld	s3,424(sp)
    80005e82:	7a1a                	ld	s4,416(sp)
    80005e84:	6afa                	ld	s5,408(sp)
    80005e86:	6179                	addi	sp,sp,464
    80005e88:	8082                	ret

0000000080005e8a <sys_pipe>:

uint64
sys_pipe(void)
{
    80005e8a:	7139                	addi	sp,sp,-64
    80005e8c:	fc06                	sd	ra,56(sp)
    80005e8e:	f822                	sd	s0,48(sp)
    80005e90:	f426                	sd	s1,40(sp)
    80005e92:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005e94:	ffffc097          	auipc	ra,0xffffc
    80005e98:	b18080e7          	jalr	-1256(ra) # 800019ac <myproc>
    80005e9c:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005e9e:	fd840593          	addi	a1,s0,-40
    80005ea2:	4501                	li	a0,0
    80005ea4:	ffffd097          	auipc	ra,0xffffd
    80005ea8:	fde080e7          	jalr	-34(ra) # 80002e82 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005eac:	fc840593          	addi	a1,s0,-56
    80005eb0:	fd040513          	addi	a0,s0,-48
    80005eb4:	fffff097          	auipc	ra,0xfffff
    80005eb8:	dc6080e7          	jalr	-570(ra) # 80004c7a <pipealloc>
    return -1;
    80005ebc:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ebe:	0c054463          	bltz	a0,80005f86 <sys_pipe+0xfc>
  fd0 = -1;
    80005ec2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ec6:	fd043503          	ld	a0,-48(s0)
    80005eca:	fffff097          	auipc	ra,0xfffff
    80005ece:	51a080e7          	jalr	1306(ra) # 800053e4 <fdalloc>
    80005ed2:	fca42223          	sw	a0,-60(s0)
    80005ed6:	08054b63          	bltz	a0,80005f6c <sys_pipe+0xe2>
    80005eda:	fc843503          	ld	a0,-56(s0)
    80005ede:	fffff097          	auipc	ra,0xfffff
    80005ee2:	506080e7          	jalr	1286(ra) # 800053e4 <fdalloc>
    80005ee6:	fca42023          	sw	a0,-64(s0)
    80005eea:	06054863          	bltz	a0,80005f5a <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005eee:	4691                	li	a3,4
    80005ef0:	fc440613          	addi	a2,s0,-60
    80005ef4:	fd843583          	ld	a1,-40(s0)
    80005ef8:	68a8                	ld	a0,80(s1)
    80005efa:	ffffb097          	auipc	ra,0xffffb
    80005efe:	76e080e7          	jalr	1902(ra) # 80001668 <copyout>
    80005f02:	02054063          	bltz	a0,80005f22 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f06:	4691                	li	a3,4
    80005f08:	fc040613          	addi	a2,s0,-64
    80005f0c:	fd843583          	ld	a1,-40(s0)
    80005f10:	0591                	addi	a1,a1,4
    80005f12:	68a8                	ld	a0,80(s1)
    80005f14:	ffffb097          	auipc	ra,0xffffb
    80005f18:	754080e7          	jalr	1876(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f1c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f1e:	06055463          	bgez	a0,80005f86 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005f22:	fc442783          	lw	a5,-60(s0)
    80005f26:	07e9                	addi	a5,a5,26
    80005f28:	078e                	slli	a5,a5,0x3
    80005f2a:	97a6                	add	a5,a5,s1
    80005f2c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005f30:	fc042503          	lw	a0,-64(s0)
    80005f34:	0569                	addi	a0,a0,26
    80005f36:	050e                	slli	a0,a0,0x3
    80005f38:	94aa                	add	s1,s1,a0
    80005f3a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005f3e:	fd043503          	ld	a0,-48(s0)
    80005f42:	fffff097          	auipc	ra,0xfffff
    80005f46:	a08080e7          	jalr	-1528(ra) # 8000494a <fileclose>
    fileclose(wf);
    80005f4a:	fc843503          	ld	a0,-56(s0)
    80005f4e:	fffff097          	auipc	ra,0xfffff
    80005f52:	9fc080e7          	jalr	-1540(ra) # 8000494a <fileclose>
    return -1;
    80005f56:	57fd                	li	a5,-1
    80005f58:	a03d                	j	80005f86 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005f5a:	fc442783          	lw	a5,-60(s0)
    80005f5e:	0007c763          	bltz	a5,80005f6c <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005f62:	07e9                	addi	a5,a5,26
    80005f64:	078e                	slli	a5,a5,0x3
    80005f66:	94be                	add	s1,s1,a5
    80005f68:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005f6c:	fd043503          	ld	a0,-48(s0)
    80005f70:	fffff097          	auipc	ra,0xfffff
    80005f74:	9da080e7          	jalr	-1574(ra) # 8000494a <fileclose>
    fileclose(wf);
    80005f78:	fc843503          	ld	a0,-56(s0)
    80005f7c:	fffff097          	auipc	ra,0xfffff
    80005f80:	9ce080e7          	jalr	-1586(ra) # 8000494a <fileclose>
    return -1;
    80005f84:	57fd                	li	a5,-1
}
    80005f86:	853e                	mv	a0,a5
    80005f88:	70e2                	ld	ra,56(sp)
    80005f8a:	7442                	ld	s0,48(sp)
    80005f8c:	74a2                	ld	s1,40(sp)
    80005f8e:	6121                	addi	sp,sp,64
    80005f90:	8082                	ret
	...

0000000080005fa0 <kernelvec>:
    80005fa0:	7111                	addi	sp,sp,-256
    80005fa2:	e006                	sd	ra,0(sp)
    80005fa4:	e40a                	sd	sp,8(sp)
    80005fa6:	e80e                	sd	gp,16(sp)
    80005fa8:	ec12                	sd	tp,24(sp)
    80005faa:	f016                	sd	t0,32(sp)
    80005fac:	f41a                	sd	t1,40(sp)
    80005fae:	f81e                	sd	t2,48(sp)
    80005fb0:	fc22                	sd	s0,56(sp)
    80005fb2:	e0a6                	sd	s1,64(sp)
    80005fb4:	e4aa                	sd	a0,72(sp)
    80005fb6:	e8ae                	sd	a1,80(sp)
    80005fb8:	ecb2                	sd	a2,88(sp)
    80005fba:	f0b6                	sd	a3,96(sp)
    80005fbc:	f4ba                	sd	a4,104(sp)
    80005fbe:	f8be                	sd	a5,112(sp)
    80005fc0:	fcc2                	sd	a6,120(sp)
    80005fc2:	e146                	sd	a7,128(sp)
    80005fc4:	e54a                	sd	s2,136(sp)
    80005fc6:	e94e                	sd	s3,144(sp)
    80005fc8:	ed52                	sd	s4,152(sp)
    80005fca:	f156                	sd	s5,160(sp)
    80005fcc:	f55a                	sd	s6,168(sp)
    80005fce:	f95e                	sd	s7,176(sp)
    80005fd0:	fd62                	sd	s8,184(sp)
    80005fd2:	e1e6                	sd	s9,192(sp)
    80005fd4:	e5ea                	sd	s10,200(sp)
    80005fd6:	e9ee                	sd	s11,208(sp)
    80005fd8:	edf2                	sd	t3,216(sp)
    80005fda:	f1f6                	sd	t4,224(sp)
    80005fdc:	f5fa                	sd	t5,232(sp)
    80005fde:	f9fe                	sd	t6,240(sp)
    80005fe0:	cb1fc0ef          	jal	ra,80002c90 <kerneltrap>
    80005fe4:	6082                	ld	ra,0(sp)
    80005fe6:	6122                	ld	sp,8(sp)
    80005fe8:	61c2                	ld	gp,16(sp)
    80005fea:	7282                	ld	t0,32(sp)
    80005fec:	7322                	ld	t1,40(sp)
    80005fee:	73c2                	ld	t2,48(sp)
    80005ff0:	7462                	ld	s0,56(sp)
    80005ff2:	6486                	ld	s1,64(sp)
    80005ff4:	6526                	ld	a0,72(sp)
    80005ff6:	65c6                	ld	a1,80(sp)
    80005ff8:	6666                	ld	a2,88(sp)
    80005ffa:	7686                	ld	a3,96(sp)
    80005ffc:	7726                	ld	a4,104(sp)
    80005ffe:	77c6                	ld	a5,112(sp)
    80006000:	7866                	ld	a6,120(sp)
    80006002:	688a                	ld	a7,128(sp)
    80006004:	692a                	ld	s2,136(sp)
    80006006:	69ca                	ld	s3,144(sp)
    80006008:	6a6a                	ld	s4,152(sp)
    8000600a:	7a8a                	ld	s5,160(sp)
    8000600c:	7b2a                	ld	s6,168(sp)
    8000600e:	7bca                	ld	s7,176(sp)
    80006010:	7c6a                	ld	s8,184(sp)
    80006012:	6c8e                	ld	s9,192(sp)
    80006014:	6d2e                	ld	s10,200(sp)
    80006016:	6dce                	ld	s11,208(sp)
    80006018:	6e6e                	ld	t3,216(sp)
    8000601a:	7e8e                	ld	t4,224(sp)
    8000601c:	7f2e                	ld	t5,232(sp)
    8000601e:	7fce                	ld	t6,240(sp)
    80006020:	6111                	addi	sp,sp,256
    80006022:	10200073          	sret
    80006026:	00000013          	nop
    8000602a:	00000013          	nop
    8000602e:	0001                	nop

0000000080006030 <timervec>:
    80006030:	34051573          	csrrw	a0,mscratch,a0
    80006034:	e10c                	sd	a1,0(a0)
    80006036:	e510                	sd	a2,8(a0)
    80006038:	e914                	sd	a3,16(a0)
    8000603a:	6d0c                	ld	a1,24(a0)
    8000603c:	7110                	ld	a2,32(a0)
    8000603e:	6194                	ld	a3,0(a1)
    80006040:	96b2                	add	a3,a3,a2
    80006042:	e194                	sd	a3,0(a1)
    80006044:	4589                	li	a1,2
    80006046:	14459073          	csrw	sip,a1
    8000604a:	6914                	ld	a3,16(a0)
    8000604c:	6510                	ld	a2,8(a0)
    8000604e:	610c                	ld	a1,0(a0)
    80006050:	34051573          	csrrw	a0,mscratch,a0
    80006054:	30200073          	mret
	...

000000008000605a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000605a:	1141                	addi	sp,sp,-16
    8000605c:	e422                	sd	s0,8(sp)
    8000605e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006060:	0c0007b7          	lui	a5,0xc000
    80006064:	4705                	li	a4,1
    80006066:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006068:	c3d8                	sw	a4,4(a5)
}
    8000606a:	6422                	ld	s0,8(sp)
    8000606c:	0141                	addi	sp,sp,16
    8000606e:	8082                	ret

0000000080006070 <plicinithart>:

void
plicinithart(void)
{
    80006070:	1141                	addi	sp,sp,-16
    80006072:	e406                	sd	ra,8(sp)
    80006074:	e022                	sd	s0,0(sp)
    80006076:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006078:	ffffc097          	auipc	ra,0xffffc
    8000607c:	908080e7          	jalr	-1784(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006080:	0085171b          	slliw	a4,a0,0x8
    80006084:	0c0027b7          	lui	a5,0xc002
    80006088:	97ba                	add	a5,a5,a4
    8000608a:	40200713          	li	a4,1026
    8000608e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006092:	00d5151b          	slliw	a0,a0,0xd
    80006096:	0c2017b7          	lui	a5,0xc201
    8000609a:	953e                	add	a0,a0,a5
    8000609c:	00052023          	sw	zero,0(a0)
}
    800060a0:	60a2                	ld	ra,8(sp)
    800060a2:	6402                	ld	s0,0(sp)
    800060a4:	0141                	addi	sp,sp,16
    800060a6:	8082                	ret

00000000800060a8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800060a8:	1141                	addi	sp,sp,-16
    800060aa:	e406                	sd	ra,8(sp)
    800060ac:	e022                	sd	s0,0(sp)
    800060ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060b0:	ffffc097          	auipc	ra,0xffffc
    800060b4:	8d0080e7          	jalr	-1840(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800060b8:	00d5179b          	slliw	a5,a0,0xd
    800060bc:	0c201537          	lui	a0,0xc201
    800060c0:	953e                	add	a0,a0,a5
  return irq;
}
    800060c2:	4148                	lw	a0,4(a0)
    800060c4:	60a2                	ld	ra,8(sp)
    800060c6:	6402                	ld	s0,0(sp)
    800060c8:	0141                	addi	sp,sp,16
    800060ca:	8082                	ret

00000000800060cc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800060cc:	1101                	addi	sp,sp,-32
    800060ce:	ec06                	sd	ra,24(sp)
    800060d0:	e822                	sd	s0,16(sp)
    800060d2:	e426                	sd	s1,8(sp)
    800060d4:	1000                	addi	s0,sp,32
    800060d6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800060d8:	ffffc097          	auipc	ra,0xffffc
    800060dc:	8a8080e7          	jalr	-1880(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800060e0:	00d5151b          	slliw	a0,a0,0xd
    800060e4:	0c2017b7          	lui	a5,0xc201
    800060e8:	97aa                	add	a5,a5,a0
    800060ea:	c3c4                	sw	s1,4(a5)
}
    800060ec:	60e2                	ld	ra,24(sp)
    800060ee:	6442                	ld	s0,16(sp)
    800060f0:	64a2                	ld	s1,8(sp)
    800060f2:	6105                	addi	sp,sp,32
    800060f4:	8082                	ret

00000000800060f6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800060f6:	1141                	addi	sp,sp,-16
    800060f8:	e406                	sd	ra,8(sp)
    800060fa:	e022                	sd	s0,0(sp)
    800060fc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800060fe:	479d                	li	a5,7
    80006100:	04a7cc63          	blt	a5,a0,80006158 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006104:	0001c797          	auipc	a5,0x1c
    80006108:	37c78793          	addi	a5,a5,892 # 80022480 <disk>
    8000610c:	97aa                	add	a5,a5,a0
    8000610e:	0187c783          	lbu	a5,24(a5)
    80006112:	ebb9                	bnez	a5,80006168 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006114:	00451613          	slli	a2,a0,0x4
    80006118:	0001c797          	auipc	a5,0x1c
    8000611c:	36878793          	addi	a5,a5,872 # 80022480 <disk>
    80006120:	6394                	ld	a3,0(a5)
    80006122:	96b2                	add	a3,a3,a2
    80006124:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006128:	6398                	ld	a4,0(a5)
    8000612a:	9732                	add	a4,a4,a2
    8000612c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006130:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006134:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006138:	953e                	add	a0,a0,a5
    8000613a:	4785                	li	a5,1
    8000613c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006140:	0001c517          	auipc	a0,0x1c
    80006144:	35850513          	addi	a0,a0,856 # 80022498 <disk+0x18>
    80006148:	ffffc097          	auipc	ra,0xffffc
    8000614c:	f70080e7          	jalr	-144(ra) # 800020b8 <wakeup>
}
    80006150:	60a2                	ld	ra,8(sp)
    80006152:	6402                	ld	s0,0(sp)
    80006154:	0141                	addi	sp,sp,16
    80006156:	8082                	ret
    panic("free_desc 1");
    80006158:	00002517          	auipc	a0,0x2
    8000615c:	64850513          	addi	a0,a0,1608 # 800087a0 <syscalls+0x308>
    80006160:	ffffa097          	auipc	ra,0xffffa
    80006164:	3de080e7          	jalr	990(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006168:	00002517          	auipc	a0,0x2
    8000616c:	64850513          	addi	a0,a0,1608 # 800087b0 <syscalls+0x318>
    80006170:	ffffa097          	auipc	ra,0xffffa
    80006174:	3ce080e7          	jalr	974(ra) # 8000053e <panic>

0000000080006178 <virtio_disk_init>:
{
    80006178:	1101                	addi	sp,sp,-32
    8000617a:	ec06                	sd	ra,24(sp)
    8000617c:	e822                	sd	s0,16(sp)
    8000617e:	e426                	sd	s1,8(sp)
    80006180:	e04a                	sd	s2,0(sp)
    80006182:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006184:	00002597          	auipc	a1,0x2
    80006188:	63c58593          	addi	a1,a1,1596 # 800087c0 <syscalls+0x328>
    8000618c:	0001c517          	auipc	a0,0x1c
    80006190:	41c50513          	addi	a0,a0,1052 # 800225a8 <disk+0x128>
    80006194:	ffffb097          	auipc	ra,0xffffb
    80006198:	9b2080e7          	jalr	-1614(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000619c:	100017b7          	lui	a5,0x10001
    800061a0:	4398                	lw	a4,0(a5)
    800061a2:	2701                	sext.w	a4,a4
    800061a4:	747277b7          	lui	a5,0x74727
    800061a8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800061ac:	14f71c63          	bne	a4,a5,80006304 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800061b0:	100017b7          	lui	a5,0x10001
    800061b4:	43dc                	lw	a5,4(a5)
    800061b6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061b8:	4709                	li	a4,2
    800061ba:	14e79563          	bne	a5,a4,80006304 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061be:	100017b7          	lui	a5,0x10001
    800061c2:	479c                	lw	a5,8(a5)
    800061c4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800061c6:	12e79f63          	bne	a5,a4,80006304 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800061ca:	100017b7          	lui	a5,0x10001
    800061ce:	47d8                	lw	a4,12(a5)
    800061d0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800061d2:	554d47b7          	lui	a5,0x554d4
    800061d6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800061da:	12f71563          	bne	a4,a5,80006304 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    800061de:	100017b7          	lui	a5,0x10001
    800061e2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800061e6:	4705                	li	a4,1
    800061e8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061ea:	470d                	li	a4,3
    800061ec:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800061ee:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800061f0:	c7ffe737          	lui	a4,0xc7ffe
    800061f4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc19f>
    800061f8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800061fa:	2701                	sext.w	a4,a4
    800061fc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800061fe:	472d                	li	a4,11
    80006200:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006202:	5bbc                	lw	a5,112(a5)
    80006204:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006208:	8ba1                	andi	a5,a5,8
    8000620a:	10078563          	beqz	a5,80006314 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000620e:	100017b7          	lui	a5,0x10001
    80006212:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006216:	43fc                	lw	a5,68(a5)
    80006218:	2781                	sext.w	a5,a5
    8000621a:	10079563          	bnez	a5,80006324 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000621e:	100017b7          	lui	a5,0x10001
    80006222:	5bdc                	lw	a5,52(a5)
    80006224:	2781                	sext.w	a5,a5
  if(max == 0)
    80006226:	10078763          	beqz	a5,80006334 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000622a:	471d                	li	a4,7
    8000622c:	10f77c63          	bgeu	a4,a5,80006344 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006230:	ffffb097          	auipc	ra,0xffffb
    80006234:	8b6080e7          	jalr	-1866(ra) # 80000ae6 <kalloc>
    80006238:	0001c497          	auipc	s1,0x1c
    8000623c:	24848493          	addi	s1,s1,584 # 80022480 <disk>
    80006240:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006242:	ffffb097          	auipc	ra,0xffffb
    80006246:	8a4080e7          	jalr	-1884(ra) # 80000ae6 <kalloc>
    8000624a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000624c:	ffffb097          	auipc	ra,0xffffb
    80006250:	89a080e7          	jalr	-1894(ra) # 80000ae6 <kalloc>
    80006254:	87aa                	mv	a5,a0
    80006256:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006258:	6088                	ld	a0,0(s1)
    8000625a:	cd6d                	beqz	a0,80006354 <virtio_disk_init+0x1dc>
    8000625c:	0001c717          	auipc	a4,0x1c
    80006260:	22c73703          	ld	a4,556(a4) # 80022488 <disk+0x8>
    80006264:	cb65                	beqz	a4,80006354 <virtio_disk_init+0x1dc>
    80006266:	c7fd                	beqz	a5,80006354 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006268:	6605                	lui	a2,0x1
    8000626a:	4581                	li	a1,0
    8000626c:	ffffb097          	auipc	ra,0xffffb
    80006270:	a66080e7          	jalr	-1434(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006274:	0001c497          	auipc	s1,0x1c
    80006278:	20c48493          	addi	s1,s1,524 # 80022480 <disk>
    8000627c:	6605                	lui	a2,0x1
    8000627e:	4581                	li	a1,0
    80006280:	6488                	ld	a0,8(s1)
    80006282:	ffffb097          	auipc	ra,0xffffb
    80006286:	a50080e7          	jalr	-1456(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    8000628a:	6605                	lui	a2,0x1
    8000628c:	4581                	li	a1,0
    8000628e:	6888                	ld	a0,16(s1)
    80006290:	ffffb097          	auipc	ra,0xffffb
    80006294:	a42080e7          	jalr	-1470(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006298:	100017b7          	lui	a5,0x10001
    8000629c:	4721                	li	a4,8
    8000629e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800062a0:	4098                	lw	a4,0(s1)
    800062a2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800062a6:	40d8                	lw	a4,4(s1)
    800062a8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800062ac:	6498                	ld	a4,8(s1)
    800062ae:	0007069b          	sext.w	a3,a4
    800062b2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800062b6:	9701                	srai	a4,a4,0x20
    800062b8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800062bc:	6898                	ld	a4,16(s1)
    800062be:	0007069b          	sext.w	a3,a4
    800062c2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800062c6:	9701                	srai	a4,a4,0x20
    800062c8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800062cc:	4705                	li	a4,1
    800062ce:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800062d0:	00e48c23          	sb	a4,24(s1)
    800062d4:	00e48ca3          	sb	a4,25(s1)
    800062d8:	00e48d23          	sb	a4,26(s1)
    800062dc:	00e48da3          	sb	a4,27(s1)
    800062e0:	00e48e23          	sb	a4,28(s1)
    800062e4:	00e48ea3          	sb	a4,29(s1)
    800062e8:	00e48f23          	sb	a4,30(s1)
    800062ec:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800062f0:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800062f4:	0727a823          	sw	s2,112(a5)
}
    800062f8:	60e2                	ld	ra,24(sp)
    800062fa:	6442                	ld	s0,16(sp)
    800062fc:	64a2                	ld	s1,8(sp)
    800062fe:	6902                	ld	s2,0(sp)
    80006300:	6105                	addi	sp,sp,32
    80006302:	8082                	ret
    panic("could not find virtio disk");
    80006304:	00002517          	auipc	a0,0x2
    80006308:	4cc50513          	addi	a0,a0,1228 # 800087d0 <syscalls+0x338>
    8000630c:	ffffa097          	auipc	ra,0xffffa
    80006310:	232080e7          	jalr	562(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006314:	00002517          	auipc	a0,0x2
    80006318:	4dc50513          	addi	a0,a0,1244 # 800087f0 <syscalls+0x358>
    8000631c:	ffffa097          	auipc	ra,0xffffa
    80006320:	222080e7          	jalr	546(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006324:	00002517          	auipc	a0,0x2
    80006328:	4ec50513          	addi	a0,a0,1260 # 80008810 <syscalls+0x378>
    8000632c:	ffffa097          	auipc	ra,0xffffa
    80006330:	212080e7          	jalr	530(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006334:	00002517          	auipc	a0,0x2
    80006338:	4fc50513          	addi	a0,a0,1276 # 80008830 <syscalls+0x398>
    8000633c:	ffffa097          	auipc	ra,0xffffa
    80006340:	202080e7          	jalr	514(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006344:	00002517          	auipc	a0,0x2
    80006348:	50c50513          	addi	a0,a0,1292 # 80008850 <syscalls+0x3b8>
    8000634c:	ffffa097          	auipc	ra,0xffffa
    80006350:	1f2080e7          	jalr	498(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006354:	00002517          	auipc	a0,0x2
    80006358:	51c50513          	addi	a0,a0,1308 # 80008870 <syscalls+0x3d8>
    8000635c:	ffffa097          	auipc	ra,0xffffa
    80006360:	1e2080e7          	jalr	482(ra) # 8000053e <panic>

0000000080006364 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006364:	7119                	addi	sp,sp,-128
    80006366:	fc86                	sd	ra,120(sp)
    80006368:	f8a2                	sd	s0,112(sp)
    8000636a:	f4a6                	sd	s1,104(sp)
    8000636c:	f0ca                	sd	s2,96(sp)
    8000636e:	ecce                	sd	s3,88(sp)
    80006370:	e8d2                	sd	s4,80(sp)
    80006372:	e4d6                	sd	s5,72(sp)
    80006374:	e0da                	sd	s6,64(sp)
    80006376:	fc5e                	sd	s7,56(sp)
    80006378:	f862                	sd	s8,48(sp)
    8000637a:	f466                	sd	s9,40(sp)
    8000637c:	f06a                	sd	s10,32(sp)
    8000637e:	ec6e                	sd	s11,24(sp)
    80006380:	0100                	addi	s0,sp,128
    80006382:	8aaa                	mv	s5,a0
    80006384:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006386:	00c52d03          	lw	s10,12(a0)
    8000638a:	001d1d1b          	slliw	s10,s10,0x1
    8000638e:	1d02                	slli	s10,s10,0x20
    80006390:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006394:	0001c517          	auipc	a0,0x1c
    80006398:	21450513          	addi	a0,a0,532 # 800225a8 <disk+0x128>
    8000639c:	ffffb097          	auipc	ra,0xffffb
    800063a0:	83a080e7          	jalr	-1990(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800063a4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800063a6:	44a1                	li	s1,8
      disk.free[i] = 0;
    800063a8:	0001cb97          	auipc	s7,0x1c
    800063ac:	0d8b8b93          	addi	s7,s7,216 # 80022480 <disk>
  for(int i = 0; i < 3; i++){
    800063b0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800063b2:	0001cc97          	auipc	s9,0x1c
    800063b6:	1f6c8c93          	addi	s9,s9,502 # 800225a8 <disk+0x128>
    800063ba:	a08d                	j	8000641c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800063bc:	00fb8733          	add	a4,s7,a5
    800063c0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800063c4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800063c6:	0207c563          	bltz	a5,800063f0 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800063ca:	2905                	addiw	s2,s2,1
    800063cc:	0611                	addi	a2,a2,4
    800063ce:	05690c63          	beq	s2,s6,80006426 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800063d2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800063d4:	0001c717          	auipc	a4,0x1c
    800063d8:	0ac70713          	addi	a4,a4,172 # 80022480 <disk>
    800063dc:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800063de:	01874683          	lbu	a3,24(a4)
    800063e2:	fee9                	bnez	a3,800063bc <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800063e4:	2785                	addiw	a5,a5,1
    800063e6:	0705                	addi	a4,a4,1
    800063e8:	fe979be3          	bne	a5,s1,800063de <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800063ec:	57fd                	li	a5,-1
    800063ee:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800063f0:	01205d63          	blez	s2,8000640a <virtio_disk_rw+0xa6>
    800063f4:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800063f6:	000a2503          	lw	a0,0(s4)
    800063fa:	00000097          	auipc	ra,0x0
    800063fe:	cfc080e7          	jalr	-772(ra) # 800060f6 <free_desc>
      for(int j = 0; j < i; j++)
    80006402:	2d85                	addiw	s11,s11,1
    80006404:	0a11                	addi	s4,s4,4
    80006406:	ffb918e3          	bne	s2,s11,800063f6 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000640a:	85e6                	mv	a1,s9
    8000640c:	0001c517          	auipc	a0,0x1c
    80006410:	08c50513          	addi	a0,a0,140 # 80022498 <disk+0x18>
    80006414:	ffffc097          	auipc	ra,0xffffc
    80006418:	c40080e7          	jalr	-960(ra) # 80002054 <sleep>
  for(int i = 0; i < 3; i++){
    8000641c:	f8040a13          	addi	s4,s0,-128
{
    80006420:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006422:	894e                	mv	s2,s3
    80006424:	b77d                	j	800063d2 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006426:	f8042583          	lw	a1,-128(s0)
    8000642a:	00a58793          	addi	a5,a1,10
    8000642e:	0792                	slli	a5,a5,0x4

  if(write)
    80006430:	0001c617          	auipc	a2,0x1c
    80006434:	05060613          	addi	a2,a2,80 # 80022480 <disk>
    80006438:	00f60733          	add	a4,a2,a5
    8000643c:	018036b3          	snez	a3,s8
    80006440:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006442:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006446:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000644a:	f6078693          	addi	a3,a5,-160
    8000644e:	6218                	ld	a4,0(a2)
    80006450:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006452:	00878513          	addi	a0,a5,8
    80006456:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006458:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000645a:	6208                	ld	a0,0(a2)
    8000645c:	96aa                	add	a3,a3,a0
    8000645e:	4741                	li	a4,16
    80006460:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006462:	4705                	li	a4,1
    80006464:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006468:	f8442703          	lw	a4,-124(s0)
    8000646c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006470:	0712                	slli	a4,a4,0x4
    80006472:	953a                	add	a0,a0,a4
    80006474:	058a8693          	addi	a3,s5,88
    80006478:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000647a:	6208                	ld	a0,0(a2)
    8000647c:	972a                	add	a4,a4,a0
    8000647e:	40000693          	li	a3,1024
    80006482:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006484:	001c3c13          	seqz	s8,s8
    80006488:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000648a:	001c6c13          	ori	s8,s8,1
    8000648e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006492:	f8842603          	lw	a2,-120(s0)
    80006496:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000649a:	0001c697          	auipc	a3,0x1c
    8000649e:	fe668693          	addi	a3,a3,-26 # 80022480 <disk>
    800064a2:	00258713          	addi	a4,a1,2
    800064a6:	0712                	slli	a4,a4,0x4
    800064a8:	9736                	add	a4,a4,a3
    800064aa:	587d                	li	a6,-1
    800064ac:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800064b0:	0612                	slli	a2,a2,0x4
    800064b2:	9532                	add	a0,a0,a2
    800064b4:	f9078793          	addi	a5,a5,-112
    800064b8:	97b6                	add	a5,a5,a3
    800064ba:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800064bc:	629c                	ld	a5,0(a3)
    800064be:	97b2                	add	a5,a5,a2
    800064c0:	4605                	li	a2,1
    800064c2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800064c4:	4509                	li	a0,2
    800064c6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800064ca:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800064ce:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800064d2:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800064d6:	6698                	ld	a4,8(a3)
    800064d8:	00275783          	lhu	a5,2(a4)
    800064dc:	8b9d                	andi	a5,a5,7
    800064de:	0786                	slli	a5,a5,0x1
    800064e0:	97ba                	add	a5,a5,a4
    800064e2:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800064e6:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800064ea:	6698                	ld	a4,8(a3)
    800064ec:	00275783          	lhu	a5,2(a4)
    800064f0:	2785                	addiw	a5,a5,1
    800064f2:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800064f6:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800064fa:	100017b7          	lui	a5,0x10001
    800064fe:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006502:	004aa783          	lw	a5,4(s5)
    80006506:	02c79163          	bne	a5,a2,80006528 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    8000650a:	0001c917          	auipc	s2,0x1c
    8000650e:	09e90913          	addi	s2,s2,158 # 800225a8 <disk+0x128>
  while(b->disk == 1) {
    80006512:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006514:	85ca                	mv	a1,s2
    80006516:	8556                	mv	a0,s5
    80006518:	ffffc097          	auipc	ra,0xffffc
    8000651c:	b3c080e7          	jalr	-1220(ra) # 80002054 <sleep>
  while(b->disk == 1) {
    80006520:	004aa783          	lw	a5,4(s5)
    80006524:	fe9788e3          	beq	a5,s1,80006514 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006528:	f8042903          	lw	s2,-128(s0)
    8000652c:	00290793          	addi	a5,s2,2
    80006530:	00479713          	slli	a4,a5,0x4
    80006534:	0001c797          	auipc	a5,0x1c
    80006538:	f4c78793          	addi	a5,a5,-180 # 80022480 <disk>
    8000653c:	97ba                	add	a5,a5,a4
    8000653e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006542:	0001c997          	auipc	s3,0x1c
    80006546:	f3e98993          	addi	s3,s3,-194 # 80022480 <disk>
    8000654a:	00491713          	slli	a4,s2,0x4
    8000654e:	0009b783          	ld	a5,0(s3)
    80006552:	97ba                	add	a5,a5,a4
    80006554:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006558:	854a                	mv	a0,s2
    8000655a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000655e:	00000097          	auipc	ra,0x0
    80006562:	b98080e7          	jalr	-1128(ra) # 800060f6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006566:	8885                	andi	s1,s1,1
    80006568:	f0ed                	bnez	s1,8000654a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000656a:	0001c517          	auipc	a0,0x1c
    8000656e:	03e50513          	addi	a0,a0,62 # 800225a8 <disk+0x128>
    80006572:	ffffa097          	auipc	ra,0xffffa
    80006576:	718080e7          	jalr	1816(ra) # 80000c8a <release>
}
    8000657a:	70e6                	ld	ra,120(sp)
    8000657c:	7446                	ld	s0,112(sp)
    8000657e:	74a6                	ld	s1,104(sp)
    80006580:	7906                	ld	s2,96(sp)
    80006582:	69e6                	ld	s3,88(sp)
    80006584:	6a46                	ld	s4,80(sp)
    80006586:	6aa6                	ld	s5,72(sp)
    80006588:	6b06                	ld	s6,64(sp)
    8000658a:	7be2                	ld	s7,56(sp)
    8000658c:	7c42                	ld	s8,48(sp)
    8000658e:	7ca2                	ld	s9,40(sp)
    80006590:	7d02                	ld	s10,32(sp)
    80006592:	6de2                	ld	s11,24(sp)
    80006594:	6109                	addi	sp,sp,128
    80006596:	8082                	ret

0000000080006598 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006598:	1101                	addi	sp,sp,-32
    8000659a:	ec06                	sd	ra,24(sp)
    8000659c:	e822                	sd	s0,16(sp)
    8000659e:	e426                	sd	s1,8(sp)
    800065a0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800065a2:	0001c497          	auipc	s1,0x1c
    800065a6:	ede48493          	addi	s1,s1,-290 # 80022480 <disk>
    800065aa:	0001c517          	auipc	a0,0x1c
    800065ae:	ffe50513          	addi	a0,a0,-2 # 800225a8 <disk+0x128>
    800065b2:	ffffa097          	auipc	ra,0xffffa
    800065b6:	624080e7          	jalr	1572(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800065ba:	10001737          	lui	a4,0x10001
    800065be:	533c                	lw	a5,96(a4)
    800065c0:	8b8d                	andi	a5,a5,3
    800065c2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800065c4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800065c8:	689c                	ld	a5,16(s1)
    800065ca:	0204d703          	lhu	a4,32(s1)
    800065ce:	0027d783          	lhu	a5,2(a5)
    800065d2:	04f70863          	beq	a4,a5,80006622 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800065d6:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800065da:	6898                	ld	a4,16(s1)
    800065dc:	0204d783          	lhu	a5,32(s1)
    800065e0:	8b9d                	andi	a5,a5,7
    800065e2:	078e                	slli	a5,a5,0x3
    800065e4:	97ba                	add	a5,a5,a4
    800065e6:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800065e8:	00278713          	addi	a4,a5,2
    800065ec:	0712                	slli	a4,a4,0x4
    800065ee:	9726                	add	a4,a4,s1
    800065f0:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800065f4:	e721                	bnez	a4,8000663c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800065f6:	0789                	addi	a5,a5,2
    800065f8:	0792                	slli	a5,a5,0x4
    800065fa:	97a6                	add	a5,a5,s1
    800065fc:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800065fe:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006602:	ffffc097          	auipc	ra,0xffffc
    80006606:	ab6080e7          	jalr	-1354(ra) # 800020b8 <wakeup>

    disk.used_idx += 1;
    8000660a:	0204d783          	lhu	a5,32(s1)
    8000660e:	2785                	addiw	a5,a5,1
    80006610:	17c2                	slli	a5,a5,0x30
    80006612:	93c1                	srli	a5,a5,0x30
    80006614:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006618:	6898                	ld	a4,16(s1)
    8000661a:	00275703          	lhu	a4,2(a4)
    8000661e:	faf71ce3          	bne	a4,a5,800065d6 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006622:	0001c517          	auipc	a0,0x1c
    80006626:	f8650513          	addi	a0,a0,-122 # 800225a8 <disk+0x128>
    8000662a:	ffffa097          	auipc	ra,0xffffa
    8000662e:	660080e7          	jalr	1632(ra) # 80000c8a <release>
}
    80006632:	60e2                	ld	ra,24(sp)
    80006634:	6442                	ld	s0,16(sp)
    80006636:	64a2                	ld	s1,8(sp)
    80006638:	6105                	addi	sp,sp,32
    8000663a:	8082                	ret
      panic("virtio_disk_intr status");
    8000663c:	00002517          	auipc	a0,0x2
    80006640:	24c50513          	addi	a0,a0,588 # 80008888 <syscalls+0x3f0>
    80006644:	ffffa097          	auipc	ra,0xffffa
    80006648:	efa080e7          	jalr	-262(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
