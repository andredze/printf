#include <stdio.h>
#include "test.h"
#include "googletest/googletest/include/gtest/gtest.h"

extern "C" void my_printf(const char* format, ...);

//------------------------------------------------------------------//

TEST_SPECIFIER(TestingChar,    TEST_DATA_CHAR   )
TEST_SPECIFIER(TestingString,  TEST_DATA_STRING )
TEST_SPECIFIER(TestingHex,     TEST_DATA_HEX    )
TEST_SPECIFIER(TestingOctal,   TEST_DATA_OCTAL  )
TEST_SPECIFIER(TestingBinary,  TEST_DATA_BINARY )
TEST_SPECIFIER(TestingDecimal, TEST_DATA_DECIMAL)
TEST_SPECIFIER(TestingPercent, TEST_DATA_PERCENT)

//------------------------------------------------------------------//

TEST(MyPrintfTest, TestingPointer)
{
    int int_a = 1000;
    void (* my_printf_ptr) (const char*, ...) = my_printf;

    testing::internal::CaptureStdout();

    printf(TEST_DATA_POINTER);

    std::string printf_output = testing::internal::GetCapturedStdout();

    testing::internal::CaptureStdout();

    my_printf(TEST_DATA_POINTER);

    std::string my_printf_output = testing::internal::GetCapturedStdout();

    ASSERT_EQ(my_printf_output, printf_output);

    my_printf("\n" YELLOW_COLOR "[MY_PRINTF ] ");

    my_printf(TEST_DATA_POINTER);

    my_printf("\n" RESET_COLOR);
}

//------------------------------------------------------------------//

int main(int argc, char** argv)
{
    ::testing::InitGoogleTest(&argc, argv);

    return RUN_ALL_TESTS();
}

//------------------------------------------------------------------//
