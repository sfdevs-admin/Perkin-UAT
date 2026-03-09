/*
Change Log:
-----------------------------------------------------------------------------------------------------------------------
VERSION 	AUTHOR			DATE			DETAIL                                            
-----------------------------------------------------------------------------------------------------------------------
01.0		Tony Tran		20-NOV-15		Initial Version, created to prevent recursive triggers
*/
public class Utility_Recursive_Check
{
    public static boolean run = true;
    
    public static boolean runOnce()
    {
        if(run)
        {
     		run=false;
     		return true;
    	}
        else
        	return run;
    }
}