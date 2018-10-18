# PAS에 애플리케이션 배포 절차 

### cf push 절차 다이어그램
![cf push절차](https://docs.pivotal.io/pivotalcf/2-2/concepts/images/app_push_flow_diagram_diego.png)

### Diego Architecture
![Diego Architecture](https://docs.pivotal.io/pivotalcf/2-2/concepts/images/diego/diego-flow-other.png)

## 설명 
0. cf push명령으로 application 배포요청(https통신)
1. Cloud Controller컴포넌가 요청을 받아 Diego Brain컴포넌트에게 애플리케이션 스테이징(droplet을 빌드하는 작업)을하도록 요청.
2. Diego Brain컴포넌트은 요청을 해석하여 Task와 LRP로 구분하고 BBS컴포넌트에게 요청

* LRP(LongRunningProcess): 애플리케이션 처럼 지속적으로 떠있어야하는 프로세스<br>
* Task: 실행했다가 종료되는일회성 프로세스

3. BBS컴포넌트는  Diego Brain컴포넌트 내의 Auctioneer프로세스에게 Task와 LRP요청을 전달
4. Auctioneer프로세스는 Auction알고리즘에 따라 낙찰된 Cell에 요청

*  Auction알고리즘: https://docs.pivotal.io/pivotalcf/2-2/concepts/diego/diego-auction.html

5. Diego Brain컴포넌트내의 Executor프로세스는 Garden 컨테이너를 생성
6. BBS컴포넌트는 Garden 컨테이너의 상태를 주기적으로 체크하여 가용성을 유지
7. Cell컴포넌트내의 Metron Agent프로세스는 Garden 컨네이네에서 발생되는 모든 로그, 메트릭을 Loggregator아키텍처에 전달
8. Cell컴포넌트내의 route-emitter는애플리케이션의 도메인URL과 Diego 컨테이너의 IP정보를 goRouter컴포넌트에 등록하여 서비스로 노출.

# 참고
- 아래 경로의 다이어그램은 클릭하시면 해당 도움말 페이지로 이동하는 다이어그램입니다.
<br> http://htmlpreview.github.io/?https://raw.githubusercontent.com/cloudfoundry/diego-design-notes/master/clickable-diego-overview/clickable-diego-overview.html)

- cf push절차: https://docs.pivotal.io/pivotalcf/2-2/concepts/how-applications-are-staged.html
- PCF 컴포넌트 아키텍처: https://docs.pivotal.io/pivotalcf/2-2/concepts/diego/diego-architecture.html
- container allocation process: https://docs.pivotal.io/pivotalcf/2-2/concepts/diego/diego-auction.html
