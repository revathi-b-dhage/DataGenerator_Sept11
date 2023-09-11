Name: ParkService (Tip: After you click the Parse WSDL button, change the Apex class name from parksServices to ParkService) Class must be in public scope
2. Create a class named: ParkLocator 
public class ParkLocator { 
    public static string[] country(String country){ 
        ParkService.ParksImplport prk = new ParkService.ParksImplport(); 
        return prk.byCountry(country); 
    } 
} 
3. Create a test class named : ParkLocatorTest 
@isTest 
private class ParkLocatorTest { 
    @istest 
    static void testCallout(){ 
        Test.setMock(WebServiceMock.class, new ParkServiceMock()); 
        String country = 'USA'; 
        string[] result = ParkLocator.country(country); 
        System.assertEquals(new List<String>{'Glacier National Park','Grand Canyon','Yellowstone'}, 
                           ParkLocator.country(country)); 
    } 
} 
3. Create a mock class named : ParkServiceMock 
@isTest 
global class ParkServiceMock implements WebServiceMock { 
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
        ParkService.byCountryResponse response_x =  
            new parkService.byCountryResponse(); 
        response_x.return_x = new List<String>{'Glacier National Park','Grand Canyon','Yellowstone'}; 
        // end 
        response.put('response_x', response_x); 
   } 
} 
4. Run your test class at least once (via Run All tests the Developer Console) before attempting to verify this challenge. 
