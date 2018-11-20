# Intro

This repo contains chip equates downloaded and extracted from [ST's "standard
peripheral library" zip archives](https://www.st.com/content/st_com/en/products/embedded-software/mcus-embedded-software/stm32-embedded-software/stm32-standard-peripheral-libraries.html).

I only unzip'd the <chip>/CMSIS/Include/ and <chip>/CMSIS/Device/Include/
directories. There is a lot of documentation, sample code, and (binary)
libraries in there as well. Each type (F0, F3, F4, L1) was a 75 MB zip file!

Using CPP and Lua I hope to transform these into useful muforth equates.

# TODO

Nested typedefs break things. CAN andd HRTIM are the major culprits. The
typedef code needs to be smarter about several things. It needs to:

* record its size after its fields have been defined

* when a "register" is really an array, it should create several named
  registers, instead of one that points to the beginning. (How to deal with
  RESERVEDx?)

* when a "register" is a sub-typedef, the sub-typedef needs to get instantiated
  recursively - and if it is an array, several times.

Also might be worth trying the STM32FxCube stuff to see what's there.

# Mistakes?

It seems like the typedef for TIM in the STM32F303 .h file is wrong. There
should be a uint16_t of padding item before the CCMR3. Their comment suggests
that this should be the case, but it's missing from the typedef!
