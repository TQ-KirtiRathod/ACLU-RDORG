/*
*
*Name  :  QueueableControlSetting
*Author:  Appirio  (Tom Burre)
*Date  :  May 28, 2017
*Purpose : Contains method to create & return record of Queueable_Control__c custom setting
*
*/
public with sharing class QueueableControlSetting {

  private static Queueable_Control__c testConfig = null;

  public static Queueable_Control__c getAppConfig() {
    if(Test.isRunningTest() && testConfig!=null) return testConfig;

    Queueable_Control__c theobject = Queueable_Control__c.getInstance('MainQueueable');
    if(theObject==null || Test.isRunningTest()) {
      theObject = new Queueable_Control__c();
      theObject.name = 'MainQueueable';
      theObject.Enable_Diagnostics__c = (Test.isRunningTest())? true: false;
      theObject.Queueable_Enabled__c = true;
      if(!Test.isRunningTest()) {
        Database.Insert(theobject);
      } else {
        testconfig = theObject;
      }
    }
    return theObject;
  }

  public static Boolean diagnosticsEnabled {
    get {
      return getAppConfig().Enable_Diagnostics__c;
    }
  }

  public static Boolean appEnabled {
    get {
      return getAppConfig().Queueable_Enabled__c;
    }
  }

}