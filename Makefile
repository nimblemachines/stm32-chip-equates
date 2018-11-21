# Preprocess ST StdPeriph library files into Forth.

# ST-LINK chip is an STM32F103C8T6; use stm32f103xb.h

cpp=	cpp -fdirectives-only -P -nostdinc -I fake_include/ -DDELETE_ME

#                  F0 disco       ST-LINK    F303 disco      F4 disco    32L disco
HFILES=		stm32f051x8.h stm32f103xb.h stm32f303xc.h stm32f407xx.h stm32l152xb.h

MUFILES=	$(HFILES:.h=.mu4)

all : $(MUFILES)

clean :
	rm -f $(HFILES) $(MUFILES)

$(HFILES) $(MUFILES) : Makefile

$(MUFILES) : c2forth.lua

### StdPeriph sources deprecated

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
	cp $< $@

# STMF0 Discovery
stm32f051x8.h : STM32Cube_FW_F0_V1.9.0/Drivers/CMSIS/Device/ST/STM32F0xx/Include/stm32f051x8.h
	cp $< $@

# STMF303 Discovery
stm32f303xc.h : STM32Cube_FW_F3_V1.10.0/Drivers/CMSIS/Device/ST/STM32F3xx/Include/stm32f303xc.h
	cp $< $@

# STMF4 Discovery
stm32f407xx.h : STM32Cube_FW_F4_V1.21.0/Drivers/CMSIS/Device/ST/STM32F4xx/Include/stm32f407xx.h
	cp $< $@

# STM32L Discovery
stm32l152xb.h : STM32Cube_FW_L1_V1.8.0/Drivers/CMSIS/Device/ST/STM32L1xx/Include/stm32l152xb.h
	cp $< $@

%.mu4 : %.h
	lua c2forth.lua $< > $@
