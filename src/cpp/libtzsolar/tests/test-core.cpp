#include "tappp.hpp"
#include <string>
#include <vector>
#include <stdexcept>
#include <cstdlib>

static const int total_tests = 1;

void test_global() {
    // TODO
}

void test_polar() {
    // TODO
}

int main(void) {
    TAP::plan(total_tests);

    // run tests
    test_global();
    test_polar();

    return 0;
}
