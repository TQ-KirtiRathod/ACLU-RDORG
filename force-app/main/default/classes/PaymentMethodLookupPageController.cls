/*
*
*Name  :  PaymentMethodLookupPageController
*Author:  Ana Ferreira
*Date  :  Dec 02, 2019
* BGE-84
*Purpose : Custom controller for PaymentMethod page. Used in BGE and opened when lookup icon.
*
*/
public with sharing class PaymentMethodLookupPageController {
    public String query {get; set;}
    public  List<RecordType> paymentMethod {get; set;}
    public Boolean searchWindow {get;set;}
    public Boolean newPayment {get;set;}
    public Boolean paymentMethodCreated {get;set;}
    public Map<Id, PaymentMethodWrapper> paymentsWrappersById {get;set;}
    public List<PaymentMethodWrapper> paymentWrappers {
        get {
            return paymentsWrappersById.values();
        }
    }
    public Id accountId{get; set;}
    public String paymentMethodNameField{get; set;}
    public String paymentMethodIdField{get; set;}
    public String previousPaymentMethod{get; set;}
    public String paymentMethodField{get; set;}

    public rC_Giving__Payment_Method__c paymentMethodNew {get; set;}

    public PaymentMethodLookupPageController (){
        searchWindow = true;
        newPayment = false;
        paymentMethodCreated = false;
        paymentsWrappersById = new Map<Id, PaymentMethodWrapper> ();
        accountId = Apexpages.currentPage().getparameters().get('accountId');
        paymentMethodNameField = Apexpages.currentPage().getparameters().get('nameField');
        paymentMethodIdField = Apexpages.currentPage().getparameters().get('idField');
        previousPaymentMethod = Apexpages.currentPage().getparameters().get('prevPayment');
        paymentMethodField = Apexpages.currentPage().getparameters().get('paymentMethod');

        if(accountId!=null) {
            String q = '';
            String qryString = '';
           if(previousPaymentMethod!= null && previousPaymentMethod == 'Cash/Check'){
                qryString=' AND Name = :previousPaymentMethod';
            }
            String initialQuery = 'SELECT Id, RecordType.Name, Name, Reference_Number__c, rC_Giving__Account__c, '+
                    ' rC_Giving__Card_Expiration_Month__c, rC_Connect__Merchant_Name__c, '+
                    ' rC_Connect__Payment_Processor__c, rC_Giving__Is_Active__c, rC_Giving__Is_Default__c '+
                    ' FROM rC_Giving__Payment_Method__c '+
                    ' WHERE rC_Giving__Account__c = :accountId ';
            q = initialQuery;
            q += qryString;
            List<rC_Giving__Payment_Method__c> paymentMethods = Database.query(q);

            if(paymentMethods.size()==0){
                paymentMethods = Database.query(initialQuery);
            }

            for (rC_Giving__Payment_Method__c acc : paymentMethods) {
                paymentsWrappersById.put(acc.Id, new PaymentMethodWrapper(acc));
            }

        }

    }

    public PageReference newPaymentWindow(){
        newPayment = true;
        paymentMethodNew = new rC_Giving__Payment_Method__c();
        paymentMethodNew.rC_Giving__Account__c = accountId;
        PageReference home = new PageReference('/apex/Payment_Method_Lookup_Page?accountId='+accountId+'&nameField='+paymentMethodNameField+'&idField='+paymentMethodIdField+'&paymentMethod='+paymentMethodField);
        return home;
    }
    public PageReference saveNewPaymentMethod(){
        try{

            paymentMethodNew.rC_Giving__Account__c = accountId;
            insert paymentMethodNew;
            PageReference home = new PageReference('/apex/Payment_Method_Lookup_Page?accountId='+accountId+'&nameField='+paymentMethodNameField+'&idField='+paymentMethodIdField+'&paymentMethod='+paymentMethodField);
            home.setRedirect(true);
            return home;
        }

        catch (Exception ex) {
            ApexPages.addMessages(ex);
            return null;
        }

}
    public PageReference runQuery()
    {
        if(searchWindow == false){
            searchWindow = true;
        }
        paymentsWrappersById = new Map<Id, PaymentMethodWrapper> ();
        if(paymentMethodCreated == false && query!= null && query.length()>2){
            string dynamicquery ='FIND \''+query+'*\' RETURNING rC_Giving__Payment_Method__c(Name, RecordType.Name,Id,Reference_Number__c, rC_Giving__Account__c, rC_Giving__Card_Expiration_Month__c,' +
                    ' rC_Connect__Merchant_Name__c, rC_Connect__Payment_Processor__c, 	rC_Giving__Is_Active__c, rC_Giving__Is_Default__c where rC_Giving__Account__c = :accountId) LIMIT 100';
            List<List<sObject>> accountList = search.query(dynamicquery);
            for(Sobject acc: accountList[0]){
                paymentsWrappersById.put(acc.Id, new PaymentMethodWrapper((rC_Giving__Payment_Method__c) acc) );
            }
        }
        else if(paymentMethodCreated == true){
             for(rC_Giving__Payment_Method__c acc:[SELECT Id, Name
                        FROM rC_Giving__Payment_Method__c ORDER BY CreatedDate desc LIMIT 1]){

                 paymentsWrappersById.put(acc.Id, new PaymentMethodWrapper(acc) );
            }
            paymentMethodCreated = false;
        }
        else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Search term must be more than two Characters'));
        }
        return null;
    }

    public PageReference createNew (){
        searchWindow = false;
        paymentMethodCreated = true;
        return null;
    }

    public static List<SelectOption> getPaymentMethodsRecordType(){
        List<SelectOption> recType = new List<SelectOption>();
        for(RecordType rec : [SELECT SobjectType, Name, Id FROM RecordType WHERE SobjectType='rC_Giving__Payment_Method__c' and IsActive = true]){
            recType.add(new SelectOption(rec.id, rec.Name));
        }
        return recType;
    }

    public class PaymentMethodWrapper{
        public rC_Giving__Payment_Method__c payment {get;set;}

        public PaymentMethodWrapper(rC_Giving__Payment_Method__c payment){
            this.payment = payment;
        }
    }
}