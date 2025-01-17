# Preprocess ST Micro C include (.h) files into Forth.

# Originally used the StdPeriph_Lib sources, then used STM32Cube; now
# downloading tar archives of "live" master branches from GitHub!

# We are initially targeting a handful of the STM32 Discovery boards, and also
# the F103 chip that ST uses to power the ST-LINK USB debug interface.

# ST-LINK and Blue Pill chip is an STM32F103C8T6; use stm32f103xb.h
# GigaDevice GD32VF103 matches STM32F105xC!

#                F0 disco    F072B disco    ST-LINK     GD32VF103
CHIPS=		stm32f051x8  stm32f072xb  stm32f103xb  stm32f105xc
#               F303 disco   F4 disco (1) F4 disco (1)
CHIPS+=		stm32f303xc  stm32f407xx  stm32f411xe
#		C031 nucleo  C071 nucleo
CHIPS+=		stm32c031xx  stm32c071xx
#		H533 nucleo  H503 nucleo
CHIPS+=		stm32h533xx  stm32h503xx

# After doing "make download", dig around in the cmsis_device_*/Include
# directories to find the chips you are interested in, and add them here!
#CHIPS+=

# Path to your Lua 5.3 or later executable
LUA=	lua

# Path to "install" .mu4 files. This should be a "muforth" directory.
MU_INSTALL_DIR=	$(HOME)/muforth

MU4_FILES=	$(patsubst %,%.mu4,$(CHIPS))

DESTUPIDIFY=	(tr -d '\r' | sed -f destupidify.sed)

all : $(MU4_FILES)

.PHONY: download muforth-install show-muforth-install

# Damn! Having trouble getting make + sh to do what I want, so I'm going to
# use Lua to generate a series of commands that the shell can execute!
muforth-install : $(MU4_FILES)
	$(LUA) gen-install.lua $(MU_INSTALL_DIR) $(MU4_FILES) | sh

# Print out the commands, but don't do anything.
show-muforth-install : $(MU4_FILES)
	$(LUA) gen-install.lua $(MU_INSTALL_DIR) $(MU4_FILES)

### Using live github sources!

download :
	for family in c0 g0 g4 f0 f1 f3 f4 h5 ; do \
		curl -L https://github.com/STMicroelectronics/cmsis_device_$$family/archive/refs/heads/master.tar.gz \
		| tar xzf - ; done

$(MU4_FILES) : c2forth.lua destupidify.sed Makefile
	$(DESTUPIDIFY) < $(wildcard cmsis*/Include/$(@:.mu4=.h)) > $(@:.mu4=.h)
	$(LUA) c2forth.lua $(@:.mu4=.h) $(wildcard cmsis*/Include/$(@:.mu4=.h)) > $@

# Cleaning up

.PHONY: clean download-clean distclean

clean :
	rm -f *.h *.mu4

download-clean :
	rm -rf cmsis*

distclean : clean download-clean
