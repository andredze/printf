#ifndef __TESTS_H__
#define __TESTS_H__

//——————————————————————————————————————————————————————————————————————————————————————————

#define TEST_SPECIFIER(name, data_name)                                     \
TEST(MyPrintfTest, name##Specifier)                                         \
{                                                                           \
    testing::internal::CaptureStdout();                                     \
                                                                            \
    printf(TEST_DATA_##data_name);                                          \
                                                                            \
    std::string printf_output = testing::internal::GetCapturedStdout();     \
                                                                            \
    testing::internal::CaptureStdout();                                     \
                                                                            \
    my_printf(TEST_DATA_##data_name);                                       \
                                                                            \
    std::string my_printf_output = testing::internal::GetCapturedStdout();  \
                                                                            \
    EXPECT_EQ(my_printf_output, printf_output);                             \
}

//------------------------------------------------------------------//

#define TEST_DATA_CHAR              \
    "%c am eating %c %c %c day\n",  \
    'I',                            \
    '5',                            \
    '@',                            \
    'a'

//------------------------------------------------------------------//

#define TEST_DATA_STRING        \
    "string: %s, %s%s",         \
    "darova",                   \
    "zaebal",                   \
    "!"

//------------------------------------------------------------------//

#define TEST_DATA_HEX           \
    "hex: %x %x %x %x %x",      \
    0xAB0BA,                    \
    0xDED,                      \
    0xFFFF,                     \
    -0x1234,                    \
    0x00

//------------------------------------------------------------------//

#define TEST_DATA_OCTAL         \
    "oct: %o %o %o %o %o",      \
    0777,                       \
    01234567,                   \
    0xFFFF,                     \
    -0xFFFF,                    \
    0x00

//------------------------------------------------------------------//

#define TEST_DATA_BINARY        \
    "bin: %b %b %b %b %b",      \
    0777,                       \
    0x8888,                     \
    0xFFFF,                     \
    -128,                       \
    0x00

//------------------------------------------------------------------//

#define TEST_DATA_DECIMAL       \
    "dec: %d %d %d %d %d",      \
    777,                        \
    1337,                       \
    128,                        \
    0,                          \
    -69

//------------------------------------------------------------------//

#define TEST_DATA_PERCENT       \
    "percent: %% %% %% %%"

//——————————————————————————————————————————————————————————————————————————————————————————

#endif /* __TESTS_H__ */
