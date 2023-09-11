public class Innova_DataGeneratorCls {

    public static Innova_Utility.Innova_Response responseData = new Innova_Utility.Innova_Response();
    //wrapper class to send to UI
    public with sharing class InsertValuewrapper{
        public string modeOfCreation; // {'Fast Record Creation', 'Multiple Record Creation (CSV)', 'Sequential Record Creation', 'Single Record Creation'}
        public string objName;
        public string recUserId;
        public Integer count;
        public string str; // for single record creation in toolingAPIHelper class
        public string result; // {'success', 'error'}
        public string successRecId;
        public string insertedRecIds;
        public string errorMessage;
    }
    
    // wrapper class 
    public with sharing class customValueWrapper {
        @auraEnabled public String custFldlabel {get;set;}
        @auraEnabled public String custFldvalue {get;set;}
        @auraEnabled public boolean fldIsNillable {get;set;}
        @auraEnabled public boolean isAccessible {get;set;}
        @auraEnabled public boolean isCreateable {get;set;}
        @auraEnabled public string dataType {get;set;}
        @auraEnabled public List<String> picklistValues {get;set;}
    }
        // wrapper class for deserializing 
        public class InputValueWrapper {
            public string index;
            public string Field;
            public string Value;
            
        }
    @testVisible
    public static Map<String,list<customValueWrapper>> customObjWrapperMap = new Map<String,list<customValueWrapper>>();
    @testVisible
    public static final Map<String, Schema.DisplayType> mReqFieldsWithDatatype = new  Map<String, Schema.DisplayType>();
    
    @AuraEnabled(Cacheable=true)
    public static Map<String,List<innova_AllObjects>> getAllObject(){
    
        Map<String,List<innova_AllObjects>> getAllObjectMap = new Map<String,List<innova_AllObjects>>(); 
        List<innova_AllObjects> allObjectWrapperList = new List<innova_AllObjects>();
        try {
        for (Schema.SObjectType o : Schema.getGlobalDescribe().values()){
            allObjectWrapperList = new innova_AllObjects().fromSchema(o, allObjectWrapperList);
            
        }
        if(!allObjectWrapperList.isEmpty()){
            getAllObjectMap.put('allObject',allObjectWrapperList);
            return getAllObjectMap;
        }else {
            return new Map<String,List<innova_AllObjects>>();
        }
            } catch (Exception e) {
                system.debug(e.getStackTraceString());
                throw new AuraHandledException(e.getMessage());
            }
    }
    
    public class fetchRelatedObjWrapper{
        public String objName;
        public Boolean isMaster;
        public String apiName;
    }
    public class userObjWrapper{
        public string label;
        public string value;
    }
    
    
    //todo: pass a Boolean indicating the Object is master
    @AuraEnabled
    public static string fetchRelatedSObjects(String sObjName){
        Map<String,List<fetchRelatedObjWrapper>> getRelatedObjMap = new Map<String,List<fetchRelatedObjWrapper>>(); 
        List<fetchRelatedObjWrapper> wrapper = new List<fetchRelatedObjWrapper>();
            
        system.debug('FROM fetchRelatedSObjects   ');
        List<Map<String,Boolean>> mObjectsMR = new List<Map<String,Boolean>>();
        
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType tripSchema = schemaMap.get(sObjName);
        Map<String, Schema.SObjectField> fieldMap = tripSchema.getDescribe().fields.getMap();
    
        for (String fieldName: fieldMap.keySet()) {
            //get all the fields label for sObjName
                integer i = 0;
            if(i<5){
                String fieldLabel = fieldMap.get(fieldName).getDescribe().getLabel();
                //get data types for each fields
                Schema.DisplayType fielddataType = fieldMap.get(fieldName).getDescribe().getType();
                DescribeFieldResult fieldResult = fieldMap.get(fieldName).getDescribe();
                system.debug('fieldResult '+fieldResult.isCreateable());
                if(fielddataType == Schema.DisplayType.Reference && fieldResult.isCreateable()) {
                    if(isValidObjectName(fieldName)){
                        fetchRelatedObjWrapper w = new fetchRelatedObjWrapper();
                        for(Schema.SObjectType reference : fieldResult.getReferenceTo()) {
                            w.apiName = reference.getDescribe().getName();
                            w.objName = reference.getDescribe().getLabel();
                        }
                        if(fieldResult.getRelationshipOrder()==0){                        
                            w.isMaster= true;
                        } else {
                            w.isMaster= false;
                        }
                        wrapper.add(w);
                        i++;
                    }
                }
            }
            
        }
    
        system.debug('wrpper='+wrapper);
        if(wrapper != null){
            system.debug('wrpper2 ='+wrapper);
            getRelatedObjMap.put('RelatedObj',wrapper);
            return JSON.serialize(getRelatedObjMap);
        }
        return null;
            
    }
    public static Boolean isValidObjectName(String objName){
        if(String.isEmpty(objName)){return false;}
        if(	!objName.endsWith('__x') && !objName.endsWith('Tag') && 
            !objName.endsWith('History') && !objName.endsWith('ChangeEvent') &&
            !objName.endsWith('Share') && objName != 'EventWhoRelation' && objName != 'User' &&
            objName != 'TaskRelation'){
                return true;       
            }
        return false;
    }
    
    @AuraEnabled(Cacheable=false)
    public static Innova_Utility.InputActivityWrapper loadCSVData(Id contentDocumentId, String sObjName, String recUserId){
        system.debug('contentDocumentId = '+contentDocumentId+' sObjName='+sObjName+' recUserId= '+recUserId);
        Innova_Utility.InputActivityWrapper returnWrapper = new Innova_Utility.InputActivityWrapper();
        //Map<Integer,Map<String, String>> strMap = new Map<Integer,Map<String,String>>();
        List<sobject> sList = new List<sobject>();
        String fieldName ;
        String fieldVal;
        List<String> csvRecordData = new List<String>();
        //Map<String,Schema.DisplayType> mFieldDataTypes = Innova_ToolingAPIHelper.getAllFields(sObjName);
	    ContentVersion contentVersionObj = [ SELECT Id, VersionData FROM 
                                                ContentVersion WHERE 
                                                ContentDocumentId =:contentDocumentId ];
      	system.debug('contentVersionObj.VersionData ->'+contentVersionObj.VersionData.toString());
        system.debug(contentVersionObj.VersionData.toString());
        String data= contentVersionObj.VersionData.toString().replaceAll('\r','');
        system.debug('data->'+data);
        system.debug(data);
        
        List<String> csvFileLines=data.split('\n');
        //csvFileLines = data.replaceAll('\r','');
        //Map<Integer,String> valuesMap = new Map<Integer,String>();
        Map<Integer,String> headerMap = new Map<Integer,String>();
        List<String> valList = new List<String>();
        List<String> headers = csvFileLines[0].split('\\,');
        for(Integer i=0; i<headers.size();i++){
            
            string s=headers[i];
            system.debug('headers->'+s);
            headerMap.put(i,s);
        }
      	system.debug('size of csvfilelines-'+csvFileLines.size());
        Map<String,Schema.DisplayType> mAllFields = Innova_ToolingAPIHelper.getAllFields(sObjName);
        
        for(Integer i=1;i<csvFileLines.size();i++){  
            sObject obj = Schema.getGlobalDescribe().get(sObjName).newSObject();
        	Integer j=0;
        	csvRecordData = csvFileLines[i].split('\\,');
            system.debug('sizeofcsvrecorddata-'+csvRecordData.size());
            for (String s :csvRecordData){
                if(s != null && String.isNotBlank(s) && String.isNotEmpty(s)){
                    system.debug('---'+i+'--'+s);
                    fieldName = headerMap.get(j);
                    system.debug('fieldname-'+fieldName);
                     system.debug('mAllFields >>>'+mAllFields.get(fieldName.toLowerCase()));
                   
                   if(mAllFields.get(fieldName.toLowerCase()) == Schema.DisplayType.String || 
                   mAllFields.get(fieldName.toLowerCase()) == Schema.DisplayType.TextArea ||
                   mAllFields.get(fieldName.toLowerCase()) == Schema.DisplayType.Id ||
                   mAllFields.get(fieldName.toLowerCase()) == Schema.DisplayType.Picklist ||
                   mAllFields.get(fieldName.toLowerCase()) == Schema.DisplayType.Reference ||
                   mAllFields.get(fieldName.toLowerCase()) == Schema.DisplayType.Phone ||
                   mAllFields.get(fieldName.toLowerCase()) == Schema.DisplayType.Email ||
                   mAllFields.get(fieldName.toLowerCase()) == Schema.DisplayType.URL){
                    system.debug('fieldval-'+s);
                       obj.put(fieldName.toLowerCase(),s);
                   }
                
                if(mAllFields.get(fieldName.toLowerCase()) == Schema.DisplayType.Double){
                       obj.put(fieldName.toLowerCase(), Decimal.valueOf(s));
                   }
                    if(mAllFields.get(fieldName.toLowerCase()) == Schema.DisplayType.CURRENCY){
                       
                        Pattern dollarPattern = Pattern.compile('[\\p{Sc},]');
                        string curr = dollarPattern.matcher(s).replaceAll('');
                        decimal d = decimal.valueof(curr);
                        
                        obj.put(fieldName.toLowerCase(), d);
                    }
                if(
                   mAllFields.get(fieldName.toLowerCase()) == Schema.DisplayType.Integer){
                    obj.put(fieldName.toLowerCase(),  Integer.valueOf(s));
                }
                
                if(mAllFields.get(fieldName.toLowerCase()) == Schema.DisplayType.Boolean){
                    obj.put(fieldName.toLowerCase(), Boolean.valueOf(s));
                }
                
                if(mAllFields.get(fieldName.toLowerCase()) == Schema.DisplayType.DateTime) {
                  obj.put(fieldName.toLowerCase(), DateTime.valueOf(s));
                }
                
                if(mAllFields.get(fieldName.toLowerCase()) == Schema.DisplayType.Date){
                    obj.put(fieldName.toLowerCase(), Date.valueOf(s));
                }
                    
                 j++;
                  
                    
                }
                
             }
              	
				sList.add(obj);
                          
        }
      
      
     List<String> resultList = new List<String>();
     List<String> successList = new List<String>();
     try{
        Database.SaveResult[] srList = Database.insert(sList,false);
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
               // System.debug('Successfully inserted. ID: ' + sr.getId());
               // system.debug('### ########### reva AFter Insert');
                resultList.add(sr.getId());
                successList.add(sr.getId());
                 }
                 if(recUserId != null){
                    sObject temp1 = Schema.getGlobalDescribe().get(sobjname).newSObject();
                    temp1.id = sr.getId();
                    temp1.put('ownerId',recUserId);
                    Database.update(temp1, false);
                    //update temp1;
                    
                 }
        
        else {
            for(Database.Error err : sr.getErrors()) {
               // System.debug('The following error has occurred.');                    
               // System.debug(err.getStatusCode() + ': ' + err.getMessage());
               // System.debug('Fields that affected this error: ' + err.getFields());
                resultList.add(err.getStatusCode() + ': ' + err.getMessage());
            }
        }

        }
        if(successList.size()>0){
         returnWrapper =insertGetActivityRecords(srList.size(),successList,'CSV Upload',sObjName);
        }
        system.debug('wrapfastCreateRecordsUser  retrun  '+returnWrapper);
        
     }catch(DMLException ex){
        String errorMsg = ex.getMessage();
        returnWrapper.errorMessage=errorMsg;
        resultList.add(errorMsg);
     }
      
            returnWrapper.resultList=resultList;
        system.debug('reesult >>>hansa '+resultList);
        return returnWrapper;
    }
    
    
    //get fields from Related objects
    @AuraEnabled(cacheable=true)
    public static Map<String,list<customValueWrapper>> getAllFields(String objectName ) {
        list<customValueWrapper> customValueWrapperObj = new list<customValueWrapper>();
        list<customValueWrapper> customValueWrapperUser = new list<customValueWrapper>();
        
        SObjectType objname =((SObject) Type.forName(objectName).newInstance()).getSObjectType();
        Schema.DescribeSObjectResult r = objname.getDescribe();
        Map<String,Schema.SObjectField> M = r.fields.getMap();
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType leadSchema = schemaMap.get(objectName);
        Map<String, Schema.SObjectField> fieldMap = leadSchema.getDescribe().fields.getMap();
        
        for (String fieldName: fieldMap.keySet()) {
        //System.debug('##Field API Name='+fieldName);// list of all field API name
        fieldMap.get(fieldName).getDescribe().getLabel();//It provides to get the object fields label.
        }
        
        for(String fieldName : M.keySet())
        { 
            system.debug('fieldName  '+fieldName);
            Schema.SObjectField field = M.get(fieldName);
            Schema.DescribeFieldResult F = field.getDescribe();
            if(F.isCreateable() == true){
                
                //A nillable field can have empty content. A isNillable Boolean non-nillable field must have a value for the object to be                       //created or saved. 
                // if F.isNillable() is false then field is mandatory
                Boolean isFieldreq  = F.isNillable();
                // Boolean isFieldreq  = F.isNillable();
                Boolean isAccessible = F.isAccessible();
                Boolean isCreateable = F.isCreateable();
                string  dataType  = string.valueOf(F.getType());
                String sFieldLabel = field.getDescribe().getLabel();
                customValueWrapper selectObjectValueWrapper = new customValueWrapper();
                selectObjectValueWrapper.custFldlabel = field.getDescribe().getLabel();
                selectObjectValueWrapper.custFldvalue = fieldName + ' - '+dataType;
                selectObjectValueWrapper.fldIsNillable = isFieldreq;
                selectObjectValueWrapper.isAccessible = isAccessible;
                selectObjectValueWrapper.isCreateable = isCreateable;
                selectObjectValueWrapper.dataType = dataType;
                if(String.valueOf(F.getType()) == 'PICKLIST'){
                    List<string> pickListValuesList = new List<String>();
                    for( Schema.PicklistEntry pickListVal : F.getPicklistValues()){
                        pickListValuesList.add(pickListVal.getLabel());
                    }     
                    selectObjectValueWrapper.picklistValues = pickListValuesList;
                }
                
                String sFieldName = selectObjectValueWrapper.custFldvalue;
                system.debug('OwnerF sFieldName = '+selectObjectValueWrapper.custFldvalue);
                if(selectObjectValueWrapper.fldIsNillable == true && sFieldName != null && F.getType() != null && !(selectObjectValueWrapper.custFldvalue).containsIgnoreCase('ownerid')){
                    mReqFieldsWithDatatype.put(sFieldName,F.getType());
                }
                if(selectObjectValueWrapper.custFldvalue != 'OwnerId' && !((selectObjectValueWrapper.custFldvalue).containsIgnoreCase('ownerid'))){
                customValueWrapperUser.add(selectObjectValueWrapper);
                }
            }
        }
        if(customValueWrapperUser != null && customValueWrapperUser.isEmpty() == false){
            customObjWrapperMap.put('AllFields',customValueWrapperUser); 
        }
        
        if(customObjWrapperMap!= null){
            //system.debug('returning non null');
            return customObjWrapperMap;
        }else{
            //system.debug('returning null');
            return null;
        }
        
    }
    
    // return true if object accessible
    public static Boolean checkAccessForObject(String objName){
        Boolean isAccessible;
        try{
            isAccessible = ((SObject) Type.forName(objName).newInstance()).getSObjectType().getDescribe().isAccessible();
        if(isAccessible != null){
            return isAccessible;    
        }
        return false;
    }catch(Exception e){
        throw new AuraHandledException(e.getMessage());    }
    }
    
    public static List<InputValueWrapper> parse(String json) {
        return (List<InputValueWrapper>) System.JSON.deserialize(json, List<InputValueWrapper>.class);
    }
    
    @AuraEnabled
    public static Innova_Utility.InputActivityWrapper wrapfastCreateRecordsUser(String ivw){
    system.debug('entered wrapfastCreateRecordsUser method. ivw = '+ivw);
    InsertValueWrapper wrapper = new InsertValueWrapper();
    wrapper = (InsertValueWrapper)System.JSON.deserialize(ivw, InsertValueWrapper.class);
    String sobjName = wrapper.objName;
    Integer count = wrapper.count;
    String str = wrapper.str;
    String modeOfCreation = wrapper.modeOfCreation;
    String recUserId = wrapper.recUserId;
            
    system.debug('wrapfastCreateRecordsUser(). wrapper = '+wrapper);
    system.debug('obj='+sobjName+' count='+count+' recUserId='+recUserId);
    List<String> insertedRecursiveList = new List<String>();
    if(sobjName == 'Opportunity'){
    //reva to-do
    //insertedRecursiveList = wrapfastCreateRecordsUser('Account',1, modeOfCreation, recUserId);
    }
    
    List<String> errorList = new List<String>();
    list<customValueWrapper> customValueWrapperUser = new list<customValueWrapper>();
    SObjectType objName =((SObject)Type.forName(sobjName).newInstance()).getSObjectType();
    Schema.DescribeSObjectResult r = objname.getDescribe();
    Map<String,Schema.SObjectField> M = r.fields.getMap();
    for(String fieldName : M.keySet())
    {
    // system.debug('fielname='+fieldname);
    Schema.SObjectField field = M.get(fieldName);
    Schema.DescribeFieldResult F = field.getDescribe();
    if(F.isCreateable() == true && F.getType() != null && F.isUpdateable() && F.isAccessible()){
    //A nillable field can have empty content. A isNillable Boolean non-nillable field must have a value for the object to be                       //created or saved.
    // if F.isNillable() is false then field is mandatory
    Boolean isFieldreq  = F.isNillable();
    customValueWrapper selectObjectValueWrapper = new customValueWrapper();
    selectObjectValueWrapper.custFldlabel = field.getDescribe().getLabel();
    selectObjectValueWrapper.custFldvalue = fieldName;
    selectObjectValueWrapper.fldIsNillable = isFieldreq;
    String sFieldName = selectObjectValueWrapper.custFldvalue;
    // system.debug('ww selectObjectValueWrapper='+selectObjectValueWrapper);
    //system.debug('sFieldName '+sFieldName+' f.gettype='+f.getType()+' f.update='+f.isUpdateable()+' f.access='+f.isAccessible()+' f.compound='+f.getCompoundFieldName());
    if(selectObjectValueWrapper.fldIsNillable == false && sFieldName != null){
    system.debug('added required field='+sfieldName);
    mReqFieldsWithDatatype.put(sFieldName,F.getType());
    }
    customValueWrapperUser.add(selectObjectValueWrapper);
    }
    }
    Map<String, Schema.DisplayType> mAllReqFieldDatatypes = mReqFieldsWithDatatype;
    List<sobject> sList = new List<sobject>();
    if(count == null){
    count = 1;
    }
    for(Integer j=0; j<count; j++){
    Map<String, String> mAllFieldValues = new Map<String,String>();
    system.debug('zz');
    system.debug(mAllReqFieldDatatypes);
    mAllFieldValues = prepopulateFields(sobjName, insertedRecursiveList, mAllReqFieldDatatypes);
    system.debug(mAllFieldValues);
    if(!mAllFieldValues.isEmpty() && !mAllReqFieldDatatypes.isEmpty() && String.isNotEmpty(sobjName)){
    List<sObject> temp = typecastAllfields(sobjName, mAllReqFieldDatatypes, mAllFieldValues );
    sList.addAll(temp);
    }
    }
    Database.SaveResult[] srList = Database.insert(sList, false);
    //return message on UI as below:
    List<String> sInsertedIds = new List<String>();
    Innova_Utility.InputActivityWrapper iaw = new Innova_Utility.InputActivityWrapper();
    Innova_Utility.InputActivityWrapper iawInserted = new Innova_Utility.InputActivityWrapper();
    String insertedRecId;
    for (Database.SaveResult sr : srList) {
        if (sr.isSuccess()) {
            System.debug('wrap Successfully inserted. ID: ' + sr.getId());
            sInsertedIds.add(sr.getId());
            if(recUserId != null){
                system.debug('update owner if a user context is selected on UI');
                sObject temp1 = Schema.getGlobalDescribe().get(sobjName).newSObject();
                temp1.id = sr.getId();
                temp1.put('ownerId',recUserId);
                Database.update(temp1, false);
                
            }
           // insertedRecId = sr.getId();
        }
        else {
            for(Database.Error err : sr.getErrors()) {
                System.debug('The following error has occurred.'+err);
                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                System.debug('Fields that affected this error: ' + err.getFields());
                errorList.add(err.getFields()+ ': '+err.getStatusCode() + ': ' + err.getMessage());
            }
        }
    }
   // System.debug('insertedRecId ' + insertedRecId);
   // iaw.totalRecordsCount = srList.size();
    //iaw.insertedRecIds = sInsertedIds;
    //iaw.successrRecordsCount = sInsertedIds.size();
    //iaw.errorRecordsCount = srList.size() - sInsertedIds.size();
    //iaw.modeOfCreation = modeOfCreation;
    //iaw.requestedBy = UserInfo.getuserId();
    string objNameStr = iaw.objName== null? sobjname : iaw.objName + ', '+sobjname;
    system.debug('entering insertInnovaActivities activity method');
    //iawInserted = Innova_Utility.insertInnovaActivities(iaw);
    
    // if(iawInserted != null ){
    //     iawInserted.successRecID = insertedRecId;
      //  iawInserted.insertedRecIds = sInsertedIds;
    // system.debug('iawInserted - '+iawInserted);
    // }
    // String returnWrapper = JSON.serialize(iawInserted);
    
    Innova_Utility.InputActivityWrapper returnWrapper =insertGetActivityRecords(srList.size(),sInsertedIds,modeOfCreation,objNameStr);
    system.debug('wrapfastCreateRecordsUser  retrun  '+returnWrapper);

    return returnWrapper;
    }
    // END wrapfastCreateRecordsUser



    //insert & Retreieve Activity Records
public static Innova_Utility.InputActivityWrapper insertGetActivityRecords(Integer srListSize, List<String> sInsertedIdsLst, String modeOfCreation, String objName){
    Innova_Utility.InputActivityWrapper iaw = new Innova_Utility.InputActivityWrapper();
    Innova_Utility.InputActivityWrapper iawInserted = new Innova_Utility.InputActivityWrapper();

    iaw.totalRecordsCount = srListSize;
   // iaw.insertedRecIds = sInsertedIdsLst;
    iaw.successrRecordsCount = sInsertedIdsLst.size();
    iaw.errorRecordsCount = srListSize - sInsertedIdsLst.size();
    iaw.modeOfCreation = modeOfCreation;
    iaw.requestedBy = UserInfo.getuserId();
    iaw.objName = objName;
    iaw.insertedRecIds = sInsertedIdsLst;
    //iaw.insertedRecIds = 
    system.debug('entering insertInnovaActivities activity method');
    system.debug('check1 iaw = '+iaw);
    
    //String returnWrapper = JSON.serialize(iawInserted);
    iawInserted = Innova_Utility.insertInnovaActivities(iaw);
    if(iawInserted != null ){
        // iawInserted.successRecID = insertedRecId;
         iawInserted.insertedRecIds = sInsertedIdsLst;
     system.debug('iawInserted - '+iawInserted);
     }
    return iawInserted;


}
    
    @AuraEnabled
        public static List<String> fastCreateRecordsUser(String sObjName, Integer count, String modeOfCreation, String recUserId ){
            //String recUserId
            system.debug('obj='+sObjName+' count='+count+' recUserId='+recUserId);
            List<String> insertedRecursiveList = new List<String>();
        if(sobjName == 'Opportunity'){
            insertedRecursiveList = fastCreateRecordsUser('Account',1, modeOfCreation, recUserId);
        }
        if(sobjName=='Trip__c'){
            insertedRecursiveList = fastCreateRecordsUser('Payment',1, modeOfCreation, recUserId);
        }
        List<String> errorList = new List<String>();
        list<customValueWrapper> customValueWrapperUser = new list<customValueWrapper>();
        SObjectType objName =((SObject)Type.forName(sObjName).newInstance()).getSObjectType();
        Schema.DescribeSObjectResult r = objname.getDescribe();
        Map<String,Schema.SObjectField> M = r.fields.getMap();
        for(String fieldName : M.keySet())
        { 
            // system.debug('fielname='+fieldname);
            Schema.SObjectField field = M.get(fieldName);
            Schema.DescribeFieldResult F = field.getDescribe();
            if(F.isCreateable() == true && F.getType() != null && F.isUpdateable() && F.isAccessible()){
            
                //A nillable field can have empty content. A isNillable Boolean non-nillable field must have a value for the object to be                       //created or saved. 
                // if F.isNillable() is false then field is mandatory
                Boolean isFieldreq  = F.isNillable();
                
                customValueWrapper selectObjectValueWrapper = new customValueWrapper();
                selectObjectValueWrapper.custFldlabel = field.getDescribe().getLabel();
                selectObjectValueWrapper.custFldvalue = fieldName;
                selectObjectValueWrapper.fldIsNillable = isFieldreq;
                String sFieldName = selectObjectValueWrapper.custFldvalue;
                
                // system.debug('ww selectObjectValueWrapper='+selectObjectValueWrapper);
                //system.debug('sFieldName '+sFieldName+' f.gettype='+f.getType()+' f.update='+f.isUpdateable()+' f.access='+f.isAccessible()+' f.compound='+f.getCompoundFieldName());
                if(selectObjectValueWrapper.fldIsNillable == false && sFieldName != null){
                    system.debug('added required field='+sfieldName);
                    mReqFieldsWithDatatype.put(sFieldName,F.getType());
                }
                customValueWrapperUser.add(selectObjectValueWrapper);
            }
        }
        Map<String, Schema.DisplayType> mAllReqFieldDatatypes = mReqFieldsWithDatatype;
        List<sobject> sList = new List<sobject>();
        if(count == null){
            count = 1;
        }
        for(Integer j=0; j<count; j++){
            Map<String, String> mAllFieldValues = new Map<String,String>();
            system.debug('zz');
            system.debug(mAllReqFieldDatatypes);
            mAllFieldValues = prepopulateFields(sObjName, insertedRecursiveList, mAllReqFieldDatatypes);
            system.debug(mAllFieldValues);
                    if(!mAllFieldValues.isEmpty() && !mAllReqFieldDatatypes.isEmpty() && String.isNotEmpty(sObjName)){
                        List<sObject> temp = typecastAllfields(sObjName, mAllReqFieldDatatypes, mAllFieldValues );
                        sList.addAll(temp);
                    }  
            
        }


        Database.SaveResult[] srList = Database.insert(sList, false);


        //return message on UI as below:
        List<String> sInsertedIds = new List<String>();
        Innova_Utility.InputActivityWrapper iaw = new Innova_Utility.InputActivityWrapper();
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug('Successfully inserted. ID: ' + sr.getId());
                    system.debug('### ########### reva AFter Insert');
                    system.debug('entered fast create succ');
                    sInsertedIds.add(sr.getId());
                    if(recUserId != null){
                        system.debug('entered fast create succ 1');
                        sObject temp1 = Schema.getGlobalDescribe().get(sobjName).newSObject();
                        temp1.id = sr.getId();
                        temp1.put('ownerId',recUserId);
                        Database.update(temp1, false);
                        //update temp1;
                     }
                    
                    //return new List<String>{'Success : created record(s)!'};
                    }
            
            else {
                for(Database.Error err : sr.getErrors()) {
                    iaw.totalRecordsCount = srList.size();
                        iaw.successrRecordsCount = sInsertedIds.size();
                        iaw.errorRecordsCount = srList.size() - sInsertedIds.size();
                        iaw.modeOfCreation = modeOfCreation;
                        iaw.requestedBy = UserInfo.getuserId();
                        Innova_Utility.InputActivityWrapper iawInserted = Innova_Utility.insertInnovaActivities((iaw));
                        system.debug('entering insertInnovaActivities activity method');
                        iawInserted = Innova_Utility.insertInnovaActivities(iaw); 
                        
                    System.debug('The following error has occurred.'+err);                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Fields that affected this error: ' + err.getFields());
                    
                        errorList.add(err.getFields()+ ': '+err.getStatusCode() + ': ' + err.getMessage());
                    
                        
                }
            }
            
        }
        iaw.totalRecordsCount = srList.size();
        iaw.successrRecordsCount = sInsertedIds.size();
        iaw.errorRecordsCount = srList.size() - sInsertedIds.size();
        iaw.modeOfCreation = modeOfCreation;
        iaw.requestedBy = UserInfo.getuserId();
        system.debug('entering insertInnovaActivities activity method');
        Innova_Utility.InputActivityWrapper iawInserted = Innova_Utility.insertInnovaActivities((iaw));
        
        if(iawInserted != null )
        system.debug('lInnovaActivityIds - '+iawInserted);
        if(count== sInsertedIds.size()){
                //return 'sInsertedIds';
                return new List<String>{'success'};
            }
            else return new List<String>{'Insert failed !'};
        
        
    }
    public static Map<String, String> prepopulateFields(String sObjName, List<String> insertedRecursiveList,  Map<String, Schema.DisplayType> mAllReqFieldDatatypes){
        List<Account> oAcc = new List<Account>();
        List<Account> pay = new List<Account>();
       /* if(sobjName == 'Opportunity'){
            if(insertedRecursiveList!= null){
                    oAcc = [Select Id from Account where Id IN:insertedRecursiveList];
            }
        }*/
        system.debug('in prepop sObjName='+sObjName+' insertedRecursiveList='+insertedRecursiveList+' mAllReqFieldDatatypes='+mAllReqFieldDatatypes);
        system.debug('mAllReqFieldDatatypes='+mAllReqFieldDatatypes);
        Map<String, String> mFieldValue = new Map<String, String>();
        Map<String, String> mFieldValueRef = new Map<String, String>();
    
        for(String sFieldName : mAllReqFieldDatatypes.keySet()){
            Schema.DisplayType fieldType = mAllReqFieldDatatypes.get(sfieldName);
            system.debug('reva required field: sfieldName = '+sfieldName+' fieldtype  = '+fieldtype);
            if(fieldtype == Schema.DisplayType.Reference){
                if(sfieldName=='ownerid'){
                    mFieldValue.put(sfieldName,UserInfo.getuserid());
                    }else{
                        system.debug('in handle sObjName='+sObjName+' sFieldName='+sFieldName);
                    mFieldValueRef = handleReferenceFields(sObjName,sFieldName);
                    system.debug(mFieldValueRef);
                    mFieldValue.putall(mFieldValueRef);
                    }
                    
            }
            
           /* if(sobjName == 'Opportunity' && sfieldName == 'AccountId'){
                mFieldValue.put(sfieldName,String.valueof(oAcc[0].Id));
            }*/
            /*if(sobjName == 'Trip__c' && sfieldName == 'Account__c'){
                mFieldValue.put(sfieldName,String.valueof(pay[0].Id));
            }*/
            if(sfieldName=='Closedate'){
                mfieldValue.put(sfieldName,String.valueof(Date.today()));
            }
            if(fieldType == (Schema.DisplayType.String) || 
            fieldType == (Schema.DisplayType.TextArea) ||
            fieldType == (Schema.DisplayType.Id) ||
            //fieldType == (Schema.DisplayType.Picklist) ||
            fieldType == (Schema.DisplayType.Phone) ||
            fieldType == (Schema.DisplayType.Email) ||
            fieldType == (Schema.DisplayType.URL)){
            String sRandomString = 'Test'+' '+generateRandomString(2);
            mFieldValue.put(sFieldName, sRandomString);
            if(sfieldName=='ownerid'){
                mFieldValue.put(sfieldName,UserInfo.getuserid());
                }
            //if(sobjName == 'Opportunity' && sfieldName == 'AccountId'){
                //  mFieldValue.put(sfieldName,String.valueof(oAcc[0].Id));
            //}else
                if(sobjName=='Opportunity' && sfieldName=='StageName'){
                mFieldValue.put(sfieldName,'Closed Won');
            } 
            
            } else if(fieldType == (Schema.DisplayType.Integer)){
            mFieldValue.put(sfieldName, String.valueOf(generateRandomNumber())); // generates random number from 0 to 1000
            } else if(fieldType == (Schema.DisplayType.DateTime)){
            mFieldValue.put(sFieldName,String.valueOf( Datetime.now()));
            } else if(fieldType == (Schema.DisplayType.Picklist)){
                // prepopulate the picklist first value
                List<String> lAllPicklistValues = getPickListValuesIntoList(sObjName,sFieldName);
                mFieldValue.put(sFieldName, String.valueOf(lAllPicklistValues[0]));
            }
            if(sfieldName == 'Name'){
            String sName = 'Test record '+sobjName+' ' +generateRandomString(8);
            mFieldValue.put(sfieldName, sName);
            }
        }
        if(mFieldValue != null){
            return mFieldValue;
        }else {
            return null;
        }
    }

    public static List<String> getPickListValuesIntoList(String objApiName, String fApiName){
        SObjectType objectApiName =((SObject)Type.forName(objApiName).newInstance()).getSObjectType();
            Schema.DescribeSObjectResult r = objectApiName.getDescribe();
            Map<String,Schema.SObjectField> M = r.fields.getMap();
            Schema.SObjectField field = M.get(fApiName);
            Schema.DescribeFieldResult fieldResult = field.getDescribe();
                   
            List<String> pickListValuesList= new List<String>();

            if(fieldResult.isRestrictedPicklist()){
                List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
                for( Schema.PicklistEntry pickListVal : ple){
                    pickListValuesList.add(pickListVal.getLabel());
                }     
            return pickListValuesList;
            }
            else{
                return new List<String>{'Test pVal'};
            }
         
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
    
    @AuraEnabled
    //public static String schemaDisplayTypeCompatibility(String objName, List<String> lFieldName){
    public static List<SObject> typecastAllfields(String objName, Map<String,Schema.DisplayType> mAllFields, Map<String,String> strMap){
        system.debug('reva : 1 entered typecast all fields 1');
        List<SObject> lObjToInsert = new List<SObject>();
        sObject obj = Schema.getGlobalDescribe().get(objName).newSObject();
        for(String fieldName : strMap.keySet()){
            if(mAllFields.get(fieldName) == Schema.DisplayType.String || 
                mAllFields.get(fieldName) == Schema.DisplayType.TextArea ||
                mAllFields.get(fieldName) == Schema.DisplayType.Id ||
                mAllFields.get(fieldName) == Schema.DisplayType.Picklist ||
                mAllFields.get(fieldName) == Schema.DisplayType.Reference ||
                mAllFields.get(fieldName) == Schema.DisplayType.Phone ||
                mAllFields.get(fieldName) == Schema.DisplayType.Email ||
                mAllFields.get(fieldName) == Schema.DisplayType.URL){
                    obj.put(fieldName,String.valueOf(strmap.get(fieldName)));
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
            
        }
        lObjToInsert.add(obj);
        system.debug('lObjToInsert.size = '+lObjToInsert.size());
        return lObjToInsert; 
    }
    @AuraEnabled  
    public static List<SObject> viewCreatedRecords(String sObjName, String recIds){
        List<String> lInsertedRecords = convertStringToList(recIds);
        system.debug(' CHECK recIds = '+recIds);
        system.debug(' CHECK lInsertedRecords = '+lInsertedRecords);
        String sQuery = 'Select Id, Name, ownerId, CreatedDate from '+sObjName+' where createddate = today and Id in '+lInsertedRecords+' order by createddate desc';
        system.debug('viewCreatedRecords  Query '+sQuery);
        List<sObject> createdRecords = Database.query(sQuery);
        system.debug('return of viewcreatedRecordss = '+createdRecords);
        return createdRecords;
    }
    public static List<String> convertStringToList(String recordIds){
        List<String> returnIdList = new List<String>();
        if(String.isBlank(recordIds)){
            returnIdList.add('');
            return returnIdList;
        }
        List<String> listOfIds = recordIds.split(',');
        system.debug('recordIds = '+recordIds);
        system.debug('listOfIds = '+listOfIds);
        
        for(String strId : listOfIds){
            returnIdList.add('\''+strId+'\'');
        }
        system.debug('returnIdList = '+returnIdList);
        return returnIdList; 
    }
    @AuraEnabled  
    public static List<SObject> viewActivityRecord(String activityRecId){
        system.debug('activityRecId -> '+activityRecId);
        String sQueryStr = ' Select Id, Name, ownerId, CreatedDate from Innova_Activity__c ';
        String whereClause = ' where id = ';
        String recIds = '\''+activityRecId+'\'';
        String sQuery = sQueryStr+whereClause+recIds;
        system.debug('sQuery -> '+sQuery);
        List<sObject> createdRecords = Database.query(sQuery);
        return createdRecords;
    }
    @AuraEnabled
    public static List<Innova_Activity__c> showAllActivity(){
        try {
            List<Innova_Activity__c> lActivitiesInsertedToday = [SELECT Id, Object__c, Requested_By__c, Error_records_count__c, Inserted_Record_Ids__c, Mode_of_Creation__c, Success_records_count__c, Total_records_count__c from Innova_Activity__c where createddate = today];
            if(lActivitiesInsertedToday != null){
                return lActivitiesInsertedToday;
            }
            else return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static String SequentialDataCreation(Integer count, String Parent, String child, Boolean isMultiple, String modeOfCreation, String recUserId){
        // obj1 in dropdown = child object;
        // obj showed in related rec tab = parents/lookup objects
        String srResultParent;
        String srResult= null;
        
        if(String.isBlank(modeOfCreation) || String.isEmpty(modeOfCreation) || modeOfCreation.contains('sequential')){
            modeOfCreation = 'Sequential Record Creation';
        }
        List<String> errorList = new List<String>();
        List<String> listSR = new List<String>();
        Innova_Utility.InputActivityWrapper IAWrapper;
        Innova_Utility.SaveResultWrapper srWrapperReturn, srw;

        //try {
            // TODO : Return RecordIdsMap in a String
            system.debug('SequentialDataCreation count='+count+' parentobjname='+Parent+' childobjname='+child);
            system.debug('SequentialDataCreation isMultiple='+isMultiple+' modeOfCreation='+modeOfCreation+' recUserId='+recUserId);

            if(Parent == 'User'){
                User adminuser = [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' LIMIT 1];
                srResultParent=(adminuser.Id);
            }else{
                InsertValueWrapper wrapper2 = new InsertValueWrapper();
                wrapper2.objName = parent;
                wrapper2.count = 1;
                wrapper2.modeOfCreation = modeOfCreation;
                wrapper2.recUserId = recUserId;
                String ivw2 = JSON.serialize(wrapper2);

                system.debug('entering fastCreateForSeq() fcfs');
                srWrapperReturn=fastCreateForSeq(ivw2);
                srResultParent = srWrapperReturn.successRecId;
                system.debug('exit fastCreateForSeq() fcfs');
                system.debug('fcfs srWrapperReturn = '+srWrapperReturn);
                //fcfs srWrapperReturn = SaveResultWrapper:[count=1, errorMessage=null, objName=Account, recUserId=null, result=success, str=null, successRecId=0015g00001GEzJoAAL]
            }
            Innova_Utility.InputActivityWrapper iawChildInserted = new Innova_Utility.InputActivityWrapper();
            Innova_Utility.InputActivityWrapper iawActivityInsert = new Innova_Utility.InputActivityWrapper();

            List<String> insertedIdsSeq = new List<String>();
            system.debug('srResultParent='+srResultParent);
                for(integer i=0; i<count; i++){
                    iawChildInserted =sequentialChildCreate(count, srResultParent, parent,child,modeOfCreation, recuserid);
                    insertedIdsSeq.addAll(iawChildInserted.insertedRecIds);
                    system.debug('fcfs2 insertedIdsSeq = '+insertedIdsSeq);
                    listSR.add('yes');
                    // system.debug('fcfs srResult = '+srResult);
                }
                insertedIdsSeq.add(srResultParent);
                iawActivityInsert.totalRecordsCount = count +1 ;
                iawActivityInsert.successrRecordsCount = insertedIdsSeq.size();
                iawActivityInsert.errorRecordsCount = count+1 - insertedIdsSeq.size();
                iawActivityInsert.modeOfCreation = modeOfCreation;
                iawActivityInsert.requestedBy = UserInfo.getuserId();
                iawActivityInsert.objName = parent + ', '+child;
                iawActivityInsert.insertedRecIds = insertedIdsSeq;
                system.debug('entering insertInnovaActivities activity method');
                iawChildInserted = Innova_Utility.insertInnovaActivities(iawActivityInsert);
       
                String returnWrapper = JSON.serialize(iawChildInserted);
                system.debug('-- final return wrapper = '+returnWrapper);
                return returnWrapper;    
    }

    // FAST RECORD CREATION FOR SEQUENTIAL INSERT 
    // TO-DO: optimise wrapfastCreateRecordsUser by separating DMLs of IA and dynamic objects
    @AuraEnabled
    public static Innova_Utility.SaveResultWrapper fastCreateForSeq(String ivw){
    system.debug('entered fastCreateForSeq method. ivw = '+ivw);
    InsertValueWrapper wrapper = new InsertValueWrapper();
    wrapper = (InsertValueWrapper)System.JSON.deserialize(ivw, InsertValueWrapper.class);
    String sobjName = wrapper.objName;
    Integer count = wrapper.count;
    String str = wrapper.str;
    String modeOfCreation = wrapper.modeOfCreation;
    String recUserId = wrapper.recUserId;
            
    system.debug('fastCreateForSeq(). wrapper = '+wrapper);
    system.debug('obj='+sobjName+' count='+count+' recUserId='+recUserId);
    List<String> insertedRecursiveList = new List<String>();
    if(sobjName == 'Opportunity'){
    //reva to-do
    //insertedRecursiveList = fastCreateForSeq('Account',1, modeOfCreation, recUserId);
    }
    
    List<String> errorList = new List<String>();
    list<customValueWrapper> customValueWrapperUser = new list<customValueWrapper>();
    SObjectType objName =((SObject)Type.forName(sobjName).newInstance()).getSObjectType();
    Schema.DescribeSObjectResult r = objname.getDescribe();
    Map<String,Schema.SObjectField> M = r.fields.getMap();
    for(String fieldName : M.keySet())
    {
    Schema.SObjectField field = M.get(fieldName);
    Schema.DescribeFieldResult F = field.getDescribe();
    if(F.isCreateable() == true && F.getType() != null && F.isUpdateable() && F.isAccessible()){
    Boolean isFieldreq  = F.isNillable();
    customValueWrapper selectObjectValueWrapper = new customValueWrapper();
    selectObjectValueWrapper.custFldlabel = field.getDescribe().getLabel();
    selectObjectValueWrapper.custFldvalue = fieldName;
    selectObjectValueWrapper.fldIsNillable = isFieldreq;
    String sFieldName = selectObjectValueWrapper.custFldvalue;
    if(selectObjectValueWrapper.fldIsNillable == false && sFieldName != null){
    mReqFieldsWithDatatype.put(sFieldName,F.getType());
    }
    customValueWrapperUser.add(selectObjectValueWrapper);
    }
    }
    Map<String, Schema.DisplayType> mAllReqFieldDatatypes = mReqFieldsWithDatatype;
    List<sobject> sList = new List<sobject>();
    if(count == null){
    count = 1;
    }
    for(Integer j=0; j<count; j++){
    Map<String, String> mAllFieldValues = new Map<String,String>();
    system.debug('zz');
    system.debug(mAllReqFieldDatatypes);
    mAllFieldValues = prepopulateFields(sobjName, insertedRecursiveList, mAllReqFieldDatatypes);
    system.debug(mAllFieldValues);
    if(!mAllFieldValues.isEmpty() && !mAllReqFieldDatatypes.isEmpty() && String.isNotEmpty(sobjName)){
    List<sObject> temp = typecastAllfields(sobjName, mAllReqFieldDatatypes, mAllFieldValues );
    sList.addAll(temp);
    }
    }
    Database.SaveResult[] srList = Database.insert(sList, false);
    String srInserted = null;
    Innova_Utility.SaveResultWrapper srWrapper = new Innova_Utility.SaveResultWrapper();
    /*
    *public with sharing class SaveResultWrapper{
        public string objName;
        public string recUserId;
        public Integer count;
        public string str; // for single record creation in toolingAPIHelper class
        public string result; // {'success', 'error'}
        public string successRecId;
        public string errorMessage;
    }*/
    srWrapper.objName = sobjName;
    srWrapper.count = 1;

    if(srList != null ){
        for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    System.debug(' fcfswrap Successfully inserted. ID: ' + sr.getId());
                    if(recUserId != null){
                        system.debug('update owner if a user context is selected on UI');
                        sObject temp1 = Schema.getGlobalDescribe().get(sobjName).newSObject();
                        temp1.id = sr.getId();
                        temp1.put('ownerId',recUserId);
                        Database.update(temp1, false);
                    }
                    srWrapper.result = 'success';
                    srWrapper.successRecID = sr.getId();
                    srWrapper.recUserId = recUserId;
                }
                else {
                        for(Database.Error err : sr.getErrors()) {
                                System.debug('The following error has occurred.'+err);
                                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                                System.debug('Fields that affected this error: ' + err.getFields());
                                errorList.add(err.getFields()+ ': '+err.getStatusCode() + ': ' + err.getMessage());
                                srWrapper.result = 'error';
                                srWrapper.errorMessage = String.valueOf(errorList);
                        }
                    }
            }
            system.debug('fcfs srWrapper = '+srWrapper);
            return srWrapper;
    }
return null;
}
    // END wrapfastCreateRecordsUser2

    public static Innova_Utility.InputActivityWrapper sequentialChildCreate(Integer count, Id parentId, String parentObjName, String childObjName, String modeOfCreation, String recUserId){
        // parent is account, child is Trips
        // Populate master fields
        // Populate childs if parent is chosen in dropdown
        // populate mandatory childs
        if(count == null){
            count = 1;
        }
        List<String> listmsg = new List<String>();
        List<sobject> sList = new List<sobject>();
        Map<String, Schema.DisplayType> mReqFieldsWithDatatypechild = new Map<String, Schema.DisplayType>();
            Map<String, String> mAllFieldValuesprep = new Map<String,String>();
            Map<String, String> mAllFieldValueschild = new Map<String,String>();
            List<sobject> listTemp = new List<sobject>();
        system.debug('sequentialChildCreate count='+count+' parentid='+parentId+' parentobjname='+parentObjName+' childobjname='+childObjName);
        Map<String, String> mFieldValue = new Map<String, String>();
        List<String> errorList = new List<String>();
        List<String> insertedRecursiveList = new List<String>();
        
        //String sObjName = childObjName;
        SObjectType childObj =((SObject)Type.forName(childObjName).newInstance()).getSObjectType();
        Schema.DescribeSObjectResult result = childObj.getDescribe();
        Map<String,Schema.SObjectField> childfieldMap = result.fields.getMap();
        system.debug('m='+childfieldMap);
        for(String fieldName : childfieldMap.keySet())
        { 
            system.debug('fieldMap.size = '+childfieldMap.size());
            system.debug('fieldName : '+fieldName);
            Schema.SObjectField field = childfieldMap.get(fieldName);
            Schema.DescribeFieldResult F = field.getDescribe();
            
            system.debug('f='+f);
            // todo : when getDefaultValue is not null, populate the default value
            if(F.isCreateable() == true && fieldName != null){
                system.debug('fieldName='+fieldName);
                Boolean isFieldOptional  = F.isNillable();
                
                customValueWrapper selectObjectValueWrapper = new customValueWrapper();
                selectObjectValueWrapper.custFldlabel = F.getLabel();
                selectObjectValueWrapper.custFldvalue = fieldName;
                selectObjectValueWrapper.fldIsNillable = isFieldOptional;
    
                String sFieldName = selectObjectValueWrapper.custFldvalue;
    
                system.debug('in child: isFieldOptional='+isFieldOptional+' /sFieldName='+sFieldName+' /F.getType='+F.getType()+' /F.isUpdateable='+F.isUpdateable()+' /F.isAccessible()='+F.isAccessible()+' /F.getCompoundFieldName()='+F.getCompoundFieldName());
                
                if(isFieldOptional == false  && F.getType() != null && F.isUpdateable() && F.isAccessible() && F.getType() != Schema.DisplayType.Reference){
                    system.debug('in child:1 added required field='+sfieldName);
                    mReqFieldsWithDatatypechild.put(sFieldName,F.getType());
                }
                
                if(isFieldOptional == true && sFieldName== 'name' && F.getType() != null && F.isUpdateable() && F.isAccessible()  && F.getType() != Schema.DisplayType.Reference){
                    system.debug('in child:name added required field='+sfieldName);
                    mReqFieldsWithDatatypechild.put(sFieldName,F.getType());
                }
                
                if(isFieldOptional == false && F.getType() == Schema.DisplayType.Reference && sfieldName != 'id'){
                    mReqFieldsWithDatatypechild.put(sFieldName,F.getType());
                }
                if(F.getType() == Schema.DisplayType.Reference && sfieldName != 'id' && !mReqFieldsWithDatatypechild.containskey(sFieldName)){
                    for(Schema.SObjectType reference : f.getReferenceTo()) {
                        System.debug('Reference object name: ' + reference.getDescribe().getName());
                        if(reference.getDescribe().getName() == parentObjName){
                            system.debug('in child: req reference added required field='+sfieldName);
                            mReqFieldsWithDatatypechild.put(sFieldName,F.getType());
                        }
                }      
                }
            }
        }
        
        // for(Integer j=0; j<count; j++){
            system.debug(' :: all mReqFieldsWithDatatypechild='+mReqFieldsWithDatatypechild);
            mAllFieldValuesprep = prepopulateFieldsSequential(childObjName, insertedRecursiveList, mReqFieldsWithDatatypechild, parentId);
            
            system.debug(mAllFieldValuesprep);
            mAllFieldValueschild.putAll(mAllFieldValuesprep);
            system.debug(mAllFieldValueschild);
                    if(!mAllFieldValueschild.isEmpty() && !mReqFieldsWithDatatypechild.isEmpty() && String.isNotEmpty(childObjName)){
                        
                        List<sObject> temp = typecastAllfields(childObjName, mReqFieldsWithDatatypechild, mAllFieldValueschild );
                        sList.addAll(temp);
                        system.debug('temp ='+temp);
                    }  
                    system.debug('listTemp='+listTemp);
            if(listTemp!= null){
                sList.addall(listTemp);
            }
            system.debug('finale sList='+sList);
            Database.SaveResult[] srResults = Innova_Utility.finalInsertDML(childObjName,sList, modeOfCreation, recUserId);
            List<String> insertedChildRecs = new List<String>();
            for(Database.SaveResult sr: srResults){
                system.debug('fcfs2 sr='+sr);
                if(sr.isSuccess()){
                    insertedChildRecs.add(sr.getId());
                }
            }

            Innova_Utility.InputActivityWrapper iaw = new Innova_Utility.InputActivityWrapper();
            Innova_Utility.InputActivityWrapper iawInserted = new Innova_Utility.InputActivityWrapper();

            iaw.totalRecordsCount = srResults.size();
            iaw.successrRecordsCount = insertedChildRecs.size();
            iaw.errorRecordsCount = srResults.size() - insertedChildRecs.size();
            iaw.modeOfCreation = modeOfCreation;
            iaw.requestedBy = UserInfo.getuserId();
            iaw.objName = iaw.objName== null? childObjName : iaw.objName + ', '+childObjName;
            system.debug('entering insertInnovaActivities activity method');
            iaw.insertedRecIds = insertedChildRecs;

            return iaw;
            
            /*system.debug('fcfs scc msg = '+srResults+' count= '+count+' listmsg size = '+listmsg.size());
            boolean isSuccess = false;
            if(srResults != null){
                isSuccess = true;
            }
            
            // }
            if(isSuccess = true){
                system.debug('here in success fcfs');
                return 'Success';
            }
            else{
                system.debug('here in error fcfs');

                return 'Error';
            }*/
    }
    public static Map<String, String> handleReferenceFields(String sObjName, String sFieldName){
        // Trip, Account__c
        system.debug('in handle: sObjName='+sObjName+' sFieldName='+sFieldName);
        String objName;
        List<String> recId;
        Map<String, String> mapFieldRef = new Map<String, String>();
        
        Schema.SObjectType sObj = Schema.getGlobalDescribe().get(sObjName);
        system.debug('sObj = '+sObj);
        Map<String, Schema.SObjectField> fieldMap = sObj.getDescribe().fields.getMap();
        system.debug('fieldMap = '+fieldMap);
        DescribeFieldResult fieldResult = fieldMap.get(sFieldName).getDescribe();
        system.debug('fieldResult = '+fieldResult);
        system.debug(fieldResult.isCreateable());
        if( fieldResult.isCreateable()) {
            for(Schema.SObjectType reference : fieldResult.getReferenceTo()) {
                System.debug('Reference object name: ' + reference.getDescribe().getName());
                System.debug('Reference object label: ' + reference.getDescribe().getLabel());
                objName = reference.getDescribe().getName();
                }
            system.debug('fieldName >>> master or lookup '+fieldResult.getRelationshipOrder());
            if(String.isNotBlank(objName) && isValidObjectName(objName)){
                InsertValueWrapper wrapper3 = new InsertValueWrapper();
                wrapper3.objName = objname;
                wrapper3.count = 1;
                wrapper3.modeOfCreation = null;
                String ivw3 = JSON.serialize(wrapper3);
                //recId = fastCreateRecords(ivw3);
                if(recId!= null && !recId[0].containsignorecase('Insert failed !')){
                    mapFieldRef.put(sFieldName, recId[0]);
                }
            }
            
        }
    
        if(mapFieldRef != null){
            return mapFieldRef;
        }
        return null;
    }
    //String sObjName, List<String> insertedRecursiveList,  Map<String, Schema.DisplayType> mAllReqFieldDatatypes){
    public Static Map<String, String> prepopulateFieldsSequential(String sObjName, List<String> insertedRecursiveList,  Map<String, Schema.DisplayType> mAllReqFieldDatatypes, Id parentId){
        List<Account> oAcc = new List<Account>();
        List<Account> pay = new List<Account>();
        system.debug('in prepop sObjName='+sObjName+' insertedRecursiveList='+insertedRecursiveList+' mAllReqFieldDatatypes='+mAllReqFieldDatatypes);
        system.debug('mAllReqFieldDatatypes='+mAllReqFieldDatatypes);
        Map<String, String> mFieldValue = new Map<String, String>();
        Map<String, String> mFieldValueRef = new Map<String, String>();
    
        for(String sFieldName : mAllReqFieldDatatypes.keySet()){
            Schema.DisplayType fieldType = mAllReqFieldDatatypes.get(sfieldName);
            system.debug('reva required field: sfieldName = '+sfieldName+' fieldtype  = '+fieldtype);
            if(fieldtype == Schema.DisplayType.Reference){
                if(sfieldName=='ownerid'){
                    mFieldValue.put(sfieldName,UserInfo.getuserid());
                    } 
                    system.debug('in handle sObjName='+sObjName+' sFieldName='+sFieldName);
                    if(parentId != null && sfieldName !='ownerid'){
                        system.debug('here in refrence');
                            mFieldValue.put(sfieldName,parentId);
                    }
                    
                    
            }if(fieldType == (Schema.DisplayType.Date)){
                mfieldValue.put(sfieldName,String.valueof(Date.today()+1));
            }
            
            if(fieldType == (Schema.DisplayType.String) || 
            fieldType == (Schema.DisplayType.TextArea) ||
            fieldType == (Schema.DisplayType.Id) ||
            fieldType == (Schema.DisplayType.URL)){
            String sRandomString = 'Test '+sFieldName+' '+generateRandomString(3);
            mFieldValue.put(sFieldName, sRandomString);
            }
            if(fieldType == (Schema.DisplayType.Phone)){
                mFieldValue.put(sfieldName, String.valueOf(generateRandomNumber())); // generates random number from 0 to 1000
            }  
            if(fieldType == (Schema.DisplayType.Email) ){
                String sRandomString = 'Test@'+generateRandomString(3)+'.com';
                mFieldValue.put(sFieldName, sRandomString);
            } 
            if(sfieldName=='ownerid'){
                mFieldValue.put(sfieldName,UserInfo.getuserid());
                }
            if(sobjName=='Opportunity' && sfieldName.equalsIgnorecase('stagename')){
                system.debug('here in stage');
                mFieldValue.put(sfieldName,'Prospecting');
            }  
            if(fieldType == (Schema.DisplayType.Integer)){
            mFieldValue.put(sfieldName, String.valueOf(generateRandomNumber())); // generates random number from 0 to 1000
            }  
            if(fieldType == (Schema.DisplayType.DateTime)){
            mFieldValue.put(sFieldName,String.valueOf( Datetime.now()));
            } 
            if(fieldType == (Schema.DisplayType.Boolean)){
            system.debug('Hansa -> '+fieldType);
            mFieldValue.put(sFieldName, 'false');
            }
            if(sfieldName == 'Name'){
            String sName = 'Test record '+sobjName+' ' +generateRandomString(3);
            mFieldValue.put(sfieldName, sName);
            }
        }
        system.debug('here in mFieldValue>>hansa '+mFieldValue);
        if(mFieldValue != null){
            return mFieldValue;
        }else {
            return null;
        }
        
    }

    @AuraEnabled
    public static String getAllUsers(String objName){
       
        Set<Id> profileIdSet = new Set<Id>();
        String permissionQuery='SELECT Profile.Name FROM PermissionSet '+
       'WHERE IsOwnedByProfile = TRUE ' +
        'AND Id IN (SELECT ParentId FROM ObjectPermissions WHERE ' + 
        'PermissionsCreate = True AND PermissionsRead = True AND PermissionsEdit = True '+ 
        'AND PermissionsDelete = True AND PermissionsRead = True '+ 
        'AND SObjectType =: objName' +
        ' ) ORDER BY Profile.Name';

        List<PermissionSet> permissionsList= database.query(permissionQuery); 
        system.debug('permissionQuery  '+permissionQuery   );
                system.debug('permissionsList  '+permissionsList   );
        if(permissionsList != null && !permissionsList.isEmpty()){
            for(PermissionSet permObj : permissionsList){
                profileIdSet.add(permObj.ProfileId);
            }
            system.debug('profileIdSet  '+profileIdSet.size());
        }

        List<User> userAccessList= [SELECT Id,Name 
        FROM User 
        WHERE 
        ProfileId In :profileIdSet];
        
        system.debug('userAccessList  '+userAccessList);

        Map<String,List<userObjWrapper>> userObjMap = new Map<String,List<userObjWrapper>>(); 
        List<userObjWrapper> userObjList = new List<userObjWrapper>();
        List<User> userList;
        userObjWrapper userObj;
        Boolean hasCreateAccess = false;
        Schema.DescribeSObjectResult describeSObjectResult = Account.SObjectType.getDescribe();

        try {
          userList=  [select  Name,FirstName,LastName,Username  from User];
            if(userAccessList.size() > 0){
                for(User uObj:userAccessList){
                     userObj = new userObjWrapper();
                    userObj.label=uObj.Name;
                    userObj.value= uObj.Id;
                    userObjList.add(userObj);
                }
            }
            userObjMap.put('userList',userObjList);
            system.debug('userObjMap  '+userObjMap);
            return JSON.serialize(userObjMap);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    

    @AuraEnabled
    public static String deactivateValidationRulesForSobject(String objectName){
        system.debug('checkdeactivate object = '+objectName);
        //String objectName = 'Account';
        List<String> rulesList = Innova_ToolingAPIHelper.queryValidationRules(objectName);
        system.debug('rulesList = '+rulesList);
        
        String[] validationRules = new List<String>();
        for(String s : rulesList){
            s = objectName+'.'+s;
            validationRules.add(s);
        }
        system.debug('validationRules '+validationRules);
        
        MetadataService.MetadataPort service = MetadataServiceExamples.createService();
        // String[] validationRules = new String[] {'Account.SIte_cannot_be_null'};
        List<MetadataService.ValidationRule> ruleListToUpdate = new List<MetadataService.ValidationRule>();
        List<MetadataService.ValidationRule> validations =
            (List<MetadataService.ValidationRule>) service.readMetadata('ValidationRule', validationRules).getRecords();
        
        for(MetadataService.ValidationRule quickValidation : validations){
            quickValidation.active = false;
            ruleListToUpdate.add(quickValidation);
        }
        
        
        List<MetadataService.SaveResult> results =
            service.updateMetadata(ruleListToUpdate);
        system.debug('success here '+results);
        Integer deactivatedRulesCount = 0;
        for (MetadataService.SaveResult sr : results) {
            system.debug('sr >> '+JSON.serializePretty(sr));
            if(sr.success == true){
                deactivatedRulesCount = ++deactivatedRulesCount;
              }
        }
        if(deactivatedRulesCount == results.size()){
            return 'All validation rules are deactivated';
        }
        return null;
    }
    @AuraEnabled
    public static Innova_Utility.Innova_Response checkSync(String endpoint){
        String sBaseURL = 'callout:';
        Boolean flag = false;
        for(NamedCredential sigRec: [Select Endpoint,DeveloperName FROM NamedCredential]){
            if(sigRec.Endpoint.equalsIgnorecase(endpoint.trim())){
                flag = true;
                sBaseURL += sigRec.DeveloperName;
                break;
            }
        }
        if(flag){
            responseData = Innova_ToolingAPIHelper.makeCallout('GET',sBaseURL+Innova_Utility.SERVICE_URL+Innova_Utility.GET_SOBJECTS,null);
            responseData.data = sBaseURL;
        }else{
            responseData.isSuccess = false;
            responseData.message   = Innova_Utility.ERROR_MESSAGE_ONE;
        }
        return responseData;
    }

    @AuraEnabled
    public static Innova_Utility.Innova_Response getDataFromExternalOrg(String sQuery,String endpoint,Boolean isTooling){
        sQuery = sQuery.trim().normalizeSpace().replaceAll('\r','');
        sQuery =  EncodingUtil.urlEncode(sQuery, 'UTF-8');
        if(isTooling){
            responseData = Innova_ToolingAPIHelper.makeCallout('GET',endpoint+Innova_Utility.TOOLING_SERVICE_URL+sQuery,null);
        }else{
            responseData = Innova_ToolingAPIHelper.makeCallout('GET',endpoint+Innova_Utility.SERVICE_URL+sQuery,null);
        }
        responseData.data = sQuery;
        return responseData;
    }

    @AuraEnabled
    public static Innova_Utility.Innova_Response pushDataToExternalOrg(String csvdata,String objectName,String endpoint){
        csvdata = csvdata.replaceAll('\r','');
        String returnString;
        List<String> inputList = csvdata.split('\n');
        List<String> filteredList;
        Integer emptylineInd = inputList.indexOf('\n');
        if(emptylineInd!= -1){
            filteredList = new List<String>();
            for(Integer i=0;i<emptylineInd;i++){
                filteredList.add(inputList[i]);
            }
        }else{
            filteredList = inputList;
        }
        returnString = filteredList[0]+ ',referenceId' + '\n';
        List<String> fieldList = filteredList[0].split(',');
        Integer colSize = fieldList.size();
        String objName = objectName.trim();
        String finalString='{"records":[';
        for(Integer i=1;i<filteredList.size();i++){
            finalString += '{ "attributes" : {"type" : "'+objName+'", "referenceId" : "'+objName+ 'ref'+i+'"},';
            returnString += filteredList[i] + ',' +objName+ 'ref'+i;
            List<String> fieldData = filteredList[i].split(',');
            if(fieldData.size()!=colSize){
                fieldData.add('');
            }
            for(Integer j=0;j<colSize;j++){
                System.debug('fieldData--->'+fieldData);
                if(fieldData[j] != null && (fieldData[j].equalsIgnoreCase('true') || fieldData[j].equalsIgnoreCase('false'))){
                    finalString += '"'+fieldList[j].toLowerCase()+'":"' +  Boolean.valueOf(fieldData[j]) + '"';
                }else{
                    finalString += '"'+fieldList[j].toLowerCase()+'":"' +  fieldData[j] + '"';
                }
                //finalString += '"'+fieldList[j].toLowerCase()+'":"' +  fieldData[j] + '"';
                if(fieldList[j] != fieldList[colSize-1]){
                    finalString += ',';
                }         
            }
            finalString += '}';
            if(filteredList[i]!= filteredList[filteredList.size()-1]){
                returnString +='\n';
                finalString+= ',';
            }
        }
        finalString += ']}';
        responseData = Innova_ToolingAPIHelper.makeCallout('POST',endpoint+Innova_Utility.COMPOSITE_SERVICE_URL+objName,finalString);
        responseData.data = returnString;
        return responseData;
    }
}