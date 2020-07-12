@isTest
private with sharing class SalutationsUtilityTest {

    static testMethod void generateSalutationsTest1(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];
        
        // Scenario 1
        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                                    LastName = 'Samples', Salutation = 'Dr.', FirstName = 'Johnathan', rC_Bios__Middle_Name__c= 'Quincy'));
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Secondary_Contact__c = TRUE,
                                    LastName = 'Samples', Salutation = 'Dr.', FirstName = 'Samples', rC_Bios__Middle_Name__c= 'Quincy'));                               
        insert contactList;    
        
        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                                  Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
                                  FROM Account
                                 ]) {      
                                     mapOfStringVsAccount.put(theAccount.Name,theAccount);
                                 }
        // Scenario 1
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'Drs. Samples');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_1__c,'Dr. Johnathan Quincy Samples');  
    }
    
    static testMethod void generateSalutationsTest2(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];
        
        // Scenario 1
        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                                    LastName = 'Samples', Salutation = 'Mr.', FirstName = 'Johnathan', rC_Bios__Middle_Name__c= 'Quincy'));
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Secondary_Contact__c = TRUE,
                                    LastName = 'Samples', Salutation = 'Mr.', FirstName = 'Samples', rC_Bios__Middle_Name__c= 'Quincy'));                               
        
        
        
        
        insert contactList;    
        
        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                                  Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
                                  FROM Account
                                 ]) {      
                                     mapOfStringVsAccount.put(theAccount.Name,theAccount);
                                 }
        // Scenario 1
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'Messrs. Samples');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_1__c,'Mr. Johnathan Quincy Samples');  
    }
    static testMethod void generateSalutationsTest3(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];
        
        // Scenario 1
        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                                    LastName = 'Samples', Salutation = 'Miss', FirstName = 'Johnathan', rC_Bios__Middle_Name__c= 'Quincy'));
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Secondary_Contact__c = TRUE,
                                    LastName = 'Samples', Salutation = 'Miss', FirstName = 'Samples', rC_Bios__Middle_Name__c= 'Quincy'));                               
        insert contactList;    
        
        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                                  Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
                                  FROM Account
                                 ]) {      
                                     mapOfStringVsAccount.put(theAccount.Name,theAccount);
                                 }
        // Scenario 1
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'Misses Samples');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_1__c,'Miss Johnathan Quincy Samples');  
    }
    static testMethod void generateSalutationsTest4(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];
        
        // Scenario 1
        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                                    LastName = 'Samples', Salutation = 'Miss', FirstName = 'Johnathan', rC_Bios__Middle_Name__c= 'Quincy'));
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Secondary_Contact__c = TRUE,
                                    LastName = 'Samples', Salutation = 'Mr.', FirstName = 'Samples', rC_Bios__Middle_Name__c= 'Quincy'));                               
        insert contactList;    
        
        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                                  Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
                                  FROM Account
                                 ]) {      
                                     mapOfStringVsAccount.put(theAccount.Name,theAccount);
                                 }
        // Scenario 1
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'Miss & Mr. Samples');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_1__c,'Miss Johnathan Quincy Samples');  
    }
    static testMethod void generateSalutationsTest5(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];
        
        // Scenario 1
        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                                    LastName = 'Samples', Salutation = '', FirstName = 'Johnathan', rC_Bios__Middle_Name__c= 'Quincy'));
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Secondary_Contact__c = TRUE,
                                    LastName = 'Samples', Salutation = '', FirstName = 'Samples', rC_Bios__Middle_Name__c= 'Quincy'));                               
       insert contactList;    
        
        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                                  Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
                                  FROM Account
                                 ]) {      
                                     mapOfStringVsAccount.put(theAccount.Name,theAccount);
                                 }
        // Scenario 1
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'Johnathan and Samples');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_1__c,'Johnathan Quincy Samples');  
    }
    static testMethod void generateSalutationsTest6(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];
        
        // Scenario 2
        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                                    LastName = 'Samples', Salutation = 'Mr.', FirstName = 'Johnathan', rC_Bios__Middle_Name__c= 'Quincy'));
        insert contactList;    
        
        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                                  Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
                                  FROM Account
                                 ]) {      
                                     mapOfStringVsAccount.put(theAccount.Name,theAccount);
                                 }
        // Scenario 2
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'Mr. Samples');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_1__c,'Mr. Johnathan Quincy Samples');
    }
    
    static testMethod void generateSalutationsTest7(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];
        
        // Scenario 3
        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                                    LastName = 'Samples', Salutation = 'Mr.', FirstName = '', rC_Bios__Middle_Name__c= ''));
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Secondary_Contact__c = TRUE,
                                    LastName = 'Samples', Salutation = 'Mr.', FirstName = '', rC_Bios__Middle_Name__c= ''));                          
        insert contactList;    
        
        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                                  Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
                                  FROM Account
                                 ]) {      
                                     mapOfStringVsAccount.put(theAccount.Name,theAccount);
                                 }
        // Scenario 3
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'Mr. & Mr. Samples');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_1__c,'Mr. & Mr. Samples');  
    }    
    
    static testMethod void generateSalutationsTest8(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];
        
        // Scenario 4
        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                                    LastName = 'Samples', Salutation = 'Mr.', FirstName = '', rC_Bios__Middle_Name__c= ''));
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Secondary_Contact__c = TRUE,
                                    LastName = 'Samples', Salutation = 'Mr.', FirstName = '', rC_Bios__Middle_Name__c= ''));                          
        insert contactList;    
        
        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                                  Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
                                  FROM Account
                                 ]) {      
                                     mapOfStringVsAccount.put(theAccount.Name,theAccount);
                                 }
        // Scenario 4
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'Mr. & Mr. Samples');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_1__c,'Mr. & Mr. Samples');  
    }  
    static testMethod void generateSalutationsTest9(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];
        
        // Scenario 5
        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                                    LastName = 'Samples', Salutation = 'Mr.', FirstName = '', rC_Bios__Middle_Name__c= '',rC_Bios__Suffix__c='D.C.'));
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Secondary_Contact__c = TRUE,
                                    LastName = 'Samples', Salutation = 'Mr.', FirstName = '', rC_Bios__Middle_Name__c= ''));                          
        insert contactList;    
        
        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                                  Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
                                  FROM Account
                                 ]) {      
                                     mapOfStringVsAccount.put(theAccount.Name,theAccount);
                                 }
        // Scenario 5
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'Mr. & Mr. Samples');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_1__c,'Samples, D.C.');  
    }   
    static testMethod void generateSalutationsTest10(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];
        
        // Scenario 6
        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                                    LastName = 'Samples', Salutation = 'Mr & Mrs.', FirstName = 'test'));
       insert contactList;    
        
        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                                  Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
                                  FROM Account
                                 ]) {      
                                     mapOfStringVsAccount.put(theAccount.Name,theAccount);
                                 }
        // Scenario 6
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'Friends');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_1__c,'Mr & Mrs. test Samples');  
    } 
    static testMethod void generateSalutationsTest11(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];
        
        // Scenario 7
        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                                    LastName = 'test', FirstName = 'test'));
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Secondary_Contact__c = TRUE,
                                    LastName = 'Samples', FirstName = 'test'));      
        insert contactList;    
        
        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                                  Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
                                  FROM Account
                                 ]) {      
                                     mapOfStringVsAccount.put(theAccount.Name,theAccount);
                                 }
        // Scenario 7
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'test and test');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_1__c,'test test');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_2__c,'test Samples');
    }
    static testMethod void generateSalutationsTest12(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        Account acc=TestUtils.createAccount('Test Account ', false);
        acc.RecordTypeId=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Organization').getRecordTypeId();   
        insert acc;
        // Scenario 7
        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId =acc.Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                                    LastName = 'test', FirstName = 'test'));
        contactList.add(new Contact(AccountId =acc.Id, rC_Bios__Active__c = True, rC_Bios__Secondary_Contact__c = TRUE,
                                    LastName = 'Samples', FirstName = 'test'));      
        insert contactList;    
        
        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                                  Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
                                  FROM Account
                                 ]) {      
                                     mapOfStringVsAccount.put(theAccount.Name,theAccount);
                                 }
        // Scenario 7
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'test');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_1__c,'test');  
    } 
    static testMethod void generateSalutationsTest13(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];
        // Scenario 7
        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId =accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                                    LastName = 'test',Salutation = 'test', FirstName = '',rC_Bios__Middle_Name__c= '',Nickname__c=''));
        contactList.add(new Contact(AccountId =accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Secondary_Contact__c = TRUE,
                                    LastName = 'Samples', FirstName = 'test'));      
        insert contactList;    
        
        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                                  Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
                                  FROM Account
                                 ]) {      
                                     mapOfStringVsAccount.put(theAccount.Name,theAccount);
                                 }
        // Scenario 7
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'Friends');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_1__c,'test test');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_2__c,'test Samples');
    }


    static testMethod void generateSalutationsTest14(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];

        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId =accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                LastName = 'Unknown', FirstName = 'ACLU Supporter',rC_Bios__Middle_Name__c= '',Nickname__c=''));
        contactList.add(new Contact(AccountId =accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Secondary_Contact__c = TRUE,
                LastName = 'Samples', FirstName = 'test'));
        insert contactList;

        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
        FROM Account
        ]) {
            mapOfStringVsAccount.put(theAccount.Name,theAccount);
        }
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'Friends');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_1__c,'Friends');
    }

    static testMethod void generateSalutationsTest15(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];

        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId =accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                LastName = 'Test', FirstName = 'Primary',rC_Bios__Middle_Name__c= '',Nickname__c=''));
        contactList.add(new Contact(AccountId =accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Secondary_Contact__c = TRUE,
                LastName = 'Samples', FirstName = 'Secondary'));
        insert contactList;

        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
        FROM Account
        ]) {
            mapOfStringVsAccount.put(theAccount.Name,theAccount);
        }
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'Primary and Secondary');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_1__c,'Primary Test');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_2__c,'Secondary Samples');
    }

    static testMethod void generateSalutationsTest16(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];

        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId =accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                LastName = 'Test', FirstName = 'Primary',rC_Bios__Middle_Name__c= '',Nickname__c=''));
        contactList.add(new Contact(AccountId =accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Secondary_Contact__c = TRUE,
                LastName = 'Samples', FirstName = ''));
        insert contactList;

        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
        FROM Account
        ]) {
            mapOfStringVsAccount.put(theAccount.Name,theAccount);
        }
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'Friends');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_1__c,'Primary Test');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_2__c,'Samples');
    }

    static testMethod void generateSalutationsTest17(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];

        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId =accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                LastName = 'Test', FirstName = 'Primary',rC_Bios__Middle_Name__c= '',Nickname__c=''));
        insert contactList;

        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
        FROM Account
        ]) {
            mapOfStringVsAccount.put(theAccount.Name,theAccount);
        }
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'Primary');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_1__c,'Primary Test');
    }

    static testMethod void generateSalutationsTest18(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];

        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId =accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                LastName = 'Test', FirstName = '',rC_Bios__Middle_Name__c= 'Middle',Nickname__c=''));
        insert contactList;

        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
        FROM Account
        ]) {
            mapOfStringVsAccount.put(theAccount.Name,theAccount);
        }
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'Friend');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_1__c,'Middle Test');
    }

    static testMethod void generateSalutationsTest19(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];

        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId =accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                LastName = 'Test', FirstName = '',rC_Bios__Middle_Name__c= 'Middle',Nickname__c=''));
        insert contactList;

        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
        FROM Account
        ]) {
            mapOfStringVsAccount.put(theAccount.Name,theAccount);
        }
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'Friend');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_1__c,'Middle Test');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Default_Email_Salutation__c,'Middle');
    }

    static testMethod void generateSalutationsTest20(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];

        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId =accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                LastName = 'Test', FirstName = '',rC_Bios__Middle_Name__c= '',Nickname__c=''));
        insert contactList;

        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
        FROM Account
        ]) {
            mapOfStringVsAccount.put(theAccount.Name,theAccount);
        }
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'Friend');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_1__c,'Test');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Default_Email_Salutation__c,'Friend');
    }


    static testMethod void generateSalutationsTest21(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];

        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId =accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                LastName = 'acLU Supporter Unknown', FirstName = '',rC_Bios__Middle_Name__c= '',Nickname__c=''));
        insert contactList;

        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
        FROM Account
        ]) {
            mapOfStringVsAccount.put(theAccount.Name,theAccount);
        }
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_1__c,'Friend');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Informal_Outside_1__c,'Friend');
    }

    static testMethod void generateSalutationsTest22(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];

        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId =accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                LastName = 'Supporter Unknown', FirstName = 'ACLU',rC_Bios__Middle_Name__c= '',Nickname__c=''));

        insert contactList;

        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
        FROM Account
        ]) {
            mapOfStringVsAccount.put(theAccount.Name,theAccount);
        }
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_1__c,'Friend');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Informal_Outside_1__c,'Friend');
    }

    static testMethod void generateSalutationsTest23(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];

        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId =accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                LastName = 'ACLU Supporter Unknown', FirstName = '',rC_Bios__Middle_Name__c= '',Nickname__c=''));
        contactList.add(new Contact(AccountId =accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = false,
                rC_Bios__Secondary_Contact__c=true, LastName = 'secondary', FirstName = 'ACLU',rC_Bios__Middle_Name__c= '',Nickname__c=''));
        insert contactList;

        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
        FROM Account
        ]) {
            mapOfStringVsAccount.put(theAccount.Name,theAccount);
        }
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Outside_1__c,'Friends');
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Informal_Outside_1__c,'Friends');
    }
    static testMethod void generateSalutationsTest24(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];

        // Scenario 1
        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                LastName = 'Samples', Salutation = '', FirstName = '', rC_Bios__Middle_Name__c= 'Quincy'));
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Secondary_Contact__c = TRUE,
                LastName = 'Samples', Salutation = '', FirstName = '', rC_Bios__Middle_Name__c= 'Quincy'));
        insert contactList;

        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
        FROM Account
        ]) {
            mapOfStringVsAccount.put(theAccount.Name,theAccount);
        }
        // Scenario 1
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'Friends');
    }

    static testMethod void generateSalutationsTest25(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];

        // Scenario 1
        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                LastName = 'Samples', Salutation = 'The', FirstName = 'Ana', rC_Bios__Middle_Name__c= ''));
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Secondary_Contact__c = TRUE,
                LastName = 'Example', Salutation = '', FirstName = 'Test', rC_Bios__Middle_Name__c= 'Quincy'));
        insert contactList;

        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
        FROM Account
        ]) {
            mapOfStringVsAccount.put(theAccount.Name,theAccount);
        }
        // Scenario 1
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'Ana and Test');
    }

    static testMethod void generateSalutationsTest26(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];

        // Scenario 1
        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                LastName = 'Samples', FirstName = 'Ana', rC_Bios__Middle_Name__c= 'C'));
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Secondary_Contact__c = TRUE,
                LastName = 'Example', Salutation = 'The', FirstName = 'Test', rC_Bios__Middle_Name__c= 'ana'));
        insert contactList;

        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
        FROM Account
        ]) {
            mapOfStringVsAccount.put(theAccount.Name,theAccount);
        }
        // Scenario 1
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'Ana and Test');
    }

    static testMethod void generateSalutationsTest27(){
        map<String,Account> mapOfStringVsAccount = new map<String,Account>();
        List<Account> accList = [SELECT Id, Name FROM Account];

        // Scenario 1
        List<Contact> contactList = new List<Contact>();
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Preferred_Contact__c = True,
                LastName = 'Samples',  Salutation = 'The',FirstName = 'Ana', rC_Bios__Middle_Name__c= ''));
        contactList.add(new Contact(AccountId = accList.get(0).Id, rC_Bios__Active__c = True, rC_Bios__Secondary_Contact__c = TRUE,
                LastName = 'Example', Salutation = 'Mr', FirstName = 'Test', rC_Bios__Middle_Name__c= ''));
        insert contactList;

        for(Account theAccount : [SELECT Id, Name, Formal_Inside__c, Formal_Outside_1__c, Formal_Outside_2__c, Formal_Outside_3__c, Informal_Inside__c, Informal_Outside_1__c,
                Informal_Outside_2__c, Default_Email_Salutation__c, Recognition_Formal__c, Recognition_Informal__c
        FROM Account
        ]) {
            mapOfStringVsAccount.put(theAccount.Name,theAccount);
        }
        // Scenario 1
        system.assertEquals(mapOfStringVsAccount.get('Test Account 1').Formal_Inside__c,'Ana and Test');
    }



    @testSetup //Method to create test data
    private static void createTestData() {
        List<Account> accList = new List<Account>();
        for(Integer i=1;i<31;i++) {
            Account newAccount = TestUtils.createAccount('Test Account '+i, false);
            newAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
            newAccount.Formal_Inside__c='test';
            newAccount.Is_Formal_Inside_Locked__c=False;
            newAccount.Formal_Outside_1__c='test';
            newAccount.Is_Formal_Outside_1_Locked__c=False;
            newAccount.Formal_Outside_2__c='test';
            newAccount.Is_Formal_Outside_2_Locked__c=false;
            newAccount.Formal_Outside_3__c='test';
            newAccount.Is_Formal_Outside_3_Locked__c=false;
            newAccount.Informal_Outside_1__c='test';
            newAccount.Informal_Outside_2__c='test';
            newAccount.Informal_Outside_3__c='test'; 
            newAccount.Informal_Inside__c='test';
            newAccount.Is_Informal_Inside_Locked__c=false;    
            newAccount.Is_Informal_Outside_1_Locked__c=false;
            newAccount.Is_Informal_Outside_2_Locked__c=false;
            newAccount.Is_Informal_Outside_3_Locked__c=false;
            newAccount.Is_Email_Salutation_Locked__c=false;
            newAccount.Is_Recognition_Formal_Locked__c=false;
            newAccount.Is_Recognition_Informal_Locked__c=false;
            newAccount.Default_Email_Salutation__c='test';
            newAccount.Recognition_Formal__c='test';
            newAccount.Recognition_Informal__c='test';         
            accList.add(newAccount);
        }
        insert accList;
    }
}