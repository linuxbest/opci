#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <byteswap.h>
#include <assert.h>
#include "pcisim.h"
#define IfPrint(c) (c >= 32 && c < 127 ? c : '.')

#include "tlsf.h"

static void HexDump(unsigned char *p_Buffer, unsigned long p_Size)
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
#define POOL_SIZE  1024 * 1024 * 64
static unsigned char system_mem[POOL_SIZE];
static int verbose = 0;

static uint32_t qemu_peek(uint32_t addr)
{
        uint32_t *val = (uint32_t *)system_mem;
        //printf("qemu_peek: %08lx %08lx\n", addr, *val);
        addr /= 4;
        val += addr;
        return *val;
}

static qemu_poke(uint32_t addr, uint32_t val)
{
        uint32_t *p = (uint32_t *)system_mem;
        //printf("qemu_poke: %08lx %08lx\n", addr, val);
        addr /= 4;
        p += addr;
        *p = val;
}

static int
pci_reset(unsigned phys_mem)
{
	pcisim_reset(10, 10);
	pcisim_config_write((1<<17) + 0x10, phys_mem);
	pcisim_wait(4, 0);
}

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
		
                if (pcisim_config_read(1<<i) == (0x1 << 16 | 0x1895))
                        idx = i;
	}
	
	return idx;
}

int
main(int argc, char *argv[])
{
	int i = 0, idx = -1;
	unsigned int lzf_mem =  0xfa000000;
	unsigned int phys_mem = 0xa0000000;
	unsigned sum;
	int cnt = 64, loop = 0, dst_cnt = 0;
	unsigned int opt = 0, p = 0;
        FILE *fp = NULL;

	while ((p = getopt(argc, argv, "NMCUAFhn:fr:vl:g:d:")) != EOF) {
		switch (p) {
                case 'd': 
                        dst_cnt = atoi(optarg);
                        break;
                case 'l':
                        loop = atoi(optarg);
                        break;
                case 'v':
                        verbose = 1;
                        break;
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
                case 'n':
                        cnt = atoi(optarg);
                        break;
		}
	}

        if (dst_cnt == 0)
                dst_cnt = cnt;
        printf("%d, %d\n", cnt, dst_cnt);

        init_memory_pool(POOL_SIZE, system_mem);

	pcisim_init(".", qemu_peek, qemu_poke);
	
	pci_reset(phys_mem);
	
	//show all the pci device 
	idx = dev_scan(-1);
	if (idx != -1)
		printf("Found %04X:%04X at %d\n", 0x100, 0x3, idx);
	else 
		goto done;
        /* master memory_enable */
	int val;
        val = pcisim_config_read((1<<idx) + 4*1);
	pcisim_config_write((1<<idx) + 4*1, val | 1<<1| 1<<2);
        pcisim_config_write((1<<idx) + 4*6, lzf_mem); /* bar1 */
        /* cache line */ 
	pcisim_config_write((1<<idx) + 4*3, 0x4004);

        pcisim_writel(lzf_mem, 0xAA55);

        pcisim_wait(400, 0);
 done:
	return 0;
}
