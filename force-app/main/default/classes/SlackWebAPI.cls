public with sharing class SlackWebAPI {

    static final String SLACK_BASE_URL = 'https://slack.com/api';
    static final String BOT_TOKEN = [SELECT Bot_Token__c FROM Slack_App__mdt LIMIT 1][0].Bot_Token__c;


    public static void postMessage(String channelId, String text) {
        //docs: https://api.slack.com/messaging/sending#conversations
        Map<String, Object> bodyMap = new Map<String, Object>{
            'channel'   => channelId,
            'text'      => text
        };
        doHttpPost('/chat.postMessage', JSON.serialize(bodyMap));
    }
/*
    public static void postMessage(String channelId, String text, SlackBlockKit.Layout layout) {
        //docs: https://api.slack.com/messaging/sending#conversations
        Map<String, Object> bodyMap = new Map<String, Object>{
                'channel'   => channelId,
                'text'      => text,
                'blocks'    => JSON.deserializeUntyped(JSON.serialize(layout.blocks, true)) //need to suppress the nulls or get slack error
        };
        doHttpPost('/chat.postMessage', JSON.serialize(bodyMap));
    }
*/
    public static void replyToMessage(String channelId, String threadTS, String text) {
        //docs: https://api.slack.com/messaging/sending#conversations
        Map<String, Object> bodyMap = new Map<String, Object>{
            'channel'   => channelId,
            'thread_ts' => threadTS,
            'text'      => text
        };
        doHttpPost('/chat.postMessage', JSON.serialize(bodyMap));
    }

    public static void addReaction(String channelId, String messageTS, String emojiName) {
        //docs: https://api.slack.com/messaging/sending#conversations
        Map<String, Object> bodyMap = new Map<String, Object>{
            'channel'   => channelId,
            'timestamp' => messageTS,
            'name'      => emojiName
        };
        doHttpPost('/reactions.add', JSON.serialize(bodyMap));
    }

    public static void openDialog2(String triggerId) {
        //docs: https://api.slack.com/messaging/sending#conversations
        // Map<String, Object> bodyMap = new Map<String, Object>{
        //     'channel'   => channelId,
        //     'timestamp' => messageTS,
        //     'name'      => emojiName
        // };
        // String triggerId = 'your_trigger_id_value'; // Replace this with your actual trigger ID

        Map<String, Object> jsonMap = new Map<String, Object>();
        jsonMap.put('trigger_id', triggerId);

        Map<String, Object> dialogMap = new Map<String, Object>();
        dialogMap.put('callback_id', 'ryde-46e2b0');
        dialogMap.put('title', 'Request a Fly');
        dialogMap.put('submit_label', 'Request');
        dialogMap.put('notify_on_cancel', true);
        dialogMap.put('state', 'Limo');

        List<Map<String, Object>> elementsList = new List<Map<String, Object>>();

        Map<String, Object> pickupLocationMap = new Map<String, Object>();
        pickupLocationMap.put('type', 'text');
        pickupLocationMap.put('label', 'Pickup ist immer gut');
        pickupLocationMap.put('name', 'loc_origin');

        Map<String, Object> dropoffLocationMap = new Map<String, Object>();
        dropoffLocationMap.put('type', 'text');
        dropoffLocationMap.put('label', 'Dropoff Location');
        dropoffLocationMap.put('name', 'loc_destination');

        elementsList.add(pickupLocationMap);
        elementsList.add(dropoffLocationMap);

        dialogMap.put('elements', elementsList);
        jsonMap.put('dialog', dialogMap);

        String jsonString = JSON.serialize(jsonMap);
        doHttpPost('/dialog.open', jsonString);
    }

    public static void openDialog(String triggerId) {

        Map<String, Object> dialogMap = new Map<String, Object>();
        dialogMap.put('dialog', new Map<String, Object>{
        'callback_id' => 'child_sickness',
        'title' => 'Childcare Request',
        'submit_label' => 'Submit2',
        'elements' => new List<Map<String, Object>>{
            new Map<String, Object>{
                'type' => 'text',
                'label' => 'Child Name',
                'name' => 'child_name',
                'placeholder' => 'Enter child name'
            },
            new Map<String, Object>{
                'type' => 'select',
                'label' => 'Is Child Sick?',
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
    });
        

    dialogMap.put('trigger_id', triggerId);

        String jsonString = JSON.serialize(dialogMap);
        doHttpPost('/dialog.open', jsonString);
    }
/*
    public static void openView(String triggerId, SlackBlockKit.View modal) {
        //docs: https://api.slack.com/surfaces/modals/using
        Map<String, Object> bodyMap = new Map<String, Object>{
            'trigger_id'    => triggerId,
            'view'          => JSON.deserializeUntyped(JSON.serialize(modal, true)) //need to suppress the nulls or get slack error
        };
        doHttpPost('/views.open', JSON.serialize(bodyMap));
    }

    public static void publishView(String userId, SlackBlockKit.View view) {
        //docs: https://api.slack.com/surfaces/modals/using
        Map<String, Object> bodyMap = new Map<String, Object>{
            'user_id'   => userId,
            'view'      => JSON.deserializeUntyped(JSON.serialize(view, true)) //need to suppress the nulls or get slack error
        };
        doHttpPost('/views.publish', JSON.serialize(bodyMap));
    }

    public static void publishView(String userId, String view) {
        //docs: https://api.slack.com/surfaces/modals/using
        Map<String, Object> bodyMap = new Map<String, Object>{
                'user_id'   => userId,
                'view'      => JSON.deserializeUntyped(view)
        };
        doHttpPost('/views.publish', JSON.serialize(bodyMap));
    }
*/
    @future(callout=true)
    public static void doHttpPost(String path, String body) {
        System.debug('doHttpPost path: ' + path);
        System.debug('doHttpPost body: ' + body);
        HttpRequest req = new HttpRequest();
        req.setEndpoint(SLACK_BASE_URL+path);
        req.setMethod('POST');
        req.setHeader('Content-type', 'application/json');
        req.setHeader('Authorization', 'Bearer ' + BOT_TOKEN);
        req.setBody(body);

        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug('res.getBody(): ' + res.getBody());
    }
}