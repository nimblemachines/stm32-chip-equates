# Preprocess ST Micro C include (.h) files into Forth.

# Originally used the StdPeriph_Lib sources, then used STM32Cube; now
# downloading tar archives of "live" master branches from GitHub!

# We are initially targeting a handful of the STM32 Discovery boards, and also
# the F103 chip that ST uses to power the ST-LINK USB debug interface.

# ST-LINK and Blue Pill chip is an STM32F103C8T6; use stm32f103xb.h
# GigaDevice GD32VF103 matches STM32F105xC!

#                  F0 disco    F072B disco    ST-LINK      GD32VF103
HFILES=		stm32f051x8.h stm32f072xb.h stm32f103xb.h stm32f105xc.h
#                  F303 disco    F4 disco
HFILES+=	stm32f303xc.h stm32f407xx.h
#		 C031 nucleo
HFILES+=	stm32c031xx.h

# After doing "make download", dig around in the cmsis_device_*/Include
# directories to find the .h files you are interested in, and add them here!
#HFILES+=

# Path to your Lua 5.3 or later executable
LUA=	lua

# Path to "install" .mu4 files. This should be a "muforth" directory.
MU_INSTALL_DIR=	$(HOME)/muforth

MUFILES=	$(HFILES:.h=.mu4)

DESTUPIDIFY=	(tr -d '\r' | sed -f destupidify.sed)

all : $(MUFILES)

hfiles : $(HFILES)

.PHONY: clean download download-clean distclean muforth-install show-muforth-install

clean :
	rm -f *.h *.mu4

distclean : clean download-clean

# Damn! Having trouble getting make + sh to do what I want, so I'm going to
# use Lua to generate a series of commands that the shell can execute!
muforth-install : $(MUFILES)
	$(LUA) gen-install.lua $(MU_INSTALL_DIR) $(MUFILES) | sh

# Print out the commands, but don't do anything.
show-muforth-install : $(MUFILES)
	$(LUA) gen-install.lua $(MU_INSTALL_DIR) $(MUFILES)

$(HFILES) : destupidify.sed

$(HFILES) $(MUFILES) : Makefile

$(MUFILES) : c2forth.lua

### Using live github sources!

download :
	for family in c0 g0 f0 f1 f3 f4 ; do \
		curl -L https://github.com/STMicroelectronics/cmsis_device_$$family/archive/refs/heads/master.tar.gz \
		| tar xzf - ; done

download-clean :
	rm -rf cmsis*

# NOTE! ST occasionally renames these directories! If make fails to find some
# .h files, make sure that these directories match the *actual* directories
# that "make download" creates!
#
# Note the lame and arbitrary mix of hyphens and underscores!!
#
# To make this automatic, let's use Make's wildcard function to find the
# *actual* directory name for each subfamily.

%.h : $(wildcard cmsis*c0*)/Include/%.h
	$(DESTUPIDIFY) < $< > $@

%.h : $(wildcard cmsis*g0*)/Include/%.h
	$(DESTUPIDIFY) < $< > $@

%.h : $(wildcard cmsis*f0*)/Include/%.h
	$(DESTUPIDIFY) < $< > $@

%.h : $(wildcard cmsis*f1*)/Include/%.h
	$(DESTUPIDIFY) < $< > $@

%.h : $(wildcard cmsis*f3*)/Include/%.h
	$(DESTUPIDIFY) < $< > $@

%.h : $(wildcard cmsis*f4*)/Include/%.h
	$(DESTUPIDIFY) < $< > $@

%.mu4 : %.h
	$(LUA) c2forth.lua $< $(wildcard cmsis*/Include/$<) > $@
