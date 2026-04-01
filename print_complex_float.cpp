#include <stdio.h>

//------------------------------------------------------------------//

// extern "C" int 
// PrintComplexFloat(double double_value)
// {
//     int printf_return = printf("%f", double_value);
    
//     fflush(stdout);
    
//     return printf_return;
// }

extern "C" int 
PrintComplexFloat(char* buffer, double double_value)
{
    return sprintf(buffer, "%f", double_value);   
}


//------------------------------------------------------------------//