@RestResource(urlMapping='/someUnqiueSecretHash/*')
//https://arlanis--slackbot.sandbox.my.salesforce-sites.com/someUnqiueSecretHash/services/apexrest/someUnqiueSecretHash


global with sharing class SlackEventListener {
    @HttpPost
    global static void handlePost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.statusCode = 200;

        Map<String, String> headers = req.headers;
        String httpMethod           = req.httpMethod;
        String remoteAddress        = req.remoteAddress;
        String requestURI           = req.requestURI;
        String resourcePath         = req.resourcePath;
        Map<String, String> params  = req.params;   //used by events
        String body                 = req.requestBody?.toString(); //used by URL verification / challenge

        Map<String, Object> bodyMap = new Map<String, Object>();
        try {
            bodyMap = (Map<String, Object>)JSON.deserializeUntyped(body);
        } catch (Exception e){
        }
        System.debug('--------------------');
        System.debug('appId: ' + params.get('api_app_id'));
        System.debug('--------------------');

        Slack_App__mdt config = [SELECT App_Id__c, Client_Id__c, Client_Secret__c, Signing_Secret__c, Verification_Token__c, SlashCommandAnswer__c FROM Slack_App__mdt LIMIT 1][0];
        Long reqTimestamp = headers.containsKey('X-Slack-Request-Timestamp') ? Long.valueOf(headers.get('X-Slack-Request-Timestamp')) : null;
        String slackSignature = headers.containsKey('X-Slack-Signature') ? headers.get('X-Slack-Signature') : null;

        SlackRequestValidator.ValidationResponse vr = SlackRequestValidator.validateRequest(config.Signing_Secret__c, body, reqTimestamp, slackSignature);

        String outerEventType = '';
        if (bodyMap.containsKey('type')) {
            outerEventType = (String)bodyMap.get('type');
        }
        else if (params.containsKey('command')) {
            outerEventType = params.get('command');
        }

        String innerEventType = '';
        String subtype = '';
        if (bodyMap.containsKey('event')) {
            Map<String, Object> eventObj = (Map<String, Object>)bodyMap.get('event');
            innerEventType = (String)eventObj.get('type');
            if (eventObj.containsKey('subtype')) {
                subtype = (String)eventObj.get('subtype');
            }
        }

        insert new Slack_Payload__c(
            Calculated_Signature__c                 = vr.calculatedSignature,
            Signed_Request_Verification_Passed__c   = vr.isValid,
            Verification_Failure__c                 = vr.failureType,
            Outer_Event__c  = outerEventType,
            Inner_Event__c  = innerEventType,
            Subtype__c      = subtype,
            Headers__c      = (headers != null) ? JSON.serializePretty(headers) : null,
            HTTP_Method__c  = httpMethod,
            Remote_IP__c    = remoteAddress,
            Request_URI__c  = requestURI,
            Path__c         = resourcePath,
            Params__c       = (params != null) ? JSON.serializePretty(params) : null,
            Raw_Body_Hex__c = (req.requestBody) != null ? EncodingUtil.convertToHex(req.requestBody) : null,
            Raw_Body__c     = body,
            Body__c         = (!bodyMap.keySet().isEmpty()) ? JSON.serializePretty(bodyMap) : null
        );

        if (!vr.isValid) {
            //failed signature validation, possible hacking attempt
            res.statusCode = 401;
            return;
        }

        switch on outerEventType {
            when 'url_verification' {
                //first time setting up an Events Endpoint, this gets invoked to make sure it's legit
                urlVerification(res, bodyMap);
            }
            when '/sick' {
                String triggerId = (String)params.get('trigger_id');
                SlackWebAPI.openDialog(triggerId);
                res.statusCode = 200;
            }
            when '/sick3' {
                RolandSlackAPI.execute(params);
                res.statusCode = 200;
            }
            when '/sick2' {
                String triggerId = (String)params.get('trigger_id');

                Map<String, Object> dialogMap = new Map<String, Object>{
                    'dialog' => new Map<String, Object>{
                        'callback_id' => 'date_and_sickness_test',
                        'title' => 'Childcare Request',
                        'submit_label' => 'Submit',
                        'elements' => new List<Map<String, Object>>{
                            new Map<String, Object>{
                                'label' => 'Select Date',
                                'type' => 'datepicker',
                                'name' => 'selected_date',
                                'placeholder' => 'Select a date'
                            },
                            new Map<String, Object>{
                                'label' => 'Is Child Sick?',
                                'type' => 'select',
                                'name' => 'is_child_sick',
                                'options' => new List<Map<String, Object>>{
                                    new Map<String, Object>{
                                        'label' => 'Yes',
                                        'value' => 'yes'
                                    },
                                    new Map<String, Object>{
                                        'label' => 'No',
                                        'value' => 'no'
                                    }
                                },
                                'placeholder' => 'Select an option'
                            }
                        }
                    }
                };

                Map<String, Object> jsonMap = new Map<String, Object>{
                    'trigger_id' => triggerId, // Replace with the actual trigger ID
                    'dialog' => dialogMap
                };

                String jsonString = JSON.serialize(jsonMap);
                jsonString = '{"blocks":[{"type": "section","text": {"type": "mrkdwn","text": "*Its 80 degrees right now.*"}},{"type": "section","text": {"type": "mrkdwn","text": "Partly cloudy today and tomorrow"}}]}';
                res.responseBody = Blob.valueOf(jsonString);
                res.addHeader('Content-type','application/json');
                //res.headers = new Map<String, String> { => };
                res.statusCode = 200;
            }
        }
    }

    public static void urlVerification(RestResponse res, Map<String, Object> bodyParams) {
        //echo back the challenge value from the parameters in the body
        res.addHeader('Content-Type', 'application/json');
        res.responseBody = Blob.valueOf((String)bodyParams.get('challenge'));
    }

    public static void eventHandler(String body, String eventType) {
        Set<String> eventsToHandle = new Set<String>{
            'message'
        };

        if (eventsToHandle.contains(eventType)) {
            SlackWebAPI.replyToMessage('C05S2PX0ETZ', '1694786175.908959', 'test answer');
        }
    }
}