This repo contains chip equates downloaded and extracted from [ST's "standard
peripheral library" zip archives](https://www.st.com/content/st_com/en/products/embedded-software/mcus-embedded-software/stm32-embedded-software/stm32-standard-peripheral-libraries.html).

I only unzip'd the <chip>/CMSIS/Include/ and <chip>/CMSIS/Device/Include/
directories. There is a lot of documentation, sample code, and (binary)
libraries in there as well. Each type (F0, F3, F4, L1) was a 75 MB zip file!

Using CPP and Lua I hope to transform these into useful muforth equates.
