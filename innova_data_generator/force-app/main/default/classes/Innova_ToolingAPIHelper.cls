public class Innova_ToolingAPIHelper {

  
   
    public static Innova_Utility.InputActivityWrapper iawrapper;
    @AuraEnabled
    public static List<innova_processedDataForValidationRule> queryValidationRule(String sObjectName){
        system.debug('sObjectName '+sObjectName);
        List<innova_processedDataForValidationRule> processedRuleList = new List<innova_processedDataForValidationRule>();
        String sFields = 'id,ValidationName,createdDate,ErrorDisplayField,ErrorMessage,Description,EntityDefinition.DeveloperName';
        String sWhereClause = 'Where+Active=True+AND+EntityDefinition.DeveloperName=\''+ sObjectName+ '\'';
        String sQuery = 'SELECT+'+ sFields + '+from+ValidationRule+'+ sWhereClause;
        processedRuleList = processData(sQuery);
        system.debug('processedRuleList >> '+processedRuleList);
        return processedRuleList;
    }
    
    @AuraEnabled
    public static List<String> queryValidationRules(String sObjectName){
        system.debug('sObjectName '+sObjectName);
        List<String> processedRuleList = new List<String>();
        String sFields = 'id,ValidationName,createdDate,ErrorDisplayField,ErrorMessage,Description,EntityDefinition.DeveloperName';
        String sWhereClause = 'Where+Active=True+AND+EntityDefinition.DeveloperName=\''+ sObjectName+ '\'';
        String sQuery = 'SELECT+'+ sFields + '+from+ValidationRule+'+ sWhereClause;
        //processedRuleList = processData(sQuery);
        for(innova_processedDataForValidationRule rule : processData(sQuery)){
            processedRuleList.add(rule.validationName);
        }
        system.debug('processedRuleList >> '+processedRuleList);
        return processedRuleList;
    }
    
    public static List<innova_processedDataForValidationRule> queryApexTrigger(String sObjectName){
        system.debug('sObjectName '+sObjectName);
        List<innova_processedDataForValidationRule> processedRuleList = new List<innova_processedDataForValidationRule>();
        String sFields = 'TableEnumOrId,UsageBeforeInsert,UsageAfterInsert,UsageBeforeUpdate,UsageAfterUpdate,UsageBeforeDelete,UsageAfterDelete,UsageAfterUndelete,ApiVersion,Status,LengthWithoutComments,CreatedDate,LastModifiedDate,Body';
        String sWhereClause = 'Where+Status=Active+AND+TableEnumOrId=\''+sObjectName+'\'';
        String sQuery = 'Select'+sFields+'+from+ApexTrigger'+sWhereClause;
        processedRuleList = processData(sQuery);
        system.debug('processedRuleList >> '+processedRuleList);
        
        return processedRuleList;
    }
    public static List<innova_processedDataForValidationRule> processData(String sQuery){
        System.debug('Query->'+sQuery);
        List<String> valList = new List<String>();
        String sPathURL = '/services/data/v38.0/tooling/query?q=';
        //system.debug(system.url.getsalesforcebaseurl());
        //String sBaseURL = String.valueOf(System.url.getsalesforcebaseurl());
        String sBaseURL = 'callout:Innova_ToolingRest';  //Named Credential
        //String sBaseURL = 'https://deloitte-5a2-dev-ed.my.salesforce.com';
        String sEndPoint = sBaseURL +sPathURL + sQuery;

        system.debug('sEndPoint  '+sEndPoint);
        
        
        HTTP newRequest = new HTTP();
        HTTPRequest request = new HTTPRequest(); 
        //request.setHeader('Authorization','Bearer '+UserInfo.getSessionId());
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Accept', 'application/json');
        
        request.setTimeout(60000);
        request.setEndpoint(sEndPoint);
        request.setMethod('GET');
        
        HTTPResponse httpResp = newRequest.send(request);
        String body = httpResp.getBody();
        system.debug('Response status->'+httpResp.getStatusCode()+'---Response body--'+ body);
        system.debug(body);
        
        
        Map<String, Object> resultsMap = (Map<String, Object>)JSON.deserializeUntyped(body);
        List<Object> recList = (List<Object>)resultsMap.get('records');
        Map<String, Object> finalMap = new Map<String, Object>();
        List<innova_processedDataForValidationRule> processDataListToReturn = new List<innova_processedDataForValidationRule>();
        for(Object obj: recList){
            Map<String, Object> toolingAttributes = (Map<String, Object>)obj;
            String validationName ;
            String validationLink ;
            innova_processedDataForValidationRule wrap = new innova_processedDataForValidationRule();
            for (String attributeName : toolingAttributes.keyset()) {
                if(attributeName == 'ValidationName'){           
                    System.debug('========> ' + attributeName + ' = ' + toolingAttributes.get(attributeName));
                    validationName = (String)toolingAttributes.get(attributeName);
                }
                if(attributeName == 'Id'){
                    String baseUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
                    String finalUrl = baseURL+ '/'+(String)toolingAttributes.get(attributeName);
                    validationLink =finalUrl; 
                }
                system.debug('wrap>>>> '+wrap);
               
                //finalMap.add()
            }
            system.debug('validationName >> '+validationName+'validationLink >> '+validationLink);
            if(validationName != null && validationLink != null){
                wrap.validationName = validationName;
                wrap.validationLink = validationLink;
                processDataListToReturn.add(wrap);
            }
        }
        SYSTEM.debug('processDataListToReturn '+processDataListToReturn);
        return processDataListToReturn;
    }	

    public static Innova_Utility.Innova_Response makeCallout(String httpMethod,String sEndpoint,String reqBody){
        Innova_Utility.Innova_Response response = new Innova_Utility.Innova_Response();
        try{
            HTTP newRequest = new HTTP();
            HTTPRequest request = new HTTPRequest(); 
            request.setHeader('Content-Type', 'application/json');
            request.setTimeout(60000);
            request.setEndpoint(sEndPoint);
            request.setMethod(httpMethod);
            if(String.isNotBlank(reqBody)){
                request.setBody(reqBody);
            }
            HttpResponse res =  newRequest.send(request);
            if(res.getStatusCode()>=200 && res.getStatusCode()<300){
                response.isSuccess = true;
            }else{
                response.isSuccess = false;
            }
            response.message = res.getBody();
        }catch(Exception e){
            response.isSuccess = false;
            response.message = e.getMessage();
        }
        return response;
    }

    public with sharing class InsertRecordwrapper{
        public string modeOfCreation; // {'Fast Record Creation', 'Multiple Record Creation (CSV)', 'Sequential Record Creation', 'Single Record Creation'}
        public string objName;
        public string recUserId;
        public Integer count;
        public string str; // for single record creation in toolingAPIHelper class
        public string result; // {'success', 'error'}
        public string successRecId;
        public string errorMessage;
    }
    
    
    @AuraEnabled
    public static Innova_Utility.InputActivityWrapper insertRec(String objName, Integer recCount, String str, String modeOfCreation,String recUserId){
   
         Innova_Utility.InputActivityWrapper lInnovaActivityObj = new Innova_Utility.InputActivityWrapper();
        Database.SaveResult[] srList = null;
        system.debug('objName  '+objName +'  recCount  '+recCount+'  str '+str + '  recUserId  '+recUserId);
        List<String> errorList = new List<String>();
        Map<String, String> strMap = new Map<String,String>();
        List<Object> strList = (List<Object>)JSON.deserializeUntyped(str);
        system.debug('inside tooling typecast() strList = '+strList);
        system.debug('### strList = '+strList);
        for(Object obj: strList){
            Map<String, Object> tMap = (Map<String, Object>)obj;
            String fieldName = (String)tMap.get('Field');
            String fieldVal = (String)tMap.get('Value');
            system.debug('inside tooling typecast() fieldName = '+fieldName+' fieldVal = '+fieldVal);
                strMap.put(fieldName.trim(),fieldVal);
        }
        
        List<sobject> sList = new List<sobject>();
        Map<String,Schema.DisplayType> mFieldDataTypes = getAllFields(objName);
        
        for (Integer i = 0; i < Integer.valueOf(recCount); i++){
            system.debug('#### reva strmap size = '+strmap.size()+' mFieldDataTypes size = '+mFieldDataTypes.size()+' objName = '+objName);
            if(!strMap.isEmpty() && !mFieldDataTypes.isEmpty() && String.isNotBlank(objName)){
               // List<sObject> temp = Innova_DataGeneratorCls.typecastAllfields(objName, mFieldDataTypes, strMap, recUserId );
               List<sObject> temp = typecastAllfields(objName, mFieldDataTypes, strMap,recUserId );

                if(recUserId != null){
                    sObject temp1 = Schema.getGlobalDescribe().get(objName).newSObject();
                    sObject temp2 = Schema.getGlobalDescribe().get(objName).newSObject();
                        temp1.put('OwnerId', recUserId);
                        system.debug('adding temp1 user into temp');
                        temp2.put('CreatedbyId', recUserId);
                        temp.add(temp1);
                        temp.add(temp2);
                }
                system.debug(temp);
                sList.addAll(temp);
            }  
        }
        
        try{
             srList = Database.insert(sList, false);
             
              
        }catch (DMLException e){
            //Added check for FIELD_CUSTOM_VALIDATION_EXCEPTION to return user friendly error.
            String errorMsg = e.getMessage();
            if(errorMsg.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')){
            errorMsg = errorMsg.substringBetween('FIELD_CUSTOM_VALIDATION_EXCEPTION, ', ': ');
            }
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,errorMsg));
            }
    
        List<Id> sInsertedIds = new List<Id>();
        
         Innova_Utility.InputActivityWrapper iaw = new Innova_Utility.InputActivityWrapper();
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug('Successfully inserted. ID: ' + sr.getId());
                    if(recUserId != null){
                        sObject temp1 = Schema.getGlobalDescribe().get(objName).newSObject();
                        temp1.id = sr.getId();
                        temp1.put('ownerId',recUserId);
                        Database.update(temp1, false);
                        //update temp1;
                        
                     }
                    sInsertedIds.add(sr.getId());
                    iaw.totalRecordsCount = srList.size();
                    iaw.successrRecordsCount = sInsertedIds.size();
                    iaw.errorRecordsCount = srList.size() - sInsertedIds.size();
                    iaw.modeOfCreation = modeOfCreation;
                    iaw.requestedBy = UserInfo.getuserId();
                    iaw.insertedRecIds = sInsertedIds;
                    system.debug('singlef srList.size() = '+srList.size()+' sInsertedIds = '+sInsertedIds);
                   // lInnovaActivityObj = Innova_Utility.insertInnovaActivities(iaw);
                   lInnovaActivityObj = Innova_DataGeneratorCls.insertGetActivityRecords(sInsertedIds.size(),sInsertedIds,modeOfCreation,objName);
                   // return lInnovaActivityObj;
                  //  return new List<String>{'Success'};
                    }
            
            else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');       
                    iaw.errorMessage =  err.getMessage();          
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Fields that affected this error: ' + err.getFields());
                    errorList.add(err.getStatusCode() + ': ' + err.getMessage());
                }
                
            }
           
        }
        return lInnovaActivityObj;
        
     //  return errorList;
       // return new List<String>{'Success'};
        
    }  
    /*public void createMetadataContainer(){
HttpRequest req = createHttpRequest(endpoint+'/sobjects/MetadataContainer','POST');
req.setBody('{"Name":"ApexContainer"}');
String response = getResponse(req);
Map<String,Object> rmp = (Map<String,Object>)JSON.deserializeuntyped(response);
String cid = (String)rmp.get('id// used to save containerId
}  */
    
    public Integer countErrorMethod(String sTrigBody){
        String tempBody = sTrigBody;
        String sError = 'addError';
        //Integer iErrorLen = sError.length();
        Integer index = tempBody.indexOf(sError);
        system.debug('index ==='+index);
        Integer count = 0;
        while(index >= 0){
            count++;
            tempBody = tempBody.substring(index + sError.length());
            index = tempBody.indexOf(sError);
            system.debug('in while loop - index ==='+index);
        }
        return count;
    }
    public static String schemaDisplayTypeCompatibility(String objName, List<String> lFieldName){
        
        SObjectType r = ((SObject)(Type.forName('Schema.'+objName).newInstance())).getSObjectType();
        DescribeSObjectResult d = r.getDescribe();
        for(String fieldName : lFieldName){
            System.debug(d.fields.getMap().get(fieldName).getDescribe().getType());
            DescribeFieldResult fieldDesc = d.fields.getMap().get(fieldName).getDescribe();
            Schema.DisplayType fieldType =  fieldDesc.getType();
            system.debug('### reva sDataType = '+fieldType);
            
        }
        //System.debug(d.fields.getMap().get(fieldName).getDescribe().getType());
        DescribeFieldResult fieldDesc ;//d.fields.getMap().get(fieldName).getDescribe();
        Schema.DisplayType fieldType ;//fieldDesc.getType();
        //system.debug('### reva sDataType = '+fieldType);
        
        //DescribeFieldResult fielddesc = field.getDescribe();
        //DisplayType fieldType = fielddesc.getType();
        Boolean canUpdate = fielddesc.isUpdateable();
        
        if(canUpdate == FALSE)
            return 'NOT UPDATEABLE';    
        if(fieldType == Schema.DisplayType.String || 
           fieldType == Schema.DisplayType.TextArea ||
           fieldType == Schema.DisplayType.Id ||
           fieldType == Schema.DisplayType.Picklist ||
           fieldType == Schema.DisplayType.Reference ||
           fieldType == Schema.DisplayType.Phone ||
           fieldType == Schema.DisplayType.Email ||
           fieldType == Schema.DisplayType.URL)
            return 'String';
        if(fieldType == Schema.DisplayType.Currency ||
           fieldType == Schema.DisplayType.Double)
            return 'Decimal';
        if(fieldType == Schema.DisplayType.Integer)
            return 'Integer';
        if(fieldType == Schema.DisplayType.Boolean)
            return 'Boolean';
        if(fieldType == Schema.DisplayType.DateTime)
            return 'DateTime';    
        if(fieldType == Schema.DisplayType.Date)
            return 'Date';            
        if(fieldType == Schema.DisplayType.Time)
            return 'Time';
        if(fieldType == Schema.DisplayType.Combobox)
            return 'Combobox';    
        if(fieldType == Schema.DisplayType.MultiPicklist)
            return 'MultiPicklist';
        if(fieldType == Schema.DisplayType.EncryptedString)
            return 'EncryptedString';
        if(fieldType == Schema.DisplayType.DataCategoryGroupReference)
            return 'DataCategoryGroupReference';        
        if(fieldType == Schema.DisplayType.base64 )
            return 'base64 ';               
        //if(fieldType == Schema.DisplayType.anytype)
        //     return 'anytype';                                  
        return 'UNKNOWN';    
    }
    
    @AuraEnabled
    public static Map<String,Schema.DisplayType> getAllFields(String objName){
        system.debug('here in getAllFields() objName = '+objName);
        Map<String, Schema.DisplayType> mFieldwithDataTypes = new Map<String, Schema.DisplayType>();
        SObjectType sType = Schema.getGlobalDescribe().get(objName);
        Map<String,Schema.SObjectField> mAllFields = sType.getDescribe().fields.getMap();
        
        for(String fieldName : mAllFields.keySet()){
            //String fieldLabel = fieldMap.get(fieldName).getDescribe().getLabel();
            Schema.DisplayType fielddataType = mAllFields.get(fieldName).getDescribe().getType();
            mFieldwithDataTypes.put(fieldName, fielddataType);
        }
        system.debug('mFieldwithDataTypes '+mFieldwithDataTypes);
        return mFieldwithDataTypes;
    }
    @AuraEnabled
    //public static String schemaDisplayTypeCompatibility(String objName, List<String> lFieldName){
    public static List<SObject> typecastAllfields(String objName, Map<String,Schema.DisplayType> mAllFields, Map<String,String> strMap, String recUserId){
        system.debug('reva : 1 entered typecast all fields 1');
        system.debug('objName = '+objName);
        system.debug('mAllFields = '+mAllFields);
        // for(String fieldnames : mAllFields.keyset()){
        //     system.debug('fieldnames mAllFields = '+fieldnames);
        //     system.debug('field dt  mAllFields  ='+mAllFields.get(fieldnames));
        //     system.debug('-----');
        // }
        system.debug('strMap = '+strMap);
        system.debug('recUserId = '+recUserId);
        List<SObject> lObjToInsert = new List<SObject>();
        sObject obj = Schema.getGlobalDescribe().get(objName).newSObject();
        for(String fieldName : strMap.keySet()){
            system.debug(' inside for loop of tooling typecastAllfields fielname = '+fieldname+'; mAllFields.get(fieldName) = '+mAllFields.get(fieldName)+'; strmap.get(fieldName) = '+strmap.get(fieldName));
            system.debug(' inside for loop of tooling typecastAllfields fielname = '+fieldname+'; mAllFields.get(name) = '+mAllFields.get('name')+'; strmap.get(name) = '+strmap.get('name'));
            if(mAllFields.get(fieldName) == Schema.DisplayType.String || 
               mAllFields.get(fieldName) == Schema.DisplayType.TextArea ||
               mAllFields.get(fieldName) == Schema.DisplayType.Id ||
               mAllFields.get(fieldName) == Schema.DisplayType.Picklist ||
               mAllFields.get(fieldName) == Schema.DisplayType.Reference ||
               mAllFields.get(fieldName) == Schema.DisplayType.Phone ||
               mAllFields.get(fieldName) == Schema.DisplayType.Email ||
               mAllFields.get(fieldName) == Schema.DisplayType.URL){
                String fieldVal = strmap.get(fieldname);
                    obj.put(fieldName,fieldVal);
                    }
                if(mAllFields.get(fieldName) == Schema.DisplayType.Reference){
                    obj.put(fieldName,Id.valueOf(strmap.get(fieldName)));
                }
            
            if(mAllFields.get(fieldName) == Schema.DisplayType.Currency ||
               mAllFields.get(fieldName) == Schema.DisplayType.Double){
                   String fieldVal = strmap.get(fieldName);
                   obj.put(fieldName, Decimal.valueOf(fieldVal));
               }
            
            if(mAllFields.get(fieldName) == Schema.DisplayType.Integer){
                Integer fieldVal = Integer.valueOf(strmap.get(fieldName));
                obj.put(fieldName, (fieldVal));
            }
            
            if(mAllFields.get(fieldName) == Schema.DisplayType.Boolean){
                Boolean fieldVal = Boolean.valueOf(strmap.get(fieldName));
                obj.put(fieldName, fieldVal);
            }
            
            if(mAllFields.get(fieldName) == Schema.DisplayType.DateTime) {
                DateTime fieldVal = (DateTime.valueOf(strmap.get(fieldName))) ;
                obj.put(fieldName, fieldVal);
            }
            
            if(mAllFields.get(fieldName) == Schema.DisplayType.Date){
                Date fieldVal = (Date.valueOf(strmap.get(fieldName))) ;
                obj.put(fieldName, fieldVal);
            }
            if(recUserId != null){
                if(fieldName == 'OwnerId'){
                    String fieldVal = recUserId;
                    obj.put(fieldName, fieldVal);
                }
                if(fieldName =='CreatedbyId'){
                    String fieldVal = recUserId;
                    obj.put(fieldName, fieldVal);
                }
            }
            
            
            /*if(mAllFields.get(fieldName) == Schema.DisplayType.Time){
                
                Time fieldVal = (Time) strmap.get(fieldName);
                obj.put(fieldName, fieldVal);
                
            }
            if(mAllFields.get(fieldName) == Schema.DisplayType.Combobox)
            {
                Combobox fieldVal = (Combobox) strmap.get(fieldName);
                obj.put(fieldName, fieldVal);
            }
            if(mAllFields.get(fieldName) == Schema.DisplayType.MultiPicklist)
            {
                MultiPickList fieldVal = (MultiPickList) strmap.get(fieldName);
                obj.put(fieldName, fieldVal);
            }
            if(mAllFields.get(fieldName) == Schema.DisplayType.EncryptedString)
            {
                EncryptedString fieldVal = (EncryptedString) strmap.get(fieldName);
                obj.put(fieldName, fieldVal);
            }
            if(mAllFields.get(fieldName) == Schema.DisplayType.DataCategoryGroupReference){
                
                DataCategoryGroupReference fieldVal = (DataCategoryGroupReference) strmap.get(fieldName);
                obj.put(fieldName, fieldVal);
                
            }
            
            if(mAllFields.get(fieldName) == Schema.DisplayType.base64 ){
                base64 fieldVal = (base64) strmap.get(fieldName);
                obj.put(fieldName, fieldVal);           
            }*/     
            system.debug('### reva : obj to insert');
            system.debug(obj);
        
        }
        lObjToInsert.add(obj);
       return lObjToInsert; 
    }

    public static List<String> generateRandomStrings(Integer count, String sName, String objName){
        List <string> lRandomGeneratedString = new List<String>{'temp123'};
        for(Integer i=0; i < count; i++){
            lRandomGeneratedString[i] = generateRandomString(12);
        }
        if(sName != null){
            sName = 'Test '+objName +' '+lRandomGeneratedString[0];
        }     
        return lRandomGeneratedString;   
    }

    public static String generateRandomString(Integer len) {
        final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
        String randStr = '';
        while (randStr.length() < len) {
           Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
           randStr += chars.substring(idx, idx+1);
        }
        return randStr; 
    }

    public static Integer generateRandomNumber() {

        Integer IntrandomNumber = Integer.valueof((Math.random() * 1000));	//generates a random number from 0 to 1000

        return IntrandomNumber; 
    }
    public static String finalInsertDML(String sObjName, List<sObject> sList, String modeOfCreation, String recUserId){
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
        for (Database.SaveResult sr : srList) {
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
       return returnWrapper;
       
    //    if(countSuccess > 0){
    //     String msg = 'Successfully inserted '+countSuccess+' record(s) :'+sInsertedIds;
    //     return msg;
    //    }
    //    else{
    //     return 'Insert failed. Please check with your admin with the following errors : '+errorList;
    //    }
    }
}