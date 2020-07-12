/*
*
*Name  :  RSFUtility
*Author:  Appirio India (Shikha Gupta)
*Date  :  December 28, 2016
*Purpose :  This class is used as rollup summary utility. 
            You can develop trigger on any object and use Utility class to automate rollup summary on fields
*
*/
/*****************************************************************************
ROLLUP SUMMARY 
This clas is used as rollup summary utility. You can develop trigger on any object and use 
Utility class to automate rollup summary on fields

COUNT example:
-----------------------------------------------------------------------------------------
list<RSFUtility.fieldDefinition> fieldDefinitions = new list<RSFUtility.fieldDefinition> {
    new RSFUtility.fieldDefinition ('COUNT', 'ID','Complete_Tasks_in_Tasks_RS__c') 
    // new RSFUtility.fieldDefinition ('COUNT', 'ID','<Field on Parent>') 
};

RSFUtility.rollUpTrigger(fieldDefinitions, trigger.new, 'Task__c', 'Project__c', 'Milestone__c', ' AND Complete__c = true');
// RSFUtility.rollUpTrigger(fieldDefinitions, trigger.new, '<Child Object>', '<Child-Parent Lookup Field>', '<Parent Object>', '<Where Condition>');
-----------------------------------------------------------------------------------------


SUM example:
-----------------------------------------------------------------------------------------
list<RSFUtility.fieldDefinition> fieldDefinitions = new list<RSFUtility.fieldDefinition> {
    new RSFUtility.fieldDefinition ('SUM', 'Total_Expense__c','Actual_Expense_From_Tasks_RS__c') 
    // new RSFUtility.fieldDefinition ('SUM', '<Field on Child to Rollup>','<Field on Parent>') 
};

RSFUtility.rollUpTrigger(fieldDefinitions, trigger.new, '<Child Object>', '<Child-Parent Lookup Field>', '<Parent Object>', '');
-----------------------------------------------------------------------------------------

******************************************************************************/


public with sharing class RSFUtility {
//the following class will be used to house the field names
    //and desired operations
    
    public class fieldDefinition {
        public String operation {get;set;}
        public String childField {get;set;}
        public String parentField {get;set;}
         
        public fieldDefinition (String o, String c, String p) {
            operation = o;
            childField = c;
            parentField = p;
        }
    }
    
    public static void rollUpTrigger(list<fieldDefinition> fieldDefinitions,
    
    list<sObject> records, String childObject, String childParentLookupField, 
    
    String parentObject, String queryFilter) {
         
        //Limit the size of list by using Sets which do not contain duplicate
        //elements prevents hitting governor limits
        set<Id> parentIds = new set<Id>();
         
        for(sObject s : records) {
            if((Id)s.get(childParentLookupField) != null){
                parentIds.add((Id)s.get(childParentLookupField));
            }
        }
         
        processRollUp(fieldDefinitions, records, childObject, childParentLookupField, parentObject, queryFilter, parentIds);
         
    }
 
    public static void processRollUp(list<fieldDefinition> fieldDefinitions, list<sObject> records, String childObject, 
        String childParentLookupField, String parentObject, String queryFilter, set<Id> parentIds){
        //populate query text strings to be used in child aggregrator and 
        //parent value assignment
        String fieldsToAggregate = '';
        String parentFields = '';
         
        for(fieldDefinition d : fieldDefinitions) {
            fieldsToAggregate += d.operation + '(' + d.childField + ') ' + 
            ', ';
            parentFields += d.parentField + ', ';
        }
         
        //Using dynamic SOQL with aggergate results to populate parentValueMap
        String aggregateQuery = 'Select ' + fieldsToAggregate + 
        childParentLookupField + ' from ' + childObject + ' where  ' + 
        childParentLookupField + ' IN :parentIds ' + queryFilter + ' ' +
        ' group by ' + childParentLookupField;
        //Map will contain one parent record Id per one aggregate object
        map<Id, AggregateResult> parentValueMap = 
        new map <Id, AggregateResult>();
         
        if(!parentIds.isEmpty()) {
            for(AggregateResult q : Database.query(aggregateQuery)){
                parentValueMap.put((Id)q.get(childParentLookupField), q);
            }
        }
         
        //list of parent object records to update
        list<sObject> parentsToUpdate = new list<sObject>();

        String parentQuery = 'select ' + parentFields + ' Id ' +
         ' from ' + parentObject + ' where Id IN :parentIds';
         
        //for each affected parent object, retrieve aggregate results and 
        //for each field definition add aggregate value to parent field
            if(!parentIds.isEmpty()) {
                for(sObject s : Database.query(parentQuery)) {
                Integer row = 0; //row counter reset for every parent record
                for(fieldDefinition d : fieldDefinitions) {
                    String field = 'expr' + row.format();
                    AggregateResult r = parentValueMap.get(s.Id);
                    if(r != null) { 
                        Decimal value = ((Decimal)r.get(field) == null ) ? 0 : 
                            (Decimal)r.get(field);
                        s.put(d.parentField, value);
                    } else {
                        s.put(d.parentField, 0);
                    }
                    row += 1; //plus 1 for every field definition after first
                }            
                parentsToUpdate.add(s);
            }
            }
         
        //if parent records exist, perform update of all parent records 
        //with a single DML statement
        if(parentsToUpdate.Size() > 0) {
            try{
                update parentsToUpdate;
            } catch(Exception e) {
                  apexLogHandler.apexLog log = new apexLogHandler.apexLog('RSFUtility','processRollUp',e.getMessage());
                  log.logException(e);
                  log.saveLogs();
            }
        }
    }
     
    public static void updatePortfolioRollUpRecords(Set<Id> portFolioIds) {
        if(portFolioIds.isEmpty()) {
            return;
        }
        Map<String,Schema.RecordTypeInfo> opptyRTMap;
        opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
        Id OPPORTUNITY_RT_PROPOSAL_ID = opptyRTMap.get('Proposal').getRecordTypeId();
        Id OPPORTUNITY_RT_GRANT_Id = opptyRTMap.get('Grant').getRecordTypeId();
        if(portFolioIds.contains(NULL)){
            portFolioIds.remove(NULL);
        }
        List<Portfolio__c> portfolioToUpdate = new List<Portfolio__c>();
        Map<id, PortFolioFieldsWrapper> portfolioFieldsMap = new Map<id, PortFolioFieldsWrapper>();
        for( Opportunity opp : [Select rC_Giving__Requested_Amount__c , rC_Giving__Projected_Amount__c , Projected_Additional__c , 
                               Closed_Amount_Total__c , Outstanding_Pledge_Amount__c , Expected_Giving_Amount_Total__c, Portfolio__c, 
                               Portfolio_2__c, Portfolio_3__c
                               from Opportunity 
                               where (Portfolio__c IN : portFolioIds OR Portfolio_2__c IN: portFolioIds
                                    OR Portfolio_3__c IN: portFolioIds ) 
                                   AND (RecordTypeId = :OPPORTUNITY_RT_PROPOSAL_ID OR RecordTypeId =:OPPORTUNITY_RT_GRANT_Id )]){
            if( opp.Portfolio__c != NULL ){
                if( !portfolioFieldsMap.containsKey(opp.Portfolio__c) ){
                    portfolioFieldsMap.put( opp.Portfolio__c, new PortFolioFieldsWrapper(opp.rC_Giving__Requested_Amount__c, 
                                                                    opp.rC_Giving__Projected_Amount__c,
                                                                    opp.Projected_Additional__c, opp.Closed_Amount_Total__c, 
                                                                    opp.Outstanding_Pledge_Amount__c,
                                                                    opp.Expected_Giving_Amount_Total__c));
                } else {
                    PortFolioFieldsWrapper wrp = new PortFolioFieldsWrapper(opp.rC_Giving__Requested_Amount__c, 
                                                                    opp.rC_Giving__Projected_Amount__c,
                                                                    opp.Projected_Additional__c, 
                                                                    opp.Closed_Amount_Total__c, 
                                                                    opp.Outstanding_Pledge_Amount__c,
                                                                    opp.Expected_Giving_Amount_Total__c);
                    portfolioFieldsMap.put( opp.Portfolio__c, sumTwoPortfolioWrapper( portfolioFieldsMap.get(opp.Portfolio__c), wrp));
                }
            }
            
            if( opp.Portfolio_2__c != NULL ){
                if( !portfolioFieldsMap.containsKey(opp.Portfolio_2__c) ){
                    portfolioFieldsMap.put( opp.Portfolio_2__c, new PortFolioFieldsWrapper(opp.rC_Giving__Requested_Amount__c, 
                                                                    opp.rC_Giving__Projected_Amount__c,
                                                                    opp.Projected_Additional__c, 
                                                                    opp.Closed_Amount_Total__c, 
                                                                    opp.Outstanding_Pledge_Amount__c,
                                                                    opp.Expected_Giving_Amount_Total__c));
                } else {
                    PortFolioFieldsWrapper wrp = new PortFolioFieldsWrapper(opp.rC_Giving__Requested_Amount__c, 
                                                                    opp.rC_Giving__Projected_Amount__c,
                                                                    opp.Projected_Additional__c, 
                                                                    opp.Closed_Amount_Total__c, 
                                                                    opp.Outstanding_Pledge_Amount__c,
                                                                    opp.Expected_Giving_Amount_Total__c);
                    portfolioFieldsMap.put( opp.Portfolio_2__c, sumTwoPortfolioWrapper( portfolioFieldsMap.get(opp.Portfolio_2__c), wrp));
                }
            }
            
            if( opp.Portfolio_3__c != NULL ){
                if( !portfolioFieldsMap.containsKey(opp.Portfolio_3__c) ){
                    portfolioFieldsMap.put( opp.Portfolio_3__c, new PortFolioFieldsWrapper(opp.rC_Giving__Requested_Amount__c, 
                                                                    opp.rC_Giving__Projected_Amount__c,
                                                                    opp.Projected_Additional__c, 
                                                                    opp.Closed_Amount_Total__c, 
                                                                    opp.Outstanding_Pledge_Amount__c,
                                                                    opp.Expected_Giving_Amount_Total__c));
                } else {
                    PortFolioFieldsWrapper wrp = new PortFolioFieldsWrapper(opp.rC_Giving__Requested_Amount__c, 
                                                                    opp.rC_Giving__Projected_Amount__c,
                                                                    opp.Projected_Additional__c, 
                                                                    opp.Closed_Amount_Total__c,
                                                                    opp.Outstanding_Pledge_Amount__c,
                                                                    opp.Expected_Giving_Amount_Total__c);
                    portfolioFieldsMap.put( opp.Portfolio_3__c, sumTwoPortfolioWrapper( portfolioFieldsMap.get(opp.Portfolio_3__c), wrp));
                }
            }
        }
        
        for(Id portfolioId :portfolioFieldsMap.keySet() ){
            PortFolioFieldsWrapper wrp = portfolioFieldsMap.get(portfolioId);
            portfolioToUpdate.add(new Portfolio__c( Id = portfolioId, 
                                                    Sum_of_Requested_Amount__c = wrp.requestedAmount,
                                                    Sum_of_Projected_Amount__c = wrp.ProjectedAmount,
                                                    Sum_of_the_Projected_Additional_Amount__c = wrp.additionalAmount,
                                                    Sum_of_Closed_Amount__c = wrp.closedAmount,
                                                    Sum_of_Outstanding_Pledge_Amount__c = wrp.outstandingPledgeAmount,
                                                    Sum_of_Expected_Giving_Amount__c = wrp.expectedGivingAmount));
        }
        
        for(Id pfID : portFolioIds){
            if( !portfolioFieldsMap.containsKey(pfID) ){
                portfolioToUpdate.add(new Portfolio__c( Id = pfID, 
                                                    Sum_of_Requested_Amount__c = 0,
                                                    Sum_of_Projected_Amount__c = 0,
                                                    Sum_of_the_Projected_Additional_Amount__c = 0,
                                                    Sum_of_Closed_Amount__c = 0,
                                                    Sum_of_Outstanding_Pledge_Amount__c = 0,
                                                    Sum_of_Expected_Giving_Amount__c = 0));
            }
        }
        
        if( portfolioToUpdate.size() > 0 ){
            try{
                update portfolioToUpdate;
            } catch(Exception e) {
                  apexLogHandler.apexLog log = new apexLogHandler.apexLog('RSFUtility','processRollUp',e.getMessage());
                  log.logException(e);
                  log.saveLogs();
            }
        }
         
    }
    
    
    public class PortFolioFieldsWrapper{
        Decimal requestedAmount, ProjectedAmount, additionalAmount, closedAmount;
        Decimal outstandingPledgeAmount, expectedGivingAmount;
        public PortFolioFieldsWrapper(Decimal ra, Decimal pa, Decimal aa, Decimal ca, Decimal opa, Decimal ega ){
            this.requestedAmount = (ra != NULL) ? ra : 0;
            this.ProjectedAmount = (pa != NULL) ? pa : 0;
            this.additionalAmount = (aa != NULL) ? aa : 0;
            this.closedAmount = (ca != NULL) ? ca : 0;
            this.outstandingPledgeAmount = (opa != NULL) ? opa : 0;
            this.expectedGivingAmount = (ega != NULL) ? ega : 0;
        }
    }
    
    public static PortFolioFieldsWrapper sumTwoPortfolioWrapper( PortFolioFieldsWrapper p1, PortFolioFieldsWrapper p2 ){
        p1.requestedAmount += (p2.requestedAmount != NULL) ? p2.requestedAmount: 0;
        p1.ProjectedAmount += (p2.ProjectedAmount != NULL) ? p2.ProjectedAmount: 0;
        p1.additionalAmount += (p2.additionalAmount != NULL) ? p2.additionalAmount: 0;
        p1.closedAmount += (p2.closedAmount != NULL) ? p2.closedAmount: 0;
        p1.outstandingPledgeAmount += (p2.outstandingPledgeAmount != NULL) ? p2.outstandingPledgeAmount: 0;
        p1.expectedGivingAmount += (p2.expectedGivingAmount != NULL) ? p2.expectedGivingAmount: 0;
        return p1;
    }
}