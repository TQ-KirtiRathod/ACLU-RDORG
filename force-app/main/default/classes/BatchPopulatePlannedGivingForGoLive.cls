/*
*
*Name  :  BatchPopulatePlannedGivingForGoLive
*Author:  Appirio (James Wasilewski)
*Date  :  May 31, 2017
*Purpose : Batch class to populate Rpt_Estimated_Average_Giving_Amount__c on rC_Giving__Planned_Giving__c for one time run
*
*/
global class BatchPopulatePlannedGivingForGoLive implements Database.Batchable<sObject>, Database.Stateful {
	
	private Datetime startTime;
	private Integer counter;
	
	global BatchPopulatePlannedGivingForGoLive() {
		startTime = datetime.now();
		counter = 0;
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([Select id, Gift_Date__c, Rpt_Estimated_Average_Giving_Amount__c 
																			from rC_Giving__Planned_Giving__c 
																			where Gift_Date__c != null
																			//and id ='a14W00000017TTR'
																		]);
	}

  global void execute(Database.BatchableContext BC, List<rC_Giving__Planned_Giving__c> scope) {
		Map<ID, rC_Giving__Planned_Giving__c> updatePg = new Map<ID, rC_Giving__Planned_Giving__c>();

		if(scope.size()>0){
			for(rC_Giving__Planned_Giving__c pg: scope){
				
				Integer fiscalYear = (pg.Gift_Date__c.month()>4)?	pg.Gift_Date__c.year() +1: pg.Gift_Date__c.year();
				
				if( fiscalYear == 2015){
					pg.Rpt_Estimated_Average_Giving_Amount__c = 161248.91;
				}else if (fiscalYear == 2016){
					pg.Rpt_Estimated_Average_Giving_Amount__c = 176617.70;
				} else if (fiscalYear == 2017) {
					pg.Rpt_Estimated_Average_Giving_Amount__c = 168221.64;
				} else if (fiscalYear == 2018) {
					pg.Rpt_Estimated_Average_Giving_Amount__c = 163177.95;
				}
				updatePg.put(pg.Id, pg);
			}
		}

		system.debug('updatePg.size = ' + updatePg.size());
		try{
		  if(updatePg.size()>0) {
		     counter += updatePg.size();
		     system.debug('counter = '+ counter+'  -size '+updatePg.size());
		     update updatePg.values();
		  }
		}
		catch(Exception e) {
		  apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchPopulatePlannedGivingForGoLive','execute',e.getMessage());
		  log.logException(e);
		  log.saveLogs();
		}
		system.debug('counter 1 = '+ counter);

	}
	
	global void finish(Database.BatchableContext BC) {
		system.debug('counter 2 = '+ counter);
		Datetime endTime = datetime.now();
		Integer elapsedMinutes = endTime.minute() - startTime.minute() ;
		
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		
		mail.setToAddresses(new String[]{'jwasilewski@appirio.com'});
		mail.setReplyTo('jwasilewski@appirio.com');
		mail.setSenderDisplayName('Batch Processing');
		mail.setSubject('Planned Giving Batch Process Completed');
		mail.setPlainTextBody('Batch BatchPopulatePlannedGivingForGoLive Process has completed.  Time Ran = ' + elapsedMinutes +'  counter = ' + counter);
		 
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

		apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchPopulatePlannedGivingForGoLive FINISHED');
		log.saveLogs();
	}
	
}