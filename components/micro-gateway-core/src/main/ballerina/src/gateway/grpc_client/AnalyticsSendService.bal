import ballerina/grpc;
import ballerina/log;
import ballerina/task;

//gRPC endpoint for http connections
//AnalyticsSendServiceClient nonblockingGRPCAnalyticsClient = new(getConfigValue(GRPC_ANALYTICS, GRPC_ENDPOINT_URL, "http://localhost:9806"));

grpc:StreamingClient gRPCEp = new grpc:StreamingClient();
boolean gRPCConnection = false;
map<any> gRPCConfigs = getConfigMapValue(GRPC_ANALYTICS);
int reConnectTime =  <int>gRPCConfigs[gRPC_RetryTimeMilliseconds];

task:Scheduler gRPCConnectTimer = new({
        intervalInMillis :  reConnectTime,
        initialDelayInMillis:0
});

service connectGRPC = service {
    resource function onTrigger(){
        if(gRPCConnection == false){
            initGRPCService();
            log:printWarn("Connection will retry again in "+ reConnectTime.toString() +" milliseconds if there is a connection error.");
        }
    }
};

//gRPC secured client endpoint configuraion  
AnalyticsSendServiceClient nonblockingGRPCAnalyticsClient = new(getConfigValue(GRPC_ANALYTICS, GRPC_ENDPOINT_URL, "https://localhost:9806"),
config = {
            secureSocket: {
                 keyStore: {
                       path : getConfigValue(LISTENER_CONF_INSTANCE_ID, LISTENER_CONF_KEY_STORE_PATH, "${ballerina.home}/bre/security/ballerinaKeystore.p12"), 
                       password : getConfigValue(LISTENER_CONF_INSTANCE_ID, LISTENER_CONF_KEY_STORE_PASSWORD, "ballerina") 
                },
                trustStore: {
                    path : getConfigValue(LISTENER_CONF_INSTANCE_ID, TRUST_STORE_PATH, "${ballerina.home}/bre/security/ballerinaTruststore.p12"), 
                    password :  getConfigValue(LISTENER_CONF_INSTANCE_ID, TRUST_STORE_PASSWORD, "ballerina") 
                },
                verifyHostname:false //to avoid SSL certificate validation error
            },
            timeoutInMillis : 2147483647
} );

//registers server message listner (AnalyticsSendServiceMessageListener)
public function initGRPCService(){
    var attachResult = gRPCConnectTimer.attach(connectGRPC);
     if (attachResult is error) {
        log:printError("Error attaching the service.");
        return;
    }
    var gRPCres = nonblockingGRPCAnalyticsClient -> sendAnalytics(AnalyticsSendServiceMessageListener);
    if (gRPCres is grpc:Error) {
        log:printError("Error from Connector: " + gRPCres.reason() + " - "
                                           + <string> gRPCres.detail()["message"]);
        return;
    } else {
        log:printDebug("Initialized gRPC connection sucessfully.");
        gRPCEp = gRPCres;
    }
}

//publishes data to relevant stream
public function dataToAnalytics(AnalyticsStreamMessage message){
    grpc:Error? connErr = gRPCEp->send(message);
        if (connErr is grpc:Error) {
            log:printDebug("Error from Connector: " + connErr.reason() + " - "
                                       + <string> connErr.detail()["message"]);
            
        } else {
            log:printDebug("Completed Sending gRPC Analytics data: ");
            if(gRPCConnection == false){
                //terminates the timer if gRPPCConnection variable assigned as false
                var stop = gRPCConnectTimer.stop();
                if (stop is error) {
                    log:printError("Stopping the task is failed.");
                    return;
                }
            }
            gRPCConnection = true;
        }
}

//server message listner
service AnalyticsSendServiceMessageListener = service {

    resource function onMessage(string message) {
    }

    resource function onError(error err) {
        //Triggers @ when startup when gRPC connection is closed.
        if (err.reason() == "{ballerina/grpc}UnavailableError" && gRPCConnection == false){
            log:printError("Error reported from server: " + err.reason() + " - " + <string> err.detail()["message"]);
            
            var startResult = gRPCConnectTimer.start();
                if (startResult is error ) {
                    log:printDebug("Starting the task is failed.");
                    return;
            }   
            gRPCConnection = false;
        }
        //starts the timer if error is gRPC unavailable and gRPCConnection has established previously.
        //(Triggers when wroked gRPC connection get closed)
        if (err.reason() == "{ballerina/grpc}UnavailableError" && gRPCConnection == true){
            gRPCConnection = false;
            log:printError("Error reported from server: " + err.reason() + " - " + <string> err.detail()["message"]);
            var startResult = gRPCConnectTimer.start();
                if (startResult is error ) {
                    log:printError("Starting the task is failed.");
                    return;
            }
        }
    }

    resource function onComplete() {
    }
};


// //Ping message used to stop gRPC reconnect Task
// AnalyticsStreamMessage gRPCPingMessage = {

//      messageStreamName: "PingMessage",
//      meta_clientType : "" ,
//      applicationConsumerKey : "" ,
//      applicationName : "" ,
//      applicationId : "" ,
//      applicationOwner : "" ,
//      apiContext : "" ,
//      apiName : "" ,
//      apiVersion : "" ,
//      apiResourcePath : "" ,
//      apiResourceTemplate : "" ,
//      apiMethod : "" ,
//      apiCreator : "" ,
//      apiCreatorTenantDomain : "" ,
//      apiTier : "" ,
//      apiHostname : "" ,
//      username : "" ,
//      userTenantDomain : "" ,
//      userIp : "" ,
//      userAgent : "" ,
//      requestTimestamp : 0 ,
//      throttledOut : false ,
//      responseTime :0 ,
//      serviceTime : 0 ,
//      backendTime : 0 ,
//      responseCacheHit : false,
//      responseSize : 0 ,
//      protocol : "" ,
//      responseCode  : 0 ,
//      destination : "" ,
//      securityLatency  : 0 ,
//      throttlingLatency  : 0 , 
//      requestMedLat : 0 ,
//      responseMedLat : 0 , 
//      backendLatency : 0 , 
//      otherLatency : 0 , 
//      gatewayType : "" , 
//      label  : "",



//      subscriber : "",
//      throttledOutReason : "",
//      throttledOutTimestamp : 0,
//      hostname : "",
 
//     errorCode : "",
//     errorMessage : ""
//     };

