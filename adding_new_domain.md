1. 서비스용 신규 도메인을 DNS에 등록하고 PCF와 연결된 Load balancer에 메핑.
2. PCF에 신규 도메인을 등록하기
2-1. cf cli에 admin으로 로그인: cf login <br>
2-2. org, space 이동 <br>
2-3. cf create-shared-domain <신규도메인> <br>
3. apps manager에서 라우팅 추가

