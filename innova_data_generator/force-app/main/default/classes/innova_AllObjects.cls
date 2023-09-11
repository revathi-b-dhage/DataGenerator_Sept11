public class innova_AllObjects {
    
    @AuraEnabled public String label {get;set;}
    @AuraEnabled public String value {get;set;}

    public innova_AllObjects[] fromSchema(Schema.SObjectType obj, innova_AllObjects[] allObjectsList){
        Schema.DescribeSObjectResult objResult = obj.getDescribe();
        system.debug('allObjectsList >>'+allObjectsList);
        if(objResult.isCreateable() && objResult.isUpdateable() && objResult.isDeletable() && objResult.isAccessible()){
            if(!objResult.getName().endsWith('__x') && !objResult.getName().endsWith('Tag') && 
            !objResult.getName().endsWith('History') && !objResult.getName().endsWith('ChangeEvent') &&
            !objResult.getName().endsWith('Share') && !objResult.getName().containsIgnorecase('Macro') && 
            objResult.getLabel() != 'Email Template' && !objResult.getName().containsIgnorecase('Feed')){
                this.label=objResult.getLabel();
                this.value=objResult.getName();
                allObjectsList.add(this);
            }
            
        }
        return allObjectsList;
    }
}