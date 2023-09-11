global without sharing class Innova_ExceptionLogger
{
    static final Integer SHORT_MESSAGE_MAX_LENGTH = 255;
    
    /**
* Log exception with context (details) passed in by user.
*/
    public static void logException( Exception ex,
                                    String processName,
                                    String rowId,
                                    String context )
    {
        ex = getRootException( ex );
        System.debug( '>>>> LOGGING EXCEPTION = ' + ex );
        
        String trace = ex.getStackTraceString();
        if( trace != null && trace.length() > 32768 )
            trace = trace.substring( 32768 );
        
        System.debug( '>>>> service name = ' + processName );
        System.debug( '>>>> msg = ' + ex.getMessage() );
        System.debug( '>>>> context = ' + context );
        System.debug( '>>>> trace = ' + trace );
        doLogError( rowId,
                   processName,
                   ex.getMessage(),
                   context,
                   trace ); 
        
    }
    
    /**
* Log exception with context (details) passed in by user.
*/
    public static void logException(ExceptionLogWrapper exLogWrap){
        
        String trace = exLogWrap.ex.getStackTraceString();
        if(trace != null && trace.length() > 32768){
            trace = trace.substring(32768);
            
        }
        doLogError(exLogWrap.rowId,
                   exLogWrap.processName,
                   exLogWrap.shortMessage,
                   exLogWrap.context,
                   trace); 
        
    }
    
    //@future( callout=false )
    public static void doLogError( String rowId,
                                  String processName,
                                  String message,
                                  String context,
                                  String stackTrace ) 
    {
        String exMessage = message;
        if(message != null && message.length() > SHORT_MESSAGE_MAX_LENGTH){
            exMessage = message.substring(0,SHORT_MESSAGE_MAX_LENGTH);
        }
        Log__c log = new Log__c( Process_Name__c=processName,
                                Row_Id__c=rowId,
                                Message_Short__c=exMessage,
                                Error_Context__c=context,
                                Message_Long__c=stackTrace
                               );
        insert log;
    }
    
    public static void doLogError(String processName,
                                  List<Database.Saveresult> resultset,
                                  String context) 
    {
        List<Log__c> errorLogList=new List<Log__c>();
        for(Database.Saveresult sr:resultset)
        {
            String errorString='';
            for(Database.Error er:sr.getErrors())
                errorString=errorString+', '+er.getMessage();
            String message=errorString;      
            if( message != null && message.length() > 255 )
                message = message.substring( 255 );      
            Log__c log = new Log__c( Process_Name__c=processName,
                                    Row_Id__c=sr.getId(),
                                    Message_Short__c=message,
                                    Error_Context__c=context,
                                    Message_Long__c=errorString
                                   );
            errorLogList.add(log);                           
        }
        insert errorLogList;
    }
    
    public static void doLogError(String processName,
                                  List<Database.Deleteresult> resultset,
                                  String context) 
    {
        List<Log__c> errorLogList=new List<Log__c>();
        for(Database.Deleteresult sr:resultset)
        {
            String errorString='';
            for(Database.Error er:sr.getErrors())
                errorString=errorString+', '+er.getMessage();
            String message=errorString;      
            if( message != null && message.length() > 255 )
                message = message.substring( 255 );      
            Log__c log = new Log__c( Process_Name__c=processName,
                                    Row_Id__c=sr.getId(),
                                    Message_Short__c=message,
                                    Error_Context__c=context,
                                    Message_Long__c=errorString
                                   );
            errorLogList.add(log);                           
        }
        insert errorLogList;
    }
    private static Exception getRootException( Exception ex )
    {
        for( Exception root = ex.getCause(); root != null; root = ex.getCause() )
        {
            ex = root;
        }
        
        return ex;
    }
    
    //created to log only error records -- added while fixing case#00156250
    public static void doLogErrorDetails(String processName,
                                         List<Database.Saveresult> resultset,
                                         String context, List<sObject> objectList) 
    {
        //system.debug('#########resultset '+resultset);
        List<Log__c> errorLogList=new List<Log__c>();
        for(Integer i=0;i< resultset.size();i++){
            if (!resultset.get(i).isSuccess()) {
                String errorString='';
                for(Database.Error er: resultset.get(i).getErrors()) {
                    errorString=errorString+', '+er.getMessage();
                    String message=errorString;      
                    if( message != null && message.length() > 255 )
                        message = message.substring( 255 );      
                    Log__c log = new Log__c( Process_Name__c=processName,
                                            Row_Id__c=objectList[i].Id,
                                            Message_Short__c=message,
                                            Error_Context__c=context,
                                            Message_Long__c=errorString
                                           );
                    errorLogList.add(log);  
                }   
            }                         
        }
        insert errorLogList;
    }   
    
    public class ExceptionLogWrapper{
        public Exception ex;
        public String processName;
        public String rowId;
        public String context;
        public String shortMessage;
        public ExceptionLogWrapper(Exception ex, String processName, String rowId,String context,String shortMessage){
            this.ex = ex;
            this.processName = processName;
            this.rowId = rowId;
            this.context = context;
            this.shortMessage = shortMessage;
        }
    }
}