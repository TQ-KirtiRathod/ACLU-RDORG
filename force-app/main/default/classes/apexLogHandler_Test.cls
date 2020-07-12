@isTest
public class apexLogHandler_Test {
    
    public class testException extends Exception{}
    public class testCauseException extends Exception{}
    
    //Method to test logging for sample Lead
    private static testmethod void apexLogTest(){
        //@TODO ideal to put these record creations in an environment specific test record utilities class
        //Create Lead records
        List<Lead> leadList =  new List<Lead>();
        for (Integer i=0; i<5; i++) {
            leadList.add(TestUtils.createLead('AppirioAALTest', 'AppirioAALTestLead', 'Open', false));
        }
        insert leadList;
        
        //Create ApexLogSettings__c
        List<ApexLogSettings__c> apexLogSettingList = new List<ApexLogSettings__c>();
        apexLogSettingList.add(new ApexLogSettings__c(name='myClass::myMethod',active__c = true, MaxDays__c=90, MaxRecords__c=90000));
        apexLogSettingList.add(new ApexLogSettings__c(name='GlobalActivation',active__c = true, MaxDays__c=90, MaxRecords__c=90000));
        insert apexLogSettingList;
        
        //Create Log Handler object
        apexLogHandler.apexLog testLog = new apexLogHandler.apexLog('myClass','myMethod', 'myMsg');
        testLog.addLead(leadList[0].Id);
        testLog.logRequestInfo('outbound WS request'); 
        testLog.logResponseInfo('WS response'); 
        testLog.logStatusInfo(1,'myStatusMsg');
        
        Test.startTest();
        //Insert log record
        testLog.saveLogs();
        
        //Query inserted record an run asserts
        Apex_Log__c savedLog = [SELECT id,class_name__c,method_name__c, status_code__c, status_Message__c,
                                start_dtm__c,start_ms__c, stop_dtm__c,stop_ms__c, request_info__c,
                                response_info__c, Lead__c, Reference_ID__c, message__c
                                FROM Apex_Log__c 
                                WHERE ID = :testLog.logObj.id 
                                LIMIT 1 ];
        System.assertEquals(savedLog.class_name__c,'myClass');
        System.assertEquals(savedLog.method_name__c,'myMethod');
        System.assertEquals(savedLog.Message__c,'myMsg');
        System.assert(savedLog.Lead__c == leadList[0].Id);
        System.assertEquals(testLog.logObj.start_dtm__c, savedLog.start_dtm__c);
        System.assertEquals(testLog.logObj.start_ms__c, savedLog.start_ms__c);
        System.assertEquals(testLog.logObj.stop_ms__c, savedLog.stop_ms__c);
        System.assertEquals(testLog.logObj.stop_dtm__c, savedLog.stop_dtm__c);
        System.assert(savedlog.stop_ms__c >= savedlog.start_ms__c);
        System.assert(savedLog.request_info__c.contains('outbound WS request'));
        System.assert(savedLog.response_info__c.contains('WS response'));
        System.assertEquals(savedLog.status_code__c, 1);
        System.assert(savedLog.status_Message__c.contains('myStatusMsg'));
        Test.stopTest();
    }
    
    //Method to test exception handling
    private static testmethod void testLoggingExceptions(){
        //Create Log Handler object
        apexLogHandler.apexLog testLog =  new apexLogHandler.apexLog('myClassName', 'myMethodName','myMsg');
        try {
            testException newTestException = new testException('trigger test exception on save');
            newTestException.initCause(new testCauseException('test exception cause'));
            throw newTestException;
        } catch (Exception e) {
            testLog.logException(e);
        }
        
        Test.startTest();
        //Insert log record
        testLog.saveLogs();
        
        //Query inserted record an run asserts
        Apex_Log__c savedLog = [SELECT Id, exception_cause__c,Message__c,exception_type__c,
                                exception_Line_Number__c, exception_Stack_Trace_string__c
                                FROM Apex_Log__c 
                                WHERE ID = :testLog.logObj.id 
                                LIMIT 1];
        system.assert(savedLog.exception_cause__c.contains('test exception cause'),'bad exception cause field');
        System.assert(savedLog.Message__c.contains('trigger test exception on save'),'bad exception message field');
        System.assert(savedLog.exception_type__c.contains('apexLogHandler_Test.testException'),'wrong exception type');
        Test.stopTest();
    }
    
    //Method to test DML exception handling
    private static testmethod void testLoggingDmlExceptions(){
        //Create ApexLogSettings__c
        List<ApexLogSettings__c> apexLogSettingList = new List<ApexLogSettings__c>();
        apexLogSettingList.add(new ApexLogSettings__c(name='myClass::myMethod',active__c = true, MaxDays__c=90, MaxRecords__c=90000, LogDmlExceptions__c = true, Send_Email__c = true));
        apexLogSettingList.add(new ApexLogSettings__c(name='GlobalActivation',active__c = true, MaxDays__c=90, MaxRecords__c=90000));
        insert apexLogSettingList;
        
        //Create Log Handler object
        apexLogHandler.apexLog testLog =  new apexLogHandler.apexLog('myClass', 'myMethod','myMsg');
        testLog.logDebug('DebugMsg');
        testLog.logWarn('WarnMsg');
        testLog.logError('ErrorMsg');
        try {
            Account testAccount = new Account(); 
            insert testAccount; // Insert account without filling required field "Name"
        } catch (Exception e) {
            testLog.logException(e);
        }
        
        Test.startTest();
        //Insert log record
        testLog.saveLogs();
        
        //Query inserted record an run asserts
        Apex_Log__c savedLog = [SELECT Id, exception_cause__c,Message__c,exception_type__c,
                                exception_Line_Number__c, exception_Stack_Trace_string__c,
                                (Select Id From DML_Exceptions__r) 
                                FROM Apex_Log__c 
                                WHERE ID = :testLog.logObj.id 
                                LIMIT 1];
        system.assert(savedLog.DML_Exceptions__r.size() > 0);
        Test.stopTest();
    }
    
    //Method to test exception when Saving
    private static testmethod void testThrowingExceptionOnSaveLog() {
        //Create Log Handler object
        apexLogHandler.apexLog testLog = new apexLogHandler.apexLog('myClassName','myMethodName','myMsg', LoggingLevel.DEBUG);
        testLog.logException(new apexLogHandler.For_Testing_Force_Exception('ouch'));
        testLog.saveLogs();
        
        //Test if log is not inserted
        System.assert(testLog.logObj.id == null, 'This log record should not have been inserted.');
    }
    
    //Method to check exception loggin
    private static testMethod void testThrowingExceptionWhileLoggingException() {
        //Create Log Handler object
        apexLogHandler.apexLog audit = new apexLogHandler.apexLog('myClass','myMethod','myMsg', LoggingLevel.DEBUG, 'myRefId');
        try {
            audit.logException(null);
            audit.logException(null);
        } catch (Exception e) {
            System.assert(true, 'Logging an exception should never throw another exception');
        }
    }
}