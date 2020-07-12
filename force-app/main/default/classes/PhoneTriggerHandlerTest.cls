/*
*
*Name  :  PhoneTriggerHandlerTest
*Author:  Appirio India (Kajal Jalan)
*Date  :  November 23, 2016
*Purpose : Test Coverage for PhoneTriggerHandler
*Made Changes By RC
*/

@isTest
public class PhoneTriggerHandlerTest {
    
    
    public static list<Contact> listContact;
    public static list<String> contactId;
    public static list<Phone__c> listPhone;
    public static Queueable_Control__c queableObj;
    
    /*
    *
    *Method testOnDuplicateRecord
    *Testing if duplicate phone records
    *are created.
    *Also,testing if first phone on contact
    *are set as Primary.
    *
    */
    
    public static testMethod void testOnDuplicatePhoneRecord(){
        
       
        Test.startTest();
        createTestData();
        insert listPhone;
        Test.stopTest();
        Phone__c phn = [SELECT Id,External_Id__c,IsPrimary__c,Contact__c,Phone_Number__c,Active__c
                       FROM Phone__c 
                       WHERE Id =: listPhone[1].Id];
        //system.assert(false,phn);
        system.assertEquals(phn.External_Id__c,String.valueOf(phn.Contact__c).Substring(0,15)+'_'+phn.Phone_Number__c.replaceAll('[^0-9]',''));              
       // system.assertEquals(phn.IsPrimary__c,true);
        //system.assertEquals(phn.Active__c,true);
        
        //verify that only single Primary phone is present under contact.
        //For listContact[4], created 3 phone records with primary as true, so only one is marked.
        system.assertEquals(1,[select count() FROM Phone__c WHERE isPrimary__c = TRUE]);
        
        Phone__c pne = new Phone__c(Contact__c = listContact[1].Id,Phone_Number__c = '0830160451');
        
        try { 
            insert pne;
        } catch (DmlException e) {
            
            //Assert Error Message
            System.assert(true,e.getMessage() );
        }
        
        Contact cont = [SELECT Id,HomePhone FROM Contact Where Id =: listContact[4].Id];
        
        system.assertEquals(cont.HomePhone,'0830160412');
        
        /*Phone__c pe = [SELECT Id,External_Id__c,Contact__c,Phone_Number__c 
                        FROM Phone__c 
                        WHERE Id =: listPhone[6].Id];
        pe.IsPrimary__c=true;
        //pe.Phone_Number__c = '0830121212';
        try {
            update pe;
            system.assertEquals('Home', [SELECT Id, Contact__r.rC_Bios__Preferred_Phone__c FROM Phone__c where Id=:pe.Id LIMIT 1][0].Contact__r.rC_Bios__Preferred_Phone__c);
        } catch (DmlException e) {  
            System.assert(false,e.getMessage());
        }*/
    }
    
    /*
    *
    *Method testHomePhone
    * If the phone is set to primary then the preferred phone will be HOME
    *
    */

    public static testMethod void testHomePhone() {
        
        Test.startTest();
        createTestData();
        insert listPhone;
        
        Phone__c pe = [SELECT Id,External_Id__c,Contact__c,Phone_Number__c 
                       FROM Phone__c 
                       WHERE Id =: listPhone[6].Id];
        pe.IsPrimary__c=true;
        //pe.Phone_Number__c = '0830121212';
        
        update pe;
        Test.stopTest();
        system.assertEquals('Home', [SELECT Id, Contact__r.rC_Bios__Preferred_Phone__c FROM Phone__c where Id=:pe.Id LIMIT 1][0].Contact__r.rC_Bios__Preferred_Phone__c);
        
    }
    
    //Create a method by rc to test InValid Phone
    //ZenDesk - ##65473
    public static testMethod void testOnInValidPhoneRecord(){
        
        Test.startTest();
        createTestData();
        insert listPhone;
        Test.stopTest();
            
        Phone__c phn = [SELECT Id,External_Id__c,IsPrimary__c,Contact__c,Phone_Number__c,Active__c
                       FROM Phone__c 
                       WHERE Id =: listPhone[1].Id];
        //system.assert(false,phn);
        system.assertEquals(phn.External_Id__c,String.valueOf(phn.Contact__c).Substring(0,15)+'_'+phn.Phone_Number__c.replaceAll('[^0-9]',''));              
       // system.assertEquals(phn.IsPrimary__c,true);
        //system.assertEquals(phn.Active__c,true);
        
        //verify that only single Primary phone is present under contact.
        //For listContact[4], created 3 phone records with primary as true, so only one is marked.
        system.assertEquals(1,[select count() FROM Phone__c WHERE isPrimary__c = TRUE]);
        
        Phone__c pne = new Phone__c(Contact__c = listContact[1].Id,Phone_Number__c = '0830160451',Phone_Status__c ='InValid');
        
        try {    
            insert pne;
        } catch (DmlException e) {  
            //Assert Error Message
            System.assert(true,e.getMessage() );
        }
        
        Contact cont = [SELECT Id,HomePhone FROM Contact Where Id =: listContact[4].Id];
        system.assertEquals(cont.HomePhone,'0830160412');
        Phone__c pe = [SELECT Id,External_Id__c,Contact__c,Phone_Number__c 
                        FROM Phone__c 
                        WHERE Id =: listPhone[6].Id];
        pe.IsPrimary__c=true;
        //pe.Phone_Number__c = '0830121212';
       /* try {
            
            update pe;
            system.assertEquals('Home', [SELECT Id, Contact__r.rC_Bios__Preferred_Phone__c FROM Phone__c where Id=:pe.Id LIMIT 1][0].Contact__r.rC_Bios__Preferred_Phone__c);
        } 
        
        catch (DmlException e) {
            
            System.assert(false,e.getMessage() );
        }*/
        
    }
    //Create a method by rc to test InValid Phone
    //ZenDesk - ##65473
    public static testMethod void testOnUpdateInValidPhoneRecord(){
        
        Test.startTest();
        createTestData();
        insert listPhone;
        Test.stopTest();
        
        Phone__c phn = [SELECT Id,External_Id__c,IsPrimary__c,Contact__c,Phone_Number__c,Active__c
                       FROM Phone__c 
                       WHERE Id =: listPhone[1].Id];
        phn.Universal_SMS_Opt_Out__c = true;
        phn.Phone_Status__c = 'InValid';
        phn.IsPrimary__c = false;
        update phn;
        //system.assert(false,phn);
        system.assertEquals(phn.External_Id__c,String.valueOf(phn.Contact__c).Substring(0,15)+'_'+phn.Phone_Number__c.replaceAll('[^0-9]',''));              
       // system.assertEquals(phn.IsPrimary__c,true);
        //system.assertEquals(phn.Active__c,true);
        
        //verify that only single Primary phone is present under contact.
        //For listContact[4], created 3 phone records with primary as true, so only one is marked.
        system.assertEquals(1,[select count() FROM Phone__c WHERE isPrimary__c = TRUE]);
        
        Phone__c pne = new Phone__c(Contact__c = listContact[1].Id,Phone_Number__c = '0830160451',Phone_Status__c ='InValid');
        
        try {
            insert pne;
        } catch (DmlException e) {  
            //Assert Error Message
            System.assert(true,e.getMessage() );
        }

        Contact cont = [SELECT Id,HomePhone FROM Contact Where Id =: listContact[4].Id];
        system.assertEquals(cont.HomePhone,'0830160412');
        /*Phone__c pe = [SELECT Id,External_Id__c,Contact__c,Phone_Number__c 
                        FROM Phone__c 
                        WHERE Id =: listPhone[6].Id];
        pe.IsPrimary__c=true;
        //pe.Phone_Number__c = '0830121212';
        try {
            
            update pe;
            system.assertEquals('Home', [SELECT Id, Contact__r.rC_Bios__Preferred_Phone__c FROM Phone__c where Id=:pe.Id LIMIT 1][0].Contact__r.rC_Bios__Preferred_Phone__c);
        } 
        
        catch (DmlException e) {
            
            System.assert(false,e.getMessage() );
        }*/
        
    }
    //Create a method by rc to test SmsOptOut
    //ZenDesk - ##65473
    public static testMethod void testOnSmsOptOutPhoneRecord(){
        
        Test.startTest();
        createTestData();
        insert listPhone;
        Test.stopTest();
       
        Phone__c phn = [SELECT Id,External_Id__c,IsPrimary__c,Contact__c,Phone_Number__c,Active__c
                       FROM Phone__c 
                       WHERE Id =: listPhone[1].Id];
        //system.assert(false,phn);
        system.assertEquals(phn.External_Id__c,String.valueOf(phn.Contact__c).Substring(0,15)+'_'+phn.Phone_Number__c.replaceAll('[^0-9]',''));              
       // system.assertEquals(phn.IsPrimary__c,true);
        //system.assertEquals(phn.Active__c,true);
        
        //verify that only single Primary phone is present under contact.
        //For listContact[4], created 3 phone records with primary as true, so only one is marked.
        system.assertEquals(1,[select count() FROM Phone__c WHERE isPrimary__c = TRUE]);
        
        Phone__c pne = new Phone__c(Contact__c = listContact[1].Id,Phone_Number__c = '0830160451'
                                    ,Phone_Status__c ='InValid',Universal_SMS_Opt_Out__c = true);
        
        try {            
            insert pne;
        } catch (DmlException e) {  
            //Assert Error Message
            System.assert(true,e.getMessage() );
        }
        
        Contact cont = [SELECT Id,HomePhone FROM Contact Where Id =: listContact[4].Id];
        system.assertEquals(cont.HomePhone,'0830160412');
        /*Phone__c pe = [SELECT Id,External_Id__c,Contact__c,Phone_Number__c 
                        FROM Phone__c 
                        WHERE Id =: listPhone[6].Id];
        pe.IsPrimary__c=true;
        //pe.Phone_Number__c = '0830121212';
        try {
            
            update pe;
            system.assertEquals('Home', [SELECT Id, Contact__r.rC_Bios__Preferred_Phone__c FROM Phone__c where Id=:pe.Id LIMIT 1][0].Contact__r.rC_Bios__Preferred_Phone__c);
        } 
        
        catch (DmlException e) {
            
            System.assert(false,e.getMessage() );
        }*/
        
    }
    
    public static testMethod void testDeletePhoneRecord(){
        
        Test.startTest();
        createTestData();
        insert listPhone;
        
        
        Phone__c phn = [SELECT Id,External_Id__c,IsPrimary__c,Contact__c,Phone_Number__c,Active__c
                       FROM Phone__c 
                       WHERE Id =: listPhone[1].Id];
        if( phn.IsPrimary__c == false){
            phn.IsPrimary__c = TRUE;
            update phn;
        }
        Test.stopTest();
        Contact cont = [SELECT Id,HomePhone FROM Contact Where Id =: listContact[1].Id];
        
        system.assertEquals(cont.HomePhone,'0830160451');
        //system.assertEquals(cont.HomePhone, null);
        Delete phn;
        system.assertEquals([SELECT Id,HomePhone FROM Contact Where Id =: listContact[1].Id].HomePhone,NULL);
    }
    
    /*
*
*Method createTestData
*Creating Sample Data
*For Testing Purpose
*
*/
    public static void createTestData(){
        queableObj = new Queueable_Control__c();
        queableObj.Name='MainQueueable';
        queableObj.Batch_Size_Account__c=100;
        queableObj.Batch_Size_Email__c=100;
        queableObj.Batch_Size_Phone__c=100;
        queableObj.Queueable_Enabled__c=true;
        queableObj.Batch_Size_Account_Address__c= 0123;
        insert queableObj;
        
        listContact = new list<Contact>();
        contactId = new list<String>();
        listPhone = new list<Phone__c>();
        for(Integer i=0;i<10;i++) {
            Contact con = TestUtils.createContact(null,'cons'+i,'testPhone'+i,false);
            listContact.add(con);
            contactId.add(con.Id);
        }
        insert listContact;
        for(Integer i=0;i<10;i++){
            Phone__c phone = TestUtils.createPhone(listContact[i].Id,'083016045'+i,false);
            phone.External_ID__c = String.valueOf(phone.Contact__c).Substring(0,15)+'_'+phone.Phone_Number__c.replaceAll('[^0-9]','') ; //adding external Id of phone 
            listPhone.add(phone);
        }
        
        for(Integer i=11;i<13;i++){
            Phone__c pho = TestUtils.createPhone(listContact[4].Id,'08301604'+i,false);
            pho.IsPrimary__c = true;
            listPhone.add(pho);
        }
        
    }   
}