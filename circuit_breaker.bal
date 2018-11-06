import ballerina/http;
import wso2/twitter;
import ballerina/config;

// This endpoint is the connection to the external service.
// We wrap it as endpoint because it helps us add capabilities to handle unpredicability of this service, which is gonna be our data source.
// The circuit breaker is a configuration parameter of the connection.
// The circuit breaker will flip with certain error codes or a 500 ms timeout
// The circuit breaker flips back to original state after 3 seconds.
endpoint http:Client homer {
    url: "http://www.simpsonquotes.xyz",
    circuitBreaker: {
        failureThreshold: 0.0,
        resetTimeMillis: 3000,
        statusCodes: [500, 501, 502]
    },
    timeoutMillis: 500
};

// Tweeter EndPoint, this will tweet stuff for us. This establishes connection to twitter using twitter connector
endpoint twitter:Client tweeter {
    clientId: "", // Your Consumer Key (API Key)
    clientSecret: "", // Your Consumer Secret (API Secret)
    accessToken: "", // Your Access Token as obtained from twitter site
    accessTokenSecret: "" // Your Access Token Secret as obtained from twitter site
    // clientConfig: {}
};

// Now we initiate our code as a service
@http:ServiceConfig {
    basePath: "/"
}

// Start the server at 9090 port
service<http:Service> hello bind {port: 9090} {
    @http:ResourceConfig {
        path: "/",
        methods: ["POST"]
    }
    
    // EndPoint on Server
    hi (endpoint caller, http:Request request) {
        http:Response res;
        // use var as a shorthand for http:Response | error union type
        // Compiler is smart enough to use the actual type
        var v = homer->get("/quote");
        // match is the way to provide different handling of error vs normal output
        match v {
            http:Response hResp => {
                // if proper http response use our old code
                string payload = check hResp.getTextPayload();
                if (!payload.contains("#ballerina")){payload=payload+" #ballerina";}
                    twitter:Status st = check tweeter->tweet(payload);
                    json myJson = {
                        text: payload,
                        id: st.id,
                        agent: "ballerina"
                    };
                res.setPayload(myJson);
            }
            error err => {
                // this block gets invoked if there is error or if circuit breaker is Open
                res.setPayload("Circuit is open. Invoking default behavior.");
            }
        }
        _ = caller->respond(res);
    }
}