/*
 * baudcheck.S
 * Mar, 2013 by Bill Westfield (WestfW@yahoo.com)
 * Exercises in executing arithmetic code on a system that we can't count
 * on having the usual languages or tools installed.
 *
 * This little "C program" is run through the C preprocessor using the same
 * arguments as our "real" target (which should assure that it gets the
 * same values for clock speed and desired baud rate), and produces as
 * output a shell script that can be run through bash, and THAT in turn
 * writes the desired output...
 *
 * Note that the C-style comments are stripped by the C preprocessor.
 * Added support for special SOFT_UART by K.-H. Kuebbeler (kh_kuebbeler@web.de)
 */

/*
 * First strip any trailing "L" from the defined constants.  To do this
 * we need to make the constants into shell variables first.
 */
// bpsx=BAUD_RATE
// bps=${bpsx/L/}
// bps=${bpsx/U/}
// determine the count of loop tics

#include <avr/io.h>
#ifndef __ASSEMBLER__
 #define __ASSEMBLER__ 
#endif
#define NO_WARNING
#include "pin_defs.h"

#define SOFT_UART_PORT UART_RX_PORT
#include "set_loop_tics.h"

#ifndef BAUD_RATE
 #error "in check_baudrate.c is BAUD_RATE not set"
#endif

bps=`$ECHO_CMD BAUD_RATE | $TR_CMD -d LU`
#ifndef F_CPU
 #error "in check_baudrate.c is F_CPU not set"
#endif
// fcpux=F_CPU
// fcpu=${fcpux/L/}
// fcpu=${fcpux/U/}
fcpu=`$ECHO_CMD F_CPU | $TR_CMD -d LU`

// $ECHO_CMD f_cpu = $fcpu, baud = $bps
/*
 * Compute the divisor
 */
$ECHO_CMD --------------------------------------------------------------------------------
#if BAUD_RATE < 100
 #if (BAUD_RATE < 25) && (SOFT_UART == 0)
  $ECHO_CMD  "Simple Baudrate measurement implemented in optiboot! (2-bit, CLK/8)"
  #define TWO_BIT_MEASURE
  #undef FULL_SPEED_CLK
 #elif BAUD_RATE < 30
  $ECHO_CMD  "Simple Baudrate measurement implemented in optiboot! (2-bit, CLK/1)"
  #define TWO_BIT_MEASURE
  #define FULL_SPEED_CLK
 #elif (BAUD_RATE < 35) && (SOFT_UART == 0)
  $ECHO_CMD  "Simple Baudrate measurement implemented in optiboot! (4-bit, CLK/8)"
  #undef TWO_BIT_MEASURE
  #undef FULL_SPEED_CLK
 #elif BAUD_RATE < 40
  $ECHO_CMD  "Simple Baudrate measurement implemented in optiboot! (4-bit, CLK/1)"
  #undef TWO_BIT_MEASURE
  #define FULL_SPEED_CLK
 #elif (BAUD_RATE < 45) && (SOFT_UART == 0)
  $ECHO_CMD  "Simple Baudrate measurement with time limit implemented in optiboot! (2-bit, CLK/8)"
  #define TWO_BIT_MEASURE
  #undef FULL_SPEED_CLK
 #elif BAUD_RATE < 50
  $ECHO_CMD  "Simple Baudrate measurement with time limit implemented in optiboot! (2-bit, CLK/1)"
  #define TWO_BIT_MEASURE
  #define FULL_SPEED_CLK
 #elif (BAUD_RATE < 55) && (SOFT_UART == 0)
  $ECHO_CMD  "Simple Baudrate measurement with time limit implemented in optiboot! (4-bit, CLK/8)"
  #undef TWO_BIT_MEASURE
  #undef FULL_SPEED_CLK
 #elif BAUD_RATE < 60
  $ECHO_CMD  "Simple Baudrate measurement with time limit implemented in optiboot! (4-bit, CLK/1)"
  #undef TWO_BIT_MEASURE
  #define FULL_SPEED_CLK
 #elif BAUD_RATE < 80
  $ECHO_CMD "Complex Baudrate measurement implemented in optiboot! (2-bit, CLK/1)"
  #define TWO_BIT_MEASURE
  #define FULL_SPEED_CLK
 #else
  $ECHO_CMD "Complex Baudrate measurement implemented in optiboot! (4-bit, CLK/1)"
  #undef TWO_BIT_MEASURE
  #define FULL_SPEED_CLK
 #endif
 
 #if SOFT_UART > 0
  #if ((BAUD_RATE - ((BAUD_RATE/2)*2)) == 1)
   // 15-bit delay 
   #if BAUD_RATE < 60
    #ifdef TWO_BIT_MEASURE
     UartDelay=$(( (65535/2) ))
    #else
     UartDelay=$(( (65535/4) ))
    #endif
   #else
    // With full check (10 bits)
    UartDelay=$(( (65535/10) ))
   #endif

UartMinDelay=$(( ((25*5)+(RCALL_TICS+1)*2 + LOOP_TICS) ))
$ECHO_CMD "SoftUART Minimum `$ECHO_CMD "scale=0;($fcpu / $UartDelay)" | $BC_CMD` Baud, Error surely less than 4% up to `$ECHO_CMD "scale=1;($fcpu / $UartMinDelay / 1000)" | $BC_CMD` kBaud, Slow 15-Bit loop"

  #else		/* 8-bit delay */

UartDelay=$(( ((255*3*2) + (RCALL_TICS*2)  + LOOP_TICS) ))
UartMinDelay=$(( ((25*3)+(RCALL_TICS*2) + LOOP_TICS) ))
$ECHO_CMD "SoftUART Minimum `$ECHO_CMD "scale=0;($fcpu / $UartDelay)" | $BC_CMD` Baud, Error surely less than 4% up to `$ECHO_CMD "scale=1;($fcpu / $UartMinDelay / 1000)" | $BC_CMD` kBaud, Fast 8-Bit loop"
  #endif

 #else		/* HW UART */
  #if BAUD_RATE < 60
   // simple mode
   #ifdef TWO_BIT_MEASURE
    UartDelay=$(( (65535/2) ))
   #else
    UartDelay=$(( (65535/4) ))
   #endif
  #else
   // full 10-bit check
   #ifdef FULL_SPEED_CLK
    UartDelay=$(( (65535/4) ))
   #else
    UartDelay=$(( (8*4096) ))
   #endif
  #endif

$ECHO_CMD "UART Minimum `$ECHO_CMD "scale=0;($fcpu / $UartDelay)" | $BC_CMD` Baud, Error surely less than 4% up to `$ECHO_CMD "scale=1;($fcpu / (8*12500))" | $BC_CMD` kBaud"

 #endif

#else 	/* BAUD_RATE >= 100) */
#if SOFT_UART > 0
 #define DelayMul 1
 #define CLOCKS_PER_BIT ((F_CPU-((((2*RCALL_TICS+LOOP_TICS)*2-1)*BAUD_RATE)/2))/BAUD_RATE)
 #if CLOCKS_PER_BIT < 0
  #undef RCALL_TICS
  #undef CLOCKS_PER_BIT
  #define RCALL_TICS 0
  #define CLOCKS_PER_BIT ((F_CPU-((((2*RCALL_TICS+LOOP_TICS)*2-1)*BAUD_RATE)/2))/BAUD_RATE)
 #else
  #define UART_B_VALUE ((CLOCKS_PER_BIT)/6)
  #if UART_B_VALUE > 255
   // try with double rcall uartDelay_single
   #undef CLOCKS_PER_BIT
   #undef UART_B_VALUE
   #undef DelayMul
   #define DelayMul 2
   #define CLOCKS_PER_BIT ( (F_CPU-(((((2*DelayMul)*RCALL_TICS+LOOP_TICS)*2-1)*BAUD_RATE)/2) )/BAUD_RATE)
   #define UART_B_VALUE ((CLOCKS_PER_BIT)/(6*DelayMul))
   #if UART_B_VALUE > 255
    // compute with 4x rcall uartDelay_single
    #undef CLOCKS_PER_BIT
    #undef UART_B_VALUE
    #undef DelayMul
    #define DelayMul 4
    #define CLOCKS_PER_BIT ( (F_CPU-(((((2*DelayMul)*RCALL_TICS+LOOP_TICS)*2-1)*BAUD_RATE)/2) )/BAUD_RATE)
    #define UART_B_VALUE ((CLOCKS_PER_BIT)/(6*DelayMul))
    #if UART_B_VALUE > 255
     // compute with 8x rcall uartDelay_single
     #undef CLOCKS_PER_BIT
     #undef UART_B_VALUE
     #undef DelayMul
     #define DelayMul 8
     #define CLOCKS_PER_BIT ( (F_CPU-(((((2*DelayMul)*RCALL_TICS+LOOP_TICS)*2-1)*BAUD_RATE)/2) )/BAUD_RATE)
     #define UART_B_VALUE ((CLOCKS_PER_BIT)/(6*DelayMul))
     #if UART_B_VALUE > 255
      // compute with 16 rcall uartDelay_single
      #undef CLOCKS_PER_BIT
      #undef UART_B_VALUE
      #undef DelayMul
      #define DelayMul 16
      #define CLOCKS_PER_BIT ( (F_CPU-(((((2*DelayMul)*RCALL_TICS+LOOP_TICS)*2-1)*BAUD_RATE)/2) )/BAUD_RATE)
      #define UART_B_VALUE ((CLOCKS_PER_BIT)/(6*DelayMul))
      #if UART_B_VALUE > 255
       // compute with 32 rcall uartDelay_single
       #undef CLOCKS_PER_BIT
       #undef UART_B_VALUE
       #undef DelayMul
       #define DelayMul 32
       #define CLOCKS_PER_BIT ( (F_CPU-(((((2*DelayMul)*RCALL_TICS+LOOP_TICS)*2-1)*BAUD_RATE)/2) )/BAUD_RATE)
       #define UART_B_VALUE ((CLOCKS_PER_BIT)/(6*DelayMul))
       #if UART_B_VALUE > 255
        // compute with 64 rcall uartDelay_single
        #undef CLOCKS_PER_BIT
        #undef UART_B_VALUE
        #undef DelayMul
        #define DelayMul 64
        #define CLOCKS_PER_BIT ( (F_CPU-(((((2*DelayMul)*RCALL_TICS+LOOP_TICS)*2-1)*BAUD_RATE)/2) )/BAUD_RATE)
        #define UART_B_VALUE ((CLOCKS_PER_BIT)/(6*DelayMul))
       #endif        /* DelayMul 64*/
      #endif        /* DelayMul 32 */
     #endif        /* DelayMul 16 */
    #endif        /* DelayMul 8 */
   #endif        /* DelayMul 4 */
  #endif         /* DelayMul 2 */
 #endif 	/* CLOCKS_PER_BIT < 0 */

delay_mul=$(( DelayMul ))
clocks=$(( (CLOCKS_PER_BIT / DelayMul) ))
UartDelay=$(( (((RCALL_TICS*2) + (CLOCKS_PER_BIT/DelayMul)) * DelayMul) + LOOP_TICS ))
 #if BAUD_RATE > 10000
$ECHO_CMD "BAUD RATE CHECK: Desired: $bps,  SoftUART_Real: `$ECHO_CMD "scale=0;($fcpu / $UartDelay)" | $BC_CMD`, Delay: $clocks*$delay_mul, Error=`$ECHO_CMD "scale=2;(100*(($fcpu / $UartDelay)- $bps) ) / $bps"| $BC_CMD`\%"
 #elif BAUD_RATE > 1000
$ECHO_CMD "BAUD RATE CHECK: Desired: $bps,  SoftUART_Real: `$ECHO_CMD "scale=1;($fcpu / $UartDelay)" | $BC_CMD`, Delay: $clocks*$delay_mul, Error=`$ECHO_CMD "scale=2;(100*(($fcpu / $UartDelay)- $bps) ) / $bps"| $BC_CMD`\%"
 #else
$ECHO_CMD "BAUD RATE CHECK: Desired: $bps,  SoftUART_Real: `$ECHO_CMD "scale=2;($fcpu / $UartDelay)" | $BC_CMD`, Delay: $clocks*$delay_mul, Error=`$ECHO_CMD "scale=2;(100*(($fcpu / $UartDelay)- $bps) ) / $bps"| $BC_CMD`\%"
 #endif
#else
// for hardware UART
 #define BAUD_DIV  ( ( ( F_CPU / 4L / BAUD_RATE )  - 1) / 2) 
 #if (BAUD_DIV > 255) && (BAUD_DIV < 2046)
BAUD_SETTING=$((  ( ( ($fcpu / 8 / $bps) - 1) / 2) ))
UartDelay=$(( (16 * ((BAUD_SETTING) +1)) ))
/*
 * Based on the computer divisor, calculate the actual bitrate,
 * And the error.  Since we're all integers, we have to calculate
 * the tenths part of the error separately.
 */
// BAUD_ACTUAL=$(( ($fcpu/(16 * (($BAUD_SETTING)+1))) ))

 #else
BAUD_SETTING=$(( ( ( ($fcpu / 4 / $bps ) - 1) / 2) ))
UartDelay=$(( (8 * ((BAUD_SETTING) +1)) ))
/*
 * Based on the computer divisor, calculate the actual bitrate,
 * And the error.  Since we're all integers, we have to calculate
 * the tenths part of the error separately.
 */
//BAUD_ACTUAL=$(( ($fcpu/(8 * (($BAUD_SETTING)+1))) ))

 #endif
// $ECHO_CMD baud setting = $BAUD_SETTING

/*
 * Print a nice message containing the info we've calculated
 */
 #if BAUD_RATE > 10000
$ECHO_CMD "BAUD RATE CHECK: Desired: $bps,  Real: `$ECHO_CMD "scale=0;($fcpu / $UartDelay)" | $BC_CMD`, UBRR = $BAUD_SETTING, Error=`$ECHO_CMD "scale=2;(100*(($fcpu / $UartDelay) - $bps) ) / $bps"| $BC_CMD`\%"
 #elif BAUD_RATE > 1000
$ECHO_CMD "BAUD RATE CHECK: Desired: $bps,  Real: `$ECHO_CMD "scale=1;($fcpu / $UartDelay)" | $BC_CMD`, UBRR = $BAUD_SETTING, Error=`$ECHO_CMD "scale=2;(100*(($fcpu / $UartDelay) - $bps) ) / $bps"| $BC_CMD`\%"
 #else
$ECHO_CMD "BAUD RATE CHECK: Desired: $bps,  Real: `$ECHO_CMD "scale=2;($fcpu / $UartDelay)" | $BC_CMD`, UBRR = $BAUD_SETTING, Error=`$ECHO_CMD "scale=2;(100*(($fcpu / $UartDelay) - $bps) ) / $bps"| $BC_CMD`\%"
 #endif
#endif	/* SOFT_UART */
#endif	/* BAUD_RATE < 100 */
$ECHO_CMD --------------------------------------------------------------------------------



