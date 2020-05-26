
## architecture
- https://docs.pivotal.io/platform/application-service/2-9/metric-registrar/index.html


## sample app(local test)
```
git clone https://github.com/pivotal-cf/metric-registrar-examples
cd java-spring-security
./gradlew bootRun
```
open https://localhost:8080
open https://localhost:8080/actuator/prometheus

## push to TAS
- guide: https://docs.pivotal.io/platform/application-service/2-9/metric-registrar/using.html#overview
```
./gradlew assemble
cf push
```
## register metric endpoint
```
## cf install-plugin -r CF-Community "metric-registrar"

cf register-metrics-endpoint my-app /actuator/prometheus
```

## verify registered metric
```
cf install-plugin -r CF-Community "log-cache"

## cf tail --envelope-class=metrics APP-NAME 
cf tail --envelope-class=gauge  my-app -f | grep custom

## refresh my-app
curl https://my-app.run.pivotal.io?inc=1

cf tail -t gauge  my=app -f | grep custom

   2020-05-26T23:41:12.00+0900 [mkim-java-metric-registrar-demo/0] GAUGE custom:35.000000
   2020-05-26T23:41:41.97+0900 [mkim-java-metric-registrar-demo/0] GAUGE custom:35.000000
   2020-05-26T23:42:12.00+0900 [mkim-java-metric-registrar-demo/0] GAUGE custom:35.000000
   2020-05-26T23:43:11.95+0900 [mkim-java-metric-registrar-demo/0] GAUGE custom:37.000000
   2020-05-26T23:43:41.96+0900 [mkim-java-metric-registrar-demo/0] GAUGE custom:37.000000

```


## register custom metric to apps-metric(indicator-documents)
- https://docs.pivotal.io/app-metrics/2-0/indicator-document-reference.html


custom_indicators.yml
```
---
apiVersion: indicatorprotocol.io/v1
kind: IndicatorDocument

metadata:
  labels:
    deployment: "my deployment name"

spec:
  product:
    name: APJ,development,mkim-java-metric-registrar-demo      <===== org,space,app-name
    version: 0.0.1

  indicators:
    - name: Custom
      promql: "sum(custom{source_id='$sourceId'})"               <===== metric name
      documentation:
        title: "Custom Metric"
      presentation:
        units: "counts"
```

```
## curl -vvv https://metrics.sys.DOMAIN/indicator-documents -H "Authorization: $(cf oauth-token)" --data-binary "@[YourDoc.yml]"
curl -vvv https://metrics.run.pivotal.io/indicator-documents -H "Authorization: $(cf oauth-token)"  --data-binary  "@custom_indicators.yml"
```

## apps-metric UI
- now you can see the custom metric
