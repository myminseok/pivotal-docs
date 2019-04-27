
# Install Event alert && setup alerts 

# Ref
https://docs.pivotal.io/event-alerts/1-2/index.html

## install 
- https://docs.pivotal.io/event-alerts/1-2/installing.html#install

### Prerequisites
https://docs.pivotal.io/event-alerts/1-2/installing.html#prereqs
- MySQL for PCF v2 
- Healthwatch for PCF
- SMTP for email notification
- webook (optional)
- slack (optional)

# after installation

### install cf plugin
- https://docs.pivotal.io/event-alerts/1-2/installing.html#plugin
```

1) download plugin from network.pivotal.io in event alert product.

2) cf install-plugin ~/Downloads/macosx64-1.1.1

3)  cf plugins
Listing installed plugins...

plugin               version   command name         command help
event-alerts         1.1.1     eva-api              Displays the version of the Event Alerts API server
event-alerts         1.1.1     eva-create-target    Creates a target
event-alerts         1.1.1     eva-delete-target    Deletes a target
event-alerts         1.1.1     eva-publishers       Displays a list of Publishers
event-alerts         1.1.1     eva-sample-publish   Publishes a sample event to all subscribers of the specified topic. This requires a UAA notification.write scope.
event-alerts         1.1.1     eva-smoke            Runs smoke test against event-alerts
event-alerts         1.1.1     eva-subscribe        Subscribes to topics for a publisher
event-alerts         1.1.1     eva-subscriptions    Displays a list of Subscriptions
event-alerts         1.1.1     eva-targets          Displays a list of Targets
event-alerts         1.1.1     eva-topics           Displays a list of Topics
event-alerts         1.1.1     eva-unsubscribe      Unsubscribes from all topics for a publisher
event-alerts         1.1.1     eva-update-target    Updates a target name
```

### subscribing alert to email.

https://docs.pivotal.io/event-alerts/1-2/using.html#email_targets

```
# create email subscription target:
cf eva-create-target my-test-email email <EMAIL-ADDRESS>

# subscribe alert:
cf eva-subscribe my-test-email healthwatch --all

Subscribing target 'my-test-email' to topics for publisher 'healthwatch' as mkim...
FAILED
Unable to subscribe:
the target 'my-test-email' has not yet been verified

=> go to your <EMAIL-ADDRESS> and confirm 

# subscribe topics:
cf eva-subscribe my-test-email healthwatch --all
Subscribing target 'my-test-email' to all topics for publisher 'healthwatch' as mkim...
OK
'my-test-email' is now subscribed to all 'healthwatch’ topics

# fire sample topics
cf eva-sample-publish healthwatch rep.unhealthycell

=> go to your <EMAIL-ADDRESS> and check notification.

# unsubscribe 
cf eva-unsubscribe my-test-email healthwatch  —all

```

### list topics to subscribe

```
$ cf eva-topics
Getting topics as admin...
OK
Publisher      Topic                            Description
healthwatch    system.mem.percent               VM Memory Used
healthwatch    system.cpu.user                  VM CPU Utilization
healthwatch    system.disk.persistent.percent   VM Persistent Disk Used
healthwatch    system.disk.ephemeral.percent    VM Ephemeral Disk Used
healthwatch    system.disk.system.percent       VM Disk Used
healthwatch    system.healthy                   VM Health Check
```

### subscribing specific topics to email.

```

cf eva-subscribe my-test-email healthwatch --topics healthwatch.diego.totalpercentageavailablediskcapacity.5m
Subscribing target 'my-test-email' to topics for publisher 'healthwatch' as mkim...
OK
'my-test-email' is now subscribed to 'healthwatch' topics:
- healthwatch.diego.totalpercentageavailablediskcapacity.5m


cf eva-unsubscribe my-test-email healthwatch --topics healthwatch.diego.totalpercentageavailablediskcapacity.5m



```
