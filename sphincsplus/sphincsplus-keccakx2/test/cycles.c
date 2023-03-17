#include "cycles.h"



#if defined(PMU_CYCLES)
void enable_cyclecounter() {
    uint64_t tmp;
    __asm __volatile (
        "mrs    %[tmp], pmcr_el0\n"
        "orr    %[tmp], %[tmp], #1\n"
        "msr    pmcr_el0, %[tmp]\n"
        "mrs    %[tmp], PMOVSCLR_EL0\n" // reset overflow bit
        "orr    %[tmp], %[tmp], #(1<<31)\n"
        "msr    PMOVSCLR_EL0, %[tmp]\n"
        "mrs    %[tmp], pmcntenset_el0\n"
        "orr    %[tmp], %[tmp], #1<<31\n"
        "msr    pmcntenset_el0, %[tmp]\n"
        : [tmp] "=r" (tmp)
    );
}

void disable_cyclecounter() {
    uint64_t tmp;
    __asm __volatile (
            "mov   %[tmp], #0x3f\n"
            "orr   %[tmp], %[tmp], #1<<31\n"
            "msr    pmcntenclr_el0, %[tmp]\n"
            : [tmp] "=r" (tmp)
            );
}

uint64_t get_cyclecounter() {
    uint64_t retval;
    __asm __volatile (
        "mrs    %[retval], pmccntr_el0\n"
    : [retval] "=r" (retval));
    return retval;
}
// Somehow weird things happen as soon as the cycle counter reaches 2^32.
// In theory, there is a long counter mode (bit 6 of pmcr_el0), but I did not
// get it to work yet.
// Instead, we reset the cycle counter after each experiment and make sure that
// it never overflows.
void reset_cpucycles() {
    uint64_t tmp;
    __asm __volatile (
        "mrs    %[tmp], pmcr_el0\n"
        "orr    %[tmp], %[tmp], #(1<<2)\n"  // reset cycle counter
        "msr    pmcr_el0, %[tmp]\n"
        : [tmp] "=r" (tmp)
    );
}

int is_cpucycles_overflow(){
    uint32_t val;
    __asm __volatile("mrs %0, PMOVSSET_EL0" : "=r"(val));
    return (val & (1U<<31));
}
#elif defined(PERF_CYCLES)

#include <asm/unistd.h>
#include <linux/perf_event.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>

static int perf_fd = 0;
void enable_cyclecounter() {
    struct perf_event_attr pe;
    memset(&pe, 0, sizeof(struct perf_event_attr));
    pe.type = PERF_TYPE_HARDWARE;
    pe.size = sizeof(struct perf_event_attr);
    pe.config = PERF_COUNT_HW_CPU_CYCLES;
    pe.disabled = 1;
    pe.exclude_kernel = 1;
    pe.exclude_hv = 1;

    perf_fd = syscall(__NR_perf_event_open, &pe, 0, -1, -1, 0);

    ioctl(perf_fd, PERF_EVENT_IOC_RESET, 0);
    ioctl(perf_fd, PERF_EVENT_IOC_ENABLE, 0);
}

void disable_cyclecounter() {
    ioctl(perf_fd, PERF_EVENT_IOC_DISABLE, 0);
    close(perf_fd);
}

uint64_t get_cyclecounter() {
    long long cpu_cycles;
    ioctl(perf_fd, PERF_EVENT_IOC_DISABLE, 0);
    ssize_t read_count = read(perf_fd, &cpu_cycles, sizeof(cpu_cycles));
    if (read_count < 0) {
        perror("read");
        exit(EXIT_FAILURE);
    } else if (read_count == 0) {
        /* Should not happen */
        printf("perf counter empty\n");
        exit(EXIT_FAILURE);
    }
    ioctl(perf_fd, PERF_EVENT_IOC_ENABLE, 0);
    return cpu_cycles;
}

void reset_cpucycles(void) {
    return;
}
int is_cpucycles_overflow(void){
    return 0;
}

#elif defined(EXTERNAL_CYCLES)

// nothing to do

#else /* NO_CYCLES */

void enable_cyclecounter() {
    return;
}
void disable_cyclecounter() {
    return;
}
uint64_t get_cyclecounter() {
    return(0);
}

void reset_cpucycles(void) {
    return;
}
int is_cpucycles_overflow(void){
    return 0;
}

#endif /* NO_CYCLES */