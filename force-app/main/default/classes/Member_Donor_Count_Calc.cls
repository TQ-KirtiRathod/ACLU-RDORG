/*
*
*Name  :  Member_Donor_Count_Calc
*Author:  Appirio India (Sai Krishna )
*Date  :  July 05, 2017
*Purpose : Calculates Member and Donor Count on Affiliate Yearly records from the number of Transactions, 
*          Pledge Payments & Soft Credits. If amount >= 5, then it is calculated under member count, else donor count.
*
*/
global with sharing class Member_Donor_Count_Calc implements Database.Batchable<sObject>,Database.stateful {
	
	// RecordType Ids
	private static Map<String,Schema.RecordTypeInfo> opptyRTMap;
	private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
	private static final String OPPORTUNITY_RT_TRANSACTION_Id;
	private static final String OPPORTUNITY_RT_SOFTCREDIT_Id;
	private static Map<String,Id> affliateCodeToaffYearlyId;
	private static Set<String> setOfRequiredCodes;
	private List<Id> allAffiliateYearls;
	private  String accAffiliationCode;
	private Integer memberCount=0;
	private Integer donorCount=0;
	public Date startDate;
    public Date endDate;
	
	
    //private static set<String> setOfNationalCodes;
	
	static{
		opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
        OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = opptyRTMap.get('Pledge Payment').getRecordTypeId();
        OPPORTUNITY_RT_TRANSACTION_Id = opptyRTMap.get('Transaction').getRecordTypeId();
        OPPORTUNITY_RT_SOFTCREDIT_Id = opptyRTMap.get('Soft Credit').getRecordTypeId();
        setOfRequiredCodes = new Set<String> {'A','B','D','P'};
        //setOfNationalCodes = new Set<String> {'NA', 'NN', 'UN', 'FN', 'PF', 'EN', 'PU', 'UA'};
	}
	
	global Member_Donor_Count_Calc(Set<Id> affiYearlyIds) {
		this.allAffiliateYearls = new List<Id>(affiYearlyIds);
        Affiliate_Yearly__c aff = [SELECT Id, Member_Donor_Count_From_Date__c, Account__r.Affiliation__c, Member_Donor_Count_To_Date__c
                                   FROM Affiliate_Yearly__c
                                   WHERE Id = : allAffiliateYearls[0]];
       this.accAffiliationCode = aff.Account__r.Affiliation__c;                                   
       this.startDate = aff.Member_Donor_Count_From_Date__c;
       this.endDate = aff.Member_Donor_Count_To_Date__c;
	}
	
	global Database.QueryLocator start(Database.BatchableContext Bc ){

        //system.debug('CMI Calculator Start');
        Set<String> setOfValidRecordTypes = new Set<String> { OPPORTUNITY_RT_TRANSACTION_Id, OPPORTUNITY_RT_PLEDGE_PAYMENT_Id, OPPORTUNITY_RT_SOFTCREDIT_Id };

        return Database.getQueryLocator([SELECT Id, Amount, accountId, Sharing_Entity_Affiliation__c, Program_Type__c, Exclude_Cost_Factors_in_RevShare__c, Exclude_from_Revenue_Sharing__c,
        							 Sharing_Entity__c, Sharing_Code__c, RecordTypeId, Cost_Factor__c, Use_Campaign_Cost__c, CloseDate
                                     FROM Opportunity
                                     WHERE RecordTypeId IN :setOfValidRecordTypes
                                     AND stageName = 'Completed'
                                     AND (Account_Affiliation__c =: accAffiliationCode.subString(0,2)) //TODO: Does we need to check with national Codes.
                                     AND CloseDate >=: startDate AND CloseDate <=: endDate
                                    ]);
    }
	
	global void execute(Database.BatchableContext Bc, List<Opportunity> scope){
		for(Opportunity theOpp : scope){
			if(theOpp.amount >=0 && theOpp.Sharing_Code__c != null){
				if(!setOfRequiredCodes.contains(string.ValueOf(theOpp.Sharing_Code__c).substring(0,1)) && theOpp.amount>=5 ){
					memberCount+= 1;
				}
				else{
					donorCount+=1;
				}
			}
		}
	}
	
	global void finish(Database.BatchableContext Bc){
        //system.debug('CMI Calculator finish');
        Affiliate_Yearly__c updatedYearlyAffiliate = new Affiliate_Yearly__c(Id = allAffiliateYearls[0], Member_Count__c = memberCount, Donor_Count__c = donorCount,
                                                                                Member_Donor_Count_Last_Calculated__c = system.now());
        
        try {
            update updatedYearlyAffiliate;
            allAffiliateYearls.remove(0);
            //system.debug('allAffiliateYearls'+allAffiliateYearls.Size());
            if(!allAffiliateYearls.IsEmpty()){
                Member_Donor_Count_Calc batch = new Member_Donor_Count_Calc(new Set<Id>(allAffiliateYearls));
                Database.executeBatch(batch,200);
            }
            else {
                //system.debug('Completed::>>>>');
                Revenue_Sharing_Sytem_Controls__c revenueSharingControls= Revenue_Sharing_Sytem_Controls__c.getAll().Values()[0];
                
                //update the Custom Setting.
                update new Revenue_Sharing_Sytem_Controls__c(Id = revenueSharingControls.Id, Report_Request_Owner_Email__c = null, Report_Request_In_Progress__c = false);
                
                // Send Email
                RevSharing_StageReportCalculations.sendEmail('Member/Donor', revenueSharingControls.Report_Request_Sender_Email__c, revenueSharingControls.Report_Request_Owner_Email__c, String.ValueOf(endDate.year()));
                
                
            }

        }
        catch(Exception e) {
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('Member_Donor_Count_Calc','finish',e.getMessage()); 
            log.logException(e);
            log.saveLogs();
        } 
	}
	
    
}