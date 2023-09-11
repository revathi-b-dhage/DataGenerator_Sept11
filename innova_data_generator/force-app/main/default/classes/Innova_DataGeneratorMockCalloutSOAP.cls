@isTest
global class Innova_DataGeneratorMockCalloutSOAP implements WebServiceMock {
   global void doInvoke(
           Object stub,
           Object request,
           Map<String, Object> response,
           String endpoint,
           String soapAction,
           String requestName,
           String responseNS,
           String responseName,
           String responseType) {
        // start - specify the response you want to send
        List<String> validationRules = new List<String>{'Account.Due_for_promotion_required'};
        //response_x.return_x = 3.0;
        // end
        //response.put('response_x', response_x); 
        MetadataService.MetadataPort service = MetadataServiceExamples.createService();
        // String[] validationRules = new String[] {'Account.SIte_cannot_be_null'};
        List<MetadataService.ValidationRule> ruleListToUpdate = new List<MetadataService.ValidationRule>();
        List<MetadataService.ValidationRule> validations =
            (List<MetadataService.ValidationRule>) service.readMetadata('ValidationRule', validationRules).getRecords();
         response.put('response_x.getResult()', ruleListToUpdate);
        
   }
}