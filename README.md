# Intro

Let's try to take ST's C sources (well, the .h files anyway) and turn them into
Forth.

We are now using the [STM32Cube zip
files](https://www.st.com/en/embedded-software/stm32cube-mcu-packages.html).
The ["standard peripheral library" zip
archives](https://www.st.com/content/st_com/en/products/embedded-software/mcus-embedded-software/stm32-embedded-software/stm32-standard-peripheral-libraries.html)
have been deprecated.

I unzip'd only the <chip>/CMSIS/Device/Include/ directories. There is a lot of
documentation, sample code, and (binary) libraries in there as well.

Using Lua I hope to transform these into useful muforth equates.

# TODO

Nested typedefs break things. CAN andd HRTIM are the major culprits. The
typedef code needs to be smarter about several things. It needs to:

* record its size after its fields have been defined

* when a "register" is really an array, it should create several named
  registers, instead of one that points to the beginning. (How to deal with
  RESERVEDx?)

* when a "register" is a sub-typedef, the sub-typedef needs to get instantiated
  recursively - and if it is an array, several times.

# Mistakes?

It seems like the comments (with offsets) for the OB typedef in the F103 is
wrong. But the offsets (that I calculated from the types in the typedef) match
several of the other parts! Go figure.

The TIM typedef in the STM32F303 .h file was wrong in the "standard peripheral
lib" version. That has been fixed in the STM32Cube version.
