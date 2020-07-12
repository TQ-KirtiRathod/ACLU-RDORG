/*
*Name  :  TriggerState
*Author:  Appirio India (Ashu Gupta)
*Date  :  October 26, 2016
*Purpose : Utility class that returns the state of a given trigger and if it should execute when test methods are executed
*
*/
public abstract class TriggerState {
    static Map<String, TriggerSettings__c> triggerSetting = TriggerSettings__c.getAll();
    
    public static boolean isActive(String triggerName) {
        boolean isActive = true;
        try {
            if(triggerSetting.containsKey(triggerName)) {
                isActive = (Boolean)triggerSetting.get(triggerName).get('isActive__c');
                if(Test.isRunningTest()) { isActive = executeForTestMethods(triggerName); }
            } else {
                addTriggerToSettings(triggerName);
            }
        } catch (Exception ex) {
          system.debug('An Error has occured. '+ex.getMessage());  
        }
        return isActive;
    }
    
    public static boolean executeForTestMethods(String triggerName) {
        boolean isTestMode = true;
        if(Test.isRunningTest()) {
            try {
                if(triggerSetting.containsKey(triggerName)) {
                    isTestMode = (Boolean)triggerSetting.get(triggerName).get('isTestMode__c');
                }
            } catch (Exception ex) {
                system.debug('An Error has occured. '+ex.getMessage()); 
            }
        }
        return isTestMode ;
    }
    
    private static void addTriggerToSettings(String triggerName) {
        TriggerSettings__c triggerSettings = new TriggerSettings__c();
        triggerSettings.Name = triggerName;
        triggerSettings.isActive__c = true;
        triggerSettings.isTestMode__c = true;
        try{        
            insert triggerSettings;
        } catch(Exception e) {
          apexLogHandler.apexLog log = new apexLogHandler.apexLog('TriggerState','addTriggerToSettings',e.getMessage());
          log.logException(e);
          log.saveLogs();
        }
        triggerSetting = TriggerSettings__c.getAll();           
    }
}