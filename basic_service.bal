import ballerina/http;
import ballerina/log;

@http:ServiceConfig {
    basePath: "/"
}

// By default, Ballerina assumes that the service is to be exposed via HTTP/1.1.
service<http:Service> hello bind { port: 9090 } {

    @http:ResourceConfig {
        path: "/",
        methods: ["POST"]
    }

    // All resources are invoked with arguments of server connector and request.
    hi(endpoint caller, http:Request req) {
        string payload = check req.getTextPayload();
        string untaintedPayload = sanitizeAndReturnUntainted(payload);
        http:Response res = new;
        // A util method that can be used to set a string payload.
        res.setPayload("Hello " + untaintedPayload + "!\n");

        // Sends the response back to the caller.
        _ = caller->respond(res);
    // caller->respond(res) but { error e => log:printError("Error sending response", err = e) };
    }
}

function sanitizeAndReturnUntainted(string input) returns @untainted string {
    string regEx = "[^a-zA-Z]";
    return input.replace(regEx, "");
}
