
## Architecture
https://techdocs.broadcom.com/us/en/vmware-tanzu/platform/elastic-application-runtime/10-2/eart/metric-registrar-index.html


## Sample app(local test)

connect https://start.spring.io

and add depencency 
```
<dependencies>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-actuator</artifactId>
		</dependency>
		<dependency>
			<groupId>org.springframework.boot</groupId>
			<artifactId>spring-boot-starter-webmvc</artifactId>
		</dependency>
	   <dependency>
			<groupId>io.micrometer</groupId>
			<artifactId>micrometer-registry-prometheus</artifactId>
			<scope>runtime</scope>
		</dependency>
```

application.yml

```
management:
  endpoints:
    web:
      exposure:
        include: "*"
  endpoint:
    health:
      show-details: always

```

ref: https://github.com/pivotal-cf/metric-registrar-examples

run app locally.

```
cd java-spring-security
./gradlew bootRun
./mvnw spring-boot:run
```

open http://localhost:8080/actuator
open http://localhost:8080/actuator/prometheus

```
...
# HELP process_files_max_files The maximum file descriptor count
# TYPE process_files_max_files gauge
process_files_max_files 1048576.0
# HELP process_files_open_files The open file descriptor count
# TYPE process_files_open_files gauge
process_files_open_files 62.0
...
```


## Push to Tanzu platform

secure actuator endpoints by editing application.yml
```
management:
  endpoints:
    web:
      exposure:
        include: "health, info, prometheus"  # Expose only safe endpoints
  endpoint:
    health:
      show-details: "when_authorized" # Hide details for public access
```

rebuild and push
```
./gradlew assemble
cf push
```

open https://APP_DOMAIN/actuator/prometheus

```
...
# HELP process_files_max_files The maximum file descriptor count
# TYPE process_files_max_files gauge
process_files_max_files 16384.0
# HELP process_files_open_files The open file descriptor count
# TYPE process_files_open_files gauge
process_files_open_files 66.0
...
```


## Register the custom metric endpoint to platform 
```
## cf install-plugin -r CF-Community "metric-registrar"

cf register-metrics-endpoint actuator-test /actuator/prometheus --internal-port 8080

```


## Register custom metric on appmetric UI
add a chart by clicking "+" button. and add one of metric name from /actuator/prometneus endpoint into query.
```
process_files_open_file{source_id="$sourceId"}
```


## Reference

https://techdocs.broadcom.com/us/en/vmware-tanzu/platform/elastic-application-runtime/10-2/eart/metric-registrar-using.html

https://blogs.vmware.com/tanzu/out-of-the-box-application-observability-with-spring-boot-pivotal-cloud-foundry/
