public class Innova_Utility {

    public static final String SERVICE_URL = '/services/data/v56.0/query?q=';
    public static final String COMPOSITE_SERVICE_URL = '/services/data/v56.0/composite/tree/';
    public static final String TOOLING_SERVICE_URL = '/services/data/v56.0/tooling/query/?q=';
    public static final String COMPOSITE_SERVICE_SOBJECT_URL = '/services/data/v56.0/composite/sobjects';
    public static final String GET_SOBJECTS = 'SELECT+Id,Label,MasterLabel,PluralLabel,DeveloperName,QualifiedApiName,KeyPrefix,NamespacePrefix+FROM+EntityDefinition+Order+by+QualifiedApiName';
    public static final String ERROR_MESSAGE_ONE = 'Enpoint is not available, Please check the endpoint.';
    public static final String ERROR_MESSAGE_TWO = '';

    public static final String CREATION_MODE_FAST = 'Fast Record Creation';
    public static final String CREATION_MODE_MULTIPLE = 'Multiple Record Creation (CSV)';
    public static final String CREATION_MODE_SEQUENTIAL = 'Sequential Record Creation';
    public static final String CREATION_MODE_SINGLE = 'Single Record Creation';

    public class Innova_Response{
        @AuraEnabled public String message{get;set;}
        @AuraEnabled public String data{get;set;}
        @AuraEnabled public Boolean isSuccess{get;set;}
        
        public Innova_Response(){}

        public Innova_Response(Boolean isSuccess, String message,String data){
            this.isSuccess = isSuccess;
            this.message = message;
            this.data = data;
        }
    }
    
    public with sharing class InputActivityWrapper{
        @AuraEnabled         public Integer totalRecordsCount {get;set;}
        @AuraEnabled         public Integer successrRecordsCount{get;set;}
        @AuraEnabled         public Integer errorRecordsCount{get;set;}
        @AuraEnabled         public String modeOfCreation{get;set;} // {'Fast Record Creation', 'Multiple Record Creation (CSV)', 'Sequential Record Creation', 'Single Record Creation'}
        @AuraEnabled         public String requestedBy{get;set;}
        @AuraEnabled         public string objName{get;set;}
        @AuraEnabled         public string actvityId{get;set;}
        @AuraEnabled         public String successRecID{get;set;}
        @AuraEnabled         public List<string> insertedRecIds{get;set;}
        @AuraEnabled         public String errorMessage{get;set;}
        @AuraEnabled         public List<String> resultList{get;set;}
    }
    
    public with sharing class SaveResultWrapper{
        public string objName;
        public string recUserId;
        public Integer count;
        public string str; // for single record creation in toolingAPIHelper class
        public string result; // {'success', 'error'}
        public string successRecId;
        public string errorMessage;
        public List<string> insertedRecIds;
    }
    public static String convertListToString(List<String> lInsertedRecords){
        String strInsertedIds = '';
        if(lInsertedRecords != null){
            for(String str : lInsertedRecords){
                strInsertedIds = str+','+strInsertedIds;
            }
        }     
        return strInsertedIds;
    }
    public static InputActivityWrapper insertInnovaActivities(InputActivityWrapper wrapper){
        List<Innova_Activity__c> innovaActivityList = new List<Innova_Activity__c>();
        Database.SaveResult[] srList;
         system.debug('insertInnovaActivities wrapper = '+wrapper);
            Innova_Activity__c innovaActivity = new Innova_Activity__c();
            innovaActivity.Total_records_count__c   = wrapper.totalRecordsCount;
            innovaActivity.Success_records_count__c = wrapper.successrRecordsCount;
            innovaActivity.Error_records_count__c   = wrapper.errorRecordsCount;
            innovaActivity.Inserted_Record_Ids__c = convertListToString(wrapper.insertedRecIds);
            if(wrapper.modeOfCreation!= null){
                if((wrapper.modeOfCreation).contains('Fast')){
                    innovaActivity.Mode_of_Creation__c = CREATION_MODE_FAST;
                } else if((wrapper.modeOfCreation).contains('Related') || (wrapper.modeOfCreation).contains('Sequential')){
                    innovaActivity.Mode_of_Creation__c = CREATION_MODE_SEQUENTIAL;
                } else if((wrapper.modeOfCreation).contains('Single')){
                    innovaActivity.Mode_of_Creation__c = CREATION_MODE_SINGLE;
                } else if((wrapper.modeOfCreation).contains('Multiple')){
                    innovaActivity.Mode_of_Creation__c = CREATION_MODE_MULTIPLE;
                }
            }
            //else
            //innovaActivity.Mode_of_Creation__c = 'null';
            innovaActivity.Requested_By__c          = wrapper.requestedBy;
            innovaActivity.Object__c                = wrapper.objName;
            //revainnovaActivity.Inserted_Record_Ids__c += wrapper.insertedRecIds;
            innovaActivityList.add(innovaActivity);
         try{
            if(innovaActivityList != null && innovaActivityList.size() > 0){
                system.debug('insertInnovaActivities innovaActivityList = '+innovaActivityList);
                srList = Database.insert(innovaActivityList, false);
                
                List<Id> sInsertedIds = new List<Id>();
                for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug('Successfully inserted activities. ID: ' + sr.getId());
                    sInsertedIds.add(sr.getId());
                    wrapper.actvityId = sr.getId();
                } else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Fields that affected this error: ' + err.getFields());
                        wrapper.actvityId = 'error!';
                    }
                }
             }
             return wrapper;
         }
        return null;
        }catch(Exception e){
            system.debug('innovaActivityList insert failed!'+e);
            return null;
         }
    }
    public static Database.SaveResult[] finalInsertDML(String sObjName, List<sObject> sList, String modeOfCreation, String recUserId){
        Innova_Utility.InputActivityWrapper iaw = new Innova_Utility.InputActivityWrapper();
        Innova_Utility.InputActivityWrapper iawInserted = new Innova_Utility.InputActivityWrapper();
        String insertedRecId;
        List<Id> sInsertedIds = new List<Id>();
        List<String> errorList = new List<String>();
        Integer countSuccess = 0;
        Database.SaveResult[] srList;
        try{
            // inserting dynamic sList(fieldname,fielvalue)
            srList = Database.insert(sList, true);
        }
       catch (DMLException e){
           
            //Added check for FIELD_CUSTOM_VALIDATION_EXCEPTION to return user friendly error.
           String errorMsg = e.getMessage();
           if(errorMsg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
           errorMsg = errorMsg.substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', ': ');
           }
           //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,errorMsg));
        }
        return srList;
        //COMMENTING SO THAT DMLS AND ACTIVITY RECORDS ARE NOT COUPLED FOR SEQ. INSERTION
        /*for (Database.SaveResult sr : srList) {
               if (sr.isSuccess()) {
                   System.debug('Successfully inserted. ID: ' + sr.getId());
                   sInsertedIds.add(sr.getId());
                   countSuccess++;
                   if(recUserId != null){
                    sObject temp1 = Schema.getGlobalDescribe().get(sObjName).newSObject();
                    temp1.id = sr.getId();
                    temp1.put('ownerId',recUserId);
                    Database.update(temp1, false);
                 }
                 insertedRecId = sr.getId();
                   }
                else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Fields that affected this error: ' + err.getFields());
                        errorList.add(err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
       } // end for loop SaveResult
        
       System.debug('insertedRecId ' + insertedRecId);
       iaw.totalRecordsCount = srList.size();
       iaw.successrRecordsCount = sInsertedIds.size();
       iaw.errorRecordsCount = srList.size() - sInsertedIds.size();
       iaw.modeOfCreation = modeOfCreation;
       iaw.requestedBy = UserInfo.getuserId();
       iaw.objName = iaw.objName== null? sobjname : iaw.objName + ', '+sobjname;
       system.debug('entering insertInnovaActivities activity method');
       iawInserted = Innova_Utility.insertInnovaActivities(iaw);
       
       if(iawInserted != null ){
           iawInserted.successRecID = insertedRecId;
       system.debug('iawInserted - '+iawInserted);
       }
       String returnWrapper = JSON.serialize(iawInserted);
       system.debug('-- final return wrapper = '+returnWrapper);
       return returnWrapper;*/
    }   
    
}