/**
* This class contains unit tests for validating the behavior of Apex classes
* and triggers.
*
* Unit tests are class methods that verify whether a particular piece
* of code is working properly. Unit test methods take no arguments,
* commit no data to the database, and are flagged with the testMethod
* keyword in the method definition.
*
* All test methods in an organization are executed whenever Apex code is deployed
* to a production organization to confirm correctness, ensure code
* coverage, and prevent regressions. All Apex classes are
* required to have at least 75% code coverage in order to be deployed
* to a production organization. In addition, all triggers must have some code coverage.
* 
* The @isTest class annotation indicates this class only contains test
* methods. Classes defined with the @isTest annotation do not count against
* the organization size limit for all Apex scripts.
*
* See the Apex Language Reference for more information about Testing and Code Coverage.
* Test class for GLGivingHelper
*/
@isTest
private class GLGivingHelperTest {
    
    /*
Method validateGlFieldsForBequest
@description : Test the GL fields 
*/
    static testMethod void validateGlFieldsForBequest() {
        //Sharing code = 'Q001'
        List<Opportunity> opps = GLGivingHelper.nationalGLCodeAssigner(new Opportunity(Sharing_Code__c = 'Q001', amount = 100, Program_Type__c = '1', Restriction__c = Label.Undefined_UNDEFINED));
        List<Opportunity> opps1 = GLGivingHelper.nationalGLCodeAssigner(new Opportunity(Sharing_Code__c = 'Q001', amount = 100, Program_Type__c = '4', Restriction__c = Label.Church_State_Work_c3_160_or_c4_303_CHST));
        system.assertEquals(80.00,opps[0].amount);
        system.assertEquals(20.00,opps[1].amount);
        for(opportunity opp: opps){
            system.assertEquals('40300',opp.GL_Code_National__c);
        }
        // Restriction equal to Undefined
        //80% gift
        system.assertEquals('1000',opps[0].Fund_Code_National__c); 
        system.assertEquals('599',opps[0].Focus_Area_Code_National__c);
        system.assertEquals('13000',opps[0].Responsibility_Center_Code_National__c ); 
        // 20% gift
        system.assertEquals('1025',opps[1].Fund_Code_National__c); 
        system.assertEquals('999',opps[1].Focus_Area_Code_National__c);
        system.assertEquals('ZZZZZ',opps[1].Responsibility_Center_Code_National__c ); 
        
        // Restriction not equal to Undefined
        //80% gift
        system.assertEquals('1001',opps1[0].Fund_Code_National__c); 
        system.assertEquals('160',opps1[0].Focus_Area_Code_National__c);
        system.assertEquals('ZZZZZ',opps1[0].Responsibility_Center_Code_National__c ); 
        // 20% gift
        system.assertEquals('1025',opps1[1].Fund_Code_National__c); 
        system.assertEquals('999',opps1[1].Focus_Area_Code_National__c);
        system.assertEquals('ZZZZZ',opps1[1].Responsibility_Center_Code_National__c ); 
        
        //Sharing code = 'Q002'
        opps = GLGivingHelper.nationalGLCodeAssigner(new Opportunity(Sharing_Code__c = 'Q002', amount = 100, Program_Type__c = '1', Restriction__c = Label.Undefined_UNDEFINED));
        opps1 = GLGivingHelper.nationalGLCodeAssigner(new Opportunity(Sharing_Code__c = 'Q002', amount = 100, Program_Type__c = '4', Restriction__c = Label.Church_State_Work_c3_160_or_c4_303_CHST));
        system.assertEquals(87.50,opps[0].amount);
        system.assertEquals(12.50,opps[1].amount);
        for(opportunity opp: opps){
            system.assertEquals('40300',opp.GL_Code_National__c);
        }
        // Restriction equal to Undefined
        //87.5% gift
        system.assertEquals('1000',opps[0].Fund_Code_National__c); 
        system.assertEquals('599',opps[0].Focus_Area_Code_National__c);
        system.assertEquals('13000',opps[0].Responsibility_Center_Code_National__c ); 
        //12.5% gift
        system.assertEquals('1025',opps[1].Fund_Code_National__c); 
        system.assertEquals('999',opps[1].Focus_Area_Code_National__c);
        system.assertEquals('ZZZZZ',opps[1].Responsibility_Center_Code_National__c ); 
        
        // Restriction not equal to Undefined
        //87.5% gift
        system.assertEquals('1001',opps1[0].Fund_Code_National__c); 
        system.assertEquals('160',opps1[0].Focus_Area_Code_National__c);
        system.assertEquals('ZZZZZ',opps1[0].Responsibility_Center_Code_National__c ); 
        //12.5%  gift
        system.assertEquals('1025',opps1[1].Fund_Code_National__c); 
        system.assertEquals('999',opps1[1].Focus_Area_Code_National__c);
        system.assertEquals('ZZZZZ',opps1[1].Responsibility_Center_Code_National__c ); 
        
        
        //Sharing code = 'Q005'
        opps = GLGivingHelper.nationalGLCodeAssigner(new Opportunity(Sharing_Code__c = 'Q005', Program_Type__c = '1', Restriction__c = Label.Undefined_UNDEFINED));
        opps1 = GLGivingHelper.nationalGLCodeAssigner(new Opportunity(Sharing_Code__c = 'Q005', Program_Type__c = '4', Restriction__c = Label.Church_State_Work_c3_160_or_c4_303_CHST));
        
        //Restriction UNDEFINED
        for(Opportunity opp: opps){
            system.assertEquals('40300',opp.GL_Code_National__c);
            system.assertEquals('1000',opp.Fund_Code_National__c);
            system.assertEquals('599',opp.Focus_Area_Code_National__c );
            system.assertEquals('13000',opp.Responsibility_Center_Code_National__c);
        }
        // (CHST)
        for(Opportunity opp: opps1){
            system.assertEquals('40300',opp.GL_Code_National__c);
            system.assertEquals('1001',opp.Fund_Code_National__c);
            system.assertEquals('160',opp.Focus_Area_Code_National__c );
            system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        }   
        //Sharing code = 'Q004'
        opps = GLGivingHelper.nationalGLCodeAssigner(new Opportunity(Sharing_Code__c = 'Q004', Program_Type__c = '1', Restriction__c = Label.Undefined_UNDEFINED));
        opps1 = GLGivingHelper.nationalGLCodeAssigner(new Opportunity(Sharing_Code__c = 'Q004', Program_Type__c = '4', Restriction__c = Label.Church_State_Work_c3_160_or_c4_303_CHST));
        
        
        //Restriction UNDEFINED
        for(Opportunity opp: opps){
            system.assertEquals('40300',opp.GL_Code_National__c);
            system.assertEquals('1000',opp.Fund_Code_National__c);
            system.assertEquals('599',opp.Focus_Area_Code_National__c );
            system.assertEquals('13000',opp.Responsibility_Center_Code_National__c);
        }
        // (CHST)
        for(Opportunity opp: opps1){
            system.assertEquals('40300',opp.GL_Code_National__c);
            system.assertEquals('1001',opp.Fund_Code_National__c);
            system.assertEquals('160',opp.Focus_Area_Code_National__c );
            system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        }       
        
        //Sharing code = 'Q003'
        opps = GLGivingHelper.nationalGLCodeAssigner(new Opportunity(Sharing_Code__c = 'Q003', Program_Type__c = '1', Restriction__c = Label.Undefined_UNDEFINED));
        opps1 = GLGivingHelper.nationalGLCodeAssigner(new Opportunity(Sharing_Code__c = 'Q003', Program_Type__c = '4', Restriction__c = Label.Church_State_Work_c3_160_or_c4_303_CHST));
        
        
        //Restriction UNDEFINED
        for(Opportunity opp: opps){
            system.assertEquals('40300',opp.GL_Code_National__c);
            system.assertEquals('1000',opp.Fund_Code_National__c);
            system.assertEquals('599',opp.Focus_Area_Code_National__c );
            system.assertEquals('13000',opp.Responsibility_Center_Code_National__c);
        }
        // (CHST)
        for(Opportunity opp: opps1){
            system.assertEquals('40300',opp.GL_Code_National__c);
            system.assertEquals('1001',opp.Fund_Code_National__c);
            system.assertEquals('160',opp.Focus_Area_Code_National__c );
            system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        }
        
        //Sharing code = 'U001'
        opps = GLGivingHelper.nationalGLCodeAssigner(new Opportunity(Sharing_Code__c = 'U001', amount = 100, Program_Type__c = '1', Restriction__c = Label.Undefined_UNDEFINED));
        opps1 = GLGivingHelper.nationalGLCodeAssigner(new Opportunity(Sharing_Code__c = 'U001', amount = 100, Program_Type__c = '4', Restriction__c = Label.Church_State_Work_c3_160_or_c4_303_CHST));
        system.assertEquals(80.00,opps[0].amount);
        system.assertEquals(20.00,opps[1].amount);
        for(opportunity opp: opps){
            system.assertEquals('40300',opp.GL_Code_National__c);
        }
        //80% gift
        system.assertEquals('3000',opps[0].Fund_Code_National__c); 
        system.assertEquals('310',opps[0].Focus_Area_Code_National__c);
        system.assertEquals('13000',opps[0].Responsibility_Center_Code_National__c ); 
        // 20% gift
        system.assertEquals('3025',opps[1].Fund_Code_National__c); 
        system.assertEquals('999',opps[1].Focus_Area_Code_National__c);
        system.assertEquals('ZZZZZ',opps[1].Responsibility_Center_Code_National__c ); 
        
        //Sharing code = 'U002'
        opps = GLGivingHelper.nationalGLCodeAssigner(new Opportunity(Sharing_Code__c = 'U002', amount = 100, Program_Type__c = '1', Restriction__c = Label.Undefined_UNDEFINED));
        opps1 = GLGivingHelper.nationalGLCodeAssigner(new Opportunity(Sharing_Code__c = 'U002', amount = 100, Program_Type__c = '4', Restriction__c = Label.Church_State_Work_c3_160_or_c4_303_CHST));
        system.assertEquals(87.50,opps[0].amount);
        system.assertEquals(12.50,opps[1].amount);
        for(opportunity opp: opps){
            system.assertEquals('40300',opp.GL_Code_National__c);
        }
        //87.5% gift
        system.assertEquals('3000',opps[0].Fund_Code_National__c); 
        system.assertEquals('310',opps[0].Focus_Area_Code_National__c);
        system.assertEquals('13000',opps[0].Responsibility_Center_Code_National__c ); 
        // 12.5% gift
        system.assertEquals('3025',opps[1].Fund_Code_National__c); 
        system.assertEquals('999',opps[1].Focus_Area_Code_National__c);
        system.assertEquals('ZZZZZ',opps[1].Responsibility_Center_Code_National__c ); 
        
        //Sharing code = 'U005'
        opps = GLGivingHelper.nationalGLCodeAssigner(new Opportunity(Sharing_Code__c = 'U005', Program_Type__c = '1', Restriction__c = Label.Undefined_UNDEFINED));
        opps1 = GLGivingHelper.nationalGLCodeAssigner(new Opportunity(Sharing_Code__c = 'U005', Program_Type__c = '4', Restriction__c = Label.Church_State_Work_c3_160_or_c4_303_CHST));
        
        //Restriction UNDEFINED
        for(Opportunity opp: opps){
            system.assertEquals('40300',opp.GL_Code_National__c);
            system.assertEquals('3000',opp.Fund_Code_National__c);
            system.assertEquals('310',opp.Focus_Area_Code_National__c );
            system.assertEquals('13000',opp.Responsibility_Center_Code_National__c);
        }
        // (CHST)
        for(Opportunity opp: opps1){
            system.assertEquals('40300',opp.GL_Code_National__c);
            system.assertEquals('3001',opp.Fund_Code_National__c);
            system.assertEquals('160',opp.Focus_Area_Code_National__c );
            system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        }   
        //Sharing code = 'U004'
        opps = GLGivingHelper.nationalGLCodeAssigner(new Opportunity(Sharing_Code__c = 'U004', Program_Type__c = '1', Restriction__c = Label.Undefined_UNDEFINED));
        opps1 = GLGivingHelper.nationalGLCodeAssigner(new Opportunity(Sharing_Code__c = 'U004', Program_Type__c = '4', Restriction__c = Label.Church_State_Work_c3_160_or_c4_303_CHST));
        
        
        //Restriction UNDEFINED
        for(Opportunity opp: opps){
            system.assertEquals('40300',opp.GL_Code_National__c);
            system.assertEquals('3000',opp.Fund_Code_National__c);
            system.assertEquals('310',opp.Focus_Area_Code_National__c );
            system.assertEquals('13000',opp.Responsibility_Center_Code_National__c);
        }
        // (CHST)
        for(Opportunity opp: opps1){
            system.assertEquals('40300',opp.GL_Code_National__c);
            system.assertEquals('3001',opp.Fund_Code_National__c);
            system.assertEquals('160',opp.Focus_Area_Code_National__c );
            system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        }       
        
        //Sharing code = 'U003'
        opps = GLGivingHelper.nationalGLCodeAssigner(new Opportunity(Sharing_Code__c = 'U003', Program_Type__c = '1', Restriction__c = Label.Undefined_UNDEFINED));
        opps1 = GLGivingHelper.nationalGLCodeAssigner(new Opportunity(Sharing_Code__c = 'U003', Program_Type__c = '4', Restriction__c = Label.Church_State_Work_c3_160_or_c4_303_CHST));
        
        
        //Restriction UNDEFINED
        for(Opportunity opp: opps){
            system.assertEquals('40300',opp.GL_Code_National__c);
            system.assertEquals('3000',opp.Fund_Code_National__c);
            system.assertEquals('310',opp.Focus_Area_Code_National__c );
            system.assertEquals('13000',opp.Responsibility_Center_Code_National__c);
        }
        // (CHST)
        for(Opportunity opp: opps1){
            system.assertEquals('40300',opp.GL_Code_National__c);
            system.assertEquals('3001',opp.Fund_Code_National__c);
            system.assertEquals('160',opp.Focus_Area_Code_National__c );
            system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        }       
        
        
    }
    
    /*
Method validateGlFieldsForNonBequest
@description : Test the GL fields 
*/
    static testMethod void validateGlFieldsForNonBequest() {
        Opportunity opp = GLGivingHelper.nationalGLCodeAssigner(new Opportunity(Sharing_Code__c = 'A001', Program_Type__c = '1', Restriction__c = Label.Undefined_UNDEFINED))[0];
        Opportunity opp1 = GLGivingHelper.nationalGLCodeAssigner(new Opportunity(Sharing_Code__c = 'A001', Program_Type__c = '4', Restriction__c = Label.Undefined_UNDEFINED))[0];
        
        //Shariing code = 'A001'
        system.assertEquals('40000',opp.GL_Code_National__c);
        system.assertEquals('3000',opp.Fund_Code_National__c);
        system.assertEquals('310',opp.Focus_Area_Code_National__c );
        system.assertEquals('13000',opp.Responsibility_Center_Code_National__c);
        
        //Sharing code = 'H100'
        opp.Sharing_Code__c = 'H100';
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        system.assertEquals('40100',opp.GL_Code_National__c);
        
        //Sharing code = 'K171'
        opp.Sharing_Code__c = 'K171';
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        system.assertEquals('40100',opp.GL_Code_National__c);
        system.assertEquals('1000',opp.Fund_Code_National__c);
        system.assertEquals('599',opp.Focus_Area_Code_National__c );
        system.assertEquals('13000',opp.Responsibility_Center_Code_National__c);
        
        //Sharing code = 'N111'
        opp.Sharing_Code__c = 'N111';
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        system.assertEquals('40200',opp.GL_Code_National__c);
        system.assertEquals('1000',opp.Fund_Code_National__c);
        system.assertEquals('599',opp.Focus_Area_Code_National__c );
        system.assertEquals('13000',opp.Responsibility_Center_Code_National__c);
        
        
        
        //Sharing code = 'C161'
        opp.Sharing_Code__c = 'C161';
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1.Sharing_Code__c = 'C161';
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1      
        system.assertEquals('40500',opp.GL_Code_National__c);
        system.assertEquals('310',opp.Focus_Area_Code_National__c);
        system.assertEquals('3000',opp.Fund_Code_National__c);
        system.assertEquals('13000',opp.Responsibility_Center_Code_National__c);
        //Program Type 4
        system.assertEquals('40500',opp1.GL_Code_National__c);
        system.assertEquals('599',opp1.Focus_Area_Code_National__c);
        system.assertEquals('1000',opp1.Fund_Code_National__c);
        system.assertEquals('13000',opp1.Responsibility_Center_Code_National__c);
        
        //Sharing code = 'E121'
        opp.Sharing_Code__c = 'E121';
        opp1.Sharing_Code__c = 'E121';
        opp.Restriction__c = Label.Church_State_Work_c3_160_or_c4_303_CHST;
        opp1.Restriction__c = Label.Church_State_Work_c3_160_or_c4_303_CHST;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('40100',opp.GL_Code_National__c);
        system.assertEquals('303',opp.Focus_Area_Code_National__c);
        system.assertEquals('3001',opp.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        //Program Type 4
        system.assertEquals('40100',opp1.GL_Code_National__c);
        system.assertEquals('160',opp1.Focus_Area_Code_National__c);
        system.assertEquals('1001',opp1.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp1.Responsibility_Center_Code_National__c);
        
        //Sharing code = 'N175'
        opp.Sharing_Code__c = 'N175';
        opp.Restriction__c = Label.Racial_Justice_Project_c4_304_RJP_C4_NATIONAL;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1.Sharing_Code__c = 'N175';
        opp1.Restriction__c = Label.Capital_Punishment_Project_100_CAPPU;
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('41000',opp.GL_Code_National__c);
        system.assertEquals('',opp.Focus_Area_Code_National__c);
        system.assertEquals('3001',opp.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        
        //Program Type 4
        system.assertEquals('41000',opp1.GL_Code_National__c);
        system.assertEquals('100',opp1.Focus_Area_Code_National__c);
        system.assertEquals('1001',opp1.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp1.Responsibility_Center_Code_National__c);
        
        //Restriction is CNTRDEM
        opp1.Restriction__c = Label.Center_for_Democracy_c3_119_CNTRDEM;
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('41000',opp1.GL_Code_National__c);
        system.assertEquals('119',opp1.Focus_Area_Code_National__c);
        system.assertEquals('1001',opp1.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp1.Responsibility_Center_Code_National__c);
        
        //Restriction is DISABLE
        opp1.Restriction__c = Label.Disability_Rights_c3_117_DISABLE;
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('41000',opp1.GL_Code_National__c);
        system.assertEquals('117',opp1.Focus_Area_Code_National__c);
        system.assertEquals('1001',opp1.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp1.Responsibility_Center_Code_National__c);
        
        //Restriction is SB1070
        opp1.Restriction__c = Label.Immigration_SB1070_War_Chest_c3_116_or_c4_316_SB1070;
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('41000',opp1.GL_Code_National__c);
        system.assertEquals('116',opp1.Focus_Area_Code_National__c);
        system.assertEquals('1001',opp1.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp1.Responsibility_Center_Code_National__c);
        
        //Restriction is 'LGBT'
        opp.Restriction__c = Label.Henry_Haley_Trust_LGBT_112_HALEY;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1.Restriction__c = Label.National_Prison_Project_105_PRIS;
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('41000',opp.GL_Code_National__c);
        //system.assertEquals('306',opp.Focus_Area_Code_National__c);
        system.assertEquals('3001',opp.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        //Program Type 4
        system.assertEquals('41000',opp1.GL_Code_National__c);
        system.assertEquals('105',opp1.Focus_Area_Code_National__c);
        system.assertEquals('1001',opp1.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp1.Responsibility_Center_Code_National__c);
        
        
        //Restriction is 'IRP'
        opp.Restriction__c = Label.Immigrants_Rights_Project_c3_115_or_c4_307_IRP;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1.Restriction__c = Label.Immigrants_Rights_Project_c3_115_or_c4_307_IRP;
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('41000',opp.GL_Code_National__c);
        system.assertEquals('307',opp.Focus_Area_Code_National__c);
        system.assertEquals('3001',opp.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        //Program Type 4
        system.assertEquals('41000',opp1.GL_Code_National__c);
        system.assertEquals('115',opp1.Focus_Area_Code_National__c);
        system.assertEquals('1001',opp1.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp1.Responsibility_Center_Code_National__c);
        
        //Restriction is 'SPCHTECH'
        opp.Restriction__c = Label.Speech_Privacy_and_Technology_c3_170_or_c4_308_SPCHTECH;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1.Restriction__c = Label.Speech_Privacy_and_Technology_c3_170_or_c4_308_SPCHTECH;
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        //system.assertEquals('41000',opp.GL_Code_National__c);
        system.assertEquals('308',opp.Focus_Area_Code_National__c);
        system.assertEquals('3001',opp.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        //Program Type 4
        system.assertEquals('41000',opp1.GL_Code_National__c);
        system.assertEquals('170',opp1.Focus_Area_Code_National__c);
        system.assertEquals('1001',opp1.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp1.Responsibility_Center_Code_National__c);
        
        //Restriction is 'KARP'
        opp.Restriction__c = Label.Karpatkin_Fellow_425_KARP;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1.Restriction__c = Label.Karpatkin_Fellow_425_KARP;
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('41000',opp.GL_Code_National__c);
        system.assertEquals('425',opp.Focus_Area_Code_National__c);
        system.assertEquals('3001',opp.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        //Program Type 4
        system.assertEquals('41000',opp1.GL_Code_National__c);
        system.assertEquals('425',opp1.Focus_Area_Code_National__c);
        system.assertEquals('1001',opp1.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp1.Responsibility_Center_Code_National__c);
        
        //Restriction is 'CNTRJUS'
        opp.Restriction__c = Label.Center_for_Justice_c3_139_or_c4_339_CNTRJUS;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1.Restriction__c = Label.Center_for_Justice_c3_139_or_c4_339_CNTRJUS;
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('41000',opp.GL_Code_National__c);
        system.assertEquals('339',opp.Focus_Area_Code_National__c);
        system.assertEquals('3001',opp.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        //Program Type 4
        system.assertEquals('41000',opp1.GL_Code_National__c);
        system.assertEquals('139',opp1.Focus_Area_Code_National__c);
        system.assertEquals('1001',opp1.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp1.Responsibility_Center_Code_National__c);
        
        //Restriction is 'CLRM'
        opp.Restriction__c = Label.Criminal_Law_Reform_Project_c3_135_or_c4_335_CLRM;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1.Restriction__c = Label.Criminal_Law_Reform_Project_c3_135_or_c4_335_CLRM;
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('41000',opp.GL_Code_National__c);
        system.assertEquals('335',opp.Focus_Area_Code_National__c);
        system.assertEquals('3001',opp.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        //Program Type 4
        system.assertEquals('41000',opp1.GL_Code_National__c);
        system.assertEquals('135',opp1.Focus_Area_Code_National__c);
        system.assertEquals('1001',opp1.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp1.Responsibility_Center_Code_National__c);
        
        //Restriction is 'VOTRG', 'VOTRGC4'
        opp.Restriction__c = Label.Voting_Rights_Project_c4_National_312_VOTRGC4;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1.Restriction__c = Label.Voting_Rights_Project_130_VOTRG;
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('41000',opp.GL_Code_National__c);
        system.assertEquals('312',opp.Focus_Area_Code_National__c);
        system.assertEquals('3001',opp.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        //Program Type 4
        system.assertEquals('41000',opp1.GL_Code_National__c);
        system.assertEquals('130',opp1.Focus_Area_Code_National__c);
        system.assertEquals('1001',opp1.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp1.Responsibility_Center_Code_National__c);
        
        //Restriction is 'RFP', 'RFP_ARNOLD'
        opp.Restriction__c = Label.Reproductive_Freedom_ARNOLD_Advocacy_Fund_315_RFP_ARNOLD;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1.Restriction__c = Label.Reproductive_Freedom_Project_120_RFP;
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('41000',opp.GL_Code_National__c);
        system.assertEquals('315',opp.Focus_Area_Code_National__c);
        system.assertEquals('3001',opp.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        //Program Type 4
        system.assertEquals('41000',opp1.GL_Code_National__c);
        system.assertEquals('120',opp1.Focus_Area_Code_National__c);
        system.assertEquals('1001',opp1.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp1.Responsibility_Center_Code_National__c);
        
        //Restriction is 'OFFLGBTC3', 'OFFLGBTC4'
        opp.Restriction__c = Label.Out_For_Freedom_Campaign_c3_LGBT_111_OFFLGBTC3;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1.Restriction__c = Label.Out_For_Freedom_Campaign_c4_LGBT_313_OFFLGBTC4;
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('41000',opp.GL_Code_National__c);
        //system.assertEquals('306',opp.Focus_Area_Code_National__c);
        system.assertEquals('3001',opp.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        //Program Type 4
        system.assertEquals('41000',opp1.GL_Code_National__c);
        //system.assertEquals('110',opp1.Focus_Area_Code_National__c);
        system.assertEquals('1001',opp1.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp1.Responsibility_Center_Code_National__c);
        
        //Restriction is '2NDAMENDC4', '2NDAMENDC3'
        opp.Restriction__c = Label.Second_Amendment_C3_156_2NDAMENDC3;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1.Restriction__c = Label.Second_Amendment_C4_319_2NDAMENDC4;
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('41000',opp.GL_Code_National__c);
        //system.assertEquals('306',opp.Focus_Area_Code_National__c);
        system.assertEquals('3001',opp.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        //Program Type 4
        system.assertEquals('41000',opp1.GL_Code_National__c);
        //system.assertEquals('110',opp1.Focus_Area_Code_National__c);
        system.assertEquals('1001',opp1.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp1.Responsibility_Center_Code_National__c);
        
        
        //Sharing code = 'E121'
        opp.Sharing_Code__c = 'E121';
        opp1.Sharing_Code__c = 'E121';
        opp.Restriction__c = Label.Unshared_No_Restriction_UNSHAREDNORESTRICT;
        opp1.Restriction__c = Label.Unshared_No_Restriction_UNSHAREDNORESTRICT;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('40100',opp.GL_Code_National__c);
        //system.assertEquals('303',opp.Focus_Area_Code_National__c);
        system.assertEquals('3001',opp.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        
        
        //Sharing code = 'E121'
        opp.Sharing_Code__c = 'E121';
        opp1.Sharing_Code__c = 'E121';
        opp.Restriction__c = Label.Second_Amendment_C4_319_2NDAMENDC4;
        opp1.Restriction__c = Label.Second_Amendment_C4_319_2NDAMENDC4;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('40100',opp.GL_Code_National__c);
        //system.assertEquals('319',opp.Focus_Area_Code_National__c);
        system.assertEquals('3001',opp.Fund_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        
        
        
        
        //Sharing code = 'E121'
        opp.Sharing_Code__c = 'E121';
        opp1.Sharing_Code__c = 'E121';
        opp.Restriction__c = Label.Out_For_Freedom_Campaign_c3_LGBT_111_OFFLGBTC3;
        opp1.Restriction__c = Label.Out_For_Freedom_Campaign_c3_LGBT_111_OFFLGBTC3;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('40100',opp.GL_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        
        //Sharing code = 'E121'
        opp.Sharing_Code__c = 'E121';
        opp1.Sharing_Code__c = 'E121';
        opp.Restriction__c = Label.Racial_Justice_Project_140_RJP;
        opp1.Restriction__c = Label.Racial_Justice_Project_140_RJP;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        
        //Program Type 1
        system.assertEquals('40100',opp.GL_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        
        
        
        //Sharing code = 'E121'
        opp.Sharing_Code__c = 'E121';
        opp1.Sharing_Code__c = 'E121';
        opp.Restriction__c = Label.Human_Rights_Project_c4_311_HRP;
        opp1.Restriction__c = Label.Human_Rights_Project_c4_311_HRP;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('40100',opp.GL_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        
        
        
        //Sharing code = 'E121'
        opp.Sharing_Code__c = 'E121';
        opp1.Sharing_Code__c = 'E121';
        opp.Restriction__c = Label.Human_Rights_Project_c4_311_HRP;
        opp1.Restriction__c = Label.Human_Rights_Project_c4_311_HRP;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('40100',opp.GL_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        
        //Sharing code = 'E121'
        opp.Sharing_Code__c = 'E121';
        opp1.Sharing_Code__c = 'E121';
        opp.Restriction__c = Label.Immigrants_Rights_Project_c3_115_or_c4_307_IRP;
        opp1.Restriction__c = Label.Immigrants_Rights_Project_c3_115_or_c4_307_IRP;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('40100',opp.GL_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        
        
        //Sharing code = 'E121'
        opp.Sharing_Code__c = 'E121';
        opp1.Sharing_Code__c = 'E121';
        opp.Restriction__c = Label.Prison_Project_Mass_Incarceration_c4_318_PRISMIC4;
        opp1.Restriction__c = Label.Prison_Project_Mass_Incarceration_c4_318_PRISMIC4;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('40100',opp.GL_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        
        
        //Sharing code = 'E121'
        opp.Sharing_Code__c = 'E121';
        opp1.Sharing_Code__c = 'E121';
        opp.Restriction__c = Label.LGBT_Rights_Project_c3_110_or_c4_306_LGBT;
        opp1.Restriction__c = Label.LGBT_Rights_Project_c3_110_or_c4_306_LGBT;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('40100',opp.GL_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        
        
        //Sharing code = 'E121'
        opp.Sharing_Code__c = 'E121';
        opp1.Sharing_Code__c = 'E121';
        opp.Restriction__c = Label.Henry_Haley_Trust_LGBT_112_HALEY;
        opp1.Restriction__c = Label.Henry_Haley_Trust_LGBT_112_HALEY;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('40100',opp.GL_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        
        
        //Sharing code = 'E121'
        opp.Sharing_Code__c = 'E121';
        opp1.Sharing_Code__c = 'E121';
        opp.Restriction__c = Label.Women_s_Rights_Project_125_WOMR;
        opp1.Restriction__c = Label.Women_s_Rights_Project_125_WOMR;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('40100',opp.GL_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        
        //Sharing code = 'E121'
        opp.Sharing_Code__c = 'E121';
        opp1.Sharing_Code__c = 'E121';
        opp.Restriction__c = Label.Molly_Ivins_Memorial_Fund_Unrestricted_148_IVINS;
        opp1.Restriction__c = Label.Molly_Ivins_Memorial_Fund_Unrestricted_148_IVINS;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('40100',opp.GL_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        
        
        //Sharing code = 'E121'
        opp.Sharing_Code__c = 'E121';
        opp1.Sharing_Code__c = 'E121';
        opp.Restriction__c = Label.Center_for_Liberty_c3_149_CNTRLIB;
        opp1.Restriction__c = Label.Center_for_Liberty_c3_149_CNTRLIB;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('40100',opp.GL_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        
        
        //Sharing code = 'E121'
        opp.Sharing_Code__c = 'E121';
        opp1.Sharing_Code__c = 'E121';
        opp.Restriction__c = Label.Internationl_Human_Rights_150_IHR;
        opp1.Restriction__c = Label.Internationl_Human_Rights_150_IHR;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('40100',opp.GL_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        
        
        //Sharing code = 'E121'
        opp.Sharing_Code__c = 'E121';
        opp1.Sharing_Code__c = 'E121';
        opp.Restriction__c = Label.Strategic_Affiliate_Initiative_500_SAI;
        opp1.Restriction__c = Label.Strategic_Affiliate_Initiative_500_SAI;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('40100',opp.GL_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        
        
        //Sharing code = 'E121'
        opp.Sharing_Code__c = 'E121';
        opp1.Sharing_Code__c = 'E121';
        opp.Restriction__c = Label.Legal_Department_c3_199_LEGAL;
        opp1.Restriction__c = Label.Legal_Department_c3_199_LEGAL;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('40100',opp.GL_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        
        
        //Sharing code = 'E121'
        opp.Sharing_Code__c = 'E121';
        opp1.Sharing_Code__c = 'E121';
        opp.Restriction__c = Label.General_Campaign_Leading_Freedom_Forward_505_GENCLFF;
        opp1.Restriction__c = Label.General_Campaign_Leading_Freedom_Forward_505_GENCLFF;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('40100',opp.GL_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        
        
        //Sharing code = 'E121'
        opp.Sharing_Code__c = 'E121';
        opp1.Sharing_Code__c = 'E121';
        opp.Restriction__c = Label.Second_Amendment_C3_156_2NDAMENDC3;
        opp1.Restriction__c = Label.Second_Amendment_C3_156_2NDAMENDC3;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('40100',opp.GL_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        
        
        
        //Sharing code = 'E121'
        opp.Sharing_Code__c = 'E121';
        opp1.Sharing_Code__c = 'E121';
        opp.Restriction__c = Label.Center_for_Equality_c3_129_CNTREQU;
        opp1.Restriction__c = Label.Center_for_Equality_c3_129_CNTREQU;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('40100',opp.GL_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
        
        
        //Sharing code = 'E121'
        opp.Sharing_Code__c = 'E121';
        opp1.Sharing_Code__c = 'E121';
        opp.Restriction__c = Label.Out_For_Freedom_Campaign_c3_LGBT_111_OFFLGBTC3;
        opp1.Restriction__c = Label.Out_For_Freedom_Campaign_c3_LGBT_111_OFFLGBTC3;
        opp = GLGivingHelper.nationalGLCodeAssigner(opp)[0];
        opp1 = GLGivingHelper.nationalGLCodeAssigner(opp1)[0];
        //Program Type 1
        system.assertEquals('40100',opp.GL_Code_National__c);
        system.assertEquals('ZZZZZ',opp.Responsibility_Center_Code_National__c);
    }
}