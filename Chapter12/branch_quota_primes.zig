const std = @import("std");

fn generatePrimes(comptime limit: usize) [limit + 1]bool {
    var is_prime: [limit + 1]bool = undefined;

    // initialize all to true
    var i: usize = 0;
    while (i <= limit) : (i += 1) is_prime[i] = true;

    if (limit >= 0) is_prime[0] = false;
    if (limit >= 1) is_prime[1] = false;

    var p: usize = 2;
    while (p * p <= limit) : (p += 1) {
        if (is_prime[p]) {
            var j: usize = p * p;
            while (j <= limit) : (j += p) {
                is_prime[j] = false;
            }
        }
    }

    return is_prime;
}

test "ch12: compile-time prime lookup table with branch quota" {
    const prime_lookup_table = comptime blk: {
        @setEvalBranchQuota(200000);
        break :blk generatePrimes(2000);
    };

    // Spot checks
    try std.testing.expect(prime_lookup_table[2]);
    try std.testing.expect(prime_lookup_table[3]);
    try std.testing.expect(prime_lookup_table[5]);
    try std.testing.expect(!prime_lookup_table[4]);
    try std.testing.expect(!prime_lookup_table[9]);
    try std.testing.expect(prime_lookup_table[1999]);
}
