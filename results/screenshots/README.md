# 실행 화면 스크린샷

주요 쿼리를 **sqlite3 CLI 에서 실제로 실행한 터미널 화면**입니다. 텍스트 결과(`../Qnn.txt`)와 같은 쿼리를 같은 시드 데이터에서 실행했으므로, 각 행의 값은 텍스트 결과와 같습니다.

| 화면 | 분류 | 확인할 점 | 텍스트 결과 |
| --- | --- | --- | --- |
| [Q01.png](Q01.png) | 기본 조회 | 2020년 이후 개봉작을 최신순으로 | [Q01.txt](../Q01.txt) |
| [Q05.png](Q05.png) | 조인 (INNER) | 3개 테이블 조인, 별점만 남긴 리뷰는 `(별점만 남김)` | [Q05.txt](../Q05.txt) |
| [Q07.png](Q07.png) | 조인 (LEFT) | 리뷰가 없는 회원 3명 (`review_id IS NULL`) | [Q07.txt](../Q07.txt) |
| [Q09.png](Q09.png) | 집계 | `HAVING COUNT(*) >= 3` 평균 별점 TOP 5 | [Q09.txt](../Q09.txt) |
| [Q13.png](Q13.png) | 서브쿼리 | 전체 평균 4.17 보다 높은 영화 | [Q13.txt](../Q13.txt) |
| [Q14.png](Q14.png) | 서브쿼리 (추가) | CTE + 상관 서브쿼리, 동점 포함 11행 | [Q14.txt](../Q14.txt) |
| [Q15.png](Q15.png) | 수정 (UPDATE) | 변경 전 대상 회원 → UPDATE → 상태별 회원 수 | [Q15.txt](../Q15.txt) |
| [Q16.png](Q16.png) | 삭제 (DELETE) | 탈퇴 회원 삭제 후 리뷰 78 → 76, 고아 리뷰 0 | [Q16.txt](../Q16.txt) |
| [Q17.png](Q17.png) | 인덱스 | `SCAN review` → `SEARCH review USING INDEX idx_review_movie_id` | [Q17.txt](../Q17.txt) |
| [ERR.png](ERR.png) | 오류 재현 | FK 꺼짐/켬, RESTRICT, CHECK, UNIQUE, NOT NULL 오류 원문 | [docs/bonus.md](../../docs/bonus.md#실제로-겪은-오류-메시지-sqlite3-cli-원문) |

## 어떻게 찍었나

1. 화면마다 `sql/01_schema.sql` → `sql/02_seed.sql` 로 새 `movie_review.db` 를 만듭니다. Q15·Q16 이 데이터를 바꾸므로 화면끼리 영향을 주지 않게 했습니다.
2. 가상 터미널(pty, `script` 명령)에서 `bash` 를 띄우고 `sqlite3 -header -separator ' | ' movie_review.db` 를 실행한 뒤, `03_queries.sql` 의 문장을 한 줄씩 입력했습니다. 입력할 때 줄 끝 주석과 정렬용 공백은 뺐습니다. 파일 첫 줄과 같이 `PRAGMA foreign_keys = ON;` 을 먼저 실행합니다. 오류 화면만 FK 가 꺼진 기본 상태에서 시작합니다.
3. 녹화한 터미널 출력(이스케이프 시퀀스 포함 원본 바이트)을 터미널 에뮬레이터 xterm.js 로 재생해 PNG 로 저장했습니다. 글꼴은 D2Coding 입니다.

- 환경: Ubuntu, sqlite3 CLI 3.46.1, 2026-11-09 촬영
- `-box`/`-column` 모드 대신 목록 모드(` | ` 구분)를 쓴 이유: sqlite3 3.46.1 CLI 는 표의 칸 너비를 **글자 수**로 계산합니다. 화면에서 두 칸을 차지하는 한글이 들어간 행은 테두리가 어긋납니다. 칸을 맞춘 표는 `run_all.py` 가 표시 너비로 정렬해 기록한 텍스트 결과를 보면 됩니다.
