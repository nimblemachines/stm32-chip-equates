-- Impossible task of parsing chip .h files and trying to generate
-- Forth-style equates from them.

fmt = string.format

-- Special edits file contents to make things easier later. See NOTES for
-- explanation(s).
function special(f)
    -- HRTIM_TypeDef *     => HRTIM_Master_TypeDef *
    -- HRTIM_TIM_TypeDef * => HRTIM_Timerx_TypeDef *
    f = f:gsub("HRTIM_TypeDef %*", "HRTIM_Master_TypeDef *")
         :gsub("HRTIM_TIM_TypeDef %*", "HRTIM_Timerx_TypeDef *")
    return f
end

function hex(s)
    return tonumber(s, 16)
end

function prettify_comment(c)
    c = c:gsub("^%s+$", "")
         :gsub("%s*/%*!?<?%s*(..-)%s*%*/", "| %1")

    return c
end

-- XXX ST defines the Cortex-M vectors with negative vector indices. Do we
-- want to keep it this way? Or start the chip-specific ones at 16 instead
-- of 0?
function exceptions(f)
    local exc = {}
    local guts = f:match "typedef enum(..-)IRQn_Type;"
    if guts then
        for name, vector, comment in guts:gmatch "([%w_]+)_IRQn%s*=%s*(%-?%d+),(.-)\n" do
            comment = prettify_comment(comment)
            --print(fmt("%s %d %s", name, tonumber(vector), comment))
            exc[#exc+1] = { name = name, vector = vector, comment = comment }
        end
    else
        print("Hmm. No IRQn_Type was found.")
    end
    return exc
end

function typedefs(f)
    local periphs = {}
    for guts, name in f:gmatch "typedef struct(..-)([%w_]+)_TypeDef;" do
        local fixedguts = guts:gsub("/%*!<([^*]-) *\n *(.-) *(Address.-)%*/", "/*!<%1 %2 %3*/")
        --print(fmt("%s: %s: %s", name, guts, fixedguts))
        local regs = {}
        periphs[name] = regs
        local offset = 0
        for bits, name, comment in fixedguts:gmatch "uint(%d+)_t%s*(%S+);(.-)\n" do
            comment = prettify_comment(comment)
            --print(fmt("%x %s %s", offset, name, comment))
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
    -- Match bare hex value, with or without enclosing parens
    local value = e:match "%(?0x(%x+)U?%)?"
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

function vectors(exc)
    print("\n( Vectors)\ndecimal")
    for _, e in ipairs(exc) do
        print(fmt("%3d vector %-20s %s", e.vector, e.name, e.comment))
    end
    print("hex")
end

function instantiate(f, base, periphs)
    for pname, ptype, pbase in f:gmatch
        "#define%s+([%w_]+)%s+%(%(([%w_]+)_TypeDef %*%)%s*([%w_]+)%)" do
        print()
        --print(fmt("instantiate: %s %s %s", pname, ptype, pbase))
        for _, r in ipairs(periphs[ptype]) do
            print(fmt("%s equ %-20s %s", muhex(r.offset + base[pbase]), pname .. "." .. r.name, r.comment))
        end
    end
end

function read_file(fname)
    local f = io.open(fname, "r")
    if f then
        local contents = f:read "a"
        f:close()
        -- If we are given CRLF line endings, change to LF only
        return contents:gsub("\r\n", "\n")
    end
end

function doit()
    local f = special(read_file(arg[1]))
    local exc = exceptions(f)
    local periphs = typedefs(f)
    local base = base_addrs(f)
    print(fmt("( Chip equates for %s)", arg[1]:match "^[%w]+"))
    vectors(exc)
    instantiate(f, base, periphs)
end

doit()
