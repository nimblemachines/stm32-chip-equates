-- Impossible task of reading chip .h file and trying to generate
-- Forth-style equates.

-- Let's tackle the typedefs for each peripheral first.

foo = [[
#define FLASH_BASE            ((uint32_t)0x08000000) /*!< FLASH base address in the alias region */
#define SRAM_BASE             ((uint32_t)0x20000000) /*!< SRAM base address in the alias region */
#define PERIPH_BASE           ((uint32_t)0x40000000) /*!< Peripheral base address in the alias region */

#define SRAM_BB_BASE          ((uint32_t)0x22000000) /*!< SRAM base address in the bit-band region */
#define PERIPH_BB_BASE        ((uint32_t)0x42000000) /*!< Peripheral base address in the bit-band region */

#define FSMC_R_BASE           ((uint32_t)0xA0000000) /*!< FSMC registers base address */

/*!< Peripheral memory map */
#define APB1PERIPH_BASE       PERIPH_BASE
#define APB2PERIPH_BASE       (PERIPH_BASE + 0x10000)
#define AHBPERIPH_BASE        (PERIPH_BASE + 0x20000)

#define TIM2_BASE             (APB1PERIPH_BASE + 0x0000)
#define TIM3_BASE             (APB1PERIPH_BASE + 0x0400)
#define TIM4_BASE             (APB1PERIPH_BASE + 0x0800)
#define TIM5_BASE             (APB1PERIPH_BASE + 0x0C00)
#define TIM6_BASE             (APB1PERIPH_BASE + 0x1000)
#define TIM7_BASE             (APB1PERIPH_BASE + 0x1400)
#define LCD_BASE              (APB1PERIPH_BASE + 0x2400)
#define RTC_BASE              (APB1PERIPH_BASE + 0x2800)
#define WWDG_BASE             (APB1PERIPH_BASE + 0x2C00)
#define IWDG_BASE             (APB1PERIPH_BASE + 0x3000)
#define SPI2_BASE             (APB1PERIPH_BASE + 0x3800)
#define SPI3_BASE             (APB1PERIPH_BASE + 0x3C00)
#define USART2_BASE           (APB1PERIPH_BASE + 0x4400)
#define USART3_BASE           (APB1PERIPH_BASE + 0x4800)
#define UART4_BASE            (APB1PERIPH_BASE + 0x4C00)
#define UART5_BASE            (APB1PERIPH_BASE + 0x5000)
#define I2C1_BASE             (APB1PERIPH_BASE + 0x5400)
#define I2C2_BASE             (APB1PERIPH_BASE + 0x5800)
#define PWR_BASE              (APB1PERIPH_BASE + 0x7000)
#define DAC_BASE              (APB1PERIPH_BASE + 0x7400)
#define COMP_BASE             (APB1PERIPH_BASE + 0x7C00)
#define RI_BASE               (APB1PERIPH_BASE + 0x7C04)
#define OPAMP_BASE            (APB1PERIPH_BASE + 0x7C5C)

#define SYSCFG_BASE           (APB2PERIPH_BASE + 0x0000)
#define EXTI_BASE             (APB2PERIPH_BASE + 0x0400)
#define TIM9_BASE             (APB2PERIPH_BASE + 0x0800)
#define TIM10_BASE            (APB2PERIPH_BASE + 0x0C00)
#define TIM11_BASE            (APB2PERIPH_BASE + 0x1000)
#define ADC1_BASE             (APB2PERIPH_BASE + 0x2400)
#define ADC_BASE              (APB2PERIPH_BASE + 0x2700)
#define SDIO_BASE             (APB2PERIPH_BASE + 0x2C00)
#define SPI1_BASE             (APB2PERIPH_BASE + 0x3000)
#define USART1_BASE           (APB2PERIPH_BASE + 0x3800)

#define GPIOA_BASE            (AHBPERIPH_BASE + 0x0000)
#define GPIOB_BASE            (AHBPERIPH_BASE + 0x0400)
#define GPIOC_BASE            (AHBPERIPH_BASE + 0x0800)
#define GPIOD_BASE            (AHBPERIPH_BASE + 0x0C00)
#define GPIOE_BASE            (AHBPERIPH_BASE + 0x1000)
#define GPIOH_BASE            (AHBPERIPH_BASE + 0x1400)
#define GPIOF_BASE            (AHBPERIPH_BASE + 0x1800)
#define GPIOG_BASE            (AHBPERIPH_BASE + 0x1C00)
#define CRC_BASE              (AHBPERIPH_BASE + 0x3000)
#define RCC_BASE              (AHBPERIPH_BASE + 0x3800)


#define FLASH_R_BASE          (AHBPERIPH_BASE + 0x3C00) /*!< FLASH registers base address */
#define OB_BASE               ((uint32_t)0x1FF80000)    /*!< FLASH Option Bytes base address */

#define DMA1_BASE             (AHBPERIPH_BASE + 0x6000)
#define DMA1_Channel1_BASE    (DMA1_BASE + 0x0008)
#define DMA1_Channel2_BASE    (DMA1_BASE + 0x001C)
#define DMA1_Channel3_BASE    (DMA1_BASE + 0x0030)
#define DMA1_Channel4_BASE    (DMA1_BASE + 0x0044)
]]

fmt = string.format

function hex(s)
    return tonumber(s, 16)
end

-- Be careful with matching! Line ending seem to be CRLF, not just bare LF.
-- So \n won't match a line-ending!
function typedefs(f)
    local periphs = {}
    for guts, name in f:gmatch("typedef struct(..-)([%w_]+)_TypeDef;") do
        -- print(fmt("%s: %s", name, guts))
        local regs = {}
        periphs[name] = regs
        local offset = 0
        for bits, name, comment in guts:gmatch "uint(%d+)_t%s*(%S+);%s*/%*!<(..-)%*/" do
            --print(fmt("%x %s | %s", offset, name, comment))
            local reg = { name = name, offset = offset, comment = comment }
            array = name:match "%[(%d+)%]"
            if array then
                offset = offset + (tonumber(array) * tonumber(bits)/8)
                -- Remove array part from name
                reg.name = reg.name:gsub("%[%d+%]", "")
            else
                offset = offset + tonumber(bits)/8
            end
            if name:match "RESERVED" then
                reg = nil
            else
                regs[#regs+1] = reg
            end
        end
    end
    return periphs
end

function eval(base, e)
    e = e:gsub("%(%s*uint32_t%s*%)", "")
    -- Match basename + offset
    local b, offset = e:match "([%w_]+_BASE) %+ 0x(%x+)"
    if b then
       return base[b] + hex(offset)
    end
    -- Match bare basename
    b = e:match "([%w_]+_BASE)"
    if b then
        return base[b]
    end
    -- Match bare hex value
    local value = e:match "%(0x(%x+)%)"
    if value then
        return hex(value)
    end
    print(fmt("Hmm. Couldn't eval %s", e))
end

function base_addrs(f)
    local base = {}
    for p, expr in f:gmatch "#define%s+([%w_]+_BASE)%s+(..-)\n" do
        --print(p, expr)
        base[p] = eval(base, expr)
        --print(fmt("%s %x", p, base[p]))
    end
    return base
end

function muhex(num)
    return fmt("%04x_%04x", num >> 16, num % (2^16))
end

function instantiate(f, base, periphs)
    for pname, ptype, pbase in f:gmatch
        "#define%s+([%w_]+)%s+%(%(([%w_]+)_TypeDef %*%)%s+([%w_]+)%)" do
        print()
        for _, r in ipairs(periphs[ptype]) do
            --print(fmt("%08x equ %-20s |%s", r.offset + base[pbase], pname .. "." .. r.name, r.comment))
            print(fmt("%s equ %-20s |%s", muhex(r.offset + base[pbase]), pname .. "." .. r.name, r.comment))
        end
    end
end

function read_file(fname)
    local f = io.open(fname, "r")
    if f then
        local contents = f:read "a"
        f:close()
        return contents
    end
end

function doit()
    local f = read_file(arg[1])
    local periphs = typedefs(f)
    local base = base_addrs(f)
    print(fmt("( Chip equates for %s)", arg[1]:match "^[%w]+"))
    instantiate(f, base, periphs)
end

doit()

