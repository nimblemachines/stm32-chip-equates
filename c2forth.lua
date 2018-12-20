-- Impossible task of parsing chip .h files and trying to generate
-- Forth-style equates from them.

fmt = string.format

function logger(prefix)
    return function(s)
        io.stderr:write(fmt("%s: %s\n", prefix, s))
    end
end

warn  = logger "Warning"
debug = logger "Debug"

function out(s)
    io.stdout:write(s .. "\n")
end

-- fixes() changes file contents to make things easier later. See NOTES for
-- explanation(s).
function fixes(f)
    f = f:gsub("HRTIM_TypeDef %*", "HRTIM_Master_TypeDef *")
         :gsub("HRTIM_TIM_TypeDef %*", "HRTIM_Timerx_TypeDef *")
         :gsub("(uint32_t FR2;%s*/%*!< CAN Filter bank register )(1)( %*/)", "%12%3")
    return f
end

function hex(s)
    return tonumber(s, 16)
end

function prettify_comment(c)
    c = c:gsub("^%s+$", "")
         :gsub("%s+", " ")
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
            --debug(fmt("%s %d %s", name, tonumber(vector), comment))
            exc[#exc+1] = { name = name, vector = vector, comment = comment }
        end
    else
        warn("Hmm. No IRQn_Type was found.")
    end
    return exc
end

function typedefs(f)
    local periphs = {}
    for guts, name in f:gmatch "typedef struct(..-)([%w_]+)_TypeDef;" do
        local fixedguts = guts:gsub("/%*!<([^*]-) *\n *(.-) *(Address.-)%*/", "/*!<%1 %2 %3*/")
        --debug(fmt("%s: %s: %s", name, guts, fixedguts))
        local regs = {}
        periphs[name] = regs
        local offset = 0
        for ctype, name, comment in fixedguts:gmatch "([%w_]+)%s+(%S+);(.-)\n" do
            comment = prettify_comment(comment)
            --debug(fmt("%x %s %s", offset, name, comment))
            local reg = { name = name, offset = offset, comment = comment }
            local size = 4  -- sanity
            local bits = ctype:match "uint(%d+)_t"
            if bits then
                size = tonumber(bits)/8
            else
                local struct = ctype:match "(.+)_TypeDef"
                if struct then
                    size = periphs[struct].size
                    reg.struct = periphs[struct]
                else
                    warn("Hmm. Couldn't figure out size of %s", name)
                end
            end

            local array = name:match "%[(%d+)%]"
            if array then
                array = tonumber(array)
                reg.array = array   -- number of entries in array
                reg.size = size     -- size of each
                reg.name = reg.name:gsub("%[(%d+)%]", "")
                offset = offset + (array * size)
            else
                offset = offset + size
            end
            if name:match "RESERVED" then
                -- Tell GC to throw it away
                reg = nil
            else
                regs[#regs+1] = reg
            end
        end
        periphs[name].size = offset
    end
    return periphs
end

-- Match _Pos, _Msk, and comment separately?
function bitfields(f)
    local fields = {}           -- array of fields
    local fields_by_name = {}   -- table indexed by field name
    local eval = function(name, expr)
        local pos = expr:match "^%d+$"      -- bare number
        if pos then
            return true, pos
        end
        local prev
        prev, pos = expr:match "([%w_]+)_Pos%s+%+%s+(%d+)"
        if prev then
            if fields_by_name[prev] and fields_by_name[prev].pos then
                return true, fields_by_name[prev].pos + pos
            end
            warn(fmt("Ignoring %s which depends on undefined bitfield %s!",
                name, prev))
                return false, 0
        end
        warn(fmt("Hmm. Can't eval %s", expr))
        return false, 0
    end

    -- Find bare shifted masks/values. Do this first! We define them as
    -- "equates" rather than fields. Sometimes the value is 0000_0000 !!
    for name, mask, comment in f:gmatch "([%w_]+)%s+%((0x%x+)U%)%s+(/%*!<.-%*/)" do
        comment = prettify_comment(comment)
        --debug(fmt("bare: %s %08x %s", name, mask, comment))
        local field = { name = name, equ = mask, comment = comment }
        fields_by_name[name] = field
        fields[#fields+1] = field
    end
    -- Find positions
    for name, expr in f:gmatch "([%w_]+)_Pos%s+%((.-%d+)U%)" do
        local ok, pos = eval(name, expr)
        if ok then
            --debug(fmt("%s %s %d", name, expr, pos))
            if fields_by_name[name] then
                warn(fmt("Skipping redefinition of bitfield %s with pos %d", name, pos))
            else
                local field = { name = name, pos = pos }
                fields_by_name[name] = field
                fields[#fields+1] = field
            end
        end
    end
    -- Find masks
    for name, mask in f:gmatch "([%w_]+)_Msk%s+%((0x%x+)U" do
        --debug(fmt("%s %s", name, mask))
        if fields_by_name[name] then
            fields_by_name[name].mask = mask
        else
            warn(fmt("Skipping mask for missing bitfield %s", name))
        end
    end
    -- Find comments
    for name, name2, comment in f:gmatch "([%w_]+)%s+([%w_]+)_Msk%s+(/%*!<.-%*/)" do
        comment = prettify_comment(comment)
        --debug(fmt("%s %s %s", name, name2, comment))
        -- Make sure names match
        if name == name2 then
            if fields_by_name[name] then
                fields_by_name[name].comment = comment
            else
                warn(fmt("Skipping comment for missing bitfield %s", name))
            end
        end
    end
    table.sort(fields, function(x, y)
        local function index(f)
            return (f.name:match "%w+_%w+") ..
                -- Sort fields before equates
                (f.pos and fmt("A%02d", f.pos) or fmt("B%08x", f.equ))
        end
        return index(x) < index(y)
    end)
    return fields, fields_by_name
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
    warn(fmt("Hmm. Couldn't eval %s", e))
end

function base_addrs(f)
    local base = {}
    for p, expr in f:gmatch "#define%s+([%w_]+_BASE)%s+(..-)\n" do
        --debug(p, expr)
        base[p] = eval(base, expr)
        --debug(fmt("%s %x", p, base[p]))
    end
    return base
end

function muhex(num)
    return fmt("%04x_%04x", num >> 16, num % (2^16))
end

function vectors(exc)
    out("\n( Vectors)\ndecimal")
    for _, e in ipairs(exc) do
        out(fmt("%3d vector %-20s %s", e.vector, e.name, e.comment))
    end
    out("hex")
end

function instantiate(f, base, periphs)
    local print_reg, print_regs
    print_reg = function(r, pname, subscript, pbase)
        if r.struct then
            print_regs(r.struct, pname .. "_" .. r.name .. subscript, pbase + r.offset)
        else
            out(fmt("%s equ %-26s %s", muhex(r.offset + pbase),
                pname .. "_" .. r.name .. subscript, r.comment))
        end
    end
    print_regs = function(regs, pname, pbase)
        for _, r in ipairs(regs) do
            if r.array then
                for i = 0, r.array - 1 do
                    print_reg(r, pname, fmt("%d", i), pbase + (i * r.size))
                end
            else
                print_reg(r, pname, "", pbase)
            end
        end
    end

    for pname, ptype, pbase in f:gmatch
        "#define%s+([%w_]+)%s+%(%(([%w_]+)_TypeDef %*%)%s*([%w_]+)%)" do
        out ""
        --debug(fmt("instantiate: %s %s %s", pname, ptype, pbase))
        print_regs(periphs[ptype], pname, base[pbase])
    end
end

function print_bitfields(fields)
    local lastreg = ""
    for _, f in ipairs(fields) do
        local reg = f.name:match "%w+_%w+"
        if reg ~= lastreg then
            out ""
        end
        if f.equ then
            -- Equate, not bit field.
            out(fmt("      %s equ    %-26s %s", muhex(f.equ), f.name, f.comment))
        else
            if convert_mask_to_width then
                -- Convert mask into width
                --debug(fmt("mask = %08x", f.mask))
                local width = 0
                local m = f.mask + 1
                while m ~= 1 do
                    m = m >> 1
                    width = width + 1
                end

                --debug(fmt("mask %08x => width %d", f.mask, width))
                out(fmt("  #%02d #%02d field  %-26s %s", f.pos, width, f.name,
                    f.comment or ""))
            else
                --debug(fmt("%s", f.name))
                out(fmt("  #%02d %s field  %-26s %s", f.pos, muhex(f.mask), f.name,
                    f.comment or ""))
            end
        end
        lastreg = reg
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
    local f = fixes(read_file(arg[1]))
    local exc = exceptions(f)
    local periphs = typedefs(f)
    local fields, fields_by_name = bitfields(f)
    local base = base_addrs(f)
    out(fmt("( Chip equates for %s)", arg[1]:match "^[%w]+"))
    vectors(exc)
    instantiate(f, base, periphs)
    print_bitfields(fields)
end

doit()
