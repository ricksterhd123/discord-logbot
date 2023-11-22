# discord-logbot

This is a simple script which publishes player events to discord channel via webhook.
It also exports a server-side function `outputDiscordLog` for use in other scripts with custom events etc.

## Getting Started

1. Get discord webhook URL on desired channel (Click on Channel Settings -> Integrations -> Webhooks -> Create Webhook)

2. Paste the discord webhook URL in the meta.xml settings

```xml
...
<setting 
    name="*WebhookURL" 
    value="PUT_WEBHOOK_URL_HERE"
    desc="Discord webhook URL"
/>
...
```

3. Do you have any keywords you would like to censor? Set censored words here, e.g.

```xml
...
<setting 
    name="*CensoredWords" 
    value="fuck, shit"
    desc="A list of words, e.g. 'fuck, shit' which get censored e.g. '****, ****' before sent to discord"
/>
...
```

4. Place resource in server `resources` folder and start the resource
