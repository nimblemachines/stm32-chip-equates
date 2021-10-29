# Intro

Let's try to take ST's C sources (well, the `.h` files anyway) and turn them
into Forth.

Previously I had been downloading various [STM32Cube zip
files](https://www.st.com/en/embedded-software/stm32cube-mcu-packages.html)
and pulling the `.h` files out of these. This is awkward and some of the zip
files were quite large.

ST has recently decided to modularize their code. Now it is possible to
download (much smaller) archives of the `.h` and `.s` startup files separately
from the C library files. Everything is on GitHub now, and the Makefile will
download and untar the appropriate files.

# How to use it

You will need a relatively recent copy of
[Lua](https://www.lua.org/download.html). It's super easy to build. I like to
install it in my `$HOME` directory.

Once you have Lua installed, just do this:

```sh
make download
make
```

to download ST's source files from GitHub and then process them into
(hopefully useful) [muforth](https://muforth.nimblemachines.com/) source files.

Right now the Makefile by default only processes a small subset of the files;
approximately corresponding to a handful of the Discovery boards. If you have
a chip that is not in the list, just add its `.h` file to the `HFILES`
variable; the corresponding `.mu4` file will be made automagically.

I have recently turned off generation of the bitfields. Right now only the
interrupt vectors and I/O register addresses are generated. Once I figure out
how I want to deal with the bitfields I will turn that code back on. Feel free
to play around with it, if you like!

# Mistakes?

ST used nested typedefs in a few places (`CAN_TypeDef`, in particular), and
used them in such a way that the resulting register names had no relation to
the names in the reference manual, or in the bit field definitions that follow
the typedefs in the .h file. This seems really stupid. The nested typedefs are
also harder to parse.

My solution? Using `sed`, of course! I have a sed script - provocatively called
`destupidify.sed` - that flattens the nested (and broken) typedefs, using the
register names from the reference manual. This is an improvement for C
programmers too!

The Makefile will process the .h file from one of the `cmsis_device_*-master`
directories, remove the `\r` characters, destupidify it, and create a fixed
version of the file in the root directory. These are the inputs to
`c2forth.lua`, which then generates the corresponding `.mu4` file.

It seems like the comments (with offsets) for the OB typedef in the F103 are
wrong. But the offsets (that I calculated from the types in the typedef) match
several of the other parts! Go figure.

# TODO

* Print the register bit fields directly after the register that they apply to?
  This is tricky, and it also clutters up the display of the register
  addresses.
* The `HRTIM` definitions are still broken and need to be fixed. If we are ever
  interested in the STM32F334, that is.
