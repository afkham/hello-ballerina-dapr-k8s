import ballerina/http;
import ballerina/os;
import ballerina/log;

// These ports are injected automatically into the container.
string daprHttpPort = os:getEnv("DAPR_HTTP_PORT");
string daprGrpcPort = os:getEnv("DAPR_GRPC_PORT");

const stateStoreName = "statestore";
http:Client clientEP = check new ("http://localhost:" + daprHttpPort + "/v1.0/state/" + stateStoreName);
service http:Service / on new http:Listener(3000) {

    resource function get 'order() returns json|error {
        json payload = check clientEP->get("/order", targetType = json);
        return payload;
    }

    resource function post neworder(http:Request req) returns json|error {
        json payload = check req.getJsonPayload();
        json data = check payload.data;
        int orderId = check data.orderId;
        log:printInfo("Got a new order! Order ID: " + orderId.toString());

        json state = [{
            key: "order",
            value: data
        }];
        
        http:Response resp = check clientEP->post("", state);
        if (resp.statusCode == 204) {
            json success = ("Successfully persisted state.");
            return success;
        }
        log:printInfo(resp.statusCode.toString());
        json failure = ("An error occured.");
        return failure;
    }

    resource function get ports() returns json {
        log:printInfo("DAPR_HTTP_PORT: " + daprHttpPort);
        log:printInfo("DAPR_GRPC_PORT: " + daprGrpcPort);
        json payload = {
            "DAPR_HTTP_PORT" : daprHttpPort,
            "DAPR_GRPC_PORT" : daprGrpcPort
        };
        return payload;
    }
}
