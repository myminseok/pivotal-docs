
script [fetch_diegocell_apps.sh](fetch_diegocell_apps.sh) will fetch all app list running on each diegocell VM under the given deployment.
tested on TAS 4.x

### how to run
1. ssh into TAS opsmanager VM
2. check bosh command in alias that the script will use.
```
source ~/.profile
bosh env
bosh ds --column=Name
```

3. download the script and run with deployment name
```
./fetch_diegocell_apps.sh cf-edc5e09298dc349e5048
```
> it will list up diego_cells to temp file as `./tmp_diego_cell_ip_${DEPLOYMENT}.txt` and fetch apps list running on each diegocell and download as `diego_cell_cfdot_actual_lrps_${DEPLOYMENT}_${ip}.json` locally.

```
./diego_cell_cfdot_actual_lrps_cf-edc5e09298dc349e5048_10.1.2.3.json
./diego_cell_cfdot_actual_lrps_cf-edc5e09298dc349e5048_10.1.2.4.json
...
```

4. beautify the output with jq command
```
jq ".metric_tags| [.app_name, .space_name, .organization_name ]" ./diego_cell_cfdot_actual_lrps_cf-edc5e09298dc349e5048_10.1.2.3.json
```
```
...
[
  "spring",
  "EDU",
  "TEST_ORG"
]
[
  "gateway",
  "b2f9f392-561a-4d98-baa0-e55c2dac6b46",
  "p-spring-cloud-gateway-service"
]

```
