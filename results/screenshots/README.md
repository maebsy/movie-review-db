# 실행 화면 스크린샷

**Q01~Q17 전체 쿼리**와 **무결성 시나리오 B07~B14** 를 sqlite3 CLI 에서 실제로 실행한 터미널 화면입니다(1차 9장 → 2차 Q01~Q17 · 오류 → 3차 B07~B14 · 엑셀 사례 추가). 각 결과 파일(`../Qnn.txt`) 머리의 `screenshot:` 줄과 [`results/README.md`](../README.md) 의 쿼리별 절에서도 바로 연결됩니다. 텍스트 결과(`../Qnn.txt`)와 같은 쿼리를 같은 시드 데이터에서 실행했으므로, 각 행의 값은 텍스트 결과와 같습니다.

| 화면 | 분류 | 확인할 점 | 텍스트 결과 |
| --- | --- | --- | --- |
| [Q01.png](Q01.png) | 기본 조회 | 2020년 이후 개봉작을 최신순으로 | [Q01.txt](../Q01.txt) |
| [Q02.png](Q02.png) | 기본 조회 | 별점 5점 리뷰 중 최근 5개 (`LIMIT`) | [Q02.txt](../Q02.txt) |
| [Q03.png](Q03.png) | 기본 조회 | 러닝타임 150분 이상 | [Q03.txt](../Q03.txt) |
| [Q04.png](Q04.png) | 기본 조회 | 제목에 '의' 가 들어간 영화 (`LIKE`) | [Q04.txt](../Q04.txt) |
| [Q05.png](Q05.png) | 조인 (INNER) | 3개 테이블 조인 — 짝이 있는 리뷰만, 별점만 남긴 리뷰는 `(별점만 남김)` | [Q05.txt](../Q05.txt) |
| [Q06.png](Q06.png) | 조인 (INNER) | 장르명과 영화 — 영화 없는 '뮤지컬' 은 빠짐 | [Q06.txt](../Q06.txt) |
| [Q07.png](Q07.png) | 조인 (LEFT) | 리뷰가 없는 회원 3명 (`review_id IS NULL`) | [Q07.txt](../Q07.txt) |
| [Q08.png](Q08.png) | 조인 (LEFT) | 영화별 리뷰 수, 리뷰 없는 2편은 0 · LEFT JOIN 의 NULL 을 COALESCE 로 `리뷰 없음` · `-` 표시 | [Q08.txt](../Q08.txt) |
| [Q09.png](Q09.png) | 집계 | `HAVING COUNT(*) >= 3` 평균 별점 TOP 5 | [Q09.txt](../Q09.txt) |
| [Q10.png](Q10.png) | 집계 | 장르별 영화 수 · 리뷰 수 · 평균 (뮤지컬 0 · NULL) | [Q10.txt](../Q10.txt) |
| [Q11.png](Q11.png) | 집계 | 회원별 리뷰 수 · 평균 · 총 관람 시간(`SUM`) | [Q11.txt](../Q11.txt) |
| [Q12.png](Q12.png) | 집계 (추가) | 월별 리뷰 수와 평균 (`strftime`) | [Q12.txt](../Q12.txt) |
| [Q13.png](Q13.png) | 서브쿼리 | 전체 평균 4.17 보다 높은 영화 | [Q13.txt](../Q13.txt) |
| [Q14.png](Q14.png) | 서브쿼리 (추가) | 중간 결과(드라마: 서울의 봄 kept 1 · 기생충 kept 0) → 장르별 1위 11행 | [Q14.txt](../Q14.txt) |
| [Q15.png](Q15.png) | 수정 (UPDATE) | 변경 전 대상 회원 → UPDATE → 상태별 회원 수 | [Q15.txt](../Q15.txt) |
| [Q16.png](Q16.png) | 삭제 (DELETE) | 탈퇴 회원 삭제 후 리뷰 78 → 76, 고아 리뷰 0 | [Q16.txt](../Q16.txt) |
| [Q17.png](Q17.png) | 인덱스 | 생성 전 `SCAN review` · JOIN `USE TEMP B-TREE` → 생성 후 `SEARCH … USING INDEX` | [Q17.txt](../Q17.txt) |
| [ERR.png](ERR.png) | 오류 재현 | FK 꺼짐/켬, RESTRICT, CHECK, UNIQUE, NOT NULL 오류 원문 | [docs/bonus.md](../../docs/bonus.md#실제로-겪은-오류-메시지-sqlite3-cli-원문) |

## 무결성(FK · CHECK · UNIQUE · NOT NULL) 시나리오 — B07~B14

스키마의 제약이 실제로 동작하는지 [`sql/05_bonus_integrity.sql`](../../sql/05_bonus_integrity.sql) 의 시도를 블록마다 새 시드 DB 에서 sqlite3 CLI 로 실행한 화면입니다(3차 동료 평가 "FK 작동을 입증하는 실행 검증 미제출" 반영). 각 `../Bnn.txt` 셋째 줄에도 화면 경로가 있습니다.

| 화면 | 시나리오 | 실제 출력 | 텍스트 결과 |
| --- | --- | --- | --- |
| [B07.png](B07.png) | FK: 없는 회원(999)의 리뷰 INSERT | `Runtime error: FOREIGN KEY constraint failed (19)` | [B07.txt](../B07.txt) |
| [B08.png](B08.png) | FK: 없는 장르(99)로 영화 INSERT | `FOREIGN KEY constraint failed` | [B08.txt](../B08.txt) |
| [B09.png](B09.png) | ON DELETE RESTRICT: 영화 4편이 있는 '액션' 삭제 → 거부, 빈 '뮤지컬' → 삭제 | `FOREIGN KEY constraint failed` 후 다음 DELETE 는 성공 | [B09.txt](../B09.txt) |
| [Q16.png](Q16.png) | ON DELETE CASCADE: 탈퇴 회원 삭제 → 리뷰 78 → 76, 고아 0 | `member_count 14 · review_count 76 · orphan_reviews 0` | [Q16.txt](../Q16.txt) |
| [B10.png](B10.png) | CHECK: 별점 6 · 2024-02-30 · 2024-13-01 · 상태 BANNED | `CHECK constraint failed: …` 4번 | [B10.txt](../B10.txt) |
| [B11.png](B11.png) | UNIQUE: 같은 회원·영화 두 번째 리뷰 · 중복 이메일 | `UNIQUE constraint failed: …` 2번 | [B11.txt](../B11.txt) |
| [B12.png](B12.png) | NOT NULL: 제목 없는 영화 | `NOT NULL constraint failed: movie.title` | [B12.txt](../B12.txt) |
| [B13.png](B13.png) | FK 검사를 끄면: 고아 리뷰 900 이 들어가고 `foreign_key_check` 가 찾아냄 → 삭제 후 0건 | `review \| 900 \| member \| 1` | [B13.txt](../B13.txt) |
| [B14.png](B14.png) | 해결: 부모(회원 16) → 자식(리뷰), 한 트랜잭션 | 리뷰 1행 조회 성공 | [B14.txt](../B14.txt) |

## 엑셀 한 시트 방식의 문제 — [EXCEL.png](EXCEL.png)

같은 상황을 엑셀 호환 스프레드시트(LibreOffice Calc 24.2)에서 실제로 계산한 화면입니다. 리뷰 시트의 닉네임을 `VLOOKUP` 으로 회원 시트에서 가져오게 하고, 회원 시트에서 2번 행을 지우면 경고 없이 지워지고 리뷰 2 · 4 가 `#N/A` 가 됩니다. 별점 칸의 `다섯` · `6` 도 그대로 들어갑니다. 재현 파일과 재계산 결과(CSV): [`excel/`](excel/) (생성: `excel/make.py`, 컨테이너: `excel/Dockerfile`).

## 어떻게 찍었나

1. 화면마다 `sql/01_schema.sql` → `sql/02_seed.sql` 로 새 `movie_review.db` 를 만듭니다. Q15·Q16 이 데이터를 바꾸므로 화면끼리 영향을 주지 않게 했습니다.
2. 가상 터미널(pty, `script` 명령)에서 `bash` 를 띄우고 `sqlite3 -header -separator ' | ' movie_review.db` 를 실행한 뒤, `03_queries.sql` 의 문장을 한 줄씩 입력했습니다. 입력할 때 줄 끝 주석과 정렬용 공백은 뺐습니다. 파일 첫 줄과 같이 `PRAGMA foreign_keys = ON;` 을 먼저 실행합니다. 오류 화면만 FK 가 꺼진 기본 상태에서 시작합니다.
3. 녹화한 터미널 출력(이스케이프 시퀀스 포함 원본 바이트)을 터미널 에뮬레이터 xterm.js 로 재생해 PNG 로 저장했습니다. 글꼴은 D2Coding 입니다.

- 환경: Ubuntu, sqlite3 CLI 3.46.1, 2026-11-10 촬영 (Q14 · Q17 은 중간 결과 · 인덱스 전 JOIN 계획이 추가된 SQL 그대로)
- `-box`/`-column` 모드 대신 목록 모드(` | ` 구분)를 쓴 이유: sqlite3 3.46.1 CLI 는 표의 칸 너비를 **글자 수**로 계산합니다. 화면에서 두 칸을 차지하는 한글이 들어간 행은 테두리가 어긋납니다. 칸을 맞춘 표는 `run_all.py` 가 표시 너비로 정렬해 기록한 텍스트 결과를 보면 됩니다.
