# 체크리스트 답변서

미션 체크리스트의 모든 항목에 대해 **충족 근거(SQL·결과 파일·테스트)**와 **설명 답변**을 정리했습니다.
리뷰어가 질문하면 해당 항목을 펼쳐 바로 답할 수 있도록 구성했습니다.

> 표기: 📂 SQL 위치 · 📄 실행 결과 · 🧪 자동 테스트 · ▶️ 직접 확인 명령
> 모든 결과는 `python scripts/run_all.py` 로 다시 만들 수 있습니다. 결과 모음: [`results/README.md`](../results/README.md)

- [항목 1. 제출물 요건](#항목-1-제출물-요건)
- [항목 2. 설계 이유](#항목-2-설계-이유)
- [항목 3. 개념 설명](#항목-3-개념-설명)
- [항목 4. 회고 질문](#항목-4-회고-질문)

---

## 항목 1. 제출물 요건

### 1-1. 최소 4개 테이블이 존재하고, 각 테이블에 PK 가 정의되어 있는가 ✅

- 📂 [`sql/01_schema.sql`](../sql/01_schema.sql) · 🧪 `test_at_least_four_tables_each_with_primary_key`

| 테이블 | PK | 역할 |
| --- | --- | --- |
| `genre` | `genre_id INTEGER PRIMARY KEY` | 장르 |
| `member` | `member_id INTEGER PRIMARY KEY` | 회원 |
| `movie` | `movie_id INTEGER PRIMARY KEY` | 영화 |
| `review` | `review_id INTEGER PRIMARY KEY` | 리뷰 (회원 × 영화) |

### 1-2. FK 를 사용한 1:N 관계가 최소 2개 이상 존재하고, 없는 값 참조가 실제로 막히는가 ✅

- 📂 `01_schema.sql` · 📄 [`results/B07.txt`](../results/B07.txt), [`B08.txt`](../results/B08.txt), [`B09.txt`](../results/B09.txt) · 🧪 `test_foreign_keys_block_missing_parent`

FK 3개, 1:N 관계 3개입니다: `genre → movie`, `member → review`, `movie → review`.

```text
sqlite> INSERT INTO review (member_id, movie_id, rating, content, created_at)
   ...> VALUES (999, 1, 5, '없는 회원이 쓴 리뷰', '2024-10-01 10:00:00');
Error: FOREIGN KEY constraint failed

sqlite> DELETE FROM genre WHERE name = '액션';          -- 영화 4편이 참조 중 (ON DELETE RESTRICT)
Error: FOREIGN KEY constraint failed
```

SQLite 는 FK 검사가 기본으로 꺼져 있어서 모든 SQL 파일 첫 줄에 `PRAGMA foreign_keys = ON;` 을 둡니다. 이 줄이 없으면 위 INSERT 가 성공해 버린다는 것도 B13 에서 직접 확인했습니다.

### 1-3. 각 테이블에 최소 10행 이상의 샘플 데이터가 입력되어 있는가 ✅

- 📂 [`sql/02_seed.sql`](../sql/02_seed.sql) · 📄 [`results/00_table_counts.txt`](../results/00_table_counts.txt) · 🧪 `test_every_table_has_at_least_ten_rows`

| genre | member | movie | review |
| ---: | ---: | ---: | ---: |
| 10 | 15 | 22 | 78 |

부모 테이블(genre, member) → movie → review 순서로 넣었고, 한 트랜잭션(`BEGIN … COMMIT`)으로 묶어 중간에 실패하면 전부 취소되게 했습니다. 입력 후 `PRAGMA foreign_key_check` 위반 0건입니다. 쿼리 결과가 의미 있도록 일부러 넣은 데이터(리뷰 없는 회원·영화, 영화 없는 장르, 탈퇴 회원 등)는 `02_seed.sql` 머리 주석에 적어 두었습니다.

### 1-4. 기본 조회(4)·조인(4)·집계(3)·서브쿼리(1)·수정/삭제(2)·인덱스(1)를 포함한 쿼리 15개가 작성되어 있는가 ✅

- 📂 [`sql/03_queries.sql`](../sql/03_queries.sql) — 필수 15 + 추가 2 · 🧪 `test_category_minimums` · `test_required_fifteen_match_categories` (SQL 문을 분석해 범주별 개수와 키워드를 검사)

| 분류 | 요구 | 필수 | 추가 | 쿼리 |
| --- | ---: | ---: | ---: | --- |
| 기본 조회 (WHERE, ORDER BY, LIMIT) | 4 | 4 | 0 | Q01 최근 개봉작 · Q02 최근 5점 리뷰 5개(LIMIT) · Q03 긴 영화 · Q04 제목 LIKE 검색 |
| 조인 (INNER 2+, LEFT 1+) | 4 | 4 | 0 | Q05 최근 리뷰 + 닉네임 + 제목(INNER 3테이블) · Q06 장르명과 영화(INNER) · Q07 리뷰 안 쓴 회원(LEFT) · Q08 영화별 리뷰 수 0 포함(LEFT) |
| 집계 (COUNT, SUM, AVG + GROUP BY) | 3 | 3 | 1 | Q09 평균 별점 TOP 5(HAVING) · Q10 장르별 통계 · Q11 회원별 활동(SUM 포함) · 추가 Q12 월별 추이(시간 축 집계·SQLite `strftime` 예시) |
| 서브쿼리 | 1 | 1 | 1 | Q13 전체 평균보다 높은 영화(스칼라) · 추가 Q14 장르별 1위(CTE + 상관 서브쿼리, 회고 4-1의 가장 복잡한 쿼리) |
| 수정 / 삭제 | 2 | 2 | 0 | Q15 휴면 전환 UPDATE · Q16 탈퇴 회원 DELETE(+ CASCADE) |
| 인덱스 | 1 | 1 | 0 | Q17 `idx_review_movie_id` + 생성 전/후 실행 계획 |

모든 쿼리 위에 `-- @Qnn | 분류 | 무엇을 확인하는 쿼리인지` 한 줄 설명이 있습니다.

### 1-5. 각 쿼리의 실행 결과가 스크린샷 또는 텍스트로 첨부되어 있는가 ✅

- 📄 [`results/`](../results) — 쿼리별 텍스트 결과(`Q01.txt` ~ `Q17.txt`, 보너스 `B01~B14`, `R01~R03`) + 전체를 표로 모은 [`results/README.md`](../results/README.md)
- 📄 [`results/screenshots/`](../results/screenshots/README.md) — Q01~Q17 전부를 실행한 sqlite3 CLI 터미널 화면 PNG (각 결과 파일 머리의 `screenshot:` 줄과 `results/README.md` 쿼리별 절에서 연결)
- ▶️ `python scripts/run_all.py --check` — SQL 을 다시 실행해 결과 파일과 일치하는지 검사 (GitHub Actions 에서 push 마다 실행)

결과 파일은 손으로 붙여넣지 않고 스크립트가 실제 실행 결과를 sqlite3 CLI 형식으로 기록합니다. 그래서 SQL 을 고치고 결과를 갱신하지 않으면 CI 가 실패합니다.

---

## 항목 2. 설계 이유

### 2-1. 테이블을 왜 이렇게 나눴는지, 각 테이블의 역할을 말할 수 있는가 ✅

**한 가지 대상은 한 테이블에 한 번만** 저장한다는 원칙으로 나눴습니다. 리뷰 한 줄에 회원·영화 정보를 모두 적으면(엑셀 한 시트처럼):

- 기생충 리뷰가 7개면 감독·개봉일이 7번 반복되고 (중복),
- 회원이 이메일을 바꾸면 그 회원의 리뷰 행을 전부 고쳐야 하며 (수정 이상),
- 리뷰가 없는 새 영화는 넣을 자리가 없고 (삽입 이상),
- 마지막 리뷰를 지우면 영화 정보도 사라집니다 (삭제 이상).

| 테이블 | 역할 |
| --- | --- |
| `genre` | 장르 이름을 한 곳에서 관리 (오타로 '드라마'/'드라마 ' 가 갈라지는 것 방지, UNIQUE) |
| `member` | 회원 정보. 이메일·닉네임은 여기 한 번만 저장 |
| `movie` | 영화 정보. 리뷰가 없어도 존재할 수 있음 |
| `review` | "누가 · 어떤 영화에 · 몇 점을 · 언제" — 회원과 영화의 N:M 관계를 연결하는 테이블 |

📂 상세: [`design.md` 2절](design.md#2-테이블을-왜-4개로-나눴나)

### 2-2. FK 로 연결한 1:N 관계가 실제 도메인에서 어떤 의미인지 예시를 들어 보여줄 수 있는가 ✅

| 관계 | 도메인 의미 | 실제 데이터 |
| --- | --- | --- |
| genre 1 : N movie | 한 장르에 여러 영화. 영화는 대표 장르 하나 | 액션 → 범죄도시, 어벤져스: 엔드게임, 탑건: 매버릭, 부산행 (Q06) |
| member 1 : N review | 한 회원이 여러 리뷰를 쓴다 | 스릴러킹 → 리뷰 10개 (Q11) |
| movie 1 : N review | 한 영화에 여러 리뷰가 달린다 | 기생충 → 리뷰 7개, 7번방의 선물 → 0개 (Q08) |

FK 는 "N 쪽" 이 "1 쪽" 을 가리킵니다. 리뷰 하나(`review_id = 1`)는 `member_id = 1`(팝콘요정), `movie_id = 2`(인터스텔라)를 들고 있어서 "팝콘요정이 인터스텔라에 남긴 리뷰" 라는 뜻이 됩니다. 반대로 회원 행은 리뷰 목록을 들고 있지 않고, 필요할 때 `JOIN` 으로 모읍니다.

FK 에는 삭제 정책도 정했습니다. 장르는 `RESTRICT`(영화가 남아 있으면 못 지움), 리뷰의 회원·영화는 `CASCADE`(부모가 지워지면 리뷰도 삭제 → Q16 에서 탈퇴 회원 삭제 시 리뷰 78 → 76).

### 2-3. 컬럼 타입(TEXT, INTEGER, DATE 등)을 왜 그렇게 선택했는지 설명할 수 있는가 ✅

| 컬럼 | 타입 | 이유 |
| --- | --- | --- |
| id | `INTEGER PRIMARY KEY` | SQLite 에서는 rowid 별칭 → 가장 빠른 조회, 자동 번호 |
| `rating` | `INTEGER` + CHECK 1~5 | 별점은 정수 단계. 평균은 조회 시 `AVG()` 로 계산 |
| `running_time` | `INTEGER`(분) | 합계·비교가 필요 (Q03 150분 이상, Q11 총 관람 시간) |
| 날짜·일시 | `TEXT` ISO-8601 + CHECK | SQLite 에는 DATE 타입이 없다. `'YYYY-MM-DD'` 문자열은 **사전순 = 날짜순**이라 `>=`·`ORDER BY` 가 그대로 되고 `date()`/`strftime()` 이 이 형식을 이해한다. 형식은 CHECK 로 강제 |
| 이름·제목·이메일·내용 | `TEXT` | 문자열. `content` 만 NULL 허용(별점만 남기는 리뷰) |
| `status` | `TEXT` + CHECK 3종 | 값이 고정된 상태 코드 |

MySQL/PostgreSQL 이라면 날짜는 `DATE`/`DATETIME`, 문자열은 `VARCHAR(n)` 을 쓰는 것이 일반적입니다([`design.md` 4절, 7절 대응표](design.md#4-컬럼-타입-선택)).

### 2-4. 인덱스를 어떤 컬럼에 걸었고, 왜 그 컬럼이어야 하는지 이유를 대답할 수 있는가 ✅

- 📂 Q17 · 📄 [`results/Q17.txt`](../results/Q17.txt)

**`review(movie_id)`** 에 걸었습니다.

1. **가장 자주 쓰는 조건**: 영화별 리뷰 수·평균·랭킹(Q08~Q14)이 모두 `review.movie_id` 로 JOIN·GROUP BY 하고, 서비스의 "영화 상세 → 리뷰 목록" 도 `WHERE movie_id = ?` 입니다.
2. **자동 인덱스가 없다**: SQLite 는 FK 컬럼에 인덱스를 만들지 않습니다. `UNIQUE(member_id, movie_id)` 가 만든 인덱스는 `member_id` 가 앞이라 `movie_id` 만으로는 못 씁니다(성으로 정렬된 전화번호부를 이름만으로 찾을 수 없는 것과 같음).
3. **효과를 실행 계획으로 확인**:

```text
생성 전  `--SCAN review                                              (전체 78행 확인)
생성 후  `--SEARCH review USING INDEX idx_review_movie_id (movie_id=?)
```

인덱스는 INSERT/DELETE 때마다 함께 갱신되고 공간을 차지하므로, 아무 컬럼에나 걸지 않고 조회 조건에 자주 쓰이는 컬럼에만 걸었습니다.

---

## 항목 3. 개념 설명

### 3-1. 데이터베이스가 엑셀과 무엇이 다른지, 왜 테이블을 나눠서 저장하는지 비교하여 설명할 수 있는가 ✅

| | 엑셀 | 관계형 DB |
| --- | --- | --- |
| 데이터 사이 관계 | VLOOKUP 등으로 참조할 수 있지만 관계를 강제하지 못함 | PK/FK 로 연결하고 정보는 한 번만 저장 |
| 규칙 강제 | 별점 칸에 "다섯" 이라고 써도 들어감 | `CHECK (rating BETWEEN 1 AND 5)`, `NOT NULL`, `UNIQUE` 로 잘못된 값을 거부 (B10~B12) |
| 무결성 | 영화 행을 지워도 그 영화의 리뷰가 남음 | FK 가 고아 행을 막고(B07), 삭제 정책(RESTRICT/CASCADE)을 정할 수 있음 |
| 질의 | 필터·피벗을 손으로 조작 | SQL 한 문장으로 조인·집계·랭킹 (Q09, Q14) |
| 동시 사용·트랜잭션 | 파일 하나를 한 사람이 편집 | 트랜잭션으로 "전부 성공 아니면 전부 취소" (seed 의 BEGIN/COMMIT, B14) |
| 대량 데이터 | 행이 많아지면 느려지고 찾기 어려움 | 인덱스로 필요한 행만 바로 찾음 (Q17) |

관계 표현에서 엑셀은 VLOOKUP 같은 참조를 써도 원본 행 삭제를 막지 못하고 `#N/A` 가 될 수 있습니다. DB 는 FK 검사를 켜면 없는 회원 999 의 리뷰 INSERT 를 `Runtime error: FOREIGN KEY constraint failed (19)` 로 거부합니다. 무결성도 DB 규칙으로 강제하여 별점 6 은 `Runtime error: CHECK constraint failed: rating BETWEEN 1 AND 5 (19)`, 같은 회원·영화의 중복 리뷰는 `Runtime error: UNIQUE constraint failed: review.member_id, review.movie_id (19)` 로 거부합니다([실제로 겪은 오류 메시지](bonus.md#실제로-겪은-오류-메시지-sqlite3-cli-원문)).

**차이의 핵심은 데이터의 양이 아니라 "관계와 규칙을 표현할 수 있는가"** 입니다. 테이블을 나누는 이유는 중복을 없애서 수정·삽입·삭제 이상을 막기 위해서입니다(2-1 참고).

### 3-2. PK 와 FK 의 역할을 구분하고, 1:N 관계가 데이터를 어떻게 연결하는지 본인 스키마 기준으로 보여줄 수 있는가 ✅

- **PK(기본키)**: 테이블 안에서 행 하나를 **유일하게 식별**하는 값. NULL·중복 불가. 예: `movie.movie_id = 1` 은 기생충 하나만 가리킵니다.
- **FK(외래키)**: 다른 테이블의 PK 를 **가리키는** 값. 가리키는 행이 실제로 있어야 합니다. 예: `review.movie_id = 1` 은 "이 리뷰는 기생충의 리뷰" 라는 뜻이고, `movie_id = 999` 처럼 없는 영화를 가리키면 거부됩니다.

PK 는 학번처럼 한 명을 정확히 가리키고, FK 는 수강신청서에 적힌 학번처럼 다른 표의 행을 가리킵니다.
실제 리뷰 40번의 `movie_id = 1` 은 “기생충의 리뷰”라는 뜻이며, 영화 제목을 리뷰마다 다시 저장하지 않아도 됩니다.

```
movie                          review
movie_id(PK) | title           review_id(PK) | member_id(FK) | movie_id(FK) | rating
-------------+--------         --------------+---------------+--------------+-------
           1 | 기생충   ◀──┬──              40 |            15 |            1 |      5
                         ├──              52 |             3 |            1 |      4
                         ├──              53 |             2 |            1 |      5
                         └── … (모두 7개)  …
          22 | 7번방의 선물  ◀── (없음: 리뷰 0개)
```

`movie_id = 1` 인 영화 한 편(1)에 리뷰 7개(N)가 연결됩니다. 1 쪽은 PK, N 쪽은 FK 를 가지며, 둘을 `ON r.movie_id = m.movie_id` 로 이어 붙이는 것이 JOIN 입니다.

### 3-3. INNER JOIN 과 LEFT JOIN 의 차이를 실행 결과를 보며 짚어줄 수 있는가 ✅

- 📄 [`Q05`](../results/Q05.txt)(INNER), [`Q07`](../results/Q07.txt)·[`Q08`](../results/Q08.txt)·[`Q10`](../results/Q10.txt)(LEFT)

대비표 (Q05 · Q07)

| 비교 | INNER JOIN (Q05) | LEFT JOIN (Q07) |
| --- | --- | --- |
| 남는 행 | 회원·리뷰·영화에 짝이 있는 리뷰 | 왼쪽 회원을 모두 남긴 뒤, Q07 은 리뷰 없는 회원만 선택 |
| 짝 없는 행 처리 | 제외 | 오른쪽 리뷰 컬럼을 NULL 로 채움 |
| 결과 행 수 | 회원×리뷰 조인 78행 → Q05 `LIMIT 10` 후 10행 | 회원×리뷰 조인 81행 → Q07 `WHERE r.review_id IS NULL` 후 3행 |
| 오른쪽 컬럼 NULL | 짝이 없어 생기는 NULL 은 없음 (`content` 자체는 NULL 가능, Q05 는 `COALESCE` 로 표시) | 리뷰 없는 3명은 `r.review_id` 등 리뷰 컬럼이 NULL |
| 언제 쓰나 | 작성된 리뷰에 회원·영화 정보를 붙일 때 | 리뷰 없는 회원(눈팅족·새내기·잠수중)을 찾을 때 |

**한 문장 요약: INNER JOIN 은 짝이 있는 행만, LEFT JOIN 은 짝이 없는 왼쪽 행까지 NULL 로 채워 남깁니다.**

- **INNER JOIN**: 양쪽에 **짝이 있는 행만** 남깁니다. 회원 × 리뷰를 INNER JOIN 하면 78행 — 리뷰를 쓴 12명만 나옵니다.
- **LEFT JOIN**: 왼쪽 테이블의 행은 **짝이 없어도 모두 남기고**, 오른쪽 컬럼을 NULL 로 채웁니다. 회원 LEFT JOIN 리뷰는 81행 — 리뷰가 없는 3명(새내기, 잠수중, 눈팅족)이 `review_id = NULL` 로 추가됩니다.

| 같은 요구 | INNER JOIN 이었다면 | LEFT JOIN (실제 쿼리) |
| --- | --- | --- |
| 영화별 리뷰 수 (Q08) | 20편 (리뷰 0개인 2편이 **사라짐**) | 22편, `7번방의 선물 0`, `반지의 제왕 0` |
| 장르별 통계 (Q10) | 9개 장르 (**뮤지컬이 사라짐**) | 10개 장르, `뮤지컬 0 · 0 · NULL` |
| 리뷰 안 쓴 회원 (Q07) | 구할 수 없음 (애초에 짝 없는 행이 없음) | `WHERE r.review_id IS NULL` 로 3명 |

정리하면 "**없는 것도 0 으로 보여줘야 하는가?**" 가 LEFT 를 쓰는 기준입니다. 그리고 LEFT JOIN 에서는 `COUNT(*)` 가 아니라 `COUNT(r.review_id)` 로 세야 합니다. `COUNT(*)` 는 NULL 로 채워진 행도 1로 세서 리뷰 없는 영화가 1 로 나옵니다.

### 3-4. GROUP BY 와 집계 함수(COUNT, SUM, AVG)가 어떻게 동작하는지 쿼리 결과를 보며 이야기할 수 있는가 ✅

- 📄 [`Q09`](../results/Q09.txt), [`Q10`](../results/Q10.txt), [`Q11`](../results/Q11.txt), [`Q12`](../results/Q12.txt)

`GROUP BY` 는 같은 값을 가진 행들을 **한 묶음으로 접고**, 집계 함수는 묶음마다 **값 하나**를 계산합니다. 실행 순서는 `FROM/JOIN → WHERE → GROUP BY → HAVING → SELECT → ORDER BY → LIMIT` 입니다.

Q09 를 기생충으로 따라가 보면:

```
1. FROM + JOIN   movie × review → 기생충 행 7개 (별점 5, 4, 5, 5, 4, 5, 5)
2. GROUP BY      movie_id 로 묶음 → 기생충 묶음 1개
3. 집계          COUNT(*) = 7, AVG(rating) = 33 / 7 = 4.714… → ROUND 4.71
4. HAVING        COUNT(*) >= 3 → 통과 (리뷰 2개인 비긴 어게인은 여기서 탈락)
5. ORDER BY      avg_rating DESC → 서울의 봄 4.75, 기생충 4.71, 인터스텔라 4.67 …
```

| 함수 | 의미 | 결과 예 |
| --- | --- | --- |
| `COUNT(*)` / `COUNT(col)` | 행 수 / NULL 이 아닌 값의 수 | 스릴러킹 리뷰 10개 (Q11) |
| `SUM(col)` | 합계 | 스릴러킹 총 관람 1,283분 (Q11) |
| `AVG(col)` | 평균 (NULL 제외) | 드라마 평균 4.73, 뮤지컬은 리뷰가 없어 NULL (Q10) |

| 특이 케이스 | 임시 DB 실행 결과 |
| --- | --- |
| NULL 과 COUNT | 전체 리뷰 `COUNT(*) = 78`, `COUNT(content) = 74` — 내용 NULL 4개는 제외 |
| NULL 과 AVG | `AVG` 는 NULL 을 무시하며, 리뷰 없는 뮤지컬 장르는 `AVG(r.rating) = NULL` |
| 정수 나눗셈 | 기생충 `SUM(rating) = 33`, `COUNT(*) = 7`: `SUM(rating)/COUNT(*) = 4`, `AVG(rating) = 4.71428571428571` |
| NULL 그룹 키 | `WHERE content IS NULL GROUP BY content` 는 NULL 을 한 그룹(4행)으로 묶음 |

`WHERE` 는 묶기 **전** 행을, `HAVING` 은 묶은 **후** 그룹을 거릅니다. "리뷰 3개 이상인 영화" 는 묶어 봐야 알 수 있으므로 `HAVING` 입니다.

---

## 항목 4. 회고 질문

### 4-1. 작성한 쿼리 중 가장 복잡했던 쿼리를 선택하고, 어떻게 풀었는지 단계별로 설명할 수 있는가 ✅

**Q14. 장르마다 평균 별점이 가장 높은 영화 (동점이면 모두)** — 📄 [`results/Q14.txt`](../results/Q14.txt)

어려운 이유: "그룹별 최댓값을 가진 **행 전체**" 를 구해야 합니다. `GROUP BY genre` 로 `MAX(avg)` 는 쉽게 구하지만, 그 최댓값을 가진 **영화 제목**은 GROUP BY 결과에 남지 않습니다.

1. **작은 문제로 나누기** — 먼저 "영화별 평균 별점" 을 만듭니다. 이 결과를 두 번 써야 해서 CTE `movie_avg` 로 이름을 붙였습니다.
   ```sql
   WITH movie_avg AS (SELECT m.movie_id, m.genre_id, m.title, AVG(r.rating) AS avg_rating, COUNT(*) AS review_count
                      FROM movie m JOIN review r ON r.movie_id = m.movie_id
                      GROUP BY m.movie_id, m.genre_id, m.title)
   ```
2. **장르별 최댓값을 상관 서브쿼리로** — 바깥 행(영화)의 `genre_id` 마다 같은 장르 안에서의 최댓값을 다시 계산합니다.
   ```sql
   WHERE ma.avg_rating = (SELECT MAX(x.avg_rating) FROM movie_avg x WHERE x.genre_id = ma.genre_id)
   ```
3. **장르 이름 붙이기** — `genre` 와 INNER JOIN.
4. **검증** — 결과 11행. 장르는 9개(리뷰가 있는 장르)인데 11행인 이유는 동점 때문입니다: SF(인터스텔라·듄 파트 2 = 4.67), 애니메이션(너의 이름은.·인사이드 아웃 2 = 4.5). `ROUND` 를 비교 전에 하면 4.666… 과 4.67 처럼 다른 값이 같아지거나 그 반대가 생길 수 있어, **비교는 원래 값으로 하고 출력에서만 ROUND** 했습니다.

다른 방법으로는 윈도 함수 `RANK() OVER (PARTITION BY genre_id ORDER BY avg_rating DESC)` 가 있지만, 과제 범위(서브쿼리)에 맞춰 상관 서브쿼리로 풀었습니다.

### 4-2. 미션 수행 중 가장 어려웠던 부분과 해결 방법을 구체적으로 말할 수 있는가 ✅

**잘못된 날짜가 CHECK 를 통과한 문제** 입니다.

- **상황**: 날짜 형식을 지키려고 `CHECK (date(joined_at) = joined_at)` 를 걸었습니다. `'2024-02-30'` 은 막혀서 잘 동작한다고 생각했습니다.
- **발견**: 제약조건 테스트(`tests/test_sql.py`)에 `'2024-13-01'` 을 추가했더니 **막히지 않고 들어갔습니다.**
- **원인 분석**:
  - `date('2024-02-30')` → `'2024-03-01'` (SQLite 가 넘친 날짜를 다음 달로 바꿈) → `'2024-03-01' = '2024-02-30'` → 거짓 → 거부. 그래서 처음엔 잘 되는 것처럼 보였습니다.
  - `date('2024-13-01')` → **NULL** (해석 불가) → `NULL = '2024-13-01'` → **NULL**.
  - SQL 의 CHECK 는 결과가 **거짓일 때만** 거부하고 NULL(알 수 없음)은 통과시킵니다(3값 논리).
- **해결**: `=` 대신 NULL 도 하나의 값으로 비교하는 `IS` 를 썼습니다. `NULL IS '2024-13-01'` → 거짓 → 거부. 세 날짜 컬럼 모두 바꾸고 B10 에 재현 쿼리를 남겼습니다.
- **두 번째 발견 (CI)**: GitHub Actions 의 Windows + Python 3.10 조합에서만 `'2024-02-30'` 이 다시 통과했습니다. 이 Python 에 들어 있는 SQLite 3.40.1 은 수식어 없는 `date('2024-02-30')` 을 계산 없이 `'2024-02-30'` 그대로 돌려주기 때문입니다(로컬 SQLite 3.45 는 `'2024-03-01'`).
- **두 번째 해결**: `date(x, '+0 days')` 처럼 값을 바꾸지 않는 수식어를 붙여 **항상 날짜 계산을 거치게** 했습니다. 이제 SQLite 버전과 상관없이 `'2024-02-30'` → `'2024-03-01'` → 거부됩니다. CI 매트릭스(Ubuntu/Windows × Python 3.10/3.13)가 없었다면 찾지 못했을 문제입니다.
- **배운 점**: "막혀야 할 값이 막히는지" 는 정상값 테스트만으로는 알 수 없어서 경계값·이상값 테스트가 필요하다는 것, SQL 에서 NULL 이 끼면 비교 결과가 참/거짓이 아닐 수 있다는 것, 그리고 같은 SQL 도 **DB 엔진 버전에 따라 결과가 다를 수 있어** 여러 환경에서 검증해야 한다는 것입니다.

그 밖에 겪은 문제

| 문제 | 해결 |
| --- | --- |
| SQLite 에서 FK 가 동작하지 않음 | FK 검사가 기본 OFF. 모든 SQL 파일과 실행 스크립트에서 `PRAGMA foreign_keys = ON` (B13 에서 OFF 일 때 고아 행이 들어가는 것 확인) |
| LEFT JOIN 했는데 리뷰 없는 영화가 1건으로 나옴 | `COUNT(*)` → `COUNT(r.review_id)` (Q08) |
| 장르별 영화 수가 리뷰 수만큼 부풀려짐 | 리뷰 조인으로 영화 행이 복제됨 → `COUNT(DISTINCT m.movie_id)` (Q10) |
| UPDATE/DELETE 결과 때문에 뒤 쿼리 결과가 바뀜 | 수정 쿼리를 파일 끝(Q15, Q16)에 두고, 보너스 파일은 새 DB 에서 실행 |

#### 시도한 방법과 최종 선택

| 시도 | 방법 | 결과 | 버린 이유/선택 이유 |
| --- | --- | --- | --- |
| ① 최초 검사 | `CHECK (date(x) = x)` | 해석 불가 날짜는 비교 결과가 NULL 이 되어 통과했습니다 | CHECK 가 NULL 을 거부하지 않아 교체했습니다 |
| ② NULL 처리 | `= → IS` | 해석 불가 날짜는 막았지만 Windows · Python 3.10 CI 에서 존재하지 않는 날짜가 통과했습니다 | 일부 SQLite 버전의 수식어 없는 `date()` 가 입력을 그대로 반환했습니다 |
| ③ 최종 선택 | `date(x, '+0 days') IS x` | 날짜 계산을 강제하여 넘친 날짜와 해석 불가 날짜를 거부했습니다 | NULL 비교와 버전별 날짜 처리 차이를 함께 해결했습니다 |
| 대안 검토만 함 | 트리거로 검증하기 | 미구현 | 미션이 트리거 사용을 금지하여 제외했습니다 |
| 대안 검토만 함 | 앱에서 검증하기 | 미구현 | DB 규칙이 아니게 되어 직접 SQL 입력을 막지 못합니다 |
| 대안 검토만 함 | `strftime` 으로 비교하기 | 미구현·미검증 | 형식 비교만으로 실제 날짜 계산이 보장되는지 별도 검증이 필요해, 날짜 계산을 명시하는 최종안을 선택했습니다 |

**작업 시간은 기록하지 않음**. `git log` 의 커밋 시각만 남깁니다: 1차 `cf86c1e` 는 2026-10-12 14:41 KST, 2차 `d5a1e43` 는 2026-10-12 23:27 KST 입니다. 2차 문제는 CI 의 Windows · Python 3.10 에서 발견했으며, 두 커밋의 시각 차이를 작업 시간으로 계산하지 않았습니다.
