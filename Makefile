# Preprocess ST StdPeriph library files into Forth.

cpp=	cpp -fdirectives-only -P -nostdinc -I fake_include/ -DDELETE_ME

HFILES=		stm32f0xx.h stm32f30x.h stm32f4xx.h stm32l1xx.h
MUFILES=	$(HFILES:.h=.mu4)

all : stm32f0xx.mu4 stm32f30x.mu4 stm32f4xx.mu4 stm32l1xx.mu4

clean :
	rm -f $(HFILES) $(MUFILES)

$(HFILES) $(MUFILES) : Makefile

$(MUFILES) : c2forth.lua

stm32f0xx.h : STM32F0xx_StdPeriph_Lib_V1.5.0/Libraries/CMSIS/Device/ST/STM32F0xx/Include/stm32f0xx.h
	$(cpp) -DSTM32F051 $< | sed -e '1,/DELETE_ME/d' > $@

stm32f30x.h : STM32F30x_DSP_StdPeriph_Lib_V1.2.3/Libraries/CMSIS/Device/ST/STM32F30x/Include/stm32f30x.h
	$(cpp) -DSTM32F303xC $< | sed -e '1,/DELETE_ME/d' > $@

stm32f4xx.h : STM32F4xx_DSP_StdPeriph_Lib_V1.8.0/Libraries/CMSIS/Device/ST/STM32F4xx/Include/stm32f4xx.h
	$(cpp) -DSTM32F40_41xxx $< | sed -e '1,/DELETE_ME/d' > $@

stm32l1xx.h : STM32L1xx_StdPeriph_Lib_V1.3.1/Libraries/CMSIS/Device/ST/STM32L1xx/Include/stm32l1xx.h
	$(cpp) -DSTM32L1XX_MD $< | sed -e '1,/DELETE_ME/d' > $@

%.mu4 : %.h
	lua c2forth.lua $< > $@
