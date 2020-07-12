/*
*
*Name  :  BatchProcessOnGiving
*Author:  Appirio India (Sandeep Soni)
*Date  :  June 02, 2017
*Purpose : This batch class is used for updating Secondary_Advocacy_Donation_Sum__c  
*          and Secondary_Advocacy_Donation_Count on the Action record based on last batch run date.
*
*/
public class BatchProcessOnGiving implements Database.Batchable<sobject> {
    private static Map<String,Schema.RecordTypeInfo> opptyRTMap;
    private static final String OPPORTUNITY_RT_DONATION_Id;

    static{
        opptyRTMap =  Schema.SObjectType.opportunity.getRecordTypeInfosByName();
        OPPORTUNITY_RT_DONATION_Id = opptyRTMap.get('Donation').getRecordTypeId();
    }


    public Database.QueryLocator start(Database.BatchableContext bc) {
        //if the custom setting is not configured, it sets the start at the current day
        DateTime lastRunTime = Last_Run_Time_Of_Batch__c.getInstance('BatchProcessOnGiving') != null 
                                && Last_Run_Time_Of_Batch__c.getValues('BatchProcessOnGiving').Last_Run_Time__c != null ?
                               Last_Run_Time_Of_Batch__c.getValues('BatchProcessOnGiving').Last_Run_Time__c :
                               Date.Today();
        //System.debug('lastRunTime::' + lastRunTime);

        String query = 'Select id, RecordTypeId, StageName, SB_Originating_Form_ID__c, rC_Giving__Closed_Amount__c '+
                'From Opportunity '+
                'Where CreatedDate > :lastRunTime AND RecordTypeId = :OPPORTUNITY_RT_DONATION_Id '+
                'and  StageName = \'Completed\''+ 
                'AND SB_Originating_Form_ID__c !=\'\' ';
                //'AND Market_Source_Other__c LIKE \'springboard_redirect_%\' '; 6-23 logic is sunset
        return Database.getQueryLocator(query);
    }


    public void execute(Database.BatchableContext bc, List<Opportunity> opportunity) {
        Map<Decimal, OpportunityWrapper> mapSpringBoardId = new Map<Decimal, OpportunityWrapper>();
        OpportunityWrapper oppWrapper = null;
        //String marketSource = null;
        Double oppAmt = 0;

        //system.debug('opp size:: '+ opportunity.size() );
        for (Opportunity opp : opportunity) {
            oppAmt = 0;
            //marketSource = (opp.Market_Source_Other__c).split('springboard_redirect_');  6-23 sunset

            if (mapSpringBoardId.containsKey(Decimal.valueOf(opp.SB_Originating_Form_ID__c))) {
                oppWrapper = mapSpringBoardId.get(Decimal.valueOf(opp.SB_Originating_Form_ID__c));
                oppWrapper.springBoardCount += 1;
                oppWrapper.oppAmount += Double.valueOf(opp.rC_Giving__Closed_Amount__c);
                mapSpringBoardId.put(Decimal.valueOf(opp.SB_Originating_Form_ID__c), oppWrapper);
            } else {
                oppWrapper = new OpportunityWrapper();
                oppWrapper.springBoardCount = 1;
                oppWrapper.oppAmount = Double.valueOf(opp.rC_Giving__Closed_Amount__c);
                mapSpringBoardId.put(Decimal.valueOf(opp.SB_Originating_Form_ID__c), oppWrapper);
            }
        }

        Set<Decimal> setSpringBordId =  mapSpringBoardId.keyset();
        String actionQuery = 'SELECT ID, Springboard_ID__c, Secondary_Advocacy_Donation_Count__c, '+
            'Secondary_Advocacy_Donation_Sum__c FROM sb_action__c '+
            'WHERE Springboard_ID__c IN :setSpringBordId';
        List<sb_action__c> lstSBAction =  Database.query(actionQuery);
        List<sb_action__c> updateSBAction = new List<sb_action__c>();
        for (sb_action__c action : lstSBAction) {
            oppWrapper = mapSpringBoardId.get(action.Springboard_ID__c);
            if (action.Secondary_Advocacy_Donation_Sum__c == null) {
                action.Secondary_Advocacy_Donation_Sum__c = 0;
            }
            if (action.Secondary_Advocacy_Donation_Count__c == null) {
                action.Secondary_Advocacy_Donation_Count__c = 0;
            }
            action.Secondary_Advocacy_Donation_Sum__c = action.Secondary_Advocacy_Donation_Sum__c + oppWrapper.oppAmount;
            action.Secondary_Advocacy_Donation_Count__c = action.Secondary_Advocacy_Donation_Count__c + oppWrapper.springBoardCount;
            updateSBAction.add(action);
        }

        try{
            update updateSBAction;
        } catch(Exception e) {
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchProcessOnGiving','execute',e.getMessage());
            log.logException(e);
            log.saveLogs();
        }

    }


    public void finish(Database.BatchableContext bc) {
        //set the run time after batch completes
        if (Last_Run_Time_Of_Batch__c.getInstance('BatchProcessOnGiving') == null) {
            Last_Run_Time_Of_Batch__c cs = new Last_Run_Time_Of_Batch__c(Name = 'BatchProcessOnGiving', Last_Run_Time__c = System.now());
            insert cs;
        } else {
            Last_Run_Time_Of_Batch__c cs = Last_Run_Time_Of_Batch__c.getInstance('BatchProcessOnGiving');
            cs.Last_Run_Time__c = system.now();
            update cs;
        }

        Id batchInstanceId = Database.executeBatch(new BatchOnActionTaken(), 200);
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('BatchProcessOnGiving FINISHED');
        log.saveLogs();
    }


    public class OpportunityWrapper {
        public Integer springBoardCount {get; set;}
        public Double oppAmount {get; set;}
        public OpportunityWrapper() {
            springBoardCount = 0;
            oppAmount = 0;
        }
    }
}