# pivotaltracker와 gitlab의 연동

## 연동 설정 방법
1. www.pivotaltracker.com에 로그인
1. 오른쪽 상단에 내 계정>profile으로 이동하여 API Token항목에서 token을 복사
1. gitlab에서 pivotal tracker와 연동하고자하는 프로젝트로 이동합니다.
1. 프로젝트> settings> integrations탭으로 이동하여 pivotaltracker항목을 클릭
1. active항목을 체크, token을 입력하고 저장후 test를 클릭. 에러가 없어야함.


## 사용방법
gitlab의 commit로그에 tracer id 를 넣어주면 git에 push할 때 commit로그가 pivotal tracer의 story의  activity에  연동됩니다.
~~~
git commit -m "[finishes #123123] Updated settings for holograph projector"
~~~


## 특히 commit-log에 Finishes|Fixes|Delivers 단어를 입력하면 tracer story의 상태를 변경할 수 있습니다.
~~~
[(Finishes|Fixes|Delivers) #TRACKER_STORY_ID]
~~~

참고:https://www.pivotaltracker.com/help/articles/github_integration/
