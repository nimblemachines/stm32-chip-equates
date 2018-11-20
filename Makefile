# Preprocess for a particular target chip
# Use *that* file as the source for the conversion via Lua.

cpp=	cpp -fdirectives-only -P -nostdinc -I fake_include/ -DDELETE_ME

HFILES=		stm32f0xx.h stm32f30x.h stm32f4xx.h stm32l1xx.h
MUFILES=	$(HFILES:.h=.mu4)

all : stm32l1xx.mu4

clean :
	rm -f $(HFILES) $(MUFILES)

$(HFILES) $(MUFILES) : Makefile

stm32f0xx.h : STM32F0xx_StdPeriph_Lib_V1.5.0/Libraries/CMSIS/Device/ST/STM32F0xx/Include/stm32f0xx.h
	$(cpp) $< | sed -e '1,/DELETE_ME/d' > $@


stm32f30x.h : STM32F30x_DSP_StdPeriph_Lib_V1.2.3/Libraries/CMSIS/Device/ST/STM32F30x/Include/stm32f30x.h
	$(cpp) $< | sed -e '1,/DELETE_ME/d' > $@

stm32f4xx.h : STM32F4xx_DSP_StdPeriph_Lib_V1.8.0/Libraries/CMSIS/Device/ST/STM32F4xx/Include/stm32f4xx.h
	$(cpp) $< | sed -e '1,/DELETE_ME/d' > $@

stm32l1xx.h : STM32L1xx_StdPeriph_Lib_V1.3.1/Libraries/CMSIS/Device/ST/STM32L1xx/Include/stm32l1xx.h
	$(cpp) -DSTM32L1XX_MD $< | sed -e '1,/DELETE_ME/d' > $@

%.mu4 : %.h
	lua c2forth.lua $< > $@
