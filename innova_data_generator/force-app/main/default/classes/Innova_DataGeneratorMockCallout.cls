@isTest
global class Innova_DataGeneratorMockCallout implements HttpCalloutMock{
    // global class AnimalsHttpCalloutMock implements HttpCalloutMock {
        // Implement this interface method
        global static HTTPResponse respond(HTTPRequest request) {
            // Create a fake response
            HttpResponse response = new HttpResponse();
            response.setHeader('Content-Type', 'application/json');
            response.setBody('{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"ValidationRule","records":[{"attributes":{"type":"ValidationRule","url":"/services/data/v38.0/tooling/sobjects/ValidationRule/03d5g0000001fxFAAQ"},"Id":"03d5g0000001fxFAAQ","ValidationName":"Due_for_promotion_required"}]}');
            //16:05:21:202 USER_DEBUG [66]|DEBUG|Response status->200---Response body--{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"ValidationRule","records":[{"attributes":{"type":"ValidationRule","url":"/services/data/v38.0/tooling/sobjects/ValidationRule/03d5g0000001fxFAAQ"},"Id":"03d5g0000001fxFAAQ","ValidationName":"Due_for_promotion_required","C
            //16:21:21:227 USER_DEBUG [67]|DEBUG|{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"ValidationRule","records":[{"attributes":{"type":"ValidationRule","url":"/services/data/v38.0/tooling/sobjects/ValidationRule/03d5g0000001fxFAAQ"},"Id":"03d5g0000001fxFAAQ","ValidationName":"Due_for_promotion_required","CreatedDate":"2022-10-18T08:49:3
            response.setStatusCode(200);
            return response; 
        }
    //}
}