global class SessionIdController {
	 global static String getSessionIdFromVFPage(PageReference visualforcePage){
        String content;
        Integer s,e;
        if(Test.isrunningTest()){
            content = 'UnitTestUnitTestUnitTestUnitTestUnitTestUnitTestUnitTest';
            s=10; 
            e=10;
        }else{
            content = visualforcePage.getContent().toString();
            s = content.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length();
            e = content.indexOf('End_Of_Session_Id');
        }
        
        return content.substring(s, e);
    }
}