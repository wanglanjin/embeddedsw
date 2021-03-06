/******************************************************************************
*
* Copyright (C) 2015 Xilinx, Inc.  All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/
		.section .vectors.reset, "ax"
		.align 2
_vector_reset:
		brai    XPfw_Init
		.section .vectors.sw_exception, "ax"
		.align 2

_vector_sw_exception:
	brai	XPfw_Exception

		.section .vectors.interrupt, "ax"
		.align 2
_vector_interrupt:
	brai	XPfw_InterruptHandler

		.section .vectors.hw_exception, "ax"
		.align 2
_vector_hw_exception:
		brai	_hw_exception_handler

/* FW StartUP Begins Here: Initialization of the Stack and Stack Protection. */
		.section .text
		.globl XPfw_Init
		.align 2
		.ent XPfw_Init
		.type XPfw_Init, @function
XPfw_Init:
		/*
		 *PMU Firmware does not reuse the ROM Stack. FW uses a speprate stack of 4k (can be changed by user)
		 */

		/* Stack Initialization */
		addik	r1,		r0,		_stack		/* R1 is stack pointer, load Stack's highest address into SP. */
		addik	r13,	r0,		_SDA_BASE_	/* The read-write small data anchor address */
		addik	r2,		r0,		_SDA2_BASE_	/* The read-only small data anchor address */


		/* Stack Protection */
		addik	r11,	r0,		_stack		/* Load  Stack's highest address into temp R11 */
		mts		rshr,	r11					/* Store Stack's highest address into STACK_HIGH_REGISTER */
		addik	r11,	r0,		_stack_end  /* Load  Stack's lowest address into temp R11 */
		mts		rslr,	r11					/* Store Stack's lowest address into STACK_LOW_REGISTER */

		/* Clear BSS */

		addi	r6, r0, __bss_start
		addi	r7, r0, __bss_end
		rsub	r18, r6, r7
		blei	r18, .Lendbss
	.Lloopbss:
		swi	r0, r6, 0
		addi	r6, r6, 4
		rsub	r18, r6, r7
		bgti	r18, .Lloopbss
	.Lendbss:
		/* Call Main*/
		brlid	r15, XPfw_Main
		nop
		/* Control never comes here */
		bri 0
		nop
		.end XPfw_Init

/* Exception Handler */
		.section .text
		.globl XPfw_Exception
		.align 2
		.ent XPfw_Exception
		.type XPfw_Exception, @function
XPfw_Exception:
/* Save ESR to PERS_GLOBAL_STORAGE0 Register */
		addik	r3,	r0,	0xffd80050
		mfs	r4,	resr
		swi	r4,	r3,	0
/* Save EAR to PERS_GLOBAL_STORAGE1 Register */
		addik	r3,	r0,	0xffd80054
		mfs	r4,	rear
		swi	r4,	r3,	0
/* Set the FW error bit-0 */
		addik	r3,	r0,	0xffd6033c
		addik	r4,	r0,	0x10000000
		swi	r4,	r3,	0
/* For now, just keep looping here. Its easier to debug */
		bri 0
		nop
		.end XPfw_Exception
