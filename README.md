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

# Mistakes?

ST used nested typedefs in a few places (`CAN_TypeDef`, in particular), and
used them in such a way that the resulting register names had no relation to
the names in the reference manual, or in the bit field definitions that follow
the typedefs in the .h file. This seems really stupid. The nested typedefs are
also harder to parse.

My solution? Using `sed`, of course! I have a sed script - provocatively called
`destupidify.sed` - that flattens the nested (and broken) typedefs, using the
register names from the reference manual. This is an improvement for C
programmers too! The Makefile will process the .h file from one of the
STM32Cube directories, remove the `\r` characters, destupidify it, and create a
fixed version of the file in the root directory. These are the inputs to
`c2forth.lua`, which then generates the corresponding `.mu4` file.

It seems like the comments (with offsets) for the OB typedef in the F103 are
wrong. But the offsets (that I calculated from the types in the typedef) match
several of the other parts! Go figure.

The TIM typedef in the STM32F303 .h file was wrong in the "standard peripheral
lib" version. That has been fixed in the STM32Cube version.

# TODO

* Print the register bit fields directly after the register that they apply to?
  This is tricky, and it also clutters up the display of the register
  addresses.
* The `HRTIM` definitions are still broken and need to be fixed. If we are ever
  interested in the STM32F334, that is.
