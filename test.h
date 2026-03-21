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
                                                                            \
    std::string printf_output = testing::internal::GetCapturedStdout();     \
                                                                            \
    testing::internal::CaptureStdout();                                     \
                                                                            \
    my_printf(test_data_name);                                              \
                                                                            \
    std::string my_printf_output = testing::internal::GetCapturedStdout();  \
                                                                            \
    ASSERT_EQ(my_printf_output, printf_output);                             \
    my_printf("\n" YELLOW_COLOR "[MY_PRINTF ] ");                           \
    my_printf(test_data_name);                                              \
    my_printf("\n" RESET_COLOR);                                            \
}

//------------------------------------------------------------------//

#define TEST_DATA_CHAR                      \
    "----------- Testing chars ---------\n" \
    "\t\t\'U\' = %c\n"                      \
    "\t\t\'g\' = %c\n"                      \
    "\t\t\'a\' = %c\n"                      \
    "\t\t\'y\' = %c\n"                      \
    "\t\t\'@\' = %c\n"                      \
    "\t\t\'7\' = %c\n"                      \
    "             "                         \
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
    "\t\t\"Кто\"    = %s\n"                 \
    "\t\t\"читает\" = %s\n"                 \
    "\t\t\"тот\"    = %s\n"                 \
    "\t\t\"лошара\" = %s\n"                 \
    "             "                         \
    "-----------------------------------\n",\
    "Кто",                                  \
    "читает",                               \
    "тот",                                  \
    "лошара"

//------------------------------------------------------------------//

#define TEST_DATA_HEX                       \
    "------- Testing hexadecimal -------\n" \
    "\t\t0xAB0BA = %x\n"                    \
    "\t\t0xDED   = %x\n"                    \
    "\t\t0xFFFF  = %x\n"                    \
    "\t\t-0x1234 = %x\n"                    \
    "\t\t0x00    = %x\n"                    \
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
    "\t\tint_ptr       = %p\n"              \
    "\t\t0xdeafbaba    = %p\n"              \
    "\t\t0xbeaf        = %p\n"              \
    "\t\tmy_printf_ptr = %p\n"              \
    "\t\t0x00          = %p\n"              \
    "             "                         \
    "-----------------------------------\n",\
    &int_a,                                 \
    (void*) 0xdeafbaba,                     \
    (void*) 0xbeaf,                         \
    my_printf_ptr,                          \
    (void*) 0x00

//------------------------------------------------------------------//

#define TEST_DATA_OCTAL                     \
    "----------- Testing octal ---------\n" \
    "\t\t0777     = %o\n"                   \
    "\t\t01234567 = %o\n"                   \
    "\t\t0xFFFF   = %o\n"                   \
    "\t\t-0xFFFF  = %o\n"                   \
    "\t\t0x00     = %o\n"                   \
    "             "                         \
    "-----------------------------------\n",\
    0777,                                   \
    01234567,                               \
    0xFFFF,                                 \
    -0xFFFF,                                \
    0x00

//------------------------------------------------------------------//

#define TEST_DATA_BINARY                    \
    "---------- Testing binary ---------\n" \
    "\t\t0777     = %b\n"                   \
    "\t\t0x8888   = %b\n"                   \
    "\t\t0xFFFF   = %b\n"                   \
    "\t\t-1       = %b\n"                   \
    "\t\t0x00     = %b\n"                   \
    "             "                         \
    "-----------------------------------\n",\
    0777,                                   \
    0x8888,                                 \
    0xFFFF,                                 \
    -1,                                     \
    0x00

//------------------------------------------------------------------//

#define TEST_DATA_DECIMAL                   \
    "---------- Testing decimal --------\n" \
    "\t\t777      = %d\n"                   \
    "\t\t1337     = %d\n"                   \
    "\t\t128      = %d\n"                   \
    "\t\t0        = %d\n"                   \
    "\t\t-69      = %d\n"                   \
    "             "                         \
    "-----------------------------------\n",\
    777,                                    \
    1337,                                   \
    128,                                    \
    0,                                      \
    -69

//------------------------------------------------------------------//

#define TEST_DATA_PERCENT                     \
    "-- Testing escaping (double \"%%\") --\n"\
    "\t\t%% %% %% %%\n"                       \
    "             "                           \
    "-----------------------------------\n"

//——————————————————————————————————————————————————————————————————————————————————————————

#endif /* __TESTS_H__ */
