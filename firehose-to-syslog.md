cloud foundry의 loggregator에서 수집한 메트릭, 이벤트, 로그는 firehose를 통해 수집할 수 있습니다. 
(Nozzles are programs which consume data from the Loggregator Firehose. Nozzles can be configured to select, buffer, and transform data, and forward it to other applications and services. Example nozzles include the following)
1) The Datadog nozzle, which publishes metrics coming from the Firehose to Datadog: https://github.com/cloudfoundry-incubator/datadog-firehose-nozzle
2) Syslog nozzle, which filters out log messages coming from the Firehose and sends it to a syslog server: https://github.com/cloudfoundry-community/firehose-to-syslog
nozzle을 구현하여 수집할 수 있으며 여기서는 두가지 방법으로 수집하는 방법을 설명합니다.



## cf nozzle plugin

https://docs.cloudfoundry.org/loggregator/cli-plugin.html#add
```
$ cf add-plugin-repo CF-Community https://plugins.cloudfoundry.org
$ cf install-plugin -r CF-Community "Firehose Plugin"
What type of firehose messages do you want to see?

Please enter one of the following choices:
	  hit 'enter' for all messages
	  4 for HttpStartStop
	  5 for LogMessage
	  6 for ValueMetric
	  7 for CounterEvent
	  8 for Error
	  9 for ContainerMetric
	> 6
Starting the nozzle
Hit Ctrl+c to exit
origin:"garden-linux" eventType:ValueMetric timestamp:1542179043567772223 deployment:"cf" job:"diego_cell" index:"49c828db-8e3e-4900-88bd-3cb0df62aac3" ip:"10.10.12.35" tags:<key:"source_id" value:"garden-linux" > valueMetric:<name:"memoryStats.numBytesAllocatedStack" value:1.1337728e+07 unit:"count" >  

origin:"garden-linux" eventType:ValueMetric timestamp:1542179043567849619 deployment:"cf" job:"diego_cell" index:"49c828db-8e3e-4900-88bd-3cb0df62aac3" ip:"10.10.12.35" tags:<key:"source_id" value:"garden-linux" > valueMetric:<name:"memoryStats.numFrees" value:3.6428645e+07 unit:"count" >  
```


## 
