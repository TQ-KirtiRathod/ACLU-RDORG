/*
*
*Name  :  AdvocacyDashboardController
*Author:  Appirio India (Sandeep Soni)
*Date  :  May 31, 2017
*Purpose :  This class is used for showing sb_action__c records in a custom vf dashboard based on filter criteria (SpringBoardId, Campaign Member, Campaign Group)
            The logic summarizes the data so it can be passed to multiple output structures for the dashboard.  Refer to the class for specifics.
*
*/
public class AdvocacyDashboardController {
  
    public Map<String ,NumberOfActionTaken> mapActionTaken {get;set;}
    public Map<String ,NumberOfActionTaken> mapSummaryActionTaken {get;set;}
    public List<PieWedgeData> lstPieData {get;set;}
    public List<PieWedgeData> mktScByEmailPieData {get;set;}
    public List<PieWedgeData> mktScByActionsPieData {get;set;}
    
    public Decimal springboardId {get;set;}
    public String campaignId {get;set;}
    public String campaignGroupId {get;set;}      
    private Set<String> campaignIdSet;
    public sb_action__c actionData {get;set;}
    
    public String lastEmailBatchRunDateSt {get;set;}
    public String lastGivingBatchRunDateSt {get;set;}
    public String lastActionTakenRunDateSt {get;set;}

    public String searchString {get;set;}
    public Boolean actionTakenFlag{get;set;}
    public Double newEmailCount {get;set;}
    public Double existEmailCount {get;set;}
    public String actionTakenOverTime {get;set;}
    public String actionTakenByContact {get;set;}
  
    //constructor             
    public AdvocacyDashboardController() {
        actionData = new sb_action__c();
        springboardId = 0;
        campaignId = ''; 
        campaignGroupId = '';
        TimeZone tz = UserInfo.getTimeZone();
        DateTime lastEmailBatchRunDate = Last_Run_Time_Of_Batch__c.getInstance('BatchProcessOnEmail') != null 
                                && Last_Run_Time_Of_Batch__c.getValues('BatchProcessOnEmail').Last_Run_Time__c != null?
                                 Last_Run_Time_Of_Batch__c.getValues('BatchProcessOnEmail').Last_Run_Time__c :
                                 Date.Today();
        lastEmailBatchRunDateSt = lastEmailBatchRunDate.format();
        DateTime lastGivingBatchRunDate = Last_Run_Time_Of_Batch__c.getInstance('BatchProcessOnGiving') != null 
                                && Last_Run_Time_Of_Batch__c.getValues('BatchProcessOnGiving').Last_Run_Time__c != null?
                                 Last_Run_Time_Of_Batch__c.getValues('BatchProcessOnGiving').Last_Run_Time__c :
                                 Date.Today();
        lastGivingBatchRunDateSt = lastGivingBatchRunDate.format();
        //System.debug('lastRunTime::'+lastGivingBatchRunDate);
        DateTime lastActionTakenRunDate = Last_Run_Time_Of_Batch__c.getInstance('BatchOnActionTaken') != null 
                                && Last_Run_Time_Of_Batch__c.getValues('BatchOnActionTaken').Last_Run_Time__c != null?
                                 Last_Run_Time_Of_Batch__c.getValues('BatchOnActionTaken').Last_Run_Time__c :
                                 Date.Today();
        lastActionTakenRunDateSt = lastActionTakenRunDate.format();

        List<Report> reports = [SELECT Id, Name, DeveloperName FROM Report where DeveloperName = 'Actions_Taken_Over_Time' or 
                            DeveloperName = 'Number_of_Prev_Actions_Taken_by_Contact' Limit 2];
        for(Report r: reports){
            if(r.DeveloperName == 'Actions_Taken_Over_Time'){
                actionTakenOverTime = r.Id;
            }
            if(r.DeveloperName == 'Number_of_Prev_Actions_Taken_by_Contact'){
                actionTakenByContact = r.Id;
            }
        }
        
        


     } //end constructor


    /*
    Method Name:    showReport()
    Parameter:      None
    Return Type:    List<SelectOption>
    Description:    This method will show report/data when user clicks on show report button.
    */
    public void showReport() {
        String filter = '';
        String query = '';
        String key = null;
        searchString = ''; //string of springboardId
        NumberOfActionTaken actionWrapper = new NumberOfActionTaken();
        NumberOfActionTaken mapSummaryActionWrapper = new NumberOfActionTaken();
        //NumberOfActionTaken SummaryActionTaken = new NumberOfActionTaken();
        mapActionTaken = new Map<String,NumberOfActionTaken>();
        mapSummaryActionTaken = new Map<String,NumberOfActionTaken>();
        actionTakenFlag = false;
        springboardId = 0;
        campaignIdSet = new Set<String>();
        newEmailCount = 0;
        existEmailCount = 0;
        
        //filter selections, counting number of selections
        Integer springboardIdFilterUsed = (actionData.Springboard_ID__c==0 || actionData.Springboard_ID__c==null)?0:1;
        Integer campaignFilterUsed = (actionData.Campaign__c==null)?0:1;
        Integer campGroupFilterUsed = (actionData.Campaign_Grouping__c==null)?0:1;

        /*For validating, at least one filter criteria should not be blank */
         if((actionData.Springboard_ID__c==0 || actionData.Springboard_ID__c==null) 
            && actionData.Campaign__c==null && actionData.Campaign_Grouping__c==null){
            mapActionTaken = null;
            /*Show an error message if filter criteria is blank/empty*/
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Enter at least one filter criteria'));
            return;
        }else if(springboardIdFilterUsed+campaignFilterUsed+campGroupFilterUsed>1){
            mapActionTaken = null;
            /*Show an error message if filter criteria is blank/empty*/
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,'Only one filter can be used at a time'));
            return;
        }else{
        /*For Total Number of Actions Taken*/
            query = 'SELECT ID, Name, Actions_Taken__c, Springboard_ID__c,Campaign__c,'+
            'Actions_Taken_Market_Source_by_Email__c, Actions_Taken_Market_Source_by_Facebook__c, '+
            'Actions_Taken_Market_Source_by_Twitter__c, Actions_Taken_Market_Source_by_Web__c, '+
            'Actions_Taken_Market_Source_by_Banner__c, Actions_Taken_Market_Source_by_Google_Ad__c, '+
            'Actions_Taken_Market_Source_by_Other__c,Email_Market_Source_by_Email__c, Email_Market_Source_by_Facebook__c, '+
            'Email_Market_Source_by_Banner__c, Email_Market_Source_by_Google_Ads__c, Email_Market_Source_By_Other__c, '+
            'Email_Market_Source_by_Twitter__c, Email_Market_Source_by_Web__c,';
            query += 'Actions_Taken_by_Existing_Email__c, Actions_Taken_by_New_Email__c, ';
            query += 'Secondary_Advocacy_Donation_Count__c, Secondary_Advocacy_Donation_Sum__c ';
            query += 'FROM sb_action__c WHERE ';                                                                                       

            if(actionData.Springboard_ID__c!=0 && String.isNotBlank(String.valueof(actionData.Springboard_ID__c))){
                springboardId = actionData.Springboard_ID__c;
                filter = filter+' Springboard_ID__c =: springboardId AND';
                           }
            if(actionData.Campaign__c!=null && String.isNotBlank(actionData.Campaign__c)){
                campaignId = actionData.Campaign__c;
                filter = filter+' Campaign__c =: campaignId AND';
                }
            if(actionData.Campaign_Grouping__c!=null && String.isNotBlank(String.valueOf(actionData.Campaign_Grouping__c))){
                campaignGroupId = actionData.Campaign_Grouping__c;
                List<Campaign_Grouping_Member__c> campaigns = [SELECT Campaign_Grouping__c, Campaign_Grouping__r.Name, 
                                Campaign__c, Campaign__r.Name 
                              FROM Campaign_Grouping_Member__c 
                              where Campaign_Grouping__c = :campaignGroupId];
                for(Campaign_Grouping_Member__c c: campaigns){
                    campaignIdSet.add(c.Campaign__c);
                }
                filter = filter+' Campaign__c IN :campaignIdSet AND';
            }
            filter = filter.removeEnd('AND');
            query+=filter;
            
            //System.debug('DB Query:: '+query);
            List<sb_action__c> lstSBAction =  Database.query(query);


            //processing qry results
            for(sb_action__c action1: lstSBAction){
                key = '';
                key = String.valueOf(action1.Springboard_ID__c);
                searchString += (searchString.length()>1)?','+String.valueOf(action1.Springboard_ID__c):String.valueOf(action1.Springboard_ID__c);
                //system.debug(searchString);

                ////sets empty values to 0
                action1 = setZeroValues(action1);

                //System.debug(key + 'springboard id' + action1.Springboard_ID__c );
                /*for creating a new record*/
                if(action1!=null && mapActionTaken!=null && !mapActionTaken.containsKey(key)){

                    actionWrapper = new NumberOfActionTaken();
                    actionWrapper.actionName = action1.Name;
                    actionWrapper.actionTaken += Double.valueOf(action1.Actions_Taken__C);
                    actionWrapper.actionsTakenbyNewEmail = Integer.valueOf(action1.Actions_Taken_by_New_Email__c);
                    actionWrapper.newEmailCount = Double.valueOf(action1.Actions_Taken_by_New_Email__c);
                    actionWrapper.actionsTakenbyExistingEmail = Double.valueOf(action1.Actions_Taken_by_Existing_Email__c);
                    actionWrapper.secondaryAdvocacyDonCount = Integer.valueOf(action1.Secondary_Advocacy_Donation_Count__c);
                    actionWrapper.secondaryAdvocacyDonSum = Double.valueof(action1.Secondary_Advocacy_Donation_Sum__c);
                    
                    /*For Email record update*/
                    mapActionTaken.put(key, actionWrapper);
                }else{
                    /*if action taken exists then it will update values*/
                    actionWrapper = mapActionTaken.get(key);
                    actionWrapper.actionTaken += Double.valueOf(action1.Actions_Taken__C);
                    actionWrapper.actionsTakenbyNewEmail += Integer.valueOf(action1.Actions_Taken_by_New_Email__c);
                    actionWrapper.newEmailCount += Double.valueOf(action1.Actions_Taken_by_New_Email__c);
                    actionWrapper.actionsTakenbyExistingEmail += Double.valueOf(action1.Actions_Taken_by_Existing_Email__c);
                    actionWrapper.secondaryAdvocacyDonCount += Integer.valueOf(action1.Secondary_Advocacy_Donation_Count__c);
                    actionWrapper.secondaryAdvocacyDonSum += Double.valueOf(action1.Secondary_Advocacy_Donation_Sum__c);

                    mapActionTaken.put(key, actionWrapper); 
                }
                    
                mapSummaryActionWrapper.actionTaken += Double.valueOf(action1.Actions_Taken__C);
                mapSummaryActionWrapper.actionsTakenbyNewEmail += Integer.valueOf(action1.Actions_Taken_by_New_Email__c);
                mapSummaryActionWrapper.newEmailCount += Double.valueOf(action1.Actions_Taken_by_New_Email__c);
                mapSummaryActionWrapper.actionsTakenbyExistingEmail += Double.valueOf(action1.Actions_Taken_by_Existing_Email__c);
                mapSummaryActionWrapper.secondaryAdvocacyDonCount += Integer.valueOf(action1.Secondary_Advocacy_Donation_Count__c);
                mapSummaryActionWrapper.secondaryAdvocacyDonSum += Double.valueOf(action1.Secondary_Advocacy_Donation_Sum__c);

                mapSummaryActionWrapper.actionTakenMSByEmail += Integer.valueOf(action1.Actions_Taken_Market_Source_by_Email__c);
                mapSummaryActionWrapper.actionTakenMSByFB += Integer.valueOf(action1.Actions_Taken_Market_Source_by_Facebook__c);
                mapSummaryActionWrapper.actionTakenMSByTW += Integer.valueOf(action1.Actions_Taken_Market_Source_by_Twitter__c);
                mapSummaryActionWrapper.actionTakenMSByWeb += Integer.valueOf(action1.Actions_Taken_Market_Source_by_Web__c);
                mapSummaryActionWrapper.actionTakenMSByBanner += Integer.valueOf(action1.Actions_Taken_Market_Source_by_Banner__c);
                mapSummaryActionWrapper.actionTakenMSByGAdd += Integer.valueOf(action1.Actions_Taken_Market_Source_by_Google_Ad__c);
                mapSummaryActionWrapper.actionTakenMSByOth += Integer.valueOf(action1.Actions_Taken_Market_Source_by_Other__c);
                
                mapSummaryActionWrapper.emailMSByEmail += Integer.valueOf(action1.Email_Market_Source_by_Email__c);
                mapSummaryActionWrapper.emailMSByFB += Integer.valueOf(action1.Email_Market_Source_by_Facebook__c);
                mapSummaryActionWrapper.emailMSByTW += Integer.valueOf(action1.Email_Market_Source_by_Twitter__c);
                mapSummaryActionWrapper.emailMSByWeb += Integer.valueOf(action1.Email_Market_Source_by_Web__c);
                mapSummaryActionWrapper.emailMSByBanner += Integer.valueOf(action1.Email_Market_Source_by_Banner__c);
                mapSummaryActionWrapper.emailMSByGAdd += Integer.valueOf(action1.Email_Market_Source_by_Google_Ads__c);
                mapSummaryActionWrapper.emailMSByOth += Integer.valueOf(action1.Email_Market_Source_By_Other__c);
                
                //System.debug('here : ' + mapSummaryActionWrapper);
                mapSummaryActionTaken.put('sum', mapSummaryActionWrapper);

            } //end for loop
        /*Number of Newly Acquired Emails Due to Action*/
        }
        if(mapActionTaken.isEmpty()){
            actionTakenFlag = true;
            lstPieData  = null;
        }else{
            getEmailPieData(mapActionTaken);
            getMSbyActionsPieData(mapSummaryActionTaken);
            getMSbyEmailPieData(mapSummaryActionTaken);
        }
    }  // end showReport


    /*For Storing Pie Chart data*/
    public void getMSbyActionsPieData(Map<String ,NumberOfActionTaken> mapActionTaken) {
        mktScByActionsPieData = new List<PieWedgeData>();
        if(mapActionTaken.isEmpty()){
            mktScByActionsPieData.add(new PieWedgeData('No Actions Taken',0));
        }else{ 
            for(NumberOfActionTaken nat:mapActionTaken.values()){
                if(nat.actionTakenMSByEmail>0) mktScByActionsPieData.add(new PieWedgeData('Email', nat.actionTakenMSByEmail));
                if(nat.actionTakenMSByFB>0) mktScByActionsPieData.add(new PieWedgeData('Facebook', nat.actionTakenMSByFB));
                if(nat.actionTakenMSByTW>0) mktScByActionsPieData.add(new PieWedgeData('Twitter', nat.actionTakenMSByTW));
                if(nat.actionTakenMSByWeb>0) mktScByActionsPieData.add(new PieWedgeData('Web', nat.actionTakenMSByWeb));
                if(nat.actionTakenMSByBanner>0) mktScByActionsPieData.add(new PieWedgeData('Banner', nat.actionTakenMSByBanner));
                if(nat.actionTakenMSByGAdd>0) mktScByActionsPieData.add(new PieWedgeData('Google Ads', nat.actionTakenMSByGAdd));
                if(nat.actionTakenMSByOth>0) mktScByActionsPieData.add(new PieWedgeData('Others', nat.actionTakenMSByOth));
            }
        }
    }
    public void getMSbyEmailPieData(Map<String ,NumberOfActionTaken> mapActionTaken) {
        mktScByEmailPieData = new List<PieWedgeData>();
        if(mapActionTaken.isEmpty()){
            mktScByEmailPieData.add(new PieWedgeData('No Market Sorces by Email',0));
        }else{ 
            for(NumberOfActionTaken nat:mapActionTaken.values()){
                if(nat.emailMSByEmail>0) mktScByEmailPieData.add(new PieWedgeData('Email', nat.emailMSByEmail));
                if(nat.emailMSByFB>0) mktScByEmailPieData.add(new PieWedgeData('Facebook', nat.emailMSByFB));
                if(nat.emailMSByTW>0) mktScByEmailPieData.add(new PieWedgeData('Twitter', nat.emailMSByTW));
                if(nat.emailMSByWeb>0) mktScByEmailPieData.add(new PieWedgeData('Web', nat.emailMSByWeb));
                if(nat.emailMSByBanner>0) mktScByEmailPieData.add(new PieWedgeData('Banner', nat.emailMSByBanner));
                if(nat.emailMSByGAdd>0) mktScByEmailPieData.add(new PieWedgeData('Google Ads', nat.emailMSByGAdd));
                if(nat.emailMSByOth>0) mktScByEmailPieData.add(new PieWedgeData('Others', nat.emailMSByOth));
            }        
        }
    }

    public void getEmailPieData(Map<String ,NumberOfActionTaken> mapActionTaken) {
        lstPieData = new List<PieWedgeData>();
        if(mapActionTaken.isEmpty()){
            newEmailCount = 0;
            existEmailCount = 0;
            lstPieData.add(new PieWedgeData('No Actions Taken',0));
        }else{ 
            for(NumberOfActionTaken nat:mapActionTaken.values()){
                newEmailCount += nat.actionsTakenbyNewEmail;
                existEmailCount += nat.actionsTakenbyExistingEmail;
            }
            lstPieData.add(new PieWedgeData('New Emails', newEmailCount));
            lstPieData.add(new PieWedgeData('Existing Emails', existEmailCount));            
        }
    }
    
    /*This is an inner class that is used for storing Team member values.*/   
    public class NumberOfActionTaken {
        public String actionName{get;set;}
        public Double actionTaken{get;set;}
        public Integer actionsTakenbyNewEmail{get;set;}
        public Double newEmailCount { get; set; }
        public Double actionsTakenbyExistingEmail { get; set; }
        public Integer secondaryAdvocacyDonCount {get;set;}
        public Double secondaryAdvocacyDonSum {get;set;}
        public Integer actionTakenMSByEmail {get;set;}
        public Integer actionTakenMSByFB {get;set;}
        public Integer actionTakenMSByTW {get;set;}
        public Integer actionTakenMSByWeb {get;set;}
        public Integer actionTakenMSByBanner {get;set;}
        public Integer actionTakenMSByGAdd {get;set;}
        public Integer actionTakenMSByOth {get;set;}
        public Integer emailMSByEmail {get;set;}
        public Integer emailMSByFB {get;set;}
        public Integer emailMSByTW {get;set;}
        public Integer emailMSByWeb {get;set;}
        public Integer emailMSByBanner {get;set;}
        public Integer emailMSByGAdd {get;set;}
        public Integer emailMSByOth {get;set;}
    
        /*This is a default constructor.*/
        public NumberOfActionTaken() {
            actionName = '';
            actionTaken = 0.0;
            actionsTakenbyNewEmail = 0;
            newEmailCount = 0.0;
            actionsTakenbyExistingEmail = 0.0;
            secondaryAdvocacyDonCount = 0;
            secondaryAdvocacyDonSum = 0;
            actionTakenMSByEmail = 0;
            actionTakenMSByFB = 0;
            actionTakenMSByTW = 0;
            actionTakenMSByWeb = 0;
            actionTakenMSByBanner = 0;
            actionTakenMSByGAdd = 0;
            actionTakenMSByOth = 0;
            emailMSByFB = 0;
            emailMSByEmail = 0;
            emailMSByTW = 0;
            emailMSByWeb = 0;
            emailMSByBanner = 0;
            emailMSByGAdd = 0;
            emailMSByOth = 0;
        }
    }  

    // Wrapper class for pie chart
    public class PieWedgeData {
        public String name { get; set; }
        public Integer data { get; set; }

        public PieWedgeData(String name, Double data) {
            this.name = name + ' : '+ data.intValue();
            this.data = data.intValue();
        }
    }

    //method to set action values to zero
    private sb_action__c setZeroValues(sb_action__c action1){
        //sets empty values to 0
        if(action1.Actions_Taken_by_New_Email__c== null){
            action1.Actions_Taken_by_New_Email__c = 0;
        }
        if(action1.Actions_Taken__C==null){
            action1.Actions_Taken__C = 0;
        }
        if(action1.Actions_Taken_by_New_Email__c==null){
            action1.Actions_Taken_by_New_Email__c = 0;
        }
        if(action1.Secondary_Advocacy_Donation_Count__c==null){
            action1.Secondary_Advocacy_Donation_Count__c = 0;
        } 
        if(action1.Secondary_Advocacy_Donation_Sum__c==null){
            action1.Secondary_Advocacy_Donation_Sum__c = 0;
        }
        if(action1.Actions_Taken_Market_Source_by_Email__c==null){
            action1.Actions_Taken_Market_Source_by_Email__c = 0;
        }
        if(action1.Actions_Taken_Market_Source_by_Facebook__c==null){
            action1.Actions_Taken_Market_Source_by_Facebook__c = 0;
        }
        if(action1.Actions_Taken_Market_Source_by_Twitter__c==null){
            action1.Actions_Taken_Market_Source_by_Twitter__c = 0;
        }
        if(action1.Actions_Taken_Market_Source_by_Web__c == null){
            action1.Actions_Taken_Market_Source_by_Web__c = 0;
        }
        if(action1.Actions_Taken_Market_Source_by_Banner__c == null){
            action1.Actions_Taken_Market_Source_by_Banner__c  = 0;
        }
        if(action1.Actions_Taken_Market_Source_by_Google_Ad__c == null){
            action1.Actions_Taken_Market_Source_by_Google_Ad__c  = 0;
        }
        if(action1.Actions_Taken_Market_Source_by_Other__c == null){
            action1.Actions_Taken_Market_Source_by_Other__c  = 0;
        }
        if(action1.Email_Market_Source_by_Email__c == null){
            action1.Email_Market_Source_by_Email__c = 0;
        }
        if(action1.Email_Market_Source_by_Facebook__c == null){
            action1.Email_Market_Source_by_Facebook__c = 0;
        }
        if(action1.Email_Market_Source_by_Banner__c == null){
            action1.Email_Market_Source_by_Banner__c = 0;
        }
        if(action1.Email_Market_Source_by_Google_Ads__c == null){
            action1.Email_Market_Source_by_Google_Ads__c = 0;
        }
        if(action1.Email_Market_Source_By_Other__c == null){
            action1.Email_Market_Source_By_Other__c = 0;
        }
        if(action1.Email_Market_Source_by_Twitter__c == null){
            action1.Email_Market_Source_by_Twitter__c = 0;
        }
        if(action1.Email_Market_Source_by_Web__c == null){
            action1.Email_Market_Source_by_Web__c = 0;
        }
        return action1;
    }


}