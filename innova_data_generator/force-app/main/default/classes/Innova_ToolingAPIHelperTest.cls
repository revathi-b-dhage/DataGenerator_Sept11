@IsTest
public class Innova_ToolingAPIHelperTest {
    @IsTest
    static void queryValidationRuleTest(){
        User contextuser = [SELECT Id from User where Profile.Name = 'System Administrator' and isActive = True LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new Innova_DataGeneratorMockCallout());
        Test.startTest();
        System.runAs(contextuser){
            //public static List<innova_processedDataForValidationRule> queryValidationRule(String sObjectName){
            List<innova_processedDataForValidationRule> returnValue = Innova_ToolingAPIHelper.queryValidationRule('Account');
        }
        Test.stopTest();  
    }
    @IsTest
    static void insertRecTest(){
        //public static Innova_Utility.InputActivityWrapper insertRec(String objName, Integer recCount, String str, String modeOfCreation,String recUserId){
        User contextuser = [SELECT Id from User where Profile.Name = 'System Administrator' and isActive = True LIMIT 1];
        String objName = 'Innova_Activity__c';
        Integer recCount = 1;
        String str = '[{"Field":"success_records_count__c","Value":"3"}]';
        String modeOfCreation = 'Single Record Creation';
        String recUserId = UserInfo.getuserId();
        Test.startTest();
        System.runAs(contextuser){
            Innova_Utility.InputActivityWrapper  returnWrapper = Innova_ToolingAPIHelper.insertRec(objName, recCount, str, modeOfCreation,recUserId);
        }
        Test.stopTest();
        
    }
    
    @istest
    static void TestMakeCallout(){
        String httpMethod ='GET';
        String sEndpoint ='http://testcallout.com';
        String reqBody = '{Name: Data Gen}';
        test.setMock(HttpCalloutMock.class, new Innova_DataGeneratorMockCallout());
        test.startTest();
        Innova_Utility.Innova_Response resp = Innova_ToolingAPIHelper.makeCallout(httpMethod,sEndpoint,reqBody);
        test.stopTest();
    }
    
    @istest
    static void TestfinalInsertDML(){
        String   sObjName = 'Contact';
        List<sObject> sList = new  List<sObject>();
        Contact cObj = new Contact();
        cObj.LastName='Test lastname wEa';
        sList.add(cObj);
        // = (Contact:{Name=Test lastname wEa, Id=0035g00000pWYnxAAG}, Contact:{Name=Test lastname Ej5, Id=0035g00000pWYnyAAG}) ; 
        String modeOfCreation = 'Single';
        String recUserId = '0058hkjhk78888det';
        test.startTest();
        String resStr= Innova_ToolingAPIHelper.finalInsertDML(sObjName,sList,modeOfCreation,recUserId);
        test.stopTest();
        
    }
    
    @istest
    static void testqueryValidationRules(){
        test.setMock(HttpCalloutMock.class, new Innova_DataGeneratorMockCallout());
        
        test.startTest();
        Innova_ToolingAPIHelper.queryValidationRules('Account');
        test.stopTest();
    }
    @istest
    static void getSessionIdFromVFPageTest(){
        test.setMock(HttpCalloutMock.class, new Innova_DataGeneratorMockCallout());
        PageReference pageRef = Page.SessionIdVf;
        // SessionIdVf
        test.startTest();
        SessionIdController.getSessionIdFromVFPage(pageRef);
        test.stopTest();
    }
    @istest
    static void generateRandomStringsTest(){
        test.startTest();
        List<string> lStr = Innova_ToolingAPIHelper.generateRandomStrings(1,'Name','Innova_Activity__c');
        system.debug('lstr ='+lstr);
        //public static List<String> generateRandomStrings(Integer count, String sName, String objName){
        //public static String generateRandomString(Integer len) {
        string str = Innova_ToolingAPIHelper.generateRandomString(2);
        system.debug('str = '+str);
        Integer num = Innova_ToolingAPIHelper.generateRandomNumber();
        system.debug(num);
        //public static Integer generateRandomNumber() {
        test.stopTest();
    }
}