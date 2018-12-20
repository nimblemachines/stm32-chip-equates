# Preprocess ST Micro C include (.h) files into Forth.

# Originally used the StdPeriph_Lib sources; now using STM32Cube instead.

# We are initially targeting a handful of the STM32 Discovery boards, and also
# the F103 chip that ST uses to power the ST-LINK USB debug interface.

# ST-LINK chip is an STM32F103C8T6; use stm32f103xb.h

#                  F0 disco       ST-LINK    F303 disco      F4 disco    32L disco
HFILES=		stm32f051x8.h stm32f103xb.h stm32f303xc.h stm32f407xx.h stm32l152xb.h

MUFILES=	$(HFILES:.h=.mu4)

DESTUPIDIFY=	sed -f destupidify.sed

all : $(MUFILES)

hfiles : $(HFILES)

clean :
	rm -f $(HFILES) $(MUFILES)

$(HFILES) : destupidify.sed

$(HFILES) $(MUFILES) : Makefile

$(MUFILES) : c2forth.lua

### StdPeriph_Lib sources deprecated

cpp=	cpp -fdirectives-only -P -nostdinc -I fake_include/ -DDELETE_ME

stm32f0xx.h : STM32F0xx_StdPeriph_Lib_V1.5.0/Libraries/CMSIS/Device/ST/STM32F0xx/Include/stm32f0xx.h
	$(cpp) -DSTM32F051 $< | sed -e '1,/DELETE_ME/d' > $@

stm32f30x.h : STM32F30x_DSP_StdPeriph_Lib_V1.2.3/Libraries/CMSIS/Device/ST/STM32F30x/Include/stm32f30x.h
	$(cpp) -DSTM32F303xC $< | sed -e '1,/DELETE_ME/d' > $@

stm32f4xx.h : STM32F4xx_DSP_StdPeriph_Lib_V1.8.0/Libraries/CMSIS/Device/ST/STM32F4xx/Include/stm32f4xx.h
	$(cpp) -DSTM32F40_41xxx $< | sed -e '1,/DELETE_ME/d' > $@

stm32l1xx.h : STM32L1xx_StdPeriph_Lib_V1.3.1/Libraries/CMSIS/Device/ST/STM32L1xx/Include/stm32l1xx.h
	$(cpp) -DSTM32L1XX_MD $< | sed -e '1,/DELETE_ME/d' > $@

### Using STM32Cube instead

# For re-programming the ST-LINK?
stm32f103xb.h : STM32Cube_FW_F1_V1.6.0/Drivers/CMSIS/Device/ST/STM32F1xx/Include/stm32f103xb.h
	$(DESTUPIDIFY) < $< > $@

# STMF0 Discovery
stm32f051x8.h : STM32Cube_FW_F0_V1.9.0/Drivers/CMSIS/Device/ST/STM32F0xx/Include/stm32f051x8.h
	$(DESTUPIDIFY) < $< > $@

# STMF303 Discovery
stm32f303xc.h : STM32Cube_FW_F3_V1.10.0/Drivers/CMSIS/Device/ST/STM32F3xx/Include/stm32f303xc.h
	$(DESTUPIDIFY) < $< > $@

# STMF4 Discovery
stm32f407xx.h : STM32Cube_FW_F4_V1.21.0/Drivers/CMSIS/Device/ST/STM32F4xx/Include/stm32f407xx.h
	$(DESTUPIDIFY) < $< > $@

# STM32L Discovery
stm32l152xb.h : STM32Cube_FW_L1_V1.8.0/Drivers/CMSIS/Device/ST/STM32L1xx/Include/stm32l152xb.h
	$(DESTUPIDIFY) < $< > $@

%.mu4 : %.h
	lua c2forth.lua $< > $@
