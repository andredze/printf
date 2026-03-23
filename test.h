#ifndef __TESTS_H__
#define __TESTS_H__

//——————————————————————————————————————————————————————————————————————————————————————————

#define RESET_COLOR  "\033[0m"
#define BLUE_COLOR   "\033[0;34m"
#define GREEN_COLOR  "\033[0;32m"
#define YELLOW_COLOR "\033[1;33m"

#define TEST_SPECIFIER(test_name, test_data_name)                           \
TEST(MyPrintfTest, test_name)                                               \
{                                                                           \
    testing::internal::CaptureStdout();                                     \
                                                                            \
    printf(test_data_name);                                                 \
    int printf_ret_value = printf(test_data_name);                          \
                                                                            \
    std::string printf_output = testing::internal::GetCapturedStdout();     \
                                                                            \
    testing::internal::CaptureStdout();                                     \
                                                                            \
    int my_printf_ret_value = my_printf(test_data_name);                    \
                                                                            \
    std::string my_printf_output = testing::internal::GetCapturedStdout();  \
                                                                            \
    EXPECT_EQ(my_printf_ret_value, printf_ret_value);                       \
    ASSERT_EQ(my_printf_output,    printf_output);                          \
    printf("\n" YELLOW_COLOR "[MY_PRINTF + LIBC PRINTF]\n");                \
    my_printf(test_data_name);                                              \
    printf("\n" RESET_COLOR);                                               \
}

//------------------------------------------------------------------//

#define TEST_DATA_CHAR                      \
    "----------- Testing chars ---------\n" \
    "\t\'U\' = %c\n"                        \
    "\t\'g\' = %c\n"                        \
    "\t\'a\' = %c\n"                        \
    "\t\'y\' = %c\n"                        \
    "\t\'@\' = %c\n"                        \
    "\t\'7\' = %c\n"                        \
    "-----------------------------------\n",\
    'U',                                    \
    'g',                                    \
    'a',                                    \
    'y',                                    \
    '@',                                    \
    '7'

//------------------------------------------------------------------//

#define TEST_DATA_STRING                    \
    "---------- Testing strings --------\n" \
    "\t\"Кто\"    = %s\n"                   \
    "\t\"читает\" = %s\n"                   \
    "\t\"тот\"    = %s\n"                   \
    "\t\"лошара\" = %s\n"                   \
    "-----------------------------------\n",\
    "Кто",                                  \
    "читает",                               \
    "тот",                                  \
    "лошара"

//------------------------------------------------------------------//

#define TEST_DATA_HEX                       \
    "------- Testing hexadecimal -------\n" \
    "\t0xAB0BA = %x\n"                      \
    "\t0xDED   = %x\n"                      \
    "\t0xFFFF  = %x\n"                      \
    "\t-0x1234 = %x\n"                      \
    "\t0x00    = %x\n"                      \
    "             "                         \
    "-----------------------------------\n",\
    0xAB0BA,                                \
    0xDED,                                  \
    0xFFFF,                                 \
    -0x1234,                                \
    0x00

//------------------------------------------------------------------//

#define TEST_DATA_POINTER                   \
    "--------- Testing pointers --------\n" \
    "\t0xdeafbaba    = %p\n"                \
    "\t0xbeaf        = %p\n"                \
    "\tprintf_ptr    = %p\n"                \
    "\tmy_printf_ptr = %p\n"                \
    "\t0x00          = %p\n"                \
    "-----------------------------------\n",\
    (void*) 0xdeafbaba,                     \
    (void*) 0xbeaf,                         \
    printf,                                 \
    my_printf,                              \
    (void*) 0x00

//------------------------------------------------------------------//

#define TEST_DATA_OCTAL                     \
    "----------- Testing octal ---------\n" \
    "\t0777     = %o\n"                     \
    "\t01234567 = %o\n"                     \
    "\t0xFFFF   = %o\n"                     \
    "\t-0xFFFF  = %o\n"                     \
    "\t0x00     = %o\n"                     \
    "-----------------------------------\n",\
    0777,                                   \
    01234567,                               \
    0xFFFF,                                 \
    -0xFFFF,                                \
    0x00

//------------------------------------------------------------------//

#define TEST_DATA_BINARY                    \
    "---------- Testing binary ---------\n" \
    "\t0777     = %b\n"                     \
    "\t0x8888   = %b\n"                     \
    "\t0xFFFF   = %b\n"                     \
    "\t-1       = %b\n"                     \
    "\t0x00     = %b\n"                     \
    "-----------------------------------\n",\
    0777,                                   \
    0x8888,                                 \
    0xFFFF,                                 \
    -1,                                     \
    0x00

//------------------------------------------------------------------//

#define TEST_DATA_DECIMAL                   \
    "---------- Testing decimal --------\n" \
    "\t777      = %d\n"                     \
    "\t1337     = %d\n"                     \
    "\t128      = %d\n"                     \
    "\t0        = %d\n"                     \
    "\t-69      = %d\n"                     \
    "-----------------------------------\n",\
    777,                                    \
    1337,                                   \
    128,                                    \
    0,                                      \
    -69

//------------------------------------------------------------------//

#define TEST_DATA_PERCENT                     \
    "-- Testing escaping (double \"%%\") --\n"\
    "\t%% %% %% %%\n"                         \
    "-----------------------------------\n"

//------------------------------------------------------------------//

#define TEST_DATA_DEDA                        \
    "------------- Test deda -----------\n"   \
    "\n%d %s %x %d %%%c%b\n"                  \
    "-----------------------------------\n",  \
    -1,                                       \
    "love",                                   \
    3802,                                     \
    100,                                      \
    33,                                       \
    126

//------------------------------------------------------------------//

#define TEST_DATA_ERRORS                      \
    "--------- Test for errors ---------\n"   \
    "%c\n"                                    \
    "-----------------------------------\n",  \
    257
//——————————————————————————————————————————————————————————————————————————————————————————

#endif /* __TESTS_H__ */
