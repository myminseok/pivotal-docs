refer to: https://community.pivotal.io/s/article/How-to-Enable-Advanced-Mode-in-the-Ops-Manager?language=en_US

## using Curl

First, we want to get an access token with User Account and Authentication (UAA). You can do that with this command.
```
curl -s -k -H 'Accept: application/json;charset=utf-8' -d 
'grant_type=password' -d 'username=<your-username>' -d 
'password=<your-pass>' -u 
'opsman:' https://<fqdn for your om>/uaa/oauth/token
 ```
The output of this will be a simple JSON dictionary and will have six keys. Look for the key named access token. Copy the value to your clipboard.

Second, we can run one of the following commands to enable, disable, or check the status of advanced mode.

To enable advanced mode, run this command.
```
curl -s -k -H 'Accept: application/json;charset=utf-8' -H "Content-Type: application/json" -H 'Authorization: bearer <access-token>' https://<fqdn for your om>/api/v0/staged/infrastructure/locked -X PUT --data '{"locked" : "false"}'
```
To check if the advanced mode is enabled, run this command:
```
curl -s -k -H 'Accept: application/json;charset=utf-8' -H 'Authorization: bearer <access-token>' https://<fqdn for your om>/api/v0/staged/infrastructure/locked
```
> The output will indicate "true" if Ops Manager is locked and advanced mode is disabled or it will indicate "false" Ops Manager is not locked and advanced mode is enabled.
To disable advanced mode, run this command:
```
curl -s -k -H 'Accept: application/json;charset=utf-8' -H "Content-Type: application/json" -H 'Authorization: bearer <access-token>' https://<fqdn for your om>/api/v0/staged/infrastructure/locked -X PUT --data '{"locked" : "true"}'
```

## using UAAC

When you have the UAA Command Line Interface (UAAC) utility installed, you can also use that to enable and disable advanced mode.  The process is similar.

1. Target UAA on Ops Manager. Run the following:
```
uaac target https://<fqdn for your om>/uaa
uaac token owner get
```
2. When prompted, enter the client name as "opsman", leave the client secret blank, enter your username and password (the same as what you use to log on to the Ops Manager UI).

3. Now you can enable, disable, and check the status of advanced mode with the following commands. To enable advanced mode, run the following:
```
uaac curl https://<fqdn for your om>/api/v0/staged/infrastructure/locked -X PUT --data '{"locked" : "false"}' -H "Content-Type: application/json"
```
4. To check the status of advanced mode, run the following:
```
uaac curl https://<fqdn for your om>/api/v0/staged/infrastructure/locked
```
5. To disable advanced mode, run the following:
```
uaac curl https://<fqdn for your om>/api/v0/staged/infrastructure/locked -X PUT --data '{"locked" : "true"}' -H "Content-Type: application/json"
```
