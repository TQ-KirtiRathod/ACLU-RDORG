/*
*
*Name  :  SalutationsUtility
*Author:  Appirio India (Lalit Bohra)
*Date  :  October 17, 2016
*Purpose : Contains methods to set formal and informal salutation fields on Account on the basis of Primary and secondary contacts
*
*/
public with sharing class SalutationsUtility {
  private static Set<String> pluralPrefixes;
  private static Set<String> specialSuffixes;
    static {
        pluralPrefixes = new Set<String>{'Mr & Mrs.', 'The','Board of Directors of','Capt. and Mrs.','Captain and Mrs.','Cdr. and Mrs.','Chap. and Mrs.',
                                         'Chaplain and Mr.','Chaplain and Mrs.','Chaplain Capt. and Mrs.','Cmdr. and Mrs.','Cmsgt. and Mrs.','Col. and Mrs.',
                                         'Commission','Committee','Committee to Re-Elect','Co-Workers at','Co-Workers in','Co-Workers of','Dr. & Mr.','Dr. & Mrs.',
                                         'Dr. & Ms.','Dr. and Mr.','Dr. and Mrs.','Dr. and Ms.','Drs.','Estate of','Faculty at','Friends at','From the','Hon. & Mrs.',
                                         'Hon. and Mrs.','Judge & Mrs.','Judge and Mrs.','Lcdr. and Mrs.','Lt. Cdr. and Mrs.','Lt. Col. and Mrs.','Ltc. and Mrs.',
                                         'Maj. Gen. and Mrs.','Major and Mr.','Major and Mrs.','Members of','Messrs.','Misses','Misters','Mr. & Mrs.','Mr. & Ms.',
                                         'Mr. and Mr.','Mr. and Mrs.','Mr. and Ms.','Mrs. and Mrs.','Ms. & Mr.','Ms. and Ms.','Msgt. and Mrs.','MSgt. and Mrs.',
                                         'Officers of','Prof. and Mrs.','Professor & Mrs.','Rabbi & Mrs.','Ret. Col. and Mrs.','Rev. and Mrs.','Reverend & Mrs.',
                                         'Senator & Mrs.','Senator and Mrs.','SFC and Mrs.','Sfc. and Mrs.','Sgt. and Mrs.','Sp6 and Mrs.','SSG and Mrs.',
                                         'Ssg. and Mrs.','Ssgt. and Mrs.','The','The Family of','The Honorable & Mrs.','The Staff of','Trust of',
                                         'Tsgt. and Mrs.','TSgt. and Mrs.','Vicar and Mrs.'};
                                         
        specialSuffixes = new Set<String>{'D.C.','D.D.','D.D.M.','D.D.S.','D.M.D.','D.O.','D.P.M.','D.Sc.','D.Th.',
                                          'D.V.M.','D.V.M., Ph.D.','Dba.','DMD','DPM.','Ed.D.','Ed.D., L.H.D.','II',
                                          'Ph.D.','II,Esq.','II,M.D.','III, Ph.D.','III,Esq.','III,M.D.','IV, M.D.','IV',
                                          'Ph.D.','IV,Esq.','J.D., Ph.D.','J.D.,R.N.','Jr.,D.D.S.','Jr.,Esq.','Jr.,M.D.',
                                          'Jr.,Ph.D','LL.D.','M.D.','M.D., FAAP','M.D., FACP','Ph.D., LISW','Ph.D., R.Ac.',
                                          'Psy.D.','R.N.','Sc.D.','Sr., Esq.','Sr., M.D.','Sr., Ph.D.','V.M.D.'};
    }
    
  
  public static void generateSalutations(Set<Id> accountIds) {
    List<Account> listOfAccounts = new List<Account>();
    Contact primaryContact;
    Contact secondaryContact;
    if(accountIds!= null && accountIds.size() >0) {
      String primaryPrefix;
      String primaryFirstName;
      String primaryMiddleName;
      String primaryLastName;
      String primarySuffix;
      String primaryNickName;
      String secondaryPrefix;
      String secondaryFirstName;
      String secondaryMiddleName;
      String secondaryLastName;
      String secondarySuffix;
      String secondaryNickName;
      for(Account theAccount : [SELECT Id,Name,RecordType.Name,Formal_Inside__c,Is_Formal_Inside_Locked__c,Formal_Outside_1__c,
                                       Is_Formal_Outside_1_Locked__c,Formal_Outside_2__c,Is_Formal_Outside_2_Locked__c,Formal_Outside_3__c,Is_Formal_Outside_3_Locked__c,
                                       Informal_Outside_1__c,Informal_Outside_2__c,Informal_Outside_3__c,Informal_Inside__c,Is_Informal_Inside_Locked__c,
                                       Is_Informal_Outside_1_Locked__c,Is_Informal_Outside_2_Locked__c,Is_Informal_Outside_3_Locked__c,Is_Email_Salutation_Locked__c,
                                       Is_Recognition_Formal_Locked__c,Is_Recognition_Informal_Locked__c,Default_Email_Salutation__c,Recognition_Formal__c,
                                       Recognition_Informal__c,
                                       (SELECT FirstName,LastName,rC_Bios__Middle_Name__c,rC_Bios__Preferred_Contact__c,rC_Bios__Secondary_Contact__c,Salutation,
                                               rC_Bios__Suffix__c,Nickname__c,Title
                                        FROM Contacts
                                        WHERE (rC_Bios__Preferred_Contact__c = TRUE OR rC_Bios__Secondary_Contact__c = TRUE))
                                FROM Account 
                                WHERE Id IN : accountIds]) {
        primaryContact = null;
        secondaryContact = null;    
        for(Contact theContact : theAccount.Contacts) {
            if(theContact.rC_Bios__Preferred_Contact__c  == TRUE) {
                primaryContact = theContact;
            }else if(theContact.rC_Bios__Secondary_Contact__c  == TRUE) {
                secondaryContact = theContact;
            } 
        }
        primaryPrefix = (primaryContact!= null && primaryContact.Salutation != null) ? primaryContact.Salutation : '';
        primaryFirstName = (primaryContact!= null && primaryContact.FirstName != null) ? primaryContact.FirstName : '';
        primaryMiddleName = (primaryContact!= null && primaryContact.rC_Bios__Middle_Name__c != null) ? primaryContact.rC_Bios__Middle_Name__c : '';
        primaryLastName = (primaryContact!= null && primaryContact.LastName != null) ? primaryContact.LastName : '';
        primarySuffix = (primaryContact!= null && primaryContact.rC_Bios__Suffix__c != null) ? primaryContact.rC_Bios__Suffix__c : '';
        primaryNickName = (primaryContact!= null && primaryContact.Nickname__c != null) ? primaryContact.Nickname__c : '';
        secondaryPrefix = (secondaryContact!= null && secondaryContact.Salutation != null) ? secondaryContact.Salutation : '';
        secondaryFirstName = (secondaryContact!= null && secondaryContact.FirstName != null) ? secondaryContact.FirstName : '';
        secondaryMiddleName = (secondaryContact!= null && secondaryContact.rC_Bios__Middle_Name__c != null) ? secondaryContact.rC_Bios__Middle_Name__c : '';
        secondaryLastName = (secondaryContact!= null && secondaryContact.LastName != null) ? secondaryContact.LastName : '';
        secondarySuffix = (secondaryContact!= null && secondaryContact.rC_Bios__Suffix__c != null) ? secondaryContact.rC_Bios__Suffix__c : '';
        secondaryNickName = (secondaryContact!= null &&secondaryContact.Nickname__c != null) ? secondaryContact.Nickname__c : '';
        
        Wrapper params = new Wrapper(primaryPrefix, primaryFirstName, primaryMiddleName, primaryLastName,
                                     primarySuffix, primaryNickName, secondaryPrefix, secondaryFirstName, secondaryMiddleName, secondaryLastName, secondarySuffix,
                                     secondaryNickName);
                                     
        Account accWithFormalSals = generateFormalSalutations(theAccount, primaryContact, secondaryContact, params);
        Account accWithInFormalSals = generateInformalSalutations(theAccount, primaryContact, secondaryContact, params);
        Account accWithEmailSals = generateEmailSalutations(theAccount, primaryContact, secondaryContact, params);
        Account accWithRecognitionFormalSals = generateRecognitionFormalSalutations(theAccount, primaryContact, secondaryContact, params);
        Account accWithRecognitionInformalSals = generateRecognitionInformalSalutations(theAccount, primaryContact, secondaryContact, params);
        listOfAccounts.add(new Account(Id = theAccount.Id,
                                       Formal_Inside__c = ((theAccount.Is_Formal_Inside_Locked__c == True ? theAccount.Formal_Inside__c 
                                                            : ((accWithFormalSals != null && accWithFormalSals.Formal_Inside__c != null)
                                                              ? accWithFormalSals.Formal_Inside__c : ''))),
                                       Formal_Outside_1__c = theAccount.Is_Formal_Outside_1_Locked__c == True ? theAccount.Formal_Outside_1__c 
                                                            : ((accWithFormalSals!= null && accWithFormalSals.Formal_Outside_1__c != null)
                                                                ? accWithFormalSals.Formal_Outside_1__c : ''),
                                       Formal_Outside_2__c = theAccount.Is_Formal_Outside_2_Locked__c == True ? theAccount.Formal_Outside_2__c 
                                                              : ((accWithFormalSals!= null && accWithFormalSals.Formal_Outside_2__c != null) 
                                                                  ? accWithFormalSals.Formal_Outside_2__c : ''),
                                       Formal_Outside_3__c = theAccount.Is_Formal_Outside_3_Locked__c == True ? theAccount.Formal_Outside_3__c 
                                                                : ((accWithFormalSals!= null && accWithFormalSals.Formal_Outside_3__c != null )
                                                                  ? accWithFormalSals.Formal_Outside_3__c : ''),
                                       Informal_Inside__c = theAccount.Is_Informal_Inside_Locked__c == True ? theAccount.Informal_Inside__c 
                                                                : ((accWithInFormalSals!= null && accWithInFormalSals.Informal_Inside__c != null)
                                                                    ? accWithInFormalSals.Informal_Inside__c : ''),
                                       Informal_Outside_1__c = theAccount.Is_Informal_Outside_1_Locked__c == True ? theAccount.Informal_Outside_1__c 
                                                                  : ((accWithInFormalSals != null && accWithInFormalSals.Informal_Outside_1__c != null)
                                                                    ?accWithInFormalSals.Informal_Outside_1__c : ''),
                                       Informal_Outside_2__c = theAccount.Is_Informal_Outside_2_Locked__c == True ? theAccount.Informal_Outside_2__c
                                                                  : ((accWithInFormalSals!= null && accWithInFormalSals.Informal_Outside_2__c != null )
                                                                    ? accWithInFormalSals.Informal_Outside_2__c : ''),
                                       Default_Email_Salutation__c = theAccount.Is_Email_Salutation_Locked__c == True ? theAccount.Default_Email_Salutation__c
                                                                      : ((accWithEmailSals!= null && accWithEmailSals.Default_Email_Salutation__c != null)
                                                                      ? accWithEmailSals.Default_Email_Salutation__c: ''),
                                       Recognition_Formal__c = theAccount.Is_Recognition_Formal_Locked__c == True ? theAccount.Recognition_Formal__c
                                                                  : ((accWithRecognitionFormalSals!= null && accWithRecognitionFormalSals.Recognition_Formal__c != null)
                                                                    ? accWithRecognitionFormalSals.Recognition_Formal__c: ''),
                                       Recognition_Informal__c = theAccount.Is_Recognition_Informal_Locked__c == True ? theAccount.Recognition_Informal__c
                                                                : ((accWithRecognitionInformalSals!= null&&accWithRecognitionInformalSals.Recognition_Informal__c != null)
                                                                ? accWithRecognitionInformalSals.Recognition_Informal__c : '')
                                       ));
      }
    }
    if(!listOfAccounts.isEmpty()) {
      try {
        Utilities.invokedByContactTrigger = true;
        Database.SaveResult[] srList = Database.update(listOfAccounts, false);
      }
      catch(Exception ex) {
        apexLogHandler.apexLog log = new apexLogHandler.apexLog('SalutationsUtility','generateSalutations',ex.getMessage());
        log.logException(ex);
        log.saveLogs();
      }
    }
  }
    
  public static Account generateFormalSalutations(Account theAccount, Contact primaryContact, Contact secondaryContact, Wrapper params) {
    Account formalAcc;
    if(primaryContact!= null && secondaryContact == null && params.primaryLastName != '' && 
      (!(pluralPrefixes.contains(params.primaryPrefix))) &&
      (!(theAccount.RecordType.Name == 'Organization'))) {
      formalAcc = firstFormalSalutation(theAccount,primaryContact,params);  
    }
    else if((primaryContact != null && secondaryContact!= null) && (params.primaryLastName == params.secondaryLastName) && 
           (!((params.primaryFirstName == '' && params.primaryMiddleName == '')|| (params.secondaryFirstName == '' && params.secondaryMiddleName == ''))) &&
           (!(specialSuffixes.contains(params.primarySuffix) || specialSuffixes.contains(params.secondarySuffix))) &&  
           (!(pluralPrefixes.contains(params.primaryPrefix))) &&
           (!(theAccount.RecordType.Name == 'Organization'))) {
      formalAcc = secondandThirdFormalSalutation(theAccount, primaryContact, secondaryContact,params);      
    }
    else if((primaryContact != null && secondaryContact!= null) && (params.primaryLastName == params.secondaryLastName) &&
            ((params.primaryFirstName == '' && params.primaryMiddleName == '') || (params.secondaryFirstName == '' && params.secondaryMiddleName == '')) &&
            (!(specialSuffixes.contains(params.primarySuffix) || specialSuffixes.contains(params.secondarySuffix))) &&  
            (!(pluralPrefixes.contains(params.primaryPrefix))) &&
            (!(theAccount.RecordType.Name == 'Organization'))) {
      formalAcc = fourthFormalSalutation(theAccount, primaryContact, secondaryContact,params); 
    }
    else if((primaryContact != null && secondaryContact!= null) && (params.primaryLastName == params.secondaryLastName) && 
            (specialSuffixes.contains(params.primarySuffix) || specialSuffixes.contains(params.secondarySuffix)) && 
            (!(pluralPrefixes.contains(params.primaryPrefix))) &&
            (!(theAccount.RecordType.Name == 'Organization'))) {
      formalAcc = fifthFormalSalutation(theAccount, primaryContact, secondaryContact,params);   
    }
    else if(primaryContact != null && 
            (pluralPrefixes.contains(params.primaryPrefix) &&
            (!(theAccount.RecordType.Name == 'Organization')))) {
      formalAcc = sixthFormalSalutation(theAccount, primaryContact, secondaryContact,params);   
    }
       
    else if((primaryContact != null && secondaryContact != null) && (params.primaryLastName != params.secondaryLastName) &&
            (!(theAccount.RecordType.Name == 'Organization'))) {
      formalAcc = seventFormalSalutation(theAccount, primaryContact, secondaryContact,params);   
    }
    else if(theAccount.RecordType.Name == 'Organization') {
      formalAcc = tenthFormalSalutation(theAccount, primaryContact, secondaryContact,params);   
    }
    return formalAcc;
  }
  
  public static Account generateInFormalSalutations(Account theAccount, Contact primaryContact, Contact secondaryContact, Wrapper params) {
    Account informalAcc;
    if(primaryContact != null && secondaryContact == null && params.primaryLastName != '' &&
      (!pluralPrefixes.contains(params.primaryPrefix))) {
      informalAcc = FirstInformalSalutation(theAccount, primaryContact, params);
    }
    else if(primaryContact != null && secondaryContact != null && params.primaryLastName == params.secondaryLastName &&
           (!pluralPrefixes.contains(params.primaryPrefix)) &&
           (!((params.primaryFirstName == '' && params.primaryMiddleName == '' && params.primaryNickName == '') 
              || (params.secondaryFirstName == '' && params.secondaryMiddleName == '' && params.secondaryNickName == '')))) {
        informalAcc = SecondInformalSalutation(theAccount, primaryContact, secondaryContact, params);
    }
    else if(primaryContact != null && secondaryContact != null && params.primaryLastName != params.secondaryLastName &&
           (!pluralPrefixes.contains(params.primaryPrefix)) &&
           (!((params.primaryFirstName == '' && params.primaryMiddleName == '' && params.primaryNickName == '') 
              || (params.secondaryFirstName == '' && params.secondaryMiddleName == '' && params.secondaryNickName == '')))) {
      informalAcc = ThirdInformalSalutation(theAccount, primaryContact, secondaryContact, params);
    }
    else if(primaryContact != null && secondaryContact != null && params.primaryLastName == params.secondaryLastName && 
           ((params.primaryFirstName == '' && params.primaryMiddleName == '' && params.primaryNickName == '') 
            || (params.secondaryFirstName == '' && params.secondaryMiddleName == '' && params.secondaryNickName == '')) &&
           (!pluralPrefixes.contains(params.primaryPrefix))) {
        informalAcc = FourthInformalSalutation(theAccount, primaryContact, secondaryContact, params);
    }
    else if(primaryContact != null && secondaryContact != null && params.primaryLastName != params.secondaryLastName &&
           (!pluralPrefixes.contains(params.primaryPrefix)) &&
           ((params.primaryFirstName == '' && params.primaryMiddleName == '' && params.primaryNickName == '') 
              || (params.secondaryFirstName == '' && params.secondaryMiddleName == '' && params.secondaryNickName == ''))) {
      informalAcc = FifthInformalSalutation(theAccount, primaryContact, secondaryContact, params);
    }
    else if(primaryContact != null && pluralPrefixes.contains(params.primaryPrefix)) {
        informalAcc = SixthInformalSalutation(theAccount, primaryContact, secondaryContact, params);
    }
    return informalAcc; 
  }
  
  public static Account generateEmailSalutations(Account theAccount, Contact primaryContact, Contact secondaryContact, Wrapper params) {
    Account emailAcc;
    if(primaryContact != null && secondaryContact == null) {
      emailAcc = FirstEmailSalutation(theAccount, primaryContact, params);  
    }
    else if(primaryContact!= null && secondaryContact != null) {
        emailAcc = secondEmailSalutation(theAccount, primaryContact, secondaryContact, params); 
    }
    return emailAcc; 
  }
  
  public static Account generateRecognitionFormalSalutations(Account theAccount, Contact primaryContact, Contact secondaryContact, Wrapper params) {
    Account FormalRecognition;
    if(primaryContact != null && secondaryContact == null && params.primaryLastName!= '') {
        FormalRecognition = FirstFormalRecognitionSalutation(theAccount, primaryContact, params);  
    }
    else if(primaryContact != null && secondaryContact != null && ((params.primaryLastName == params.secondaryLastName) 
                                              || (params.primaryLastName != params.secondaryLastName))) {
        FormalRecognition = secondFormalRecognitionSalutation(theAccount, primaryContact, secondaryContact, params); 
    }
    return FormalRecognition;
  }
  
  public static Account generateRecognitionInformalSalutations(Account theAccount, Contact primaryContact, Contact secondaryContact, Wrapper params) {
    Account InformalRecognition;
    if(primaryContact != null && secondaryContact == null && params.primaryLastName!= '') {
      InformalRecognition = FirstInformalRecognitionSalutation(theAccount, primaryContact, params);  
    }
    else if(primaryContact != null && secondaryContact != null && (params.primaryLastName == params.secondaryLastName) ) {
      InformalRecognition = secondInformalRecognitionSalutation(theAccount, primaryContact, secondaryContact, params); 
    }
    else if(primaryContact != null && secondaryContact != null && (params.primaryLastName != params.secondaryLastName)) {
      InformalRecognition = thirdInformalRecognitionSalutation(theAccount, primaryContact, secondaryContact, params); 
    }
    return InformalRecognition;  
  }
     
  private static Account firstFormalSalutation(Account account, Contact primaryContact, Wrapper params) {
    String formalInside = '';
    String formalOutside1 = '';
    String informalOutside = '';
    String fullName = createName(params.primaryPrefix,params.primaryFirstName,params.primaryMiddleName ,params.primaryLastName,null);
    if (String.isBlank(params.primaryPrefix) && !String.isBlank(params.primaryFirstName)) {
        formalInside = params.primaryFirstName;
    } else {
          formalInside = params.primaryPrefix != '' ? params.primaryPrefix  + ' ' + params.primaryLastName : 'Friend';
    }
//    formalInside = params.primaryPrefix != '' ? params.primaryPrefix  + ' ' + params.primaryLastName : 'Friend';

      if( (params.primaryFirstName == 'ACLU Supporter' && params.primaryLastName =='Unknown')){
          formalOutside1 = 'Friend';
          informalOutside = 'Friend';
      }else if((params.primaryFirstName + ' ' + params.primaryLastName).containsIgnoreCase('ACLU Supporter Unknown')){
        formalOutside1 = 'Friend';
        informalOutside = 'Friend';
      }else{
          formalOutside1 = params.primarySuffix != '' ? fullName + ', ' +params.primarySuffix : fullName;
      }
    Account acc = new Account();
    acc.Formal_Inside__c = formalInside;
    acc.Formal_Outside_1__c = formalOutside1;
    if (!String.isBlank(informalOutside)) acc.Informal_Outside_1__c = informalOutside;
    return acc;
  }
  
  private static Account secondandThirdFormalSalutation(Account account, Contact primaryContact, Contact secondaryContact, Wrapper params) {
    String formalInside = '';
    String formalOutside1 = '';
    String formalOutside2 = ''; 
    String primaryfullName = createName(params.primaryPrefix,params.primaryFirstName,params.primaryMiddleName ,params.primaryLastName,null);
    String secondaryFullName =createName(params.secondaryPrefix,params.secondaryFirstName,params.secondaryMiddleName ,params.secondaryLastName,null);
    
    if(params.primaryPrefix == 'Dr.' && params.secondaryPrefix == 'Dr.') {
      formalInside = params.primaryLastName!= '' ? 'Drs. ' + params.primaryLastName : '';
      formalOutside1 = params.primarySuffix != '' ? primaryfullName + ', ' +params.primarySuffix : primaryfullName;
      formalOutside2 = params.secondarySuffix != ''? secondaryFullName +', ' +params.secondarySuffix : secondaryFullName;  
    }    
    else if(params.primaryPrefix == 'Mr.'&& params.secondaryPrefix == 'Mr.') {
      formalInside = params.primaryLastName!= '' ? 'Messrs. ' + params.primaryLastName : '';
      formalOutside1 = params.primarySuffix != '' ? primaryfullName + ', ' +params.primarySuffix : primaryfullName;
      formalOutside2 = params.secondarySuffix != ''? secondaryFullName +', ' +params.secondarySuffix : secondaryFullName;   
    }
    else if(params.primaryPrefix == 'Miss'&& params.secondaryPrefix == 'Miss') {
      formalInside = params.primaryLastName!= '' ? 'Misses ' + params.primaryLastName : '';
      formalOutside1 = params.primarySuffix != '' ? primaryfullName + ', ' +params.primarySuffix : primaryfullName;
      formalOutside2 = params.secondarySuffix != ''? secondaryFullName +', ' +params.secondarySuffix : secondaryFullName;
    }
    else if(params.primaryPrefix != '' && params.secondaryPrefix != '') {
        formalInside =  params.primaryLastName!= '' ? params.primaryPrefix + ' & ' + params.secondaryPrefix + ' ' + params.primaryLastName : '';
      formalOutside1 = params.primarySuffix != '' ? primaryfullName + ', ' +params.primarySuffix : primaryfullName;
      formalOutside2 = params.secondarySuffix != ''? secondaryFullName +', ' +params.secondarySuffix : secondaryFullName;
    }
    else if(((params.primaryPrefix == '' && params.secondaryPrefix == '')|| (params.primaryPrefix != '' || params.secondaryPrefix != '')) &&
            !String.isBlank(params.primaryFirstName) &&  !String.isBlank(params.secondaryFirstName)) {
        formalInside =  params.primaryFirstName + ' and ' + params.secondaryFirstName;
        formalOutside1 = params.primarySuffix != '' ? primaryfullName + ', ' +params.primarySuffix : primaryfullName;
        formalOutside2 = params.secondarySuffix != ''? secondaryFullName +', ' +params.secondarySuffix : secondaryFullName;
    }
    else if(params.primaryPrefix == '' || params.secondaryPrefix == '') {
        formalInside =  'Friends';
      formalOutside1 = params.primarySuffix != '' ? primaryfullName + ', ' +params.primarySuffix : primaryfullName;
      formalOutside2 = params.secondarySuffix != ''? secondaryFullName +', ' +params.secondarySuffix : secondaryFullName;
    }
    else if ((params.primaryFirstName == 'ACLU Supporter' && params.primaryLastName =='Unknown')||
            (params.secondaryFirstName == 'ACLU Supporter' && params.secondaryLastName =='Unknown')){
        formalOutside1= 'Friends';
        formalOutside2= 'Friends';
    }else if ((params.primaryFirstName + ' ' + params.primaryLastName).containsIgnoreCase('ACLU Supporter Unknown')||
            (params.secondaryFirstName + ' ' + params.secondaryLastName).containsIgnoreCase('ACLU Supporter Unknown')){
        formalOutside1= 'Friends';
        formalOutside2= 'Friends';
    }else if (!String.isBlank(params.primaryFirstName) &&  !String.isBlank(params.secondaryFirstName)){
        formalOutside1= params.primaryFirstName;
        formalOutside2= params.secondaryFirstName;
    }else if(String.isBlank(params.primaryFirstName) || String.isBlank(params.secondaryFirstName)){
        formalInside = 'Friends';
        formalOutside1= 'Friends';
        formalOutside2= 'Friends';
    }

    Account acc = new Account();
    acc.Formal_Inside__c = formalInside;
    acc.Formal_Outside_1__c = formalOutside1;
    acc.Formal_Outside_2__c = formalOutside2;
    return acc;       
  }  
  
  private static Account fourthFormalSalutation(Account account, Contact primaryContact, Contact secondaryContact, Wrapper params) {
    String formalInside = '';
    String formalOutside1 = '';
    String formalOutside2 = '';
    String combinePrefix = params.primaryPrefix != '' && params.secondaryPrefix != '' ? params.primaryPrefix + ' & ' + params.secondaryPrefix :
                           (params.primaryPrefix ==  '' ? params.secondaryPrefix : (params.secondaryPrefix == '' ? params.primaryPrefix : ''));
    formalInside = params.primaryPrefix != '' && params.secondaryPrefix != '' ?
                     (params.primaryLastName != '' ? params.primaryPrefix + ' & ' + params.secondaryPrefix + ' ' + params.primaryLastName : '') : 'Friends';
    if(params.primaryFirstName == '' && params.primaryMiddleName == '' && params.secondaryFirstName == '' && params.secondaryMiddleName == '') {
      String primaryfullName = createName(combinePrefix,params.primaryFirstName,params.primaryMiddleName ,params.primaryLastName,null);
      formalOutside1 = params.primarySuffix != '' ? primaryfullName + ', ' +params.primarySuffix : primaryfullName;
    }
    else if(params.primaryFirstName != '' && params.primaryMiddleName != '' && params.secondaryFirstName ==  '' && params.secondaryMiddleName == '') {       
        String primaryfullName = createName(combinePrefix,params.primaryFirstName,params.primaryMiddleName ,params.primaryLastName,null);
      formalOutside1 = params.primarySuffix != '' ? primaryfullName + ', ' +params.primarySuffix : primaryfullName;
    } 
    else if(params.primaryFirstName == '' && params.primaryMiddleName == '' && params.secondaryFirstName != '' && params.secondaryMiddleName != '') {
        String primaryfullName = createName(params.primaryPrefix,params.primaryFirstName,params.primaryMiddleName ,params.primaryLastName,null);
        String secondaryFullName =createName(params.secondaryPrefix,params.secondaryFirstName,params.secondaryMiddleName ,params.secondaryLastName,null);
      formalOutside1 = params.primarySuffix != '' ? primaryfullName + ', ' +params.primarySuffix : primaryfullName;
      formalOutside2 = params.secondarySuffix != ''? secondaryFullName +', ' +params.secondarySuffix : secondaryFullName;   
    }
    Account acc = new Account();
    acc.Formal_Inside__c = formalInside;
    acc.Formal_Outside_1__c = formalOutside1;
    acc.Formal_Outside_2__c = formalOutside2;
    return acc;    
  }
  
  private static Account fifthFormalSalutation(Account account, Contact primaryContact, Contact secondaryContact, Wrapper params) {
    String formalInside = '';
    String formalOutside1 = '';
    String formalOutside2 = '';
    String prefix1 = specialSuffixes.contains(params.primarySuffix) ? params.primarySuffix : params.primaryPrefix;
    String prefix2 = specialSuffixes.contains(params.secondarySuffix) ? params.secondarySuffix : params.secondaryPrefix;
    formalInside = params.primaryPrefix != '' &&  params.secondaryPrefix != '' ?
                   (params.primaryLastName!= '' ? params.primaryPrefix + ' & ' +  params.secondaryPrefix + ' ' + params.primaryLastName : '')
                   : 'Friends';
                   
    String primaryFullNameWithPrefix = createName(params.primaryPrefix,params.primaryFirstName,params.primaryMiddleName ,params.primaryLastName,null);
    String primaryFullNameWithoutPrefix = createName(params.primaryFirstName,params.primaryMiddleName ,params.primaryLastName,null,null);
    String secondaryFullNameWithPrefix = createName(params.secondaryPrefix,params.secondaryFirstName,params.secondaryMiddleName ,params.secondaryLastName,null);
    String secondaryFullNameWithoutPrefix = createName(params.secondaryFirstName,params.secondaryMiddleName ,params.secondaryLastName,null,null);

    formalOutside1 = specialSuffixes.contains(params.primarySuffix) ? (params.primarySuffix != '' ? primaryFullNameWithoutPrefix +', '
                                                                              +params.primarySuffix : primaryFullNameWithoutPrefix)
                                                                    : (params.primarySuffix != '' ? primaryFullNameWithPrefix + ', '
                                                                              +params.primarySuffix : primaryFullNameWithPrefix);
    formalOutside2 = specialSuffixes.contains(params.secondarySuffix) ? (params.secondarySuffix!= '' ? secondaryFullNameWithoutPrefix +', '+ 
                                                                               params.secondarySuffix : secondaryFullNameWithoutPrefix)
                                                                      : (params.secondarySuffix!= '' ? secondaryFullNameWithPrefix +', '
                                                                                +params.secondarySuffix : secondaryFullNameWithPrefix);
    Account acc = new Account();
    acc.Formal_Inside__c = formalInside;
    acc.Formal_Outside_1__c = formalOutside1;
    acc.Formal_Outside_2__c = formalOutside2;
    return acc; 
  }
  
  private static Account sixthFormalSalutation(Account account, Contact primaryContact, Contact secondaryContact, Wrapper params) {
    String formalInside = '';
    String formalOutside1 = '';
    String formalOutside2 = '';
    String primaryFullName = createName(params.primaryPrefix,params.primaryFirstName,params.primaryMiddleName ,params.primaryLastName,null);
    if(primaryContact!= null && secondaryContact!= null) {
        if((params.primaryPrefix != '' || params.secondaryPrefix!= '') &&
                !String.isBlank(params.primaryFirstName) &&  !String.isBlank(params.secondaryFirstName) ){
            formalInside =  params.primaryFirstName + ' and ' + params.secondaryFirstName;
        }else{
      formalInside =  params.primaryLastName!= '' ? params.primaryPrefix +  ' ' + params.primaryLastName : '';
        }
      formalOutside1 = params.primarySuffix!= '' ? primaryFullName + ', ' +params.primarySuffix : primaryFullName;  
    }
    else if(primaryContact!= null && secondaryContact== null) {
      formalInside = 'Friends';
      formalOutside1 =  params.primarySuffix!= '' ? primaryFullName +', ' +params.primarySuffix : primaryFullName;
    }
    Account acc = new Account();
    acc.Formal_Inside__c = formalInside;
    acc.Formal_Outside_1__c = formalOutside1;
    return acc; 
  }
  
  private static Account seventFormalSalutation(Account account, Contact primaryContact, Contact secondaryContact, Wrapper params) {
    String formalInside = '';
    String formalOutside1 = '';
    String informalOutside1 = '';
    String formalOutside2 = '';
    String primaryfullName = createName(params.primaryPrefix,params.primaryFirstName,params.primaryMiddleName ,params.primaryLastName,null);
    String secondaryFullName =createName(params.secondaryPrefix,params.secondaryFirstName,params.secondaryMiddleName ,params.secondaryLastName,null);
    formalInside = (params.primaryPrefix != '' && params.secondaryPrefix!= '')
                   ? (params.primaryLastName!= '' && params.secondaryLastName!= '' ? params.primaryPrefix + ' ' + params.primaryLastName 
                          + ' & ' +  params.secondaryPrefix + ' ' + params.secondaryLastName : '')
                   : 'Friends';
    formalOutside1 = params.primarySuffix != '' ? primaryfullName + ', ' +params.primarySuffix : primaryfullName;
    formalOutside2 = params.secondarySuffix != ''? secondaryFullName +', ' +params.secondarySuffix : secondaryFullName;

      if ((params.primaryFirstName == 'ACLU Supporter' && params.primaryLastName =='Unknown')||
              (params.secondaryFirstName == 'ACLU Supporter' && params.secondaryLastName =='Unknown')){
          formalOutside1= 'Friends';
          formalOutside2= 'Friends';
          informalOutside1 = 'Friends';
      }else if((params.primaryFirstName + ' ' + params.primaryLastName).containsIgnoreCase('ACLU Supporter Unknown')||
              (params.secondaryFirstName + ' ' + params.secondaryLastName).containsIgnoreCase('ACLU Supporter Unknown')){
          formalOutside1= 'Friends';
          formalOutside2= 'Friends';
          informalOutside1 = 'Friends';
      } else if (!String.isBlank(params.primaryFirstName) &&  !String.isBlank(params.secondaryFirstName)){
          formalInside = params.primaryFirstName +' and '+ params.secondaryFirstName;
      }else if(String.isBlank(params.primaryFirstName) || String.isBlank(params.secondaryFirstName)){
          formalInside = 'Friends';
      }
    Account acc = new Account();
    acc.Formal_Inside__c = formalInside;
    acc.Formal_Outside_1__c = formalOutside1;
    acc.informal_Outside_1__c = informalOutside1;
    acc.Formal_Outside_2__c = formalOutside2;
    return acc; 
  }
    
  private static Account tenthFormalSalutation(Account account, Contact primaryContact, Contact secondaryContact, Wrapper params) {
    String formalInside = '';
    String formalOutside1 = '';
    String formalOutside2 = '';
    String formalOutside3 = '';
    String primaryfullName = createName(params.primaryPrefix,params.primaryFirstName,params.primaryMiddleName ,params.primaryLastName,null);
    String secondaryFullName =createName(params.secondaryPrefix,params.secondaryFirstName,params.secondaryMiddleName ,params.secondaryLastName,null);
    if(primaryContact == null && secondaryContact == null && (account.Name != null || account.Name != '')) {
     formalInside = 'Friends';
     formalOutside1 = account.Name; 
    }
    else if(primaryContact != null && !String.isBlank(params.primaryPrefix) && !String.isBlank(params.primaryFirstName) && !String.isBlank(params.primaryLastName)  ){
        formalInside = params.primaryPrefix +' '+ params.primaryLastName;
        formalOutside1 = params.primarySuffix!= '' ? primaryfullName + ', '+ params.primarySuffix : primaryfullName;
        formalOutside2 = primaryContact.Title;
        formalOutside3 = account.Name;
    }
    else if(primaryContact != null && String.isBlank(params.primaryPrefix) && !String.isBlank(params.primaryFirstName) ){
        formalInside = params.primaryFirstName;
        formalOutside1 = params.primarySuffix!= '' ? primaryfullName + ', '+ params.primarySuffix : primaryfullName;
        formalOutside2 = primaryContact.Title;
        formalOutside3 = account.Name;
    }
//    else if(primaryContact != null && secondaryContact == null && (account.Name != null || account.Name != '')
//                                && (primaryContact.Title != null || primaryContact.Title != '')) {
//        formalInside = 'Friend';
//        formalOutside1 = params.primarySuffix!= '' ? primaryfullName + ', '+ params.primarySuffix : primaryfullName;
//        formalOutside2 = primaryContact.Title;
//        formalOutside3 = account.Name;
//    }
    else if(primaryContact == null && secondaryContact != null && (account.Name != null || account.Name != '')) {
     formalInside = 'Friend';
     formalOutside1 = params.secondarySuffix != '' ? secondaryFullName + ', ' +params.secondarySuffix : secondaryFullName;
     formalOutside2 = account.Name;     
    }
    /*else if(primaryContact == null && secondaryContact != null && account.Name != null && primaryContact.Title != null) {
     formalInside = 'Friend';
     formalOutside1 = params.secondarySuffix != '' ? secondaryFullName + ', ' +params.secondarySuffix : secondaryFullName;
     formalOutside2 = account.Name; 
    }*/
    else if(primaryContact != null && secondaryContact != null && (account.Name != null || account.Name != '')) {
      formalInside = 'Friends';
      formalOutside1 = params.primarySuffix!= '' ? primaryfullName + ', '+ params.primarySuffix : primaryfullName;
      formalOutside2 = params.secondarySuffix!= '' ? secondaryFullName + ', ' +params.secondarySuffix : secondaryFullName;
      formalOutside3 = account.Name;    
    }
    Account acc = new Account();
    acc.Formal_Inside__c = formalInside;
    acc.Formal_Outside_1__c = formalOutside1;
    acc.Formal_Outside_2__c = formalOutside2;
    acc.Formal_Outside_3__c  = formalOutside3;
    return acc; 
  }
  
  private static Account FirstInformalSalutation(Account account, Contact primaryContact, Wrapper params) {
    String informalInside = '';
    String informalOutside1 = '';
    String informalPickOfPrimray = params.primaryNickName != '' ? params.primaryNickName : ((params.primaryFirstName) != '' ? params.primaryFirstName :
                                    (params.primaryMiddleName != '' ? params.primaryMiddleName : null));
    informalInside = informalPickOfPrimray != null ? informalPickOfPrimray : 'Friend';
    informalOutside1 = informalPickOfPrimray != null
                     ? informalPickOfPrimray + ' ' + params.primaryLastName 
                     : (params.primaryPrefix != '' ? params.primaryPrefix + ' ' + params.primaryLastName : (params.primaryLastName));
    if((params.primaryFirstName + ' ' + params.primaryLastName).containsIgnoreCase('ACLU Supporter Unknown')||
              (params.secondaryFirstName + ' ' + params.secondaryLastName).containsIgnoreCase('ACLU Supporter Unknown')){
          informalOutside1 = 'Friend';
      }
    Account acc = new Account();
    acc.Informal_Inside__c = informalInside;
    acc.Informal_Outside_1__c = informalOutside1;
    return acc;
  }
  
  private static Account SecondInformalSalutation(Account account, Contact primaryContact, Contact secondaryContact, Wrapper params) {
    String informalInside;
    String informalOutside1;
    String informalPickOfPrimray = params.primaryNickName != '' ? params.primaryNickName : ((params.primaryFirstName) != '' ? params.primaryFirstName :
                                    (params.primaryMiddleName != '' ? params.primaryMiddleName : null));
    String inofrmalPickOfSecondary = params.secondaryNickName != '' ? params.secondaryNickName : ((params.secondaryFirstName) != '' ? params.secondaryFirstName :
                                    (params.secondaryMiddleName != '' ? params.secondaryMiddleName : null));
    informalInside = informalPickOfPrimray != null && inofrmalPickOfSecondary != null ? informalPickOfPrimray + ' and ' +  inofrmalPickOfSecondary : 'Friends';
    
    informalOutside1 = informalPickOfPrimray != null && inofrmalPickOfSecondary != null && params.primaryLastName!= ''
                     ? informalPickOfPrimray + ' and ' +  inofrmalPickOfSecondary + ' ' + params.primaryLastName
                     : (informalPickOfPrimray == null && inofrmalPickOfSecondary != null && params.primaryLastName!= '' 
                          ? inofrmalPickOfSecondary + ' ' + params.primaryLastName 
                         : (inofrmalPickOfSecondary== null && informalPickOfPrimray != null && params.primaryLastName!= ''
                              ? informalPickOfPrimray + ' ' + params.primaryLastName 
                                :(params.primaryLastName != '' ? params.primaryLastName : '')));

      if((params.primaryFirstName + ' ' + params.primaryLastName).containsIgnoreCase('ACLU Supporter Unknown')||
              (params.secondaryFirstName + ' ' + params.secondaryLastName).containsIgnoreCase('ACLU Supporter Unknown')){
          informalOutside1 = 'Friends';
      }
    Account acc = new Account();
    acc.Informal_Inside__c = informalInside;
    acc.Informal_Outside_1__c = informalOutside1;
    return acc;
  }
  
  private static Account ThirdInformalSalutation(Account account, Contact primaryContact, Contact secondaryContact, Wrapper params) {
    String informalInside;
    String informalOutside1;
    String informalPickOfPrimray = params.primaryNickName != ''? params.primaryNickName : ((params.primaryFirstName) != '' ? params.primaryFirstName :
                                    (params.primaryMiddleName != '' ? params.primaryMiddleName : ''));
    String inofrmalPickOfSecondary = params.secondaryNickName != '' ? params.secondaryNickName : ((params.secondaryFirstName) != '' ? params.secondaryFirstName :
                                    (params.secondaryMiddleName != '' ? params.secondaryMiddleName : ''));
    informalInside = informalPickOfPrimray!= '' && inofrmalPickOfSecondary!= '' ? informalPickOfPrimray + ' and ' +  inofrmalPickOfSecondary : 'Friends';
    String part1 = createName(informalPickOfPrimray,params.primaryLastName,null,null,null);
    String part2 = createName(inofrmalPickOfSecondary,params.secondaryLastName,null,null,null);
    informalOutside1 = part1!= '' && part2 != '' ? part1 + ' and ' + part2 : (part1 == '' ? part2 : (part2 == '' ? part1 : ''));
      if((params.primaryFirstName + ' ' + params.primaryLastName).containsIgnoreCase('ACLU Supporter Unknown')||
              (params.secondaryFirstName + ' ' + params.secondaryLastName).containsIgnoreCase('ACLU Supporter Unknown')){
          informalOutside1 = 'Friends';
      }
    Account acc = new Account();
    acc.Informal_Inside__c = informalInside;
    acc.Informal_Outside_1__c = informalOutside1;
    return acc; 
  }
  
  private static Account FourthInformalSalutation(Account account, Contact primaryContact, Contact secondaryContact, Wrapper params) {
    String informalInside;
    String informalOutside1;
    String informalPickOfPrimray = params.primaryNickName != '' ? params.primaryNickName : ((params.primaryFirstName) != '' ? params.primaryFirstName :
                                    (params.primaryMiddleName != '' ? params.primaryMiddleName : null));
    String inofrmalPickOfSecondary = params.secondaryNickName != '' ? params.secondaryNickName : ((params.secondaryFirstName) != '' ? params.secondaryFirstName :
                                    (params.secondaryMiddleName != '' ? params.secondaryMiddleName : null));
    informalInside = params.primaryPrefix != '' && params.secondaryPrefix != ''
                      ? (params.primaryLastName != '' ? params.primaryPrefix + ' and ' + params.secondaryPrefix + ' ' + params.primaryLastName : '')
                      : 'Friends';
    String combinePrefix = params.primaryPrefix!= '' && params.secondaryPrefix!= '' ? params.primaryPrefix + ' and ' + params.secondaryPrefix
                             : (params.primaryPrefix == '' ? params.secondaryPrefix : ( params.secondaryPrefix == '' ? params.primaryPrefix : ''));
    if((params.primaryFirstName + ' ' + params.primaryLastName).containsIgnoreCase('ACLU Supporter Unknown')||
       (params.secondaryFirstName + ' ' + params.secondaryLastName).containsIgnoreCase('ACLU Supporter Unknown')){
          informalOutside1 = 'Friends';
    }else if(informalPickOfPrimray == null && inofrmalPickOfSecondary == null) {
      informalOutside1 =  createName(combinePrefix,params.primaryLastName,null,null,null);
    }
    else if(inofrmalPickOfSecondary == null) {
      informalOutside1 =  createName(combinePrefix,informalPickOfPrimray,params.primaryLastName,null,null); 
    }
    else if(informalPickOfPrimray == null) {
      informalOutside1 =  createName(combinePrefix,inofrmalPickOfSecondary,params.primaryLastName,null,null); 
    }
    Account acc = new Account();
    acc.Informal_Inside__c = informalInside;
    acc.Informal_Outside_1__c = informalOutside1;
    return acc;  
  }
  
  private static Account FifthInformalSalutation(Account account, Contact primaryContact, Contact secondaryContact, Wrapper params) {
    String informalInside;
    String informalOutside1;
    String informalPickOfPrimray = params.primaryNickName != '' ? params.primaryNickName : ((params.primaryFirstName) != '' ? params.primaryFirstName :
                                    (params.primaryMiddleName != '' ? params.primaryMiddleName : null));
    String inofrmalPickOfSecondary = params.secondaryNickName != '' ? params.secondaryNickName : ((params.secondaryFirstName) != '' ? params.secondaryFirstName :
                                    (params.secondaryMiddleName != '' ? params.secondaryMiddleName : null));
     if((params.primaryFirstName + ' ' + params.primaryLastName).containsIgnoreCase('ACLU Supporter Unknown')||
      (params.secondaryFirstName + ' ' + params.secondaryLastName).containsIgnoreCase('ACLU Supporter Unknown')){
      informalOutside1 = 'Friends';
    }else if(informalPickOfPrimray == null && inofrmalPickOfSecondary == null) {
      informalInside =  'Friends';
      String part1 = createName(params.primaryPrefix,params.primaryLastName,null,null,null);
      String part2 = createName(params.secondaryPrefix,params.secondaryLastName,null,null,null);
      informalOutside1 = part1 != '' && part2 != '' ? part1 + ' and ' + part2 : (part1 == '' ? part2 : (part2 == '' ? part1 : ''));
    }
    else if(inofrmalPickOfSecondary == null) {
      informalInside = 'Friends';
      String part1 = createName(informalPickOfPrimray,params.primaryLastName,null,null,null);
      String part2 = createName(params.secondaryPrefix,params.secondaryLastName,null,null,null);
      informalOutside1 = part1 != '' && part2 != '' ? part1 + ' and ' + part2 : (part1 == '' ? part2 : (part2 == '' ? part1 : ''));
    }
    else if(informalPickOfPrimray == null) {
      informalInside = 'Friends';
      String part1 = createName(params.primaryPrefix,params.primaryLastName,null,null,null);
      String part2 = createName(inofrmalPickOfSecondary,params.secondaryLastName,null,null,null);
      informalOutside1 = part1 != '' && part2 != '' ? part1 + ' and ' + part2 : (part1 == '' ? part2 : (part2 == '' ? part1 : ''));
    }
    Account acc = new Account();
    acc.Informal_Inside__c = informalInside;
    acc.Informal_Outside_1__c = informalOutside1;
    return acc;
  }
  
  private static Account SixthInformalSalutation(Account account, Contact primaryContact, Contact secondaryContact, Wrapper params) {
    String informalInside;
    String informalOutside1;
    String informalPickOfPrimray = params.primaryNickName != '' ? params.primaryNickName : ((params.primaryFirstName) != '' ? params.primaryFirstName :
                                    (params.primaryMiddleName != '' ? params.primaryMiddleName : null));
    String inofrmalPickOfSecondary = params.secondaryNickName != '' ? params.secondaryNickName : ((params.secondaryFirstName) != '' ? params.secondaryFirstName :
                                    (params.secondaryMiddleName != '' ? params.secondaryMiddleName : null));
    if(secondaryContact == null) {
        informalOutside1 = createName(params.primaryPrefix,informalPickOfPrimray,params.primaryLastName,null,null);
        informalInside = 'Friends'; 
    }
    else if(secondaryContact!= null) {
        informalInside = (informalPickOfPrimray != null && inofrmalPickOfSecondary!= null) ? informalPickOfPrimray + ' and ' + inofrmalPickOfSecondary : 'Friends';
        if(informalPickOfPrimray!= null && inofrmalPickOfSecondary != null) {
            if(params.primaryLastName != params.secondaryLastName) {
            String part1 = createName(informalPickOfPrimray,params.primaryLastName,null,null,null);
        String part2 = createName(inofrmalPickOfSecondary,params.secondaryLastName,null,null,null);
        informalOutside1 = part1 != '' && part2 != '' ? part1 + ' and ' + part2 : (part1 == '' ? part2 : (part2 == '' ? part1 : ''));
            }
            else {
                informalOutside1 = informalPickOfPrimray + ' and ' + inofrmalPickOfSecondary + ' ' + params.primaryLastName;
            }
        }
        else if(informalPickOfPrimray == null) {
          informalOutside1 = createName(params.primaryprefix,params.primaryLastName,null,null,null);
        }
    }
    Account acc = new Account();
    acc.Informal_Inside__c = informalInside;
    acc.Informal_Outside_1__c = informalOutside1;
    return acc;
  } 
  
  private static Account firstEmailSalutation(Account account, Contact primaryContact, Wrapper params) {
      String defaultEmailSal = '';
      if ( !String.isBlank(params.primaryFirstName)) {
          defaultEmailSal = params.primaryFirstName;
      } else if (!String.isBlank(params.primaryMiddleName)){
          defaultEmailSal = params.primaryMiddleName;
      } else {
          defaultEmailSal = 'Friend';
      }
//    String defaultEmailSal = params.primaryFirstName != '' ? params.primaryFirstName : ((params.primaryMiddleName) != '' ? params.primaryMiddleName : 'Friend');

    Account acc = new Account();
    acc.Default_Email_Salutation__c = defaultEmailSal;
    return acc;
  }
  
  private static Account secondEmailSalutation(Account account, Contact primaryContact, Contact secondaryContact, Wrapper params) {
    Account acc = new Account();
    acc.Default_Email_Salutation__c = 'Friends';
    return acc;
  }
  
  private static Account FirstFormalRecognitionSalutation(Account account, Contact primaryContact, Wrapper params) {
    Account acc = new Account();
    String primaryfullName = createName(params.primaryPrefix,params.primaryFirstName,params.primaryMiddleName ,params.primaryLastName,null);
    acc.Recognition_Formal__c = params.primarySuffix != '' ? primaryfullName + ', ' + params.primarySuffix : primaryfullName;
    return acc;
  }
  
  private static Account secondFormalRecognitionSalutation(Account account, Contact primaryContact, Contact secondaryContact, Wrapper params) {
    Account acc = new Account();
    String primaryfullName = createName(params.primaryPrefix,params.primaryFirstName,params.primaryMiddleName ,params.primaryLastName,null);
    String secondaryFullName =createName(params.secondaryFirstName,params.secondaryMiddleName ,params.secondaryLastName,null,null);
    primaryfullName = params.primarySuffix!= '' ? primaryfullName + ', '+  params.primarySuffix : primaryfullName;
    secondaryFullName = params.secondarySuffix!= '' ? secondaryFullName + ', ' + params.secondarySuffix : secondaryFullName;
    acc.Recognition_Formal__c = primaryfullName + ' & ' + secondaryFullName;
    return acc;
  }  
  
    private static Account FirstInformalRecognitionSalutation(Account account, Contact primaryContact, Wrapper params) {
    Account acc = new Account();
    acc.Recognition_Informal__c = params.primaryFirstName != '' && params.primaryLastName!= ''? params.primaryFirstName + ' ' + params.primaryLastName
                                                         : (params.primaryMiddleName != '' && params.primaryLastName!= '' ? params.primaryMiddleName + ' ' 
                                                                                                                                + params.primaryLastName
                                                                                     : (params.primaryPrefix!= '' && params.primaryLastName!= '' ? params.primaryPrefix + ' ' + 
                                                                                     params.primaryLastName : params.primaryLastName));
    return acc;
  }
  
  private static Account secondInformalRecognitionSalutation(Account account, Contact primaryContact, Contact secondaryContact, Wrapper params) {
    String informalPick1 = params.primaryFirstName != '' ?params.primaryFirstName : (params.primaryMiddleName!= ''? params.primaryMiddleName 
                              : (params.primaryPrefix != '' ? params.primaryPrefix : ''));
    String informalPick2 = params.secondaryFirstName!= '' ? params.secondaryFirstName :(params.secondaryMiddleName != '' ? params.secondaryMiddleName 
                              : (params.secondaryPrefix != '' ? params.secondaryPrefix : ''));
    Account acc = new Account();
    acc.Recognition_Informal__c = informalPick1!= '' && informalPick2 != '' && params.primaryLastName!= '' 
                                ? informalPick1 + ' & ' + informalPick2 + ' ' + params.primaryLastName
                                : params.primaryLastName;// This needs to be confirmed
    return acc;
  }
  
  private static Account thirdInformalRecognitionSalutation(Account account, Contact primaryContact, Contact secondaryContact, Wrapper params) {
    String informalPick1 = params.primaryFirstName != '' ?params.primaryFirstName : (params.primaryMiddleName!= ''? params.primaryMiddleName 
                              : (params.primaryPrefix != '' ? params.primaryPrefix : ''));
    String informalPick2 = params.secondaryFirstName!= '' ? params.secondaryFirstName :(params.secondaryMiddleName != '' ? params.secondaryMiddleName 
                              : (params.secondaryPrefix != '' ? params.secondaryPrefix : ''));
    String part1 =  createName(informalPick1,params.primaryLastName,null,null,null);
    String part2 =  createName(informalPick2,params.secondaryLastName,null,null,null);
    Account acc = new Account();
    acc.Recognition_Informal__c =  part1!= '' && part2 != '' ? part1 + ' & ' + part2 : (part1 == '' ? part2 : (part2 == '' ? part1 : ''));                           
    return acc;
  }
  
  public class Wrapper {
    public String primaryPrefix;
    public String primaryFirstName;
    public String primaryMiddleName;
    public String primaryLastName;
    public String primarySuffix;
    public String secondaryPrefix;
    public String secondaryFirstName;
    public String secondaryMiddleName;
    public String secondaryLastName;
    public String secondarySuffix;
    public String primaryNickName;
    public String secondaryNickName;
    public Wrapper(String primaryPrefix, String primaryFirstName, String primaryMiddleName,
                   String primaryLastName, String primarySuffix, String primaryNickName, String secondaryPrefix, String secondaryFirstName,
                   String secondaryMiddleName,String secondaryLastName, String secondarySuffix, String secondaryNickName) {
      this.primaryPrefix = primaryPrefix;
      this.primaryFirstName = primaryFirstName;
      this.primaryMiddleName = primaryMiddleName;
      this.primaryLastName = primaryLastName;
      this.primarySuffix = primarySuffix;
      this.primaryNickName = primaryNickName;
      this.secondaryPrefix = secondaryPrefix;
      this.secondaryFirstName = secondaryFirstName;
      this.secondaryMiddleName = secondaryMiddleName;
      this.secondaryLastName = secondaryLastName;
      this.secondarySuffix = secondarySuffix;
      this.secondaryNickName = secondaryNickName;
    }
  }
  
  
  private static String createName(String param1, String param2, String param3, String param4, String param5){
    String FullName='';
    if(param1 != null && param1 !=''){
      FullName+=param1+' ';
    }
    if(param2 != null && param2 !=''){
      FullName+=param2+' ';
    }
    if(param3 != null && param3 !=''){
      FullName+=param3+' ';
    }
    if(param4 != null && param4 !=''){
      FullName+=param4+' ';
    }
    if(param5 != null && param5 !=''){
      FullName+=param5+' ';
    }
    FullName = FullName.subString(0,FullName.Length());
    FullName = FullName.removeEnd(' ');
    return FullName;
  }
  
}