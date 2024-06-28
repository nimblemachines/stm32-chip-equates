-- Generate a series of shell commands to install the equates files into a
-- nearby checkout of the muforth repo.

for i,a in ipairs(arg) do
    if i == 1 then
        stm32dir = a .. "/mu/target/ARM/stm32/"
    else
        src = a
        family, partnum, package, flash_size = a:match "stm32(%w%d)(%d%d)(%w)(%w)"
        destdir = stm32dir .. family .. "/"
        destfile = string.format("%s_%s-equates.mu4", partnum, flash_size)

        print(string.format("mkdir -p %s", destdir))
        print(string.format("cp -f %s %s", src, destdir .. destfile))
    end
end
