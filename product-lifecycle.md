

## 버전 체계
```
ex) v2.3.0

첫번째 자리: major 
두번째 자리: minor > major와 minor는 동일하게 취급하고 이 것이 변경되면 서로 호환이 안되는 breaking change를 의미함. 예를 들어, v2.2.0와 v2.3.0은 호환되지 않음.
세번째 자리: patch > patch 내에서는 아키텍처 변경이 없으므로 서로 호환된다. v2.3.0, v2.3.3는 서로 호환됨.
```

## PCF 기술지원 라이프사이클 정책
https://pivotal.io/support/lifecycle_policy
### General Support Phase: 
Major and Minor Releases는 동일한  General Support 기간을 가짐, GA날짜 이후부터 9개월 동안 General Support함.(N, N-1, and N-2 Releases (N은 최근 major,minor release버전))
- Maintenance updates and upgrades
- New security patches
- New bug fixes
- New hardware support
- Server, Client, and Guest OS updates
- Technical Guidance Phase 내용 포함.


### Technical Guidance Phase:
- Workarounds for non-business critical issues
