-- Generate a series of "cp" commands to install the equates files into a
-- checkout of the muforth repo.

for i,a in ipairs(arg) do
    if i == 1 then
        installdir = a .. "/mu/target/ARM/stm32/"
    else
        src = a
        dest = a:gsub("x(.)%.mu4", "_%1-equates.mu4")
                :gsub("^stm32", "")

        print(string.format("cp -f %s %s", src, installdir .. dest))
    end
end
