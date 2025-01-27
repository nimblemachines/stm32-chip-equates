-- Impossible task of parsing chip .h files and trying to generate
-- Forth-style equates from them.

fmt = string.format

-- Logging and errors
function logger(class)
    return function(format, ...)
        io.stderr:write(fmt("    [%s] "..format.."\n", class, ...))
    end
end

debug = logger "DEBUG"
info  = logger "INFO"
warn  = logger "WARNING"
err   = logger "ERROR"

-- There are often trailing spaces in the generated code. Let's remove them
-- here before printing the line.
-- NOTE: Don't replace the literal space with %s (whitespace): some lines
-- end with newlines that we want to keep!
function out(s)
    io.stdout:write(s:gsub(" +$", "") .. "\n")
end

function prettify_comment(c)
    c = c:gsub("^%s+$", "")
         :gsub("%s+", " ")
         :gsub("%s*/%*!?<?%s*(..-)%s*%*/", "| %1")

    return c
end

function more_destupidify(f)
    f = f:gsub("([^_])TypeDef", "%1_TypeDef")
         :gsub("XSPI_TypeDef", "OCTOSPI_TypeDef")
    return f
end

function parse_vectors(f)
    local vecs = {}
    local guts = f:match "typedef enum(..-)IRQn_Type;"
    if guts then
        for name, vector, comment in guts:gmatch "([%w_]+)_IRQn%s*=%s*(%d+),?(.-)\n" do
            comment = prettify_comment(comment)
            vector = tonumber(vector)
            --debug("%s %d %s", name, vector, comment)
            vecs[#vecs+1] = { name = name, vector = vector, comment = comment }
        end
        -- Create a "dummy" LAST vector so we know where the table ends.
        local last_vector = vecs[#vecs].vector + 1
        vecs[#vecs+1] = {
            name = "LAST",
            vector = last_vector,
            comment = "| dummy LAST vector to mark end of vector table"
        }
    else
        warn "Hmm. No IRQn_Type was found."
    end
    return vecs
end

function parse_typedefs(f)
    local periphs = {}
    for guts, name in f:gmatch "typedef struct(..-)([%w_]+)_TypeDef;" do
        if not name:match "_IGNORE$" then   -- We ignore these
            local fixedguts = guts:gsub("/%*!<([^*]-) *\n *(.-) *(Address.-)%*/", "/*!<%1 %2 %3*/")
                                  :gsub("(%w) ;", "%1;")    -- "OR1 ;" in H5 TIM_TypeDef, eg
            --debug("%s: %s: %s", name, guts, fixedguts)
            local regs = {}
            periphs[name] = regs
            local offset = 0
            for bits, name, comment in fixedguts:gmatch "uint(%d+)_t%s+(%S+);(.-)\n" do
                comment = prettify_comment(comment)
                --debug("%x %s %s", offset, name, comment)
                local reg = { name = name, offset = offset, comment = comment }
                local size = tonumber(bits)/8
                local array = name:match "%[(%w+)%]"
                if array then
                    array = tonumber(array)
                    --debug("matched reg array %s length %d", name, array)
                    reg.name = reg.name:gsub("%[(%w+)%]", "")
                    offset = offset + (array * size)
                else
                    offset = offset + size
                end
                if name:match "RESERVED" or name:match "Reserved" then
                    -- Tell GC to throw it away
                    reg = nil
                else
                    regs[#regs+1] = reg
                end
            end
        end
    end
    return periphs
end

-- Match _Pos, _Msk, and comment separately?
function parse_bitfields(f)
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
            warn("Ignoring %s which depends on undefined bitfield %s!", name, prev)
            return false, 0
        end
        warn("Hmm. Can't eval %s", expr)
        return false, 0
    end

    -- Find bare shifted masks/values. Do this first! We define them as
    -- "equates" rather than fields. Sometimes the value is 0000_0000 !!
    for name, mask, comment in f:gmatch "([%w_]+)%s+%((0x%x+)U%)%s+(/%*!<.-%*/)" do
        comment = prettify_comment(comment)
        --debug("bare: %s %08x %s", name, mask, comment)
        local field = { name = name, equ = mask, comment = comment }
        fields_by_name[name] = field
        fields[#fields+1] = field
    end
    -- Find positions
    for name, expr in f:gmatch "([%w_]+)_Pos%s+%((.-%d+)U%)" do
        local ok, pos = eval(name, expr)
        if ok then
            --debug("%s %s %d", name, expr, pos)
            if fields_by_name[name] then
                warn("Skipping redefinition of bitfield %s with pos %d", name, pos)
            else
                local field = { name = name, pos = pos }
                fields_by_name[name] = field
                fields[#fields+1] = field
            end
        end
    end
    -- Find masks
    for name, mask in f:gmatch "([%w_]+)_Msk%s+%((0x%x+)U" do
        --debug("%s %s", name, mask)
        if fields_by_name[name] then
            fields_by_name[name].mask = mask
        else
            warn("Skipping mask for missing bitfield %s", name)
        end
    end
    -- Find comments
    for name, name2, comment in f:gmatch "([%w_]+)%s+([%w_]+)_Msk%s+(/%*!<.-%*/)" do
        comment = prettify_comment(comment)
        --debug("%s %s %s", name, name2, comment)
        -- Make sure names match
        if name == name2 then
            if fields_by_name[name] then
                fields_by_name[name].comment = comment
            else
                warn("Skipping comment for missing bitfield %s", name)
            end
        end
    end
    table.sort(fields, function(x, y)
        local function index(f)
            return f.name:match "^(%w+_%w+)" ..
                -- Sort fields before equates
                -- Fields with same pos will sort by mask
                (f.pos and fmt("A%02d%08x", f.pos, f.mask) or
                           fmt("B%08x", f.equ))
        end
        return index(x) < index(y)
    end)
    return fields
end

function parse_base_addrs(f)
    local base = {}
    local eval
    eval = function (e)
        -- Remove any casts
        e = e:gsub("%(%s*uint32_t%s*%)", "")

        -- If the whole expression is enclosed by balanced parens, remove
        -- the outer ones and re-eval.
        if e:match "^%b()$" then
            return eval(e:sub(2, -2))
        end

        -- Match expr + expr
        local e1, e2 = e:match "(%S+) %+ (%S+)"
        if e1 then
            return eval(e1) + eval(e2)
        end

        -- Match bare basename or size
        b = e:match "[%w_]+"
        if b and base[b] then
            return base[b]
        end

        -- Match bare hex or decimal value.
        local value = e:match "0x%x+" or e:match "%d+"
        if value then
            return tonumber(value)
        end

        warn("Hmm. Couldn't eval %s", e)
        return 0xdeadbeef
    end

    for p, expr in f:gmatch "#define%s+([%w_]+)%s+(..-)\n" do
        -- Remove any comment field from expr before evaluating.
        expr = expr:gsub("/%*.+%*/", "")

        if p:match "_BASE$"
            or p:match "_BASE_NS$"
            or p:match "_BASE_S$" then
            --debug("eval %s = %s", p, expr)
            base[p] = eval(expr)
            --debug("set %s = %x", p, base[p])
        end
    end

    return base
end

function muhex(num)
    num = tonumber(num)     -- make sure it's a number, not a string
    return fmt("%04x_%04x", num >> 16, num % (2^16))
end

-- Print vectors as hex offsets from start of vector table. This means we
-- skip the first 16 vectors - they are defined by the architectural spec.
-- Each vector takes 4 bytes of space.
function print_vectors(vectors)
    out("\n( Vectors)")

    for _, v in ipairs(vectors) do
        out(fmt("%04x vector %-28s | %2d: %s",
            (v.vector + 16) * 4,
            v.name.."_irq",
            v.vector,
            v.comment:sub(3)))
    end
end

function instantiate(f, base, periphs)
    local print_regs = function(regs, pname, pbase)
        for _, r in ipairs(regs) do
            out(fmt("%s equ %-26s %s", muhex(r.offset + pbase),
                pname .. "_" .. r.name, r.comment))
        end
    end

    out "\n( Register addresses)"
    for pname, ptype, pbase in f:gmatch
        "#define%s+([%w_]+)%s+%(%(([%w_]+)_TypeDef %*%)%s*([%w_]+)%)" do
        if pbase:match "_BASE$" or pbase:match "_BASE_NS$" then
            -- instantiate bare and non-secure, but skip secure
            --debug("instantiate: %s %s %s", pname, ptype, pbase)
            if not periphs[ptype] then
                warn("When instantiating %s, no %s_TypeDef found", pname, ptype)
            elseif not base[pbase] then
                warn("When instantiating %s, no %s address found", pname, pbase)
            elseif pname:match "SSLIB" then
                warn("Skipping instantiation of %s", pname)
            elseif pname:match "^USB_OTG_" then
                -- USB_OTG isn't fully instantiated by the .h files;
                -- intervention is necessary. This exists in F105, F107,
                -- and F4xx devices.
                warn("Skipping instantiation of %s", pname)
            else
                pname = pname:gsub("_NS$", "")

                -- XXX have a list of renames somewhere?
                pname = pname:gsub("^USB_DRD.*", "USB", 1)

                out ""
                print_regs(periphs[ptype], pname, base[pbase])
            end
        end
    end
end

function print_bitfields(fields)
    local lastreg = ""
    out "\n( Register bit fields)"
    for _, f in ipairs(fields) do
        local reg = f.name:match "%w+_%w+"
        if reg ~= lastreg then
            out ""
        end
        if f.equ then
            -- Equate, not bit field.
            out(fmt("      %s equ   %-26s %s", muhex(f.equ), f.name, f.comment))
        else
            if convert_mask_to_width then
                -- Convert mask into width
                --debug("mask = %08x", f.mask)
                local width = 0
                local m = f.mask + 1
                while m ~= 1 do
                    m = m >> 1
                    width = width + 1
                end

                --debug("mask %08x => width %d", f.mask, width)
                out(fmt("  #%02d #%02d field %-26s %s", f.pos, width, f.name,
                    f.comment or ""))
            else
                --debug("%s", f.name)
                out(fmt("  #%02d %s field %-26s %s", f.pos, muhex(f.mask), f.name,
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

function nicer_chip_name(c)
    c = c:gsub("x", "@")
         :upper()
         :gsub("@", "x")
    return c
end

function print_heading(chip)
    out "| Automagically generated. DO NOT EDIT!\n|"
    out "| Generated by https://github.com/nimblemachines/stm32-chip-equates"
    out(fmt("| from source file %s\n", arg[2]))
    out(fmt("loading %s equates\n", chip))
    out [[
( Define .equates. and the defining words we need.)
ld target/ARM/v6-m/equates.mu4

hex]]
end

function doit()
    local f = more_destupidify(read_file(arg[1]))
    local vectors = parse_vectors(f)
    local periphs = parse_typedefs(f)
    --local fields = parse_bitfields(f)
    local base = parse_base_addrs(f)
    print_heading(nicer_chip_name(arg[1]:match "^%w+"))
    print_vectors(vectors)
    instantiate(f, base, periphs)
    --print_bitfields(fields)
end

doit()
