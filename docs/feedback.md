# 동료 평가 반영 체크리스트

동료 평가 15개 항목(FAIL 2 · PASS 13)의 부족한 점과 보완 요청을 하나씩 반영한 기록입니다. 위치 링크는 반영한 파일·줄·절로 이어집니다.

| # | 평가 | 부족한 점 | 보완 요청 | 반영 내용 | 위치 |
| ---: | --- | --- | --- | --- | --- |
| 1 | PASS | 스키마 생성 순서의 이유와 스키마 버전·실행 순서가 파일에 드러나지 않음 | 생성 순서와 이유 주석 한 줄, 스키마 버전과 실행 순서 명확히 표기 | 머리 주석 2줄에 `v1.0` · `실행 순서 1/3: 01_schema → 02_seed → 03_queries` 를 넣음. 11줄에 생성 순서와 이유(자식의 FK 가 가리킬 부모를 먼저 만듦, MySQL·PostgreSQL 은 필수)를 적음. 12줄에는 DROP 을 반대 순서로 하는 이유(자식 행이 남은 부모를 DROP 하면 FK 오류)를 적음. 03 파일 머리에도 `실행 순서 3/3`. 기존 줄을 고쳐 줄 수는 그대로 | [`01_schema.sql:2`](../sql/01_schema.sql#L2) · [`01_schema.sql:11`](../sql/01_schema.sql#L11) · [`01_schema.sql:12`](../sql/01_schema.sql#L12) · [`03_queries.sql:2`](../sql/03_queries.sql#L2) |
| 2 | PASS | FK 마다 삭제 정책이 한눈에 보이지 않음 (`ON UPDATE`·NULL 여부 포함) | FK 줄마다 삭제 정책(ON DELETE 등) 주석 | FK 3개의 `REFERENCES` 줄 끝에 `NULL 불가 · 삭제 RESTRICT/CASCADE · 수정 CASCADE/NO ACTION(미지정)` 주석을 달고, `ON UPDATE CASCADE` 줄에도 동작을 설명함 | [`01_schema.sql:64`](../sql/01_schema.sql#L64) · [`01_schema.sql:65`](../sql/01_schema.sql#L65) · [`01_schema.sql:81`](../sql/01_schema.sql#L81) · [`01_schema.sql:84`](../sql/01_schema.sql#L84) |
| 3 | PASS | content 가 NULL 인 샘플 리뷰의 의도가 설명되지 않음 | README 에 NULL content(별점만 남긴 리뷰)의 의도 한 줄 | 리뷰 78개 중 content NULL 4개는 의도한 "별점만 남긴 리뷰"이고, Q05 에서 `COALESCE` 로 `(별점만 남김)` 을 표시한다는 문장을 추가함 (NULL 4개는 sqlite3 로 확인) | [README 스키마](../README.md#스키마) |
| 4 | **FAIL** | 요구는 15개(조회 4·조인 4·집계 3·서브쿼리 1·수정/삭제 2·인덱스 1)인데 "핵심 쿼리 17개"로 적혀 있어 범주별 개수(집계 4·서브쿼리 2)가 요구와 맞지 않음 | 요구 범주·개수에 맞추거나 추가 쿼리의 이유를 명시. 필수 15개와 추가분을 분명히 구분. README·design·발표 자료의 개수 표기도 함께 맞춤 | 쿼리 ID 는 그대로 두고 **필수 15개(Q01~Q11, Q13, Q15~Q17) + 추가 2개(Q12 집계, Q14 서브쿼리)** 로 구분함. 03 파일 머리 표에 필수/추가 열과 추가 이유를 적고, 마커의 분류에 `추가` 를 붙임. `test_required_fifteen_match_categories` 가 필수 15개의 범주별 개수가 요구(4·4·3·1·2·1)와 정확히 같은지 검사함. README(설명·배지·제출물·쿼리 목록 구분 열·요구사항 매핑·구조), checklist 1-4, design(§1 쿼리 구분, §8 테스트 설명), 발표 자료 3·14·15·61·63쪽의 개수를 맞춤 | [03_queries.sql 1~15줄](../sql/03_queries.sql#L1-15) · [@Q12](../sql/03_queries.sql#L126) · [@Q14](../sql/03_queries.sql#L147) · [test_sql.py:143](../tests/test_sql.py#L143) · [README 쿼리 목록](../README.md#쿼리-목록) · [design §1](../docs/design.md#1-도메인) · [checklist 1-4](../docs/checklist.md#1-4-기본-조회4조인4집계3서브쿼리1수정삭제2인덱스1를-포함한-쿼리-15개가-작성되어-있는가-) |
| 5 | **FAIL** | 실행 결과가 `results/Q01.txt` 같은 텍스트뿐이고 요구된 실행 화면 스크린샷이 없음 | 주요 쿼리를 터미널/DB 툴에서 실행한 실제 화면을 캡처해 결과와 함께 첨부 (예: `results/screenshots/`) | 주요 쿼리 9개(Q01·Q05·Q07·Q09·Q13·Q14·Q15·Q16·Q17)와 오류 재현 1장, 모두 10장을 `results/screenshots/` 에 PNG 로 첨부함. 화면마다 새 시드 DB 를 만들고, pty(`script`) 에서 bash → `sqlite3` CLI 3.46.1 을 실제로 실행해 입력하고 출력을 녹화함. 녹화한 원본 바이트는 터미널 에뮬레이터(xterm.js)로 재생해 캡처함. 색인 README 에 화면별 확인할 점, 대응 텍스트 결과, 촬영 방법을 적음. README 제출물 표, checklist 1-5, 발표 17쪽에서도 링크함 | [results/screenshots/](../results/screenshots/README.md) · [checklist 1-5](../docs/checklist.md#1-5-각-쿼리의-실행-결과가-스크린샷-또는-텍스트로-첨부되어-있는가-) |
| 6 | PASS | 테이블 분리의 유지보수 이점이 수치 없이 서술됨 | design.md 에 업데이트 비용 절감 등 사례 수치 보강 | "한 시트 방식 vs 분리 구조" 수정 행 수 표를 추가함: 스릴러킹 이메일 변경 10행 → 1행, 기생충 감독·개봉일 변경 7행 → 1행, 영화 정보 저장 78회 → 22회 (sqlite3 로 확인) | [design §2](../docs/design.md#2-테이블을-왜-4개로-나눴나) |
| 7 | PASS | 관계표에 관계별 NULL 허용 여부와 그 영향이 없음 | 관계표에 NULL 허용 여부와 ON DELETE 동작의 영향을 덧붙임 | 관계표에 "FK NULL 허용 여부"(세 FK 모두 NOT NULL)와 "ON DELETE 동작과 그 영향" 열을 추가함. 영향은 수치로 적음: 액션 장르 삭제 거부(B09), 탈퇴 회원 삭제 시 리뷰 78 → 76(Q16), 기생충 삭제 시 78 → 71. NOT NULL 이라 NULL 로 우회할 수도 없다는 문장도 넣음 | [design §3](../docs/design.md#3-관계-1n) |
| 8 | PASS | 숫자형 컬럼의 타입 선택 근거(값의 범위)가 없음 | 숫자형 컬럼마다 예상 최대값·범위로 타입을 고른 이유 한 줄 | `*_id`(시드 최대 10/15/22/78, 최대 2^63−1), `rating`(1~5, 1바이트, MySQL TINYINT), `running_time`(시드 94~181분, 1~600분 가정, SMALLINT), `birth_year`(시드 1978~2004, CHECK 1900~2026, 2바이트)의 근거를 적음. SQLite 정수 저장 크기(1·2·3·4·6·8바이트, 0·1 은 0바이트)도 설명함 | [design §4](../docs/design.md#4-컬럼-타입-선택) |
| 9 | PASS | 인덱스 유지 비용을 고려한 대안이 한 줄뿐임 | 유지 비용을 고려한 대안 후보와 우선순위를 짧게 추가 (현재 `idx_review_movie_id`, Q17) | 쓰기 비용 설명(가장 쓰기가 잦은 review 는 인덱스 1개만 유지)과 우선순위 4개를 추가함: ① `review(created_at)` Q02·Q05 ② `review(movie_id, rating)` 커버링, 기존 인덱스를 대체할 때만 ③ `movie(genre_id)` Q10, Q06 은 효과 없음을 명시 ④ `movie(release_date)` Q01. 각 후보의 효과는 임시 DB 에서 EXPLAIN QUERY PLAN 으로 확인함 | [design §6](../docs/design.md#6-인덱스) |
| 10 | PASS | DB 와 엑셀의 장단점을 README 에서 한눈에 볼 수 없음 | README 에 DB vs 엑셀 요약표(장단점) | 시작·편집 / 관계·규칙 / 중복·조회 / 동시 편집 / 구조 변경 5개 기준으로 엑셀과 관계형 DB 의 장단점을 비교한 표를 넣고 checklist 3-1 로 링크함 | [README DB 와 엑셀 비교](../README.md#db-와-엑셀-비교) |
| 11 | PASS | 초보 독자를 위한 PK/FK 사용 예시가 부족함 | PK/FK 사용 예시 문장 추가 | "PK 는 학번, FK 는 수강신청서에 적힌 학번" 비유와 "리뷰 40번의 movie_id = 1 → 기생충의 리뷰" 예시 문장을 추가함 (리뷰 40번은 sqlite3 로 확인) | [checklist 3-2](../docs/checklist.md#3-2-pk-와-fk-의-역할을-구분하고-1n-관계가-데이터를-어떻게-연결하는지-본인-스키마-기준으로-보여줄-수-있는가-) |
| 12 | PASS | INNER JOIN 과 LEFT JOIN 의 차이가 표 하나로 요약되어 있지 않음 | 대비표 하나 + 한 문장 요약 (Q05, Q07) | Q05(INNER) vs Q07(LEFT) 대비표(남는 행 · 짝 없는 행 · 결과 행 수 78→10 / 81→3 · 오른쪽 NULL · 언제 쓰나)와 한 문장 요약을 맨 앞에 두고, 기존 설명과 Q08·Q10 비교표는 그대로 둠 | [checklist 3-3](../docs/checklist.md#3-3-inner-join-과-left-join-의-차이를-실행-결과를-보며-짚어줄-수-있는가-) |
| 13 | PASS | GROUP BY 에서 NULL·숫자 집계의 특이 케이스 설명이 없음 | COUNT(*) vs COUNT(col), AVG 의 NULL 무시, 정수 나눗셈 등 한두 문장 | 실행 결과로 특이 케이스 표를 추가함: `COUNT(*) = 78` vs `COUNT(content) = 74`, 리뷰 없는 뮤지컬의 `AVG = NULL`, 기생충 `SUM/COUNT = 33/7 = 4` vs `AVG = 4.714…`, NULL 그룹 키는 한 그룹(4행)으로 묶임 | [checklist 3-4](../docs/checklist.md#3-4-group-by-와-집계-함수count-sum-avg가-어떻게-동작하는지-쿼리-결과를-보며-이야기할-수-있는가-) |
| 14 | PASS | 복잡 쿼리 Q14(CTE)의 단계별 중간 결과를 볼 수 없음 | 각 단계에 기대 결과 예시를 한 행씩 | Q14 SQL 안에 1~4단계 기대 결과 주석을 한 행씩 넣음: ① CTE `1 \| 2 \| 기생충 \| 4.714… \| 7`(20행 중) ③ JOIN 기생충 + 드라마 ② 상관 서브쿼리 드라마 MAX 4.75 → 기생충 탈락 ④ 최종 `드라마 \| 서울의 봄 \| 4.75 \| 4`(11행 중). 단계 번호는 checklist 4-1 · 발표 43쪽과 같고, 43쪽 설명에도 예시를 넣음 | [03_queries.sql:149](../sql/03_queries.sql#L149) · [162](../sql/03_queries.sql#L162) · [166~167](../sql/03_queries.sql#L166) · [results/Q14.txt](../results/Q14.txt) |
| 15 | PASS | 실제로 겪은 오류 메시지 예시가 없음 (표에 요약만 있음) | FK 검사 OFF/ON 의 `FOREIGN KEY constraint failed`, CHECK 위반 등을 직접 재현한 진짜 출력 첨부 | sqlite3 CLI 3.46.1 대화형 세션에서 직접 재현한 원문을 손대지 않고 넣음: FK OFF(기본 0)에서 고아 리뷰 INSERT 성공 → `foreign_key_check` 가 `review \| 79 \| member \| 1` 로 찾아냄, FK ON 후 `Runtime error: FOREIGN KEY constraint failed (19)`, RESTRICT, `CHECK constraint failed: rating BETWEEN 1 AND 5`, 날짜 CHECK, UNIQUE, NOT NULL. 메시지 읽는 법 표와 화면(ERR.png)도 붙이고 README 에서 링크함 | [bonus.md 실제 오류 메시지](../docs/bonus.md#실제로-겪은-오류-메시지-sqlite3-cli-원문) · [ERR.png](../results/screenshots/ERR.png) |

## 발표 자료 수정 (`docs/presentation.html`)

새 페이지 없이 기존 70장 안에서만 고쳤습니다. 수정 전후 모두 70장입니다. 바뀐 SQL 줄 번호는 `git diff` 의 줄 대응으로 다시 매겼고, 코드 장의 "줄 번호 + 코드"가 실제 파일 줄과 맞는지 스크립트로 대조했습니다. 수정 후 새로 생긴 불일치는 0건이고, 남은 23건은 수정 전부터 있던 요약 표기와 다른 파일 블록입니다.

| 쪽 | 장 | 고친 내용 |
| ---: | --- | --- |
| 1 | 표지(발표자 노트) | 결과 기록 SQLite 버전 3.45.1 → 3.46.1, 재생성 날짜 |
| 3 | 충족 현황 | unittest 12 → 13개, QueryFileTest 3 → 4 |
| 10 | 코드 해부 1-2 | FK 줄 설명에 "줄 끝 주석에 NULL 불가 · 삭제/수정 정책" (#2) |
| 14 | 1-4 | 제목 "필수 15개 + 추가 2개", 표 열 "필수+추가"(3+1, 1+1), 파일 줄 수 224 → 232, 테스트 이름, 발표자 노트 (#4) |
| 15 | 코드 해부 1-4 | 03 머리 주석 표를 새 내용(필수/추가 열 · 합계)으로, 줄 번호 4~10 · 19~23 → 4~11 · 24~28 (#4) |
| 16 · 23 · 27 · 34 · 37 · 40 · 43 | 코드 해부 | 03_queries.sql 줄 번호 재매핑 (+5 · +6 · +8) |
| 17 | 1-5 | 제목과 카드에 실행 화면 스크린샷 10장(`results/screenshots/`), 발표자 노트 (#5) |
| 21 | 코드 해부 2-1 | 01_schema.sql 2 · 11 · 12줄의 새 주석(버전 · 생성 순서와 이유 · DROP 순서) (#1) |
| 22 · 26 · 36 · 39 · 42 | 질문 장 | 03_queries.sql 줄 범위 재매핑, 26쪽 실행 계획 SQLite 버전 |
| 43 | 코드 해부 4-1 | 단계별 설명에 기대 결과 예시(기생충 4.714… · 드라마 · MAX 4.75), 생략 줄 표기 (#14) |
| 48 | 보너스 ① | B05 실행 계획 SQLite 버전 3.46.1 |
| 61 | 검증과 재현 | 테스트 13개(QueryFileTest 4), `Ran 13 tests` |
| 63 | 체크리스트 매트릭스 | 1-4 "필수 15 + 추가 2", 1-5 "텍스트 · 스크린샷 · 대조" |

## 검증 (2026-11-09)

| 명령 | 결과 |
| --- | --- |
| `sqlite3 db < sql/01_schema.sql` → `02_seed.sql` → `PRAGMA foreign_key_check` | 위반 0건 |
| `sqlite3 -bail db < sql/03_queries.sql` | 정상 종료. 이후 회원 14 · 리뷰 76 · 영화 22 · 장르 10, `foreign_key_check` 0건, `idx_review_movie_id` 생성 확인 |
| `uv run --no-project --python /usr/bin/python3.14 python scripts/run_all.py` (SQLite 3.46.1) | `results/` 36개 파일 다시 생성. 내용이 바뀐 파일은 Q12 · Q14(마커 · 주석) · README · 00_table_counts(버전 줄) |
| `uv run python -m unittest discover -s tests -t .` | `Ran 13 tests` OK |
| `uv run python scripts/run_all.py --check` (SQLite 3.50.4) · 같은 명령을 3.46.1 에서 | 둘 다 `[통과] results/ 의 33개 파일이 SQL 실행 결과와 일치` |
