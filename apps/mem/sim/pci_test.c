#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <byteswap.h>
//#include "pcisim.h"
//#include "../drv/pci_dma.h"
//#include "../drv/liblzs.c"
#define OC_PCI_VENDOR 0x1895
#define OC_PCI_DEVICE 0x0001

#define IfPrint(c) (c >= 32 && c < 127 ? c : '.')

typedef struct {
                int mmr_base;
} pcidev_t;
static pcidev_t lzf_dev;
static pcidev_t *dev = &lzf_dev;

static void HexDump (unsigned char *p_Buffer, unsigned long p_Size)
{
        unsigned long l_Index, l_Idx;
        unsigned char l_Row [17];

        for (l_Index = l_Row [16] = 0; 
                        l_Index < p_Size || l_Index % 16; ++l_Index) {
                if (l_Index % 16 == 0)
                        printf("%05x   ", l_Index);
                printf("%02x ", l_Row [l_Index % 16] = (l_Index < p_Size ? 
                                                p_Buffer [l_Index] : 0));
                l_Row [l_Index % 16] = IfPrint (l_Row [l_Index % 16]);
                if ((l_Index + 1) % 16 == 0)
                        printf("   %s\n", l_Row);
        }

        printf("\n");
}
static unsigned char system_mem[1024 * 1024 * 64];

static uint32_t qemu_peek(uint32_t addr)
{
        uint32_t *val = (uint32_t *)system_mem;
        addr /= 4;
        val += addr;
        //printf("qemu_peek: %08lx %08lx\n", addr, *val);
        return *val;
}

static qemu_poke(uint32_t addr, uint32_t val)
{
        uint32_t *p = (uint32_t *)system_mem;
        addr /= 4;
        p += addr;
        //fprintf("qemu_poke: %08lx %08lx\n", addr, val);
        *p = val;
}

static int
pci_reset(unsigned phys_mem)
{
	pcisim_reset(10, 10);
	pcisim_config_write((1<<17) + 0x10, phys_mem);
	pcisim_wait(4, 0);
}

enum DO_OPT {
	DO_NULL = 1<<0,
	DO_FILL = 1<<1,
	DO_MEMCPY = 1<<2,
	DO_COMPRESS =  1<<3,
	DO_UNCOMPRESS = 1<<4,
        DO_FILL_LOOP  = 1<<5,
};

static int 
dev_scan(int dev)
{
	int i = 0, idx = -1, max = 31;
	
	if (dev != -1) {
		max = dev + 1;
		i = dev;
	}
	
	for (; i < max; i++) {
		int j;
		if (pcisim_config_read(1<<i) == 0xffffffff)
			continue;
		printf("%02d: ", i);
		for (j = 0; j < 10; j ++) {
			printf("%08X ", pcisim_config_read((1<<i) + j * 4));
		}
		printf("\n");
		
		if (pcisim_config_read(1<<i) == 
		    (OC_PCI_DEVICE << 16 | OC_PCI_VENDOR))
			idx = i;
	}
	
	return idx;
}
static void
lzf_write(unsigned long base, int reg, unsigned long val)
{
        pcisim_writel(base + reg * 4, val);
}

static unsigned long
lzf_read(unsigned int base, int reg)
{
        return pcisim_readl(base + reg*4);
}

int
main(int argc, char *argv[])
{
	int i = 0, idx = -1;
	unsigned int lzf_mem =  0xfa000000;
	unsigned int phys_mem = 0xa0000000;
	unsigned sum;
	int cnt = 64;
	unsigned int opt = 0, p = 0;
        FILE *fp = NULL;

	while ((p = getopt(argc, argv, "NMCUAFhn:fr:")) != EOF) {
		switch (p) {
                case 'r':
                        fp = fopen(optarg, "r");
                        if (fp == NULL) {
                                perror("fopen");
                                return 0;
                        }
                        break;
		case 'h':
			printf("%s: \t-n cnt\n"
                               "\t-N DO NULL\n"
			       "\t-F DO FILL\n"
			       "\t-M DO MEMCPY\n"
			       "\t-C DO COMPRESS\n"
			       "\t-U DO Uncompress\n"
			       "\t-A ALL tested\n", argv[0]);
			return -1;
		case 'N':
			opt |= DO_NULL;
			break;
		case 'F':
			opt |= DO_FILL;
			break;
                case 'f':
			opt |= DO_FILL_LOOP;
                        break;
		case 'M':
			opt |= DO_MEMCPY;
			break;
		case 'C':
			opt |= DO_COMPRESS;
			break;
		case 'U':
			opt |= DO_UNCOMPRESS;
			break;
		case 'A':
			opt = 0xFFFFFFFF;
			break;
                case 'n':
                        cnt = atoi(optarg);
                        break;
		}
	}
	pcisim_init(".", qemu_peek, qemu_poke);
	
	pci_reset(phys_mem);
	
	//show all the pci device 
	idx = dev_scan(-1);
	if (idx != -1)
		printf("Found %04X:%04X at %d\n", OC_PCI_VENDOR,
		       OC_PCI_DEVICE, idx);
	else 
		goto done;
        /* master memory_enable */
	int val;
        val = pcisim_config_read((1<<idx) + 4*1);
	pcisim_config_write((1<<idx) + 4*1, val | 1<<1| 1<<2);

        /* cache line */ 
	pcisim_config_write((1<<idx) + 4*3, 0x4004);
        
        /* enable PRE_EN MRL_EN */
        //val = pcisim_config_read((1<<idx) + 4*0x61);
        // W_IMG_CTRL0
        val  = 1 << 0;  /* MRL */
        val |= 1 << 1;  /* PREFETCH */
	pcisim_config_write((1<<idx) + 0x184, val);
        // P_IMG_CTRL0
	//pcisim_config_write((1<<idx) + 0x110, 3);

	pcisim_config_write((1<<idx) + 4*5, lzf_mem);

	dev_scan(idx);
	
	lzf_dev.mmr_base = lzf_mem;
        lzf_write(lzf_mem, 0, 0xAA55);
        printf("%08x\n", lzf_read(lzf_mem, 0));

 done:
	return 0;
}
