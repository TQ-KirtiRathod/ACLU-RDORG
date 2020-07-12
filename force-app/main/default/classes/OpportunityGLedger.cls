/*
*
*Name  :  OpportunityGLedger
*Author:  Appirio India (Sai Krishna)
*Date  :  Jan 31, 2016
*Purpose : Class populates the Deposit Number field. Class called from Batch_SummaryReportGenerations
*/

public with sharing class OpportunityGLedger {
    
    private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id;
    private static final String OPPORTUNITY_RT_TRANSACTION_Id;
    public static Map<String,Schema.RecordTypeInfo> opptyRTMap;
    
     static {
        opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
        OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = opptyRTMap.get('Pledge Payment').getRecordTypeId();
        OPPORTUNITY_RT_TRANSACTION_Id = opptyRTMap.get('Transaction').getRecordTypeId();
     }
     /*
    Method populateDepositNumber
    @description : populates the Deposit Number field
    */
    public static Opportunity populateDepositNumber( Opportunity Opp ) {
        Set<Id> parentOpptyIds = new Set<Id>();
        Set<Id> batchLogIds = new Set<Id>();
        /*for(Opportunity Opp: Opportunities){
            if(opp.rC_Giving__Parent__c != null && (opp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id || opp.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id)){
                parentOpptyIds.add(opp.rC_Giving__Parent__c);
            }
            
            if(opp.Batch_Log__c != null ){
                batchLogIds.add(opp.Batch_Log__c);
            }       
        }*/
        
        //map<Id,Opportunity> parentOpportunties = new map<Id,Opportunity>([SELECT Id, Program_Type__c FROM Opportunity WHERE ID =:parentOpptyIds]);
        //map<Id, Batch_Log__c> batchLogs = new map<Id, Batch_Log__c>([SELECT Id, Batch_Date__c FROM Batch_Log__c WHERE ID =:batchLogIds]);
        //for(Opportunity Opp: Opportunities){
            String depositNumber;
            if(opp.rC_Giving__Parent__c != null && (opp.RecordTypeId == OPPORTUNITY_RT_PLEDGE_PAYMENT_Id || opp.RecordTypeId == OPPORTUNITY_RT_TRANSACTION_Id) && opp.Deposit_Site__c != null){
                if(String.ValueOf(opp.Deposit_Site__c).substring(0, 3) == 'NAI' || String.ValueOf(opp.Deposit_Site__c).substring(0, 3) == 'NAJ' || String.ValueOf(opp.Deposit_Site__c).substring(0, 3) == 'NAT' || String.ValueOf(opp.Deposit_Site__c).substring(0, 3) == 'NAY'){
                    if(opp.rC_Giving__Parent__r.Program_Type__c == '4'){
                        depositNumber = 'CRFW';
                    }
                    else if(opp.rC_Giving__Parent__r.Program_Type__c == '1' || opp.rC_Giving__Parent__r.Program_Type__c == '2' || opp.rC_Giving__Parent__r.Program_Type__c == '3'){
                        depositNumber = 'CRUW';
                    }
                }               
                else if(String.ValueOf(opp.Deposit_Site__c).substring(0, 3) != 'NAI' || String.ValueOf(opp.Deposit_Site__c).substring(0, 3) != 'NAJ' || String.ValueOf(opp.Deposit_Site__c).substring(0, 3) != 'NAT' || String.ValueOf(opp.Deposit_Site__c).substring(0, 3) != 'NAY'){
                    if(opp.rC_Giving__Parent__r.Program_Type__c == '4'){
                        depositNumber = 'CRF';
                    }
                    else if(opp.rC_Giving__Parent__r.Program_Type__c == '1' || opp.rC_Giving__Parent__r.Program_Type__c == '2' || opp.rC_Giving__Parent__r.Program_Type__c == '3'){
                        depositNumber = 'CRU';
                    }
                }
                
                if(Opp.Batch_Log__c != null && Opp.Batch_Log__r.Batch_Date__c != null){
                    //batch date in YYMMDD format
                    Date batchDate = Opp.Batch_Log__r.Batch_Date__c;
                    String dateYYMMDD = String.ValueOf(batchDate.year()).substring(2,4)+ ((batchDate.month()>9) ? String.ValueOf(batchDate.month()): '0'+String.ValueOf(batchDate.month()))+ ((batchDate.day()>9) ? String.ValueOf(batchDate.day()): '0'+String.ValueOf(batchDate.day()));
                    Datetime myDT = datetime.newInstance(batchDate.year(), batchDate.month(), batchDate.day());
                    String myDate = myDT.format('YYMMDD');
                    depositNumber = depositNumber + dateYYMMDD;
                }
                
                /*if(Opp.Batch_Log__c != null && Opp.Batch_Log__r.Batch_Date__c != null && Opp.Bank_Date__c != null && Date.ValueOf(Opp.Batch_Log__r.Batch_Date__c).month() != Date.ValueOf(Opp.Bank_Date__c).month()){
                    depositNumber = depositNumber + '-' + seqNumber;
                }*/
                
                /*if(opp.rC_Giving__Source_Code__c != null && String.ValueOf(opp.Campaign.rC_Giving__Channel__c) == 'Canvassing'){
                    depositNumber = depositNumber + 'C';
                }
                
                if(opp.Batch_Log__c != null && (opp.rC_Giving__Payment_Method__c == 'Cash/Check')){
                    depositNumber = depositNumber + 'S';
                }*/
                
                
                
            } 
            // update the deposit number for the giving record.
            opp.Deposit_Number__c = depositNumber;
            return opp;
        //}
    }
}