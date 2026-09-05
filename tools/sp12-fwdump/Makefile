obj-m := sp12_fwdump.o
KDIR ?= /home/franz/sp12-kernel-rebuild/linux-next
all:
	$(MAKE) -C $(KDIR) M=$(PWD) KERNELRELEASE=7.1.0-next-20260626-nft modules
clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
