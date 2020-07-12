/*
*
*Name  :  BatchPopulateActPreferencesForGoLive
*Author:  Appirio  (James Wasilewski)
*Date  :  May 22, 2017
*Purpose : Populate the preference values string on Account for initialization. Batch ran intended to run for go-live only
*
*/
global class BatchPopulateActPreferencesForGoLive implements Database.Batchable<sObject>, Database.Stateful {

	Private static Set<String> commonPreValues = new Set<String>{'AL','AN','AY','FA','FN','U1','UA','UN','Z1','ZD','ZN',
	                                        'AXXAPNO','AXXBNNO','AXXCUNO','AXXEMNO','AXXINNO',
	                                        'AXXNWNO','AXXPHNO','AXXTMNO','OXXAKNO','OXXAPNO',
	                                        'OXXCTNO','OXXINNO','OXXIPNO','OXXNWNO','OXXPCNO',
	                                        'OXXPHNO','OXXPUNA','OXXPUNL','OXXPUNO','OXXTMNO','OXXVDNO',
	                                        'AXXTRANS','AJ','AN','AL'
	                                        };
	private Datetime startTime;
	private Account lastAccount = new Account();
	private Double counter;

	global BatchPopulateActPreferencesForGoLive() {
		startTime = datetime.now();
		counter = 0;
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([select id, rC_Bios__Code_Value__c, rC_Bios__Category__c,  rC_Bios__Account__c
																		from rC_Bios__Preference__c
																		where rC_Bios__Active__c = True
																			and rC_Bios__Account__c != ''
																			//and rC_Bios__Code_Value__c != ''
																			//and (rC_Bios__Account__c = '001W000000RUCTU'
																			//	OR  rC_Bios__Account__c = '001W000000QG8OL'
																			//	OR  rC_Bios__Account__c = '001W000000QkmPn')
																		order by rC_Bios__Account__c, rC_Bios__Code_Value__c
																		//Limit 400
																		]);

			//select id, name, Rpt_Board_Member__c, Affiliate_Major_Gifts_Program_ML__c,
								//Affiliate_Major_Donor_Prospect_MQ__c, Rpt_Common_Preference_Filters__c, Rpt_Interest_String__c, Preference_String__c,
						//(select rC_Bios__Code_Value__c, rC_Bios__Category__c from rC_Bios__Preferences__r where rC_Bios__Active__c = True order by rC_Bios__Code_Value__c ASC)
						//from Account
						//where Id IN (select rC_Bios__Account__c from rC_Bios__Preference__c )
						//where id = '001W000000RUCTU'

	}

  global void execute(Database.BatchableContext BC, List<rC_Bios__Preference__c> scope) {
		//system.debug(scope.size());
		Map<id, Account> accountsToUpdate = new Map<ID, Account>();
		Account a = new Account();  //current account
		//String lastId;

		if(scope.size()>0){
			for(rC_Bios__Preference__c pref: scope){
				//if id is diferent than previous account start new account write last account to accouts to update
				//if this is last row write account to last account
				system.debug('**new record : ' + pref);

				if ( a.Id == null ){  //first run
					a.Id = pref.rC_Bios__Account__c;
					//system.debug('******a.id was null: ' + a.Id);
				} else if( pref.rC_Bios__Account__c != a.Id ){  // id changes, write to update, clear it and initialize new account
					//system.debug('******a.id was different: ' + a);
					accountsToUpdate.put(a.Id, a);
					//system.debug('******accountsToUpdate: ' + accountsToUpdate);
					//a = .clear();  this did not work kept the reference
					a = new Account(); //resets reference
					//system.debug('******a cleared: ' + a);
					a.Id = pref.rC_Bios__Account__c;
					//system.debug('******a updated: ' + a);
				}
				//system.debug('Account id ' + a.id );

				if(pref.rC_Bios__Code_Value__c != '' && pref.rC_Bios__Code_Value__c != null){

					if(pref.rC_Bios__Code_Value__c == 'BA') {  //Board Member
				    a.Rpt_Board_Member__c=true;
				    //system.debug('***********checked Board Member');
					}
					if(pref.rC_Bios__Code_Value__c == 'ML'){  //Affiliate Major Gifts Program (ML)
						a.Affiliate_Major_Gifts_Program_ML__c=true;
						//system.debug('***********checked Affiliate Major Gifts Program');
					}
					if(pref.rC_Bios__Code_Value__c == 'MQ'){  //Affiliate Major Donor Prospect (MQ)
						a.Affiliate_Major_Donor_Prospect_MQ__c=true;
						//system.debug('***********checked Affiliate Major Gifts Program');
					}
					if(commonPreValues.contains(pref.rC_Bios__Code_Value__c)){  //Common Preference Filters
						a.Rpt_Common_Preference_Filters__c = add_dedup(a.Rpt_Common_Preference_Filters__c, pref.rC_Bios__Code_Value__c);
						//system.debug('***********checked Common Preference Filters: ' + pref.rC_Bios__Code_Value__c);
					}
					if(pref.rC_Bios__Category__c == 'Interests') {  //Interest String
						a.Rpt_Interest_String__c = add_dedup(a.Rpt_Interest_String__c, pref.rC_Bios__Code_Value__c);
						//system.debug('***********added Interest String: ' + pref.rC_Bios__Code_Value__c);
					} else {  //Preference String
						a.Preference_String__c = add_dedup(a.Preference_String__c, pref.rC_Bios__Code_Value__c);
						//system.debug('***********added Preference String: ' + pref.rC_Bios__Code_Value__c);
						//system.debug('current pref string  ' + a.Preference_String__c);
					}
				}
				lastAccount = a;
			}//end account for loop
		}

		try{
		  if(!accountsToUpdate.isEmpty()) {
		  	//system.debug('account update call ' + accountsToUpdate.size() +' : '+ accountsToUpdate);
		     counter += accountsToUpdate.size();
		     //system.debug('counter = '+ counter+'  -size '+accountsToUpdate.size());
		     update accountsToUpdate.values();
		  }
		}
		catch(Exception e) {
		  apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchPopulateActPreferencesForGoLive','execute',e.getMessage());
		  log.logException(e);
		  log.saveLogs();
		}
	}

	global void finish(Database.BatchableContext BC) {
		//system.debug('final lastAccount '  +' : '+ lastAccount);
		update lastAccount;


		Datetime endTime = datetime.now();
		Integer elapsedMinutes = endTime.minute() - startTime.minute() ;

		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

		mail.setToAddresses(new String[]{'jwasilewski@appirio.com'});
		mail.setReplyTo('jwasilewski@appirio.com');
		mail.setSenderDisplayName('Batch Processing');
		mail.setSubject('Batch Process Completed');
		mail.setPlainTextBody('Batch BatchPopulateActPreferencesForGoLive Process has completed.  Time Ran = ' + elapsedMinutes +'  counter = ' + counter);

		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

		apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchPopulateActPreferencesForGoLive FINISHED');
		log.saveLogs();
	}

	private String add_dedup(String prefString, String codeVal){
		//system.debug('dedup start '+prefString);
		if(String.isBlank(prefstring)){
			prefString = ':'+codeVal+':';
		} else if(!prefstring.contains(':'+codeVal+':')){
			prefString = prefString + codeVal+':';
		}
		//system.debug('*******dedup stop '+prefString);
		return prefString;
	}

}