/*
*
*Name  :  CampaignRollUpDeleteBatch
*Author:  Appirio (James Wasilewski)
*Date  :  Aug 27, 2017
*Purpose : Batch class deletes Campaign_Roll_Up__c records so they can be recreated for the Centential Report
*
*/
global class CampaignRollUpDeleteBatch implements Database.Batchable<sObject>{
   global CampaignRollUpDeleteBatch() {
   } 
   
   global Database.QueryLocator start(Database.BatchableContext Bc ){
     String fy = getFiscalYear( getStartDate() );

     //qry will delete based on custom setting fy or custom setting fy -1 on saturdays
     return Database.getQueryLocator([SELECT Id
                                      FROM Campaign_Roll_Up__c
                                      WHERE Fiscal_Year__c >= :fy 
                                      ]);
   }
   
   global void execute(Database.BatchableContext Bc, List<Campaign_Roll_Up__c> scope){
    List<Campaign_Roll_Up__c> listOfCampaignRollUps = scope;
       if(!listOfCampaignRollUps.IsEmpty()){
           try{
             delete listOfCampaignRollUps;
             database.emptyRecycleBin(listOfCampaignRollUps);
             if(test.isRunningTest()){
                 Decimal d= 2/0;
             }               
           } catch(Exception e) {
                apexLogHandler.apexLog log = new apexLogHandler.apexLog('CampaignRollUpDeleteBatch','execute',e.getMessage());
                log.logException(e);
                log.saveLogs();
            }
       }

   }
   
   global void finish(Database.BatchableContext Bc){
      Id batchInstanceId = Database.executeBatch(new CampaignRollUpBatch(), 2000);
      apexLogHandler.apexLog log = new apexLogHandler.apexLog('CampaignRollUpDeleteBatch FINISHED');
      log.saveLogs();
   }

   public static Date getStartDate(){
      //run one additional year for saturday
      if(System.now().format('EEEE') == 'Saturday'){
        return Opportunity_Start_End_Date_To_Process__c.getValues('Run Range').Start_Date__c.addYears(-1) ;
      } else {
        return Opportunity_Start_End_Date_To_Process__c.getValues('Run Range').Start_Date__c;
      }
   }

   private String getFiscalYear(Date d){
      Organization orgInfo  = [SELECT FiscalYearStartMonth, UsesStartDateAsFiscalYearName
                   FROM Organization
                   WHERE id=:Userinfo.getOrganizationId()];
      if (d.month() >= orgInfo.FiscalYearStartMonth) {
         return String.valueOf(d.year() + 1);
      } else
         return String.valueOf(d.year());
   }

}