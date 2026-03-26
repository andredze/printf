#include <stdio.h>
#include <math.h>
#include "test.h"
#include "googletest/googletest/include/gtest/gtest.h"

extern "C" int my_printf(const char* format, ...);

//------------------------------------------------------------------//

TEST_SPECIFIER(TestingChar      , TEST_DATA_CHAR      )
TEST_SPECIFIER(TestingString    , TEST_DATA_STRING    )
TEST_SPECIFIER(TestingHex       , TEST_DATA_HEX       )
TEST_SPECIFIER(TestingOctal     , TEST_DATA_OCTAL     )
TEST_SPECIFIER(TestingBinary    , TEST_DATA_BINARY    )
TEST_SPECIFIER(TestingDecimal   , TEST_DATA_DECIMAL   )
TEST_SPECIFIER(TestingPercent   , TEST_DATA_PERCENT   )
TEST_SPECIFIER(TestingPointer   , TEST_DATA_POINTER   )
TEST_SPECIFIER(TestingFloat     , TEST_DATA_FLOAT     )
TEST_SPECIFIER(TestingFloat2    , TEST_DATA_FLOAT2    )
TEST_SPECIFIER(TestingFloatCases, TEST_DATA_SPECIAL   )
TEST_SPECIFIER(TestingPrimerDeda, TEST_DATA_DEDA      )

//------------------------------------------------------------------//

int main(int argc, char** argv)
{
    ::testing::InitGoogleTest(&argc, argv);

    return RUN_ALL_TESTS();
}

//------------------------------------------------------------------//
