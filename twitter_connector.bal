import ballerina/config;
import ballerina/http;
import wso2/twitter;

// twitter package defines this type of endpoint
// that incorporates the twitter API.
// We need to initialize it with OAuth data from apps.twitter.com.
// Instead of providing this confidential data in the code
// we read it from a toml file.
endpoint twitter:Client tweeter {
    clientId: "", // Your Consumer Key (API Key)
    clientSecret: "", // Your Consumer Secret (API Secret)
    accessToken: "", // Your Access Token as obtained from twitter site
    accessTokenSecret: "" // Your Access Token Secret as obtained from twitter site
};

@http:ServiceConfig {
    basePath: "/"
}
service<http:Service> hello bind {port:9090} {
    @http:ResourceConfig {
        path: "/",
        methods: ["POST"]
    }
    hi (endpoint caller, http:Request request) {
        http:Response res;
        string payload = check request.getTextPayload();
        // transformation of request value on its way to Twitter
        if (!payload.contains("#ballerina")) {
            payload =payload+" #ballerina";
        }
        twitter:Status st = check tweeter->tweet(payload);
        // transformation on the way out - generate a JSON and pass it back
        json myJson = {
            text: payload,
            id:
        st.id,
            agent: "ballerina"
        };
        // pass back JSON instead of text
        res.setPayload(myJson);
        _ = caller->respond(res);
    }
}
