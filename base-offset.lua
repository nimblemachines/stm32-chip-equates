-- Previously part of c2forth.lua.

-- This code is experimental and CURRENTLY UNUSED.

-- I put it here to keep it around in case I want to travel down this path
-- again in the future.

function muhex16(num)
    num = tonumber(num)     -- make sure it's a number, not a string
    return fmt("%04x", num % (2^16))
end

function muhex32(num)
    num = tonumber(num)     -- make sure it's a number, not a string
    return fmt("%04x_%04x", num >> 16, num % (2^16))
end

-- Generate register offsets for each peripheral type and base addresses
-- for each instance of a peripheral.
function instantiate_base_offset(f, base, periphs)
    out "\n( Register offsets)"
    -- Let's print these sorted by the name of the peripheral.
    periphs_sorted = {}
    for name, regs in pairs(periphs) do
        table.insert(periphs_sorted, { name = name, regs = regs })
    end
    table.sort(periphs_sorted, function(x, y)
        return x.name < y.name
    end)
    for _, p in ipairs(periphs_sorted) do
        out(fmt("( %s)", p.name))
        for _, reg in ipairs(p.regs) do
            out(fmt("%s equ %-26s %s", muhex16(reg.offset),
                p.name .. "_" .. reg.name, reg.comment))
        end
        out ""
    end

    out "\n( Base addresses)"
    bases_ordered = {}
    for pname, ptype, pbase, comment in f:gmatch
        "#define%s+([%w_]+)%s+%(%(([%w_]+)_TypeDef %*%)%s*([%w_]+)%)(.-)\n" do
        if not comment:match "legacy" then
            table.insert(bases_ordered, { name = pname, addr = base[pbase] })
        end
    end
    table.sort(bases_ordered, function(x, y)
        return x.addr < y.addr
    end)
    for _, b in ipairs(bases_ordered) do
        out(fmt("%s equ %s_BASE", muhex32(b.addr), b.name))
    end
end
