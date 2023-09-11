/*
@description       : Salesforce Test class to cover the 3 modes of data creation (Fast, CSV, Sequential)
@author            : Revathi Dhage, Prabhakar Singh
@last modified on  : 05-22-2023
@last modified by  : Revathi Dhage
Modifications Log 
Ver   Date         Author         Modification
1.0   05-22-2023   Revathi Dhage   Initial Version
*/
@IsTest
public class Innova_DataGeneratorClsTest {
    
    @IsTest static void fastcreationtestMethod(){
    String INPUTWRAPPER_FAST = '{"objName":"Innova_Activity__c","count":"3","modeOfCreation":"Fast"}';
    String INPUTWRAPPER_Logger_FAST = '{"objName":"Innova_Logger__c","count":"3","modeOfCreation":"Fast"}';
     // System Admin as Context User
     User contextuser = [SELECT Id from User where Profile.Name = 'System Administrator' and isActive = True LIMIT 1];

    Test.startTest();
    System.runAs(contextuser){
       
        //Fast Creation Data
        Innova_Utility.InputActivityWrapper returnWrapper_Fast =  Innova_DataGeneratorCls.wrapfastCreateRecordsUser(INPUTWRAPPER_FAST) ;
        //Assert.isNotNull(returnWrapper_Fast.actvityId);
    }
    Test.stopTest();
    }

    @IsTest static void csvCreationTestMethod(){
        User usr = new User(lastname = 'lname', firstname = 'test', email='test@emailT.com', username='test@emailT.dev');
        //insert usr;
        // System Admin as Context User
        User contextuser = [SELECT Id from User where Profile.Name = 'System Administrator' and isActive = True LIMIT 1];
    
        //Create Document
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Test Document';
            cv.PathOnClient = 'TestDocument.csv';
              cv.VersionData = Blob.valueOf('Name,Error_records_count__c,Inserted_Record_Ids__c,Mode_of_Creation__c,Object__c,Success_records_count__c,Total_records_count__c\r\nest IA record,1,3,Fast Record Creation,Innova_Activity__c,2,3');
            cv.IsMajorVersion = true;
            Insert cv;
    		system.debug(cv);
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            system.debug(documents);
            //create ContentDocumentLink record 
            ContentDocumentLink cdl = New ContentDocumentLink();
            cdl.LinkedEntityId = Userinfo.getUserId();//usr.Id;
            cdl.ContentDocumentId = documents[0].Id;
            cdl.shareType = 'I';
            //insert cdl;
            system.debug(cdl);
         
        Test.startTest();
        System.runAs(contextuser){
           
            //Fast Creation Data
            //List<String> returnWrapper_List =  
                Innova_DataGeneratorCls.loadCSVData( documents[0].Id, 'Innova_Activity__c', null) ;
            //system.debug('returnWrapper_List = '+returnWrapper_List);
            //Assert.isNotNull(returnWrapper_List);
            }
        Test.stopTest();
        
    }    

    @IsTest static void getAllFieldsTest(){
    // System Admin as Context User
    User contextuser = [SELECT Id from User where Profile.Name = 'System Administrator' and isActive = True LIMIT 1]; 
    Test.startTest();
    System.runAs(contextuser){
       
        //Fast Creation Data
        Map<String,List<Innova_DataGeneratorCls.customValueWrapper>> returnWrapper =  Innova_DataGeneratorCls.getAllFields(  'Innova_Activity__c') ;
        Assert.isNotNull(returnWrapper);
        }
    Test.stopTest() ;
    }
    @IsTest static void checkAccessForObjectTest(){
        // System Admin as Context User
        User contextuser = [SELECT Id from User where Profile.Name = 'System Administrator' and isActive = True LIMIT 1]; 
        Test.startTest();
        System.runAs(contextuser){
           
            //Fast Creation Data
            Boolean returnWrapper =  Innova_DataGeneratorCls.checkAccessForObject( 'Innova_Activity__c') ;
            Assert.isNotNull(returnWrapper);
            }
        Test.stopTest() ;
        }

        @IsTest static void fastCreateRecordsUserTest(){
            User contextuser = [SELECT Id from User where Profile.Name = 'System Administrator' and isActive = True LIMIT 1];
            //public static List<String> fastCreateRecordsUser(String sObjName, Integer count, String modeOfCreation, String recUserId ){
            String sObjName = 'Innova_Activity__c';
            Integer count = 3;
            String modeOfCreation = 'Fast Record Creation';
            String recuserid = contextuser.Id;
            Test.startTest();
            System.runAs(contextuser){
               
                //Fast Creation Data
                List<String> returnWrapperFast =  Innova_DataGeneratorCls.fastCreateRecordsUser(sObjName, count, modeOfCreation,recUserId ) ;
                Assert.isNotNull(returnWrapperFast);
            }
            Test.stopTest();
        }
        @IsTest static void generateRandomStringsTest(){
            User contextuser = [SELECT Id from User where Profile.Name = 'System Administrator' and isActive = True LIMIT 1];
            //public static List<String> generateRandomStrings(Integer count, String sName, String objName){
            String sObjName = 'Innova_Activity__c';
            Integer count = 1;
            String modeOfCreation = 'Fast Record Creation';
            String recuserid = contextuser.Id;
            Test.startTest();
            System.runAs(contextuser){
               
                //Fast Creation Data
                List<String> returnWrapperFast =  Innova_DataGeneratorCls.generateRandomStrings(count, modeOfCreation,sObjName ) ;
                Assert.isNotNull(returnWrapperFast);
            }
            Test.stopTest();
        }
        @IsTest static void generateRandomStringTest(){
            User contextuser = [SELECT Id from User where Profile.Name = 'System Administrator' and isActive = True LIMIT 1];
            //public static List<String> generateRandomStrings(Integer count, String sName, String objName){
            String sObjName = 'Innova_Activity__c';
            Integer count = 3;
            String modeOfCreation = 'Fast Record Creation';
            String recuserid = contextuser.Id;
            Test.startTest();
            System.runAs(contextuser){
               
                //Fast Creation Data
                String returnWrapperFast =  Innova_DataGeneratorCls.generateRandomString(count) ;
                Assert.isNotNull(returnWrapperFast);
            }
            Test.stopTest();
        }

        @IsTest static void generateRandomNumberTest(){
            User contextuser = [SELECT Id from User where Profile.Name = 'System Administrator' and isActive = True LIMIT 1];
            //public static List<String> generateRandomStrings(Integer count, String sName, String objName){
            String sObjName = 'Innova_Activity__c';
            Integer count = 3;
            String modeOfCreation = 'Fast Record Creation';
            String recuserid = contextuser.Id;
            Test.startTest();
            System.runAs(contextuser){
               
                //Fast Creation Data
                Integer returnWrapperFast =  Innova_DataGeneratorCls.generateRandomNumber() ;
                Assert.isNotNull(returnWrapperFast);
            }
            Test.stopTest();
        }

        @IsTest static void viewCreatedRecords(){
            Innova_Activity__c iaRecord = new Innova_Activity__c(name = 'TestInnova1', Error_records_count__c=1, Inserted_Record_Ids__c = '5', Mode_of_Creation__c = 'Fast Record Creation', Object__c = 'Innova_Activity__c', Success_records_count__c = 4, Total_records_count__c = 5);
            insert iaRecord;
            User contextuser = [SELECT Id from User where Profile.Name = 'System Administrator' and isActive = True LIMIT 1];
            
            List<Innova_Activity__c> innovaActivityList = new List<Innova_Activity__c>{
                 // new Innova_Activity__c(name = 'TestInnova1', Error_records_count__c=1, Inserted_Record_Ids__c = iaRecord.Id, Mode_of_Creation__c = 'Fast Record Creation', Object__c = 'Innova_Activity__c', Success_records_count__c = 4, Total_records_count__c = 5),
                // new Innova_Activity__c(name = 'TestInnova2', Error_records_count__c=1, Inserted_Record_Ids__c = iaRecord.Id, Mode_of_Creation__c = 'Fast Record Creation', Object__c = 'Innova_Activity__c', Success_records_count__c = 4, Total_records_count__c = 5),
                // new Innova_Activity__c(name = 'TestInnova3', Error_records_count__c=1, Inserted_Record_Ids__c = iaRecord.Id, Mode_of_Creation__c = 'Fast Record Creation', Object__c = 'Innova_Activity__c', Success_records_count__c = 4, Total_records_count__c = 5),
                new Innova_Activity__c(name = 'TestInnova4', Error_records_count__c=1, Inserted_Record_Ids__c = iaRecord.Id, Mode_of_Creation__c = 'Fast Record Creation', Object__c = 'Innova_Activity__c', Success_records_count__c = 4, Total_records_count__c = 5)
            };
            insert innovaActivityList;
            //public static List<String> generateRandomStrings(Integer count, String sName, String objName){
                //public static List<SObject> viewActivityRecord(String activityRecId){
            String sObjName = 'Innova_Activity__c';
            Integer count = 3;
            String modeOfCreation = 'Fast Record Creation';
            String recuserid = contextuser.Id;
            Test.startTest();
            System.runAs(contextuser){
               
                //Fast Creation Data
                List<sObject> returnWrapperFast =  Innova_DataGeneratorCls.viewActivityRecord(innovaActivityList[0].Id) ;
                List<sObject> returnWrapperFast2 =  Innova_DataGeneratorCls.viewCreatedRecords('Innova_Activity__c', innovaActivityList[0].Id) ;
                Assert.isNotNull(returnWrapperFast);
            }
            Test.stopTest();
        }

        @IsTest static void SequentialDataCreationTest(){
            User contextuser = [SELECT Id from User where Profile.Name = 'System Administrator' and isActive = True LIMIT 1];
            // public static String SequentialDataCreation(Integer count, String Parent, String child, Boolean isMultiple, String modeOfCreation, String recUserId){
   
            String sObjName = 'Innova_Activity__c';
            Integer count = 3;
            String modeOfCreation = 'Fast Record Creation';
            String recuserid = contextuser.Id;
            Test.startTest();
            System.runAs(contextuser){
               
                //Fast Creation Data
                String returnWrapperFast =  Innova_DataGeneratorCls.SequentialDataCreation(count, 'User', sobjname, false, modeOfCreation, null ) ;
                system.debug('setqq returnWrapperFast = '+returnWrapperFast);
                //Assert.isNotNull(returnWrapperFast);
                String returnWrapperFast2 =  Innova_DataGeneratorCls.SequentialDataCreation(count, 'Innova_Activity__c', sobjname, false, modeOfCreation, null ) ;
                system.debug('setqq returnWrapperFast2 = '+returnWrapperFast2);
            }
            Test.stopTest();
        }
        @IsTest static void getAllObjectTest(){
            User contextuser = [SELECT Id from User where Profile.Name = 'System Administrator' and isActive = True LIMIT 1];
            //public static List<String> generateRandomStrings(Integer count, String sName, String objName){
            String sObjName = 'Innova_Activity__c';
            Integer count = 3;
            String modeOfCreation = 'Fast Record Creation';
            String recuserid = contextuser.Id;
            Test.startTest();
            System.runAs(contextuser){
               Assert.isNotNull( Innova_DataGeneratorCls.getAllObject());
               Assert.isNotNull( Innova_DataGeneratorCls.fetchRelatedSObjects('Innova_Activity__c'));
               Assert.isNotNull( Innova_DataGeneratorCls.isValidObjectName('Innova_Activity__c'));
               //public static String getAllUsers(String objName){
               Assert.isNotNull( Innova_DataGeneratorCls.getAllUsers('Innova_Activity__c'));
            //  public static String deactivateValidationRulesForSobject(String objectName){
               //system.debug( Innova_DataGeneratorCls.deactivateValidationRulesForSobject('Account'));
               //Assert.isNotNull
            }
            Test.stopTest();
        }
        @isTest 
            static void testPostCallout() {
            Test.setMock(HttpCalloutMock.class, new Innova_DataGeneratorMockCallout()); 
            //String response = Innova_DataGeneratorCls.deactivateValidationRulesForSobject('Innova_Activity__c');
            //system.debug('response -> '+response);
            
        }
    	@isTest 
            static void handleReferenceFieldsTest() {
		//(String sObjName, String sFieldName){(String sObjName, String sFieldName){            
            system.debug(Innova_DataGeneratorCls.handleReferenceFields('Innova_Logger__c', 'Related_Innova_Activity__c')) ;
            //system.debug('response -> '+response);
            
        }
}