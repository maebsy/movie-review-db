# 보너스 과제 ① ② — JOIN vs 서브쿼리, 정합성 깨뜨려 보기

> 세 번째 보너스(미니 리포트)는 [`mini-report.md`](mini-report.md) 에 있습니다.
> 모든 결과는 `python scripts/run_all.py` 가 새 DB 에서 실제로 실행한 출력입니다.

## ① 조인 1개를 두 방식으로 풀기

📂 [`sql/04_bonus_join_vs_subquery.sql`](../sql/04_bonus_join_vs_subquery.sql) · 📄 [`results/B01~B06`](../results/README.md)

### 요구 A. "리뷰를 1개 이상 작성한 회원 목록"

```sql
-- ① INNER JOIN
SELECT DISTINCT mb.member_id, mb.nickname
FROM member mb JOIN review r ON r.member_id = mb.member_id;

-- ② EXISTS
SELECT mb.member_id, mb.nickname
FROM member mb
WHERE EXISTS (SELECT 1 FROM review r WHERE r.member_id = mb.member_id);

-- ③ IN
SELECT mb.member_id, mb.nickname
FROM member mb
WHERE mb.member_id IN (SELECT r.member_id FROM review r);
```

**결과 비교 (B04)**: 세 결과의 차집합(`EXCEPT`)이 모두 0행 → 12명으로 완전히 같습니다. 다만 ①은 `DISTINCT` 를 빼면 **78행**이 나옵니다. JOIN 은 "회원 × 그 회원의 리뷰" 조합을 만들기 때문에 리뷰 10개를 쓴 스릴러킹이 10번 나옵니다.

**실행 계획 비교 (B05, SQLite 3.45)**

```text
① JOIN + DISTINCT                     ② EXISTS                                    ③ IN
|--SCAN mb USING COVERING INDEX …     |--SCAN mb USING COVERING INDEX …           |--SEARCH mb USING INTEGER PRIMARY KEY
`--SEARCH r USING COVERING INDEX      `--CORRELATED SCALAR SUBQUERY 1             `--LIST SUBQUERY 1
   sqlite_autoindex_review_1             `--SEARCH r USING COVERING INDEX            `--SCAN r USING COVERING INDEX
   (member_id=?)                            sqlite_autoindex_review_1 (member_id=?)     sqlite_autoindex_review_1
```

| | ① JOIN + DISTINCT | ② EXISTS | ③ IN |
| --- | --- | --- | --- |
| 읽는 방식 | 회원마다 리뷰 인덱스 탐색 | 회원마다 리뷰 인덱스에서 **한 건만** 찾으면 멈춤 | 리뷰의 member_id 목록을 **한 번** 만들고, 그 목록의 회원만 PK 로 찾음 |
| 중복 | 조인 결과에 중복이 생겨 DISTINCT 필요 | 없음 | 없음 |
| 리뷰 컬럼 사용 | 가능 (예: 리뷰 수, 최근 리뷰일) | 불가 (존재 여부만) | 불가 |
| 의도 표현 | "연결된 데이터를 함께 보고 싶다" | "**있는지**만 궁금하다" | "**목록 안에** 있는가" |

이 DB 에서는 결과 컬럼(`member_id`)이 회원의 유일 키라 SQLite 옵티마이저가 ①도 임시 B-tree 없이 처리했고, 데이터가 작아 세 방식의 속도 차이는 없습니다.
그래서 선택 기준은 성능보다 **의도**입니다. 리뷰 정보가 필요 없고 존재 여부만 확인한다면 `EXISTS` 가 가장 정확하게 의도를 드러내고, 중복 제거 실수도 생기지 않습니다. 반대로 "회원별 리뷰 수" 처럼 리뷰 쪽 값이 필요하면 JOIN + GROUP BY 가 자연스럽습니다.

`NOT IN` 은 주의가 필요합니다. 서브쿼리 결과에 NULL 이 하나라도 있으면 `x NOT IN (…, NULL)` 은 항상 참이 아니게 되어 결과가 비어 버립니다. 이 스키마는 `review.member_id` 가 `NOT NULL` 이라 안전하지만, "없는 것 찾기" 는 `NOT EXISTS` 나 `LEFT JOIN … IS NULL`(Q07) 이 더 안전합니다.

### 요구 B. "영화별 리뷰 수 (리뷰 없는 영화는 0)" — B06

```sql
-- ① LEFT JOIN + GROUP BY                       -- ② SELECT 절 상관 서브쿼리
SELECT m.movie_id, m.title, COUNT(r.review_id)   SELECT m.movie_id, m.title,
FROM movie m                                            (SELECT COUNT(*) FROM review r
LEFT JOIN review r ON r.movie_id = m.movie_id            WHERE r.movie_id = m.movie_id)
GROUP BY m.movie_id, m.title;                    FROM movie m;
```

두 결과는 22행 모두 같습니다(`mismatched_rows = 0`). 차이점:

- ① 은 **한 번 조인한 뒤 묶어서** 셉니다. 리뷰 수와 평균 별점처럼 여러 집계를 한 번에 구할 때 유리합니다.
- ② 는 **영화마다 서브쿼리를 한 번씩** 실행합니다. 읽기는 쉽지만 집계가 여러 개면 서브쿼리도 여러 개가 됩니다. 리뷰가 없을 때 `COUNT(*)` 를 써도 0 이 나와서, ①의 `COUNT(*)` 함정(LEFT JOIN 에서 1 로 세짐)이 없습니다.

## ② 데이터 정합성 깨뜨려 보기

📂 [`sql/05_bonus_integrity.sql`](../sql/05_bonus_integrity.sql) · 📄 [`results/B07~B14`](../results/README.md)

일부러 규칙을 어기는 입력을 시도하고, **왜 막히는지 / 어떻게 고쳐야 하는지** 를 기록했습니다. `-- @expect-error` 가 붙은 문장이 만약 성공하면 `run_all.py` 가 실패하도록 해서, 제약조건이 정말 동작하는지 매번 검증합니다.

| ID | 시도 | 결과 | 왜 막혔나 | 올바른 방법 |
| --- | --- | --- | --- | --- |
| B07 | 없는 회원(999)의 리뷰 INSERT | `FOREIGN KEY constraint failed` | `review.member_id` 가 가리킬 `member` 행이 없음 | 회원을 먼저 만든 뒤 리뷰 INSERT (B14) |
| B08 | 없는 장르(99)로 영화 INSERT | `FOREIGN KEY constraint failed` | 부모 `genre` 행이 없음 | 장르를 먼저 등록 |
| B09 | 영화가 남아 있는 '액션' 장르 DELETE | `FOREIGN KEY constraint failed` | `ON DELETE RESTRICT`: 4편이 참조 중 | 영화를 다른 장르로 옮긴 뒤 삭제. 참조 없는 '뮤지컬' 은 삭제 성공 |
| B10 | 별점 6 / 날짜 `2024-02-30`, `2024-13-01` / 상태 `BANNED` | `CHECK constraint failed: …` | 허용 범위 밖의 값 | 1~5, 실제 날짜, 정해진 상태값 |
| B11 | 같은 회원이 같은 영화에 두 번째 리뷰 / 중복 이메일 가입 | `UNIQUE constraint failed: review.member_id, review.movie_id` | 한 회원·한 영화 리뷰 1개 규칙 | 기존 리뷰를 UPDATE |
| B12 | 제목 NULL 인 영화 | `NOT NULL constraint failed: movie.title` | 필수 컬럼 | 값을 채워서 INSERT |
| B13 | `PRAGMA foreign_keys = OFF` 후 고아 리뷰 INSERT | **성공해 버림** | SQLite 는 FK 검사가 연결마다 꺼져 있을 수 있음 | 항상 `ON`. 이미 들어간 고아 행은 `PRAGMA foreign_key_check` 로 찾아 정리 |
| B14 | 부모(회원 16) → 자식(리뷰) 순서로, 한 트랜잭션으로 INSERT | 성공 | 참조할 부모가 먼저 존재 | — |

### B13 에서 확인한 것

```text
sqlite> PRAGMA foreign_keys = OFF;
sqlite> INSERT INTO review (review_id, member_id, …) VALUES (900, 999, …);   → OK (1 row affected)
sqlite> PRAGMA foreign_keys = ON;
sqlite> PRAGMA foreign_key_check;
table  | rowid | parent | fkid
review |   900 | member |    1      ← 다시 켜도 이미 들어간 고아 행은 그대로 남아 있다
sqlite> DELETE FROM review WHERE review_id = 900;
sqlite> PRAGMA foreign_key_check;  → (0 rows)
```

FK 를 다시 켜도 **기존 데이터는 자동으로 검사되지 않습니다.** 그래서 DB 도구에서 FK 설정을 확인하지 않고 데이터를 넣었다면, 나중에 `foreign_key_check` 로 반드시 점검해야 합니다.

### B10 에서 발견한 CHECK 의 함정

`'2024-13-01'` 은 처음 스키마(`CHECK (date(x) = x)`)에서는 **통과했습니다.** `date('2024-13-01')` 이 NULL 이고, `NULL = '…'` 도 NULL 인데, CHECK 는 거짓일 때만 막기 때문입니다. `IS` 비교로 바꿔 해결했고, 자세한 과정은 [`checklist.md` 4-2](checklist.md#4-2-미션-수행-중-가장-어려웠던-부분과-해결-방법을-구체적으로-말할-수-있는가-) 에 있습니다.

### 실제로 겪은 오류 메시지 (sqlite3 CLI 원문)

위 표의 메시지를 `sqlite3` 대화형 CLI(3.46.1)에서 직접 다시 입력해 받은 출력입니다. 손으로 고치지 않았고, 화면은 [`results/screenshots/ERR.png`](../results/screenshots/ERR.png) 입니다. 시드 직후 DB 를 새로 열었으므로 `PRAGMA foreign_keys` 는 기본값 0(꺼짐)에서 시작합니다.

```text
movie-review-db$ sqlite3 -header -separator ' | ' movie_review.db
SQLite version 3.46.1 2024-08-13 09:16:08
Enter ".help" for usage hints.
sqlite> PRAGMA foreign_keys;
foreign_keys
0
sqlite> INSERT INTO review (member_id, movie_id, rating, created_at) VALUES (999, 1, 5, '2024-10-01 12:00:00');
sqlite> PRAGMA foreign_key_check;
table | rowid | parent | fkid
review | 79 | member | 1
sqlite> DELETE FROM review WHERE member_id = 999;
sqlite> PRAGMA foreign_keys = ON;
sqlite> INSERT INTO review (member_id, movie_id, rating, created_at) VALUES (999, 1, 5, '2024-10-01 12:00:00');
Runtime error: FOREIGN KEY constraint failed (19)
sqlite> DELETE FROM genre WHERE name = '액션';
Runtime error: FOREIGN KEY constraint failed (19)
sqlite> UPDATE review SET rating = 6 WHERE review_id = 1;
Runtime error: CHECK constraint failed: rating BETWEEN 1 AND 5 (19)
sqlite> INSERT INTO member (email, nickname, joined_at) VALUES ('new@example.com', '새회원', '2024-13-01');
Runtime error: CHECK constraint failed: date(joined_at, '+0 days') IS joined_at (19)
sqlite> INSERT INTO review (member_id, movie_id, rating, created_at) VALUES (1, 1, 4, '2024-10-01 12:00:00');
Runtime error: UNIQUE constraint failed: review.member_id, review.movie_id (19)
sqlite> INSERT INTO review (member_id, movie_id, created_at) VALUES (1, 22, '2024-10-01 12:00:00');
Runtime error: NOT NULL constraint failed: review.rating (19)
sqlite> PRAGMA foreign_key_check;
sqlite> .quit
movie-review-db$ exit
exit
```

| 순서 | 상황 | 실제 메시지 | 읽는 법 |
| --- | --- | --- | --- |
| 1 | FK **꺼짐**(0)에서 없는 회원 999 의 리뷰 INSERT | (메시지 없음, 성공) | 검사를 안 하므로 고아 행이 들어간다. `foreign_key_check` 가 `review \| 79 \| member \| 1` 로 찾아낸다 |
| 2 | FK **켬** 후 같은 INSERT | `Runtime error: FOREIGN KEY constraint failed (19)` | 19 = `SQLITE_CONSTRAINT`. FK 메시지는 어느 FK 인지 알려 주지 않아 `foreign_key_check` 나 스키마로 찾아야 한다 |
| 3 | 영화 4편이 쓰는 '액션' DELETE | `FOREIGN KEY constraint failed (19)` | `ON DELETE RESTRICT` (B09) |
| 4 | 별점 6 으로 UPDATE | `CHECK constraint failed: rating BETWEEN 1 AND 5 (19)` | CHECK 메시지에는 **실패한 식이 그대로** 나온다 |
| 5 | 가입일 `2024-13-01` | `CHECK constraint failed: date(joined_at, '+0 days') IS joined_at (19)` | 날짜 CHECK 가 `IS` 로 NULL 까지 거부 (B10) |
| 6 | 같은 회원·영화 두 번째 리뷰 | `UNIQUE constraint failed: review.member_id, review.movie_id (19)` | 위반한 컬럼 조합이 나온다 (B11) |
| 7 | 별점 없이 리뷰 INSERT | `NOT NULL constraint failed: review.rating (19)` | 빠진 컬럼이 나온다 (B12) |

Python `sqlite3` 모듈(`run_all.py`)에서는 같은 문장이 `sqlite3.IntegrityError` 로 올라오고 메시지 본문은 같습니다(결과 파일의 `Error (예상된 오류): …` 줄, 예: [`B07`](../results/B07.txt)).
