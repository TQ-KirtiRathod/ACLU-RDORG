/*
* Test Class for MultiselectController Class
*/
@isTest
public class MultiselectControllerTest 
{
    
    @isTest
    public static void testMultiselectController()
    {
        MultiselectController m = new MultiselectController();
        List<Account> lo = new List<Account>();
        // List<String> ro = new List<String>();
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('test','test'));
        m.leftOptions = options;
        List<SelectOption> options1 = new List<SelectOption>();
        options1.add(new SelectOption('test','test'));
        m.leftOptions = options1;
        m.leftOptionsHidden = 'test & testing';
        m.rightOptionsHidden = 'test1 & value';
        System.assertEquals(null,m.rightOptions);
        
    }
}