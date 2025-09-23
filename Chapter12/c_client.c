#include <stdio.h>
#include <stdint.h>

// Declare the Zig function with C linkage
extern uint32_t count_words(const char *str);

int main() {
    const char *example = "Zig is awesome";
    uint32_t result = count_words(example);
    printf("Word count: %u\n", result); // Output: Word count: 3
    return 0;
}