savedcmd_sp12_fwdump.mod := printf '%s\n'   sp12_fwdump.o | awk '!x[$$0]++ { print("./"$$0) }' > sp12_fwdump.mod
