# 실행 결과

`python scripts/run_all.py` 가 빈 DB 에 `01_schema.sql` → `02_seed.sql` 을 실행한 뒤, 아래 쿼리를 **순서대로** 실행한 실제 결과입니다.
쿼리별 텍스트 결과(sqlite3 CLI 형식)는 같은 폴더의 `Qnn.txt` · `Bnn.txt` 파일에 있습니다.

- SQLite 3.46.1
- 테이블 행 수: genre 10, member 15, movie 22, review 78 (모두 10행 이상)
- `PRAGMA foreign_key_check` 위반 0건

## 목차

| ID | 분류 | 내용 | 결과 파일 |
| --- | --- | --- | --- |
| [Q01](#q01--2020년-이후-개봉한-영화를-최신-개봉순으로-보기) | 기본 조회 | 2020년 이후 개봉한 영화를 최신 개봉순으로 보기 | [Q01.txt](Q01.txt) |
| [Q02](#q02--별점-5점-리뷰-중-가장-최근-5개) | 기본 조회 | 별점 5점 리뷰 중 가장 최근 5개 | [Q02.txt](Q02.txt) |
| [Q03](#q03--러닝타임-150분-이상인-긴-영화-긴-순서-같으면-제목순) | 기본 조회 | 러닝타임 150분 이상인 긴 영화 (긴 순서, 같으면 제목순) | [Q03.txt](Q03.txt) |
| [Q04](#q04--제목-검색-의-가-들어간-영화-like-부분-일치) | 기본 조회 | 제목 검색: '의' 가 들어간 영화 (LIKE 부분 일치) | [Q04.txt](Q04.txt) |
| [Q05](#q05--최근-리뷰-10개를-회원-닉네임영화-제목과-함께-보기-3개-테이블-조인) | 조인 (INNER) | 최근 리뷰 10개를 회원 닉네임·영화 제목과 함께 보기 (3개 테이블 조인) | [Q05.txt](Q05.txt) |
| [Q06](#q06--장르-이름과-함께-영화-목록-보기-장르--개봉일-순) | 조인 (INNER) | 장르 이름과 함께 영화 목록 보기 (장르 → 개봉일 순) | [Q06.txt](Q06.txt) |
| [Q07](#q07--리뷰를-한-번도-작성하지-않은-회원-찾기) | 조인 (LEFT) | 리뷰를 한 번도 작성하지 않은 회원 찾기 | [Q07.txt](Q07.txt) |
| [Q08](#q08--영화별-리뷰-수--리뷰가-없는-영화도-0으로-표시) | 조인 (LEFT) | 영화별 리뷰 수 — 리뷰가 없는 영화도 0으로 표시 | [Q08.txt](Q08.txt) |
| [Q09](#q09--평균-별점-top-5-영화-리뷰-3개-이상만-동점이면-리뷰-많은-순) | 집계 (랭킹) | 평균 별점 TOP 5 영화 (리뷰 3개 이상만, 동점이면 리뷰 많은 순) | [Q09.txt](Q09.txt) |
| [Q10](#q10--장르별-영화-수--리뷰-수--평균-별점-영화가-없는-장르도-포함) | 집계 | 장르별 영화 수 · 리뷰 수 · 평균 별점 (영화가 없는 장르도 포함) | [Q10.txt](Q10.txt) |
| [Q11](#q11--회원별-리뷰-수--평균-준-별점--총-관람-시간분--활동량-순) | 집계 | 회원별 리뷰 수 · 평균 준 별점 · 총 관람 시간(분) — 활동량 순 | [Q11.txt](Q11.txt) |
| [Q12](#q12--월별-리뷰-수와-평균-별점-추이) | 집계 (추가) | 월별 리뷰 수와 평균 별점 추이 | [Q12.txt](Q12.txt) |
| [Q13](#q13--전체-리뷰-평균-별점보다-평균이-높은-영화) | 서브쿼리 | 전체 리뷰 평균 별점보다 평균이 높은 영화 | [Q13.txt](Q13.txt) |
| [Q14](#q14--장르마다-평균-별점이-가장-높은-영화-동점이면-모두-표시) | 서브쿼리 (상관·추가) | 장르마다 평균 별점이 가장 높은 영화 (동점이면 모두 표시) | [Q14.txt](Q14.txt) |
| [Q15](#q15--2024-06-01-이후-리뷰가-없는-active-회원을-휴면dormant으로-전환) | 수정 (UPDATE) | 2024-06-01 이후 리뷰가 없는 ACTIVE 회원을 휴면(DORMANT)으로 전환 | [Q15.txt](Q15.txt) |
| [Q16](#q16--탈퇴withdrawn-회원-삭제--그-회원의-리뷰는-on-delete-cascade-로-함께-삭제) | 삭제 (DELETE) | 탈퇴(WITHDRAWN) 회원 삭제 → 그 회원의 리뷰는 ON DELETE CASCADE 로 함께 삭제 | [Q16.txt](Q16.txt) |
| [Q17](#q17--reviewmovie_id-인덱스-생성-전후-실행-계획-비교) | 인덱스 | review.movie_id 인덱스 생성 전/후 실행 계획 비교 | [Q17.txt](Q17.txt) |
| [B01](#b01--요구-a-①-inner-join--회원--리뷰-행이-늘어나므로-distinct-로-중복-제거) | 보너스: JOIN vs 서브쿼리 | 요구 A ① INNER JOIN — 회원 × 리뷰 행이 늘어나므로 DISTINCT 로 중복 제거 | [B01.txt](B01.txt) |
| [B02](#b02--요구-a-②-exists--회원마다-리뷰가-하나라도-있나만-확인-찾으면-즉시-멈춤) | 보너스: JOIN vs 서브쿼리 | 요구 A ② EXISTS — 회원마다 "리뷰가 하나라도 있나"만 확인 (찾으면 즉시 멈춤) | [B02.txt](B02.txt) |
| [B03](#b03--요구-a-③-in--리뷰를-쓴-member_id-목록을-먼저-만들고-그-안에-있는지-확인) | 보너스: JOIN vs 서브쿼리 | 요구 A ③ IN — 리뷰를 쓴 member_id 목록을 먼저 만들고 그 안에 있는지 확인 | [B03.txt](B03.txt) |
| [B04](#b04--세-방식의-결과가-정확히-같은지-검증-차집합이-모두-0행이어야-함) | 보너스: JOIN vs 서브쿼리 | 세 방식의 결과가 정확히 같은지 검증 (차집합이 모두 0행이어야 함) | [B04.txt](B04.txt) |
| [B05](#b05--실행-계획-비교-sqlite-전용-explain-query-plan) | 보너스: JOIN vs 서브쿼리 | 실행 계획 비교 [SQLite 전용: EXPLAIN QUERY PLAN] | [B05.txt](B05.txt) |
| [B06](#b06--요구-b--left-join--group-by-와-상관-스칼라-서브쿼리의-결과-비교) | 보너스: JOIN vs 서브쿼리 | 요구 B — LEFT JOIN + GROUP BY 와 상관 스칼라 서브쿼리의 결과 비교 | [B06.txt](B06.txt) |
| [B07](#b07--fk-위반-①-존재하지-않는-회원999의-리뷰를-insert) | 보너스: 정합성 | FK 위반 ① 존재하지 않는 회원(999)의 리뷰를 INSERT | [B07.txt](B07.txt) |
| [B08](#b08--fk-위반-②-존재하지-않는-장르99로-영화를-insert) | 보너스: 정합성 | FK 위반 ② 존재하지 않는 장르(99)로 영화를 INSERT | [B08.txt](B08.txt) |
| [B09](#b09--fk-위반-③-영화가-남아-있는-장르액션를-delete--on-delete-restrict) | 보너스: 정합성 | FK 위반 ③ 영화가 남아 있는 장르(액션)를 DELETE → ON DELETE RESTRICT | [B09.txt](B09.txt) |
| [B10](#b10--check-위반-별점-6점-존재하지-않는-날짜-허용되지-않는-회원-상태) | 보너스: 정합성 | CHECK 위반: 별점 6점, 존재하지 않는 날짜, 허용되지 않는 회원 상태 | [B10.txt](B10.txt) |
| [B11](#b11--unique-위반-같은-회원이-같은-영화에-두-번째-리뷰-이미-쓰는-이메일로-가입) | 보너스: 정합성 | UNIQUE 위반: 같은 회원이 같은 영화에 두 번째 리뷰, 이미 쓰는 이메일로 가입 | [B11.txt](B11.txt) |
| [B12](#b12--not-null-위반-제목-없는-영화) | 보너스: 정합성 | NOT NULL 위반: 제목 없는 영화 | [B12.txt](B12.txt) |
| [B13](#b13--fk-검사를-끄면-pragma-foreign_keys--off-상태에서는-고아-리뷰가-들어간다-sqlite-전용) | 보너스: 정합성 | FK 검사를 끄면? PRAGMA foreign_keys = OFF 상태에서는 고아 리뷰가 들어간다 [SQLite 전용] | [B13.txt](B13.txt) |
| [B14](#b14--해결-부모회원를-먼저-만들고-자식리뷰을-넣는다--한-트랜잭션으로-묶어서) | 보너스: 정합성 | 해결: 부모(회원)를 먼저 만들고 자식(리뷰)을 넣는다 — 한 트랜잭션으로 묶어서 | [B14.txt](B14.txt) |
| [R01](#r01--지표-1-월별-리뷰-활동-추이) | 보너스: 미니 리포트 | 지표 1. 월별 리뷰 활동 추이 | [R01.txt](R01.txt) |
| [R02](#r02--지표-2-인기-영화-top-10--베이지안-가중-평점) | 보너스: 미니 리포트 | 지표 2. 인기 영화 TOP 10 — 베이지안 가중 평점 | [R02.txt](R02.txt) |
| [R03](#r03--지표-3-장르별-만족도--호평률4점-이상--혹평률2점-이하) | 보너스: 미니 리포트 | 지표 3. 장르별 만족도 — 호평률(4점 이상) · 혹평률(2점 이하) | [R03.txt](R03.txt) |

## 결과

### Q01 · 2020년 이후 개봉한 영화를 최신 개봉순으로 보기

`기본 조회` · 원본: [`sql/03_queries.sql`](../sql/03_queries.sql)

```sql
SELECT title, release_date, running_time, country
FROM movie
WHERE release_date >= '2020-01-01'          -- ISO-8601 문자열은 사전순 = 날짜순이라 문자열 비교로 기간 검색이 된다
ORDER BY release_date DESC;
```

| title | release_date | running_time | country |
| --- | --- | ---: | --- |
| 인사이드 아웃 2 | 2024-06-12 | 96 | 미국 |
| 듄: 파트 2 | 2024-02-28 | 166 | 미국 |
| 파묘 | 2024-02-22 | 134 | 한국 |
| 서울의 봄 | 2023-11-22 | 141 | 한국 |
| 엘리멘탈 | 2023-06-14 | 109 | 미국 |
| 헤어질 결심 | 2022-06-29 | 138 | 한국 |
| 탑건: 매버릭 | 2022-06-22 | 130 | 미국 |

(7 rows)

### Q02 · 별점 5점 리뷰 중 가장 최근 5개

`기본 조회` · 원본: [`sql/03_queries.sql`](../sql/03_queries.sql)

```sql
SELECT review_id, movie_id, member_id, content, created_at
FROM review
WHERE rating = 5
ORDER BY created_at DESC
LIMIT 5;
```

| review_id | movie_id | member_id | content | created_at |
| ---: | ---: | ---: | --- | --- |
| 78 | 13 | 1 | 연출, 연기, 음악 모두 완벽 | 2024-09-25 17:40:26 |
| 77 | 8 | 2 | 연출, 연기, 음악 모두 완벽 | 2024-09-21 22:02:34 |
| 76 | 13 | 3 | IMAX 로 봐야 하는 영화. 모래벌레 등장 장면 최고 | 2024-09-17 18:14:52 |
| 74 | 8 | 5 | 결말을 알고 봐도 분노가 차오른다 | 2024-09-09 17:53:13 |
| 73 | 12 | 6 | 불안이를 보고 내 얘기 같아서 울컥했다 | 2024-09-05 10:54:30 |

(5 rows)

### Q03 · 러닝타임 150분 이상인 긴 영화 (긴 순서, 같으면 제목순)

`기본 조회` · 원본: [`sql/03_queries.sql`](../sql/03_queries.sql)

```sql
SELECT title, running_time, director
FROM movie
WHERE running_time >= 150
ORDER BY running_time DESC, title;
```

| title | running_time | director |
| --- | ---: | --- |
| 어벤져스: 엔드게임 | 181 | 루소 형제 |
| 반지의 제왕: 반지 원정대 | 178 | 피터 잭슨 |
| 인터스텔라 | 169 | 크리스토퍼 놀란 |
| 듄: 파트 2 | 166 | 드니 빌뇌브 |
| 해리 포터와 마법사의 돌 | 152 | 크리스 콜럼버스 |

(5 rows)

### Q04 · 제목 검색: '의' 가 들어간 영화 (LIKE 부분 일치)

`기본 조회` · 원본: [`sql/03_queries.sql`](../sql/03_queries.sql)

```sql
SELECT movie_id, title, release_date
FROM movie
WHERE title LIKE '%의%'
ORDER BY release_date;
```

| movie_id | title | release_date |
| ---: | --- | --- |
| 17 | 해리 포터와 마법사의 돌 | 2001-12-14 |
| 18 | 반지의 제왕: 반지 원정대 | 2001-12-31 |
| 22 | 7번방의 선물 | 2013-01-23 |
| 5 | 너의 이름은. | 2017-01-04 |
| 8 | 서울의 봄 | 2023-11-22 |

(5 rows)

### Q05 · 최근 리뷰 10개를 회원 닉네임·영화 제목과 함께 보기 (3개 테이블 조인)

`조인 (INNER)` · 원본: [`sql/03_queries.sql`](../sql/03_queries.sql)

```sql
SELECT r.created_at,
       mb.nickname,
       mv.title,
       r.rating,
       COALESCE(r.content, '(별점만 남김)') AS content
FROM review AS r
INNER JOIN member AS mb ON mb.member_id = r.member_id     -- review.member_id (FK) → member.member_id (PK)
INNER JOIN movie  AS mv ON mv.movie_id  = r.movie_id      -- review.movie_id  (FK) → movie.movie_id  (PK)
ORDER BY r.created_at DESC
LIMIT 10;
```

| created_at | nickname | title | rating | content |
| --- | --- | --- | ---: | --- |
| 2024-09-25 17:40:26 | 팝콘요정 | 듄: 파트 2 | 5 | 연출, 연기, 음악 모두 완벽 |
| 2024-09-21 22:02:34 | 시네필 | 서울의 봄 | 5 | 연출, 연기, 음악 모두 완벽 |
| 2024-09-17 18:14:52 | SF덕후 | 듄: 파트 2 | 5 | IMAX 로 봐야 하는 영화. 모래벌레 등장 장면 최고 |
| 2024-09-13 12:31:05 | 심야영화 | 듄: 파트 2 | 4 | 배우들 연기가 좋았다 |
| 2024-09-09 17:53:13 | 김평론 | 서울의 봄 | 5 | 결말을 알고 봐도 분노가 차오른다 |
| 2024-09-05 10:54:30 | 애니러버 | 인사이드 아웃 2 | 5 | 불안이를 보고 내 얘기 같아서 울컥했다 |
| 2024-09-01 21:38:40 | 스릴러킹 | 파묘 | 4 | 탄탄하고 재밌다. 중반이 살짝 늘어짐 |
| 2024-08-28 12:44:52 | 주말관객 | 서울의 봄 | 5 | 인생 영화 등극 |
| 2024-08-24 18:45:09 | 로맨스장인 | 인사이드 아웃 2 | 4 | 배우들 연기가 좋았다 |
| 2024-08-07 18:27:39 | 스릴러킹 | 서울의 봄 | 4 | 영상미가 훌륭하다 |

(10 rows)

### Q06 · 장르 이름과 함께 영화 목록 보기 (장르 → 개봉일 순)

`조인 (INNER)` · 원본: [`sql/03_queries.sql`](../sql/03_queries.sql)

```sql
SELECT g.name AS genre, m.title, m.release_date, m.director
FROM movie AS m
INNER JOIN genre AS g ON g.genre_id = m.genre_id
ORDER BY g.genre_id, m.release_date;
```

| genre | title | release_date | director |
| --- | --- | --- | --- |
| 액션 | 부산행 | 2016-07-20 | 연상호 |
| 액션 | 범죄도시 | 2017-10-03 | 강윤성 |
| 액션 | 어벤져스: 엔드게임 | 2019-04-24 | 루소 형제 |
| 액션 | 탑건: 매버릭 | 2022-06-22 | 조셉 코신스키 |
| 드라마 | 7번방의 선물 | 2013-01-23 | 이환경 |
| 드라마 | 기생충 | 2019-05-30 | 봉준호 |
| 드라마 | 서울의 봄 | 2023-11-22 | 김성수 |
| 코미디 | 극한직업 | 2019-01-23 | 이병헌 |
| SF | 인터스텔라 | 2014-11-06 | 크리스토퍼 놀란 |
| SF | 듄: 파트 2 | 2024-02-28 | 드니 빌뇌브 |
| 애니메이션 | 너의 이름은. | 2017-01-04 | 신카이 마코토 |
| 애니메이션 | 엘리멘탈 | 2023-06-14 | 피터 손 |
| 애니메이션 | 인사이드 아웃 2 | 2024-06-12 | 켈시 맨 |
| 로맨스 | 비긴 어게인 | 2014-08-13 | 존 카니 |
| 로맨스 | 라라랜드 | 2016-12-07 | 데이미언 셔젤 |
| 공포 | 곤지암 | 2018-03-28 | 정범식 |
| 공포 | 파묘 | 2024-02-22 | 장재현 |
| 스릴러 | 올드보이 | 2003-11-21 | 박찬욱 |
| 스릴러 | 겟 아웃 | 2017-05-17 | 조던 필 |
| 스릴러 | 헤어질 결심 | 2022-06-29 | 박찬욱 |
| 판타지 | 해리 포터와 마법사의 돌 | 2001-12-14 | 크리스 콜럼버스 |
| 판타지 | 반지의 제왕: 반지 원정대 | 2001-12-31 | 피터 잭슨 |

(22 rows)

### Q07 · 리뷰를 한 번도 작성하지 않은 회원 찾기

`조인 (LEFT)` · 원본: [`sql/03_queries.sql`](../sql/03_queries.sql)

```sql
SELECT mb.member_id, mb.nickname, mb.joined_at, mb.status
FROM member AS mb
LEFT JOIN review AS r ON r.member_id = mb.member_id   -- 리뷰가 없는 회원도 남기고, 리뷰 쪽 컬럼은 NULL
WHERE r.review_id IS NULL                             -- 짝이 없었던(NULL) 행만 고른다
ORDER BY mb.member_id;
```

| member_id | nickname | joined_at | status |
| ---: | --- | --- | --- |
| 12 | 새내기 | 2024-03-02 | ACTIVE |
| 13 | 잠수중 | 2023-02-14 | DORMANT |
| 14 | 눈팅족 | 2024-01-20 | ACTIVE |

(3 rows)

### Q08 · 영화별 리뷰 수 — 리뷰가 없는 영화도 0으로 표시

`조인 (LEFT)` · 원본: [`sql/03_queries.sql`](../sql/03_queries.sql)

```sql
SELECT m.title,
       COUNT(r.review_id) AS review_count            -- COUNT(*) 를 쓰면 리뷰 없는 영화도 1로 세진다
FROM movie AS m
LEFT JOIN review AS r ON r.movie_id = m.movie_id
GROUP BY m.movie_id, m.title
ORDER BY review_count DESC, m.title;
```

| title | review_count |
| --- | ---: |
| 기생충 | 7 |
| 어벤져스: 엔드게임 | 6 |
| 인터스텔라 | 6 |
| 라라랜드 | 5 |
| 범죄도시 | 5 |
| 파묘 | 5 |
| 곤지암 | 4 |
| 극한직업 | 4 |
| 너의 이름은. | 4 |
| 서울의 봄 | 4 |
| 탑건: 매버릭 | 4 |
| 겟 아웃 | 3 |
| 듄: 파트 2 | 3 |
| 부산행 | 3 |
| 엘리멘탈 | 3 |
| 해리 포터와 마법사의 돌 | 3 |
| 헤어질 결심 | 3 |
| 비긴 어게인 | 2 |
| 올드보이 | 2 |
| 인사이드 아웃 2 | 2 |
| 7번방의 선물 | 0 |
| 반지의 제왕: 반지 원정대 | 0 |

(22 rows)

### Q09 · 평균 별점 TOP 5 영화 (리뷰 3개 이상만, 동점이면 리뷰 많은 순)

`집계 (랭킹)` · 원본: [`sql/03_queries.sql`](../sql/03_queries.sql)

```sql
SELECT m.title,
       ROUND(AVG(r.rating), 2) AS avg_rating,
       COUNT(*)                AS review_count
FROM movie AS m
INNER JOIN review AS r ON r.movie_id = m.movie_id
GROUP BY m.movie_id, m.title
HAVING COUNT(*) >= 3                                 -- 그룹을 만든 뒤 거르는 조건은 WHERE 가 아니라 HAVING
ORDER BY avg_rating DESC, review_count DESC, m.title
LIMIT 5;
```

| title | avg_rating | review_count |
| --- | ---: | ---: |
| 서울의 봄 | 4.75 | 4 |
| 기생충 | 4.71 | 7 |
| 인터스텔라 | 4.67 | 6 |
| 듄: 파트 2 | 4.67 | 3 |
| 너의 이름은. | 4.5 | 4 |

(5 rows)

### Q10 · 장르별 영화 수 · 리뷰 수 · 평균 별점 (영화가 없는 장르도 포함)

`집계` · 원본: [`sql/03_queries.sql`](../sql/03_queries.sql)

```sql
SELECT g.name                              AS genre,
       COUNT(DISTINCT m.movie_id)          AS movie_count,   -- 리뷰 조인으로 영화 행이 복제되므로 DISTINCT
       COUNT(r.review_id)                  AS review_count,
       ROUND(AVG(r.rating), 2)             AS avg_rating     -- 리뷰가 없으면 AVG 는 NULL
FROM genre AS g
LEFT JOIN movie  AS m ON m.genre_id = g.genre_id
LEFT JOIN review AS r ON r.movie_id = m.movie_id
GROUP BY g.genre_id, g.name
ORDER BY review_count DESC, g.genre_id;
```

| genre | movie_count | review_count | avg_rating |
| --- | ---: | ---: | ---: |
| 액션 | 4 | 18 | 4.06 |
| 드라마 | 3 | 11 | 4.73 |
| SF | 2 | 9 | 4.67 |
| 애니메이션 | 3 | 9 | 4.44 |
| 공포 | 2 | 9 | 3 |
| 스릴러 | 3 | 8 | 4.25 |
| 로맨스 | 2 | 7 | 4.29 |
| 코미디 | 1 | 4 | 4 |
| 판타지 | 2 | 3 | 3.67 |
| 뮤지컬 | 0 | 0 | NULL |

(10 rows)

### Q11 · 회원별 리뷰 수 · 평균 준 별점 · 총 관람 시간(분) — 활동량 순

`집계` · 원본: [`sql/03_queries.sql`](../sql/03_queries.sql)

```sql
SELECT mb.nickname,
       COUNT(*)                  AS review_count,
       ROUND(AVG(r.rating), 2)   AS avg_given,
       SUM(mv.running_time)      AS total_minutes
FROM review AS r
INNER JOIN member AS mb ON mb.member_id = r.member_id
INNER JOIN movie  AS mv ON mv.movie_id  = r.movie_id
GROUP BY mb.member_id, mb.nickname
ORDER BY review_count DESC, avg_given DESC;
```

| nickname | review_count | avg_given | total_minutes |
| --- | ---: | ---: | ---: |
| 스릴러킹 | 10 | 3.7 | 1283 |
| 로맨스장인 | 9 | 4.67 | 1113 |
| 김평론 | 7 | 4.57 | 932 |
| 주말관객 | 7 | 4 | 985 |
| 가족나들이 | 7 | 3.86 | 885 |
| 심야영화 | 7 | 3.86 | 971 |
| 팝콘요정 | 6 | 4.67 | 893 |
| SF덕후 | 6 | 4.5 | 896 |
| 시네필 | 6 | 4.17 | 746 |
| 애니러버 | 6 | 4 | 695 |
| 공포체험 | 5 | 3.8 | 631 |
| 떠난관객 | 2 | 4.5 | 238 |

(12 rows)

### Q12 · 월별 리뷰 수와 평균 별점 추이

`집계 (추가)` · 원본: [`sql/03_queries.sql`](../sql/03_queries.sql)

_[SQLite 전용] strftime('%Y-%m', …). MySQL: DATE_FORMAT(created_at, '%Y-%m'), PostgreSQL: to_char(created_at, 'YYYY-MM')_

```sql
SELECT strftime('%Y-%m', created_at) AS month,
       COUNT(*)                      AS review_count,
       ROUND(AVG(rating), 2)         AS avg_rating
FROM review
GROUP BY month
ORDER BY month;
```

| month | review_count | avg_rating |
| --- | ---: | ---: |
| 2024-01 | 12 | 4.25 |
| 2024-02 | 9 | 4.22 |
| 2024-03 | 7 | 4.29 |
| 2024-04 | 12 | 3.83 |
| 2024-05 | 9 | 3.67 |
| 2024-06 | 9 | 4.44 |
| 2024-07 | 6 | 4.33 |
| 2024-08 | 7 | 4 |
| 2024-09 | 7 | 4.71 |

(9 rows)

### Q13 · 전체 리뷰 평균 별점보다 평균이 높은 영화

`서브쿼리` · 원본: [`sql/03_queries.sql`](../sql/03_queries.sql)

```sql
SELECT m.title,
       ROUND(AVG(r.rating), 2) AS avg_rating,
       (SELECT ROUND(AVG(rating), 2) FROM review) AS overall_avg      -- 스칼라 서브쿼리: 값 1개를 돌려준다
FROM movie AS m
INNER JOIN review AS r ON r.movie_id = m.movie_id
GROUP BY m.movie_id, m.title
HAVING AVG(r.rating) > (SELECT AVG(rating) FROM review)
ORDER BY avg_rating DESC, m.title;
```

| title | avg_rating | overall_avg |
| --- | ---: | ---: |
| 서울의 봄 | 4.75 | 4.17 |
| 기생충 | 4.71 | 4.17 |
| 듄: 파트 2 | 4.67 | 4.17 |
| 인터스텔라 | 4.67 | 4.17 |
| 너의 이름은. | 4.5 | 4.17 |
| 비긴 어게인 | 4.5 | 4.17 |
| 올드보이 | 4.5 | 4.17 |
| 인사이드 아웃 2 | 4.5 | 4.17 |
| 겟 아웃 | 4.33 | 4.17 |
| 엘리멘탈 | 4.33 | 4.17 |
| 탑건: 매버릭 | 4.25 | 4.17 |
| 라라랜드 | 4.2 | 4.17 |

(12 rows)

### Q14 · 장르마다 평균 별점이 가장 높은 영화 (동점이면 모두 표시)

`서브쿼리 (상관·추가)` · 원본: [`sql/03_queries.sql`](../sql/03_queries.sql)

```sql
WITH movie_avg AS (                                   -- CTE: 영화별 평균을 이름 붙인 임시 결과로 만든다 (View 아님)
    -- 1단계 기대 결과(리뷰가 있는 영화 20행 중 한 행): movie_id 1 | genre_id 2 | 기생충 | 4.714… | 7
    SELECT m.movie_id, m.genre_id, m.title,
           AVG(r.rating) AS avg_rating,
           COUNT(*)      AS review_count
    FROM movie AS m
    INNER JOIN review AS r ON r.movie_id = m.movie_id
    GROUP BY m.movie_id, m.genre_id, m.title
)
SELECT g.name AS genre,
       ma.title,
       ROUND(ma.avg_rating, 2) AS avg_rating,
       ma.review_count
FROM movie_avg AS ma
INNER JOIN genre AS g ON g.genre_id = ma.genre_id    -- 3단계 기대 결과: 기생충 행에 genre_id 2 → '드라마' 가 붙는다
WHERE ma.avg_rating = (SELECT MAX(x.avg_rating)        -- 상관 서브쿼리: 바깥 행의 genre_id 마다 다시 계산된다
                       FROM movie_avg AS x
                       WHERE x.genre_id = ma.genre_id)
-- 2단계 기대 결과: 바깥 행이 기생충(genre_id 2)이면 MAX = 4.75(서울의 봄) → 4.714… ≠ 4.75 라 기생충은 빠진다
-- 4단계 기대 결과(정렬 후 11행 중 첫 행, 동점 2쌍 포함): 드라마 | 서울의 봄 | 4.75 | 4
ORDER BY ma.avg_rating DESC, g.name;
```

| genre | title | avg_rating | review_count |
| --- | --- | ---: | ---: |
| 드라마 | 서울의 봄 | 4.75 | 4 |
| SF | 인터스텔라 | 4.67 | 6 |
| SF | 듄: 파트 2 | 4.67 | 3 |
| 로맨스 | 비긴 어게인 | 4.5 | 2 |
| 스릴러 | 올드보이 | 4.5 | 2 |
| 애니메이션 | 너의 이름은. | 4.5 | 4 |
| 애니메이션 | 인사이드 아웃 2 | 4.5 | 2 |
| 액션 | 탑건: 매버릭 | 4.25 | 4 |
| 코미디 | 극한직업 | 4 | 4 |
| 공포 | 파묘 | 3.8 | 5 |
| 판타지 | 해리 포터와 마법사의 돌 | 3.67 | 3 |

(11 rows)

### Q15 · 2024-06-01 이후 리뷰가 없는 ACTIVE 회원을 휴면(DORMANT)으로 전환

`수정 (UPDATE)` · 원본: [`sql/03_queries.sql`](../sql/03_queries.sql)

_변경 전: 대상 회원 확인_

```sql
SELECT mb.member_id, mb.nickname, mb.status,
       (SELECT MAX(created_at) FROM review WHERE member_id = mb.member_id) AS last_review_at
FROM member AS mb
WHERE mb.status = 'ACTIVE'
  AND NOT EXISTS (SELECT 1 FROM review AS r
                  WHERE r.member_id = mb.member_id AND r.created_at >= '2024-06-01')
ORDER BY mb.member_id;
```

| member_id | nickname | status | last_review_at |
| ---: | --- | --- | --- |
| 10 | 공포체험 | ACTIVE | 2024-05-18 16:29:19 |
| 11 | 가족나들이 | ACTIVE | 2024-05-25 10:46:32 |
| 12 | 새내기 | ACTIVE | NULL |
| 14 | 눈팅족 | ACTIVE | NULL |

(4 rows)

```sql
UPDATE member
SET status = 'DORMANT'
WHERE status = 'ACTIVE'
  AND NOT EXISTS (SELECT 1 FROM review AS r
                  WHERE r.member_id = member.member_id AND r.created_at >= '2024-06-01');
```

`OK (4 rows affected)`

_변경 후: 상태별 회원 수_

```sql
SELECT status, COUNT(*) AS member_count
FROM member
GROUP BY status
ORDER BY status;
```

| status | member_count |
| --- | ---: |
| ACTIVE | 9 |
| DORMANT | 5 |
| WITHDRAWN | 1 |

(3 rows)

### Q16 · 탈퇴(WITHDRAWN) 회원 삭제 → 그 회원의 리뷰는 ON DELETE CASCADE 로 함께 삭제

`삭제 (DELETE)` · 원본: [`sql/03_queries.sql`](../sql/03_queries.sql)

_삭제 전_

```sql
SELECT mb.nickname, mb.status, COUNT(r.review_id) AS review_count
FROM member AS mb
LEFT JOIN review AS r ON r.member_id = mb.member_id
WHERE mb.status = 'WITHDRAWN'
GROUP BY mb.member_id, mb.nickname, mb.status;
```

| nickname | status | review_count |
| --- | --- | ---: |
| 떠난관객 | WITHDRAWN | 2 |

(1 row)

```sql
DELETE FROM member
WHERE status = 'WITHDRAWN';
```

`OK (1 rows affected)`

_삭제 후: 회원 수와 리뷰 수 (리뷰 78 → 76, 고아 리뷰 0건)_

```sql
SELECT (SELECT COUNT(*) FROM member) AS member_count,
       (SELECT COUNT(*) FROM review) AS review_count,
       (SELECT COUNT(*) FROM review AS r
        WHERE NOT EXISTS (SELECT 1 FROM member AS mb WHERE mb.member_id = r.member_id)) AS orphan_reviews;
```

| member_count | review_count | orphan_reviews |
| ---: | ---: | ---: |
| 14 | 76 | 0 |

(1 row)

### Q17 · review.movie_id 인덱스 생성 전/후 실행 계획 비교

`인덱스` · 원본: [`sql/03_queries.sql`](../sql/03_queries.sql)

_적용 이유: review.movie_id 는 영화별 리뷰 조회·JOIN·GROUP BY(Q08~Q14)에 가장 자주 쓰이는 컬럼인데, SQLite 는 FK 컬럼에 인덱스를 자동으로 만들지 않고, UNIQUE(member_id, movie_id) 인덱스는 member_id 가 앞이라 movie_id 만으로는 사용할 수 없다. [SQLite 전용] EXPLAIN QUERY PLAN. MySQL/PostgreSQL: EXPLAIN 생성 전: 리뷰 테이블 전체를 훑는다 (SCAN)_

```sql
EXPLAIN QUERY PLAN
SELECT rating, content FROM review WHERE movie_id = 1;
```

```text
QUERY PLAN
`--SCAN review
```

```sql
CREATE INDEX idx_review_movie_id ON review (movie_id);
```

`OK`

_생성 후: 인덱스로 movie_id = 1 인 행만 찾아간다 (SEARCH … USING INDEX)_

```sql
EXPLAIN QUERY PLAN
SELECT rating, content FROM review WHERE movie_id = 1;
```

```text
QUERY PLAN
`--SEARCH review USING INDEX idx_review_movie_id (movie_id=?)
```

_같은 인덱스가 영화별 집계(Q09)의 JOIN 에도 쓰이는지 확인_

```sql
EXPLAIN QUERY PLAN
SELECT m.title, AVG(r.rating)
FROM movie AS m
INNER JOIN review AS r ON r.movie_id = m.movie_id
GROUP BY m.movie_id;
```

```text
QUERY PLAN
|--SCAN m
`--SEARCH r USING INDEX idx_review_movie_id (movie_id=?)
```

### B01 · 요구 A ① INNER JOIN — 회원 × 리뷰 행이 늘어나므로 DISTINCT 로 중복 제거

`보너스: JOIN vs 서브쿼리` · 원본: [`sql/04_bonus_join_vs_subquery.sql`](../sql/04_bonus_join_vs_subquery.sql)

```sql
SELECT DISTINCT mb.member_id, mb.nickname
FROM member AS mb
INNER JOIN review AS r ON r.member_id = mb.member_id
ORDER BY mb.member_id;
```

| member_id | nickname |
| ---: | --- |
| 1 | 팝콘요정 |
| 2 | 시네필 |
| 3 | SF덕후 |
| 4 | 심야영화 |
| 5 | 김평론 |
| 6 | 애니러버 |
| 7 | 스릴러킹 |
| 8 | 주말관객 |
| 9 | 로맨스장인 |
| 10 | 공포체험 |
| 11 | 가족나들이 |
| 15 | 떠난관객 |

(12 rows)

### B02 · 요구 A ② EXISTS — 회원마다 "리뷰가 하나라도 있나"만 확인 (찾으면 즉시 멈춤)

`보너스: JOIN vs 서브쿼리` · 원본: [`sql/04_bonus_join_vs_subquery.sql`](../sql/04_bonus_join_vs_subquery.sql)

```sql
SELECT mb.member_id, mb.nickname
FROM member AS mb
WHERE EXISTS (SELECT 1 FROM review AS r WHERE r.member_id = mb.member_id)
ORDER BY mb.member_id;
```

| member_id | nickname |
| ---: | --- |
| 1 | 팝콘요정 |
| 2 | 시네필 |
| 3 | SF덕후 |
| 4 | 심야영화 |
| 5 | 김평론 |
| 6 | 애니러버 |
| 7 | 스릴러킹 |
| 8 | 주말관객 |
| 9 | 로맨스장인 |
| 10 | 공포체험 |
| 11 | 가족나들이 |
| 15 | 떠난관객 |

(12 rows)

### B03 · 요구 A ③ IN — 리뷰를 쓴 member_id 목록을 먼저 만들고 그 안에 있는지 확인

`보너스: JOIN vs 서브쿼리` · 원본: [`sql/04_bonus_join_vs_subquery.sql`](../sql/04_bonus_join_vs_subquery.sql)

```sql
SELECT mb.member_id, mb.nickname
FROM member AS mb
WHERE mb.member_id IN (SELECT r.member_id FROM review AS r)
ORDER BY mb.member_id;
```

| member_id | nickname |
| ---: | --- |
| 1 | 팝콘요정 |
| 2 | 시네필 |
| 3 | SF덕후 |
| 4 | 심야영화 |
| 5 | 김평론 |
| 6 | 애니러버 |
| 7 | 스릴러킹 |
| 8 | 주말관객 |
| 9 | 로맨스장인 |
| 10 | 공포체험 |
| 11 | 가족나들이 |
| 15 | 떠난관객 |

(12 rows)

### B04 · 세 방식의 결과가 정확히 같은지 검증 (차집합이 모두 0행이어야 함)

`보너스: JOIN vs 서브쿼리` · 원본: [`sql/04_bonus_join_vs_subquery.sql`](../sql/04_bonus_join_vs_subquery.sql)

```sql
SELECT
    (SELECT COUNT(*) FROM (
        SELECT DISTINCT mb.member_id FROM member mb JOIN review r ON r.member_id = mb.member_id
        EXCEPT
        SELECT mb.member_id FROM member mb WHERE EXISTS (SELECT 1 FROM review r WHERE r.member_id = mb.member_id)
    )) AS join_minus_exists,
    (SELECT COUNT(*) FROM (
        SELECT mb.member_id FROM member mb WHERE EXISTS (SELECT 1 FROM review r WHERE r.member_id = mb.member_id)
        EXCEPT
        SELECT mb.member_id FROM member mb WHERE mb.member_id IN (SELECT member_id FROM review)
    )) AS exists_minus_in,
    (SELECT COUNT(*) FROM (
        SELECT mb.member_id FROM member mb WHERE mb.member_id IN (SELECT member_id FROM review)
        EXCEPT
        SELECT DISTINCT mb.member_id FROM member mb JOIN review r ON r.member_id = mb.member_id
    )) AS in_minus_join,
    (SELECT COUNT(*) FROM member mb JOIN review r ON r.member_id = mb.member_id) AS join_rows_before_distinct;
```

| join_minus_exists | exists_minus_in | in_minus_join | join_rows_before_distinct |
| ---: | ---: | ---: | ---: |
| 0 | 0 | 0 | 78 |

(1 row)

### B05 · 실행 계획 비교 [SQLite 전용: EXPLAIN QUERY PLAN]

`보너스: JOIN vs 서브쿼리` · 원본: [`sql/04_bonus_join_vs_subquery.sql`](../sql/04_bonus_join_vs_subquery.sql)

_① JOIN + DISTINCT: 결과 컬럼(member_id)이 회원 테이블의 유일 키라서, SQLite 옵티마이저가 임시 B-tree 없이 회원마다 리뷰 인덱스를 찾아보는 계획을 만든다 (조인된 78행을 만든 뒤 지우는 방식이 아님)_

```sql
EXPLAIN QUERY PLAN
SELECT DISTINCT mb.member_id, mb.nickname
FROM member AS mb INNER JOIN review AS r ON r.member_id = mb.member_id;
```

```text
QUERY PLAN
|--SCAN mb USING COVERING INDEX sqlite_autoindex_member_2
`--SEARCH r USING COVERING INDEX sqlite_autoindex_review_1 (member_id=?)
```

_② EXISTS: 회원마다 UNIQUE(member_id, movie_id) 자동 인덱스로 한 건만 찾아본다 (상관 서브쿼리)_

```sql
EXPLAIN QUERY PLAN
SELECT mb.member_id, mb.nickname
FROM member AS mb
WHERE EXISTS (SELECT 1 FROM review AS r WHERE r.member_id = mb.member_id);
```

```text
QUERY PLAN
|--SCAN mb USING COVERING INDEX sqlite_autoindex_member_2
`--CORRELATED SCALAR SUBQUERY 1
   `--SEARCH r USING COVERING INDEX sqlite_autoindex_review_1 (member_id=?)
```

_③ IN: 서브쿼리 결과를 한 번 만들어 두고(LIST SUBQUERY) 회원마다 그 목록에서 찾는다_

```sql
EXPLAIN QUERY PLAN
SELECT mb.member_id, mb.nickname
FROM member AS mb
WHERE mb.member_id IN (SELECT r.member_id FROM review AS r);
```

```text
QUERY PLAN
|--SEARCH mb USING INTEGER PRIMARY KEY (rowid=?)
`--LIST SUBQUERY 1
   `--SCAN r USING COVERING INDEX sqlite_autoindex_review_1
```

### B06 · 요구 B — LEFT JOIN + GROUP BY 와 상관 스칼라 서브쿼리의 결과 비교

`보너스: JOIN vs 서브쿼리` · 원본: [`sql/04_bonus_join_vs_subquery.sql`](../sql/04_bonus_join_vs_subquery.sql)

_① LEFT JOIN + GROUP BY: 한 번 조인한 뒤 묶어서 센다_

```sql
SELECT m.movie_id, m.title, COUNT(r.review_id) AS review_count
FROM movie AS m
LEFT JOIN review AS r ON r.movie_id = m.movie_id
GROUP BY m.movie_id, m.title
ORDER BY m.movie_id;
```

| movie_id | title | review_count |
| ---: | --- | ---: |
| 1 | 기생충 | 7 |
| 2 | 인터스텔라 | 6 |
| 3 | 범죄도시 | 5 |
| 4 | 극한직업 | 4 |
| 5 | 너의 이름은. | 4 |
| 6 | 라라랜드 | 5 |
| 7 | 어벤져스: 엔드게임 | 6 |
| 8 | 서울의 봄 | 4 |
| 9 | 파묘 | 5 |
| 10 | 곤지암 | 4 |
| 11 | 겟 아웃 | 3 |
| 12 | 인사이드 아웃 2 | 2 |
| 13 | 듄: 파트 2 | 3 |
| 14 | 탑건: 매버릭 | 4 |
| 15 | 헤어질 결심 | 3 |
| 16 | 올드보이 | 2 |
| 17 | 해리 포터와 마법사의 돌 | 3 |
| 18 | 반지의 제왕: 반지 원정대 | 0 |
| 19 | 부산행 | 3 |
| 20 | 엘리멘탈 | 3 |
| 21 | 비긴 어게인 | 2 |
| 22 | 7번방의 선물 | 0 |

(22 rows)

_② SELECT 절 상관 서브쿼리: 영화 한 편마다 리뷰 수를 따로 센다_

```sql
SELECT m.movie_id, m.title,
       (SELECT COUNT(*) FROM review AS r WHERE r.movie_id = m.movie_id) AS review_count
FROM movie AS m
ORDER BY m.movie_id;
```

| movie_id | title | review_count |
| ---: | --- | ---: |
| 1 | 기생충 | 7 |
| 2 | 인터스텔라 | 6 |
| 3 | 범죄도시 | 5 |
| 4 | 극한직업 | 4 |
| 5 | 너의 이름은. | 4 |
| 6 | 라라랜드 | 5 |
| 7 | 어벤져스: 엔드게임 | 6 |
| 8 | 서울의 봄 | 4 |
| 9 | 파묘 | 5 |
| 10 | 곤지암 | 4 |
| 11 | 겟 아웃 | 3 |
| 12 | 인사이드 아웃 2 | 2 |
| 13 | 듄: 파트 2 | 3 |
| 14 | 탑건: 매버릭 | 4 |
| 15 | 헤어질 결심 | 3 |
| 16 | 올드보이 | 2 |
| 17 | 해리 포터와 마법사의 돌 | 3 |
| 18 | 반지의 제왕: 반지 원정대 | 0 |
| 19 | 부산행 | 3 |
| 20 | 엘리멘탈 | 3 |
| 21 | 비긴 어게인 | 2 |
| 22 | 7번방의 선물 | 0 |

(22 rows)

_두 결과가 같은지 검증 (서로 다른 행 0개)_

```sql
SELECT COUNT(*) AS mismatched_rows
FROM (
    SELECT m.movie_id, COUNT(r.review_id) AS c FROM movie m LEFT JOIN review r ON r.movie_id = m.movie_id GROUP BY m.movie_id
    EXCEPT
    SELECT m.movie_id, (SELECT COUNT(*) FROM review r WHERE r.movie_id = m.movie_id) FROM movie m
);
```

| mismatched_rows |
| ---: |
| 0 |

(1 row)

### B07 · FK 위반 ① 존재하지 않는 회원(999)의 리뷰를 INSERT

`보너스: 정합성` · 원본: [`sql/05_bonus_integrity.sql`](../sql/05_bonus_integrity.sql)

```sql
INSERT INTO review (member_id, movie_id, rating, content, created_at)
VALUES (999, 1, 5, '없는 회원이 쓴 리뷰', '2024-10-01 10:00:00');
```

```text
Error (예상된 오류): FOREIGN KEY constraint failed
```

### B08 · FK 위반 ② 존재하지 않는 장르(99)로 영화를 INSERT

`보너스: 정합성` · 원본: [`sql/05_bonus_integrity.sql`](../sql/05_bonus_integrity.sql)

```sql
INSERT INTO movie (genre_id, title, release_date, running_time, country, director)
VALUES (99, '장르가 없는 영화', '2024-10-01', 100, '한국', '미상');
```

```text
Error (예상된 오류): FOREIGN KEY constraint failed
```

### B09 · FK 위반 ③ 영화가 남아 있는 장르(액션)를 DELETE → ON DELETE RESTRICT

`보너스: 정합성` · 원본: [`sql/05_bonus_integrity.sql`](../sql/05_bonus_integrity.sql)

```sql
DELETE FROM genre WHERE name = '액션';
```

```text
Error (예상된 오류): FOREIGN KEY constraint failed
```

_참조하는 영화가 없는 장르(뮤지컬)는 지울 수 있다 → RESTRICT 는 "쓰이는 부모"만 보호한다_

```sql
DELETE FROM genre WHERE name = '뮤지컬';
```

`OK (1 rows affected)`

### B10 · CHECK 위반: 별점 6점, 존재하지 않는 날짜, 허용되지 않는 회원 상태

`보너스: 정합성` · 원본: [`sql/05_bonus_integrity.sql`](../sql/05_bonus_integrity.sql)

```sql
INSERT INTO review (member_id, movie_id, rating, content, created_at)
VALUES (12, 1, 6, '별점 6점?', '2024-10-01 10:00:00');
```

```text
Error (예상된 오류): CHECK constraint failed: rating BETWEEN 1 AND 5
```

```sql
INSERT INTO movie (genre_id, title, release_date, running_time, country, director)
VALUES (2, '날짜 오류 영화', '2024-02-30', 100, '한국', '미상');
```

```text
Error (예상된 오류): CHECK constraint failed: date(release_date, '+0 days') IS release_date
```

_CHECK 를 date(x) = x 로 만들었다면 이 행은 통과했다 (date('2024-13-01') 이 NULL → CHECK 가 NULL 을 통과시킴). IS 로 비교하도록 고쳐서 막힌다. '2024-02-30' 은 '+0 days' 수식어로 버전과 상관없이 막는다. 01_schema.sql 주석 참고_

```sql
INSERT INTO movie (genre_id, title, release_date, running_time, country, director)
VALUES (2, '13월 영화', '2024-13-01', 100, '한국', '미상');
```

```text
Error (예상된 오류): CHECK constraint failed: date(release_date, '+0 days') IS release_date
```

```sql
UPDATE member SET status = 'BANNED' WHERE member_id = 1;
```

```text
Error (예상된 오류): CHECK constraint failed: status IN ('ACTIVE', 'DORMANT', 'WITHDRAWN')
```

### B11 · UNIQUE 위반: 같은 회원이 같은 영화에 두 번째 리뷰, 이미 쓰는 이메일로 가입

`보너스: 정합성` · 원본: [`sql/05_bonus_integrity.sql`](../sql/05_bonus_integrity.sql)

```sql
INSERT INTO review (member_id, movie_id, rating, content, created_at)
VALUES (1, 1, 3, '두 번째 리뷰', '2024-10-01 10:00:00');
```

```text
Error (예상된 오류): UNIQUE constraint failed: review.member_id, review.movie_id
```

```sql
INSERT INTO member (email, nickname, birth_year, joined_at)
VALUES ('popcorn@example.com', '팝콘요정2', 1995, '2024-10-01');
```

```text
Error (예상된 오류): UNIQUE constraint failed: member.email
```

### B12 · NOT NULL 위반: 제목 없는 영화

`보너스: 정합성` · 원본: [`sql/05_bonus_integrity.sql`](../sql/05_bonus_integrity.sql)

```sql
INSERT INTO movie (genre_id, title, release_date, running_time, country, director)
VALUES (2, NULL, '2024-10-01', 100, '한국', '미상');
```

```text
Error (예상된 오류): NOT NULL constraint failed: movie.title
```

### B13 · FK 검사를 끄면? PRAGMA foreign_keys = OFF 상태에서는 고아 리뷰가 들어간다 [SQLite 전용]

`보너스: 정합성` · 원본: [`sql/05_bonus_integrity.sql`](../sql/05_bonus_integrity.sql)

```sql
PRAGMA foreign_keys = OFF;
```

`OK`

```sql
INSERT INTO review (review_id, member_id, movie_id, rating, content, created_at)
VALUES (900, 999, 1, 5, 'FK 검사가 꺼져서 들어간 고아 리뷰', '2024-10-01 10:00:00');
```

`OK (1 rows affected)`

_다시 켜도 이미 들어간 데이터는 자동으로 검사되지 않는다 → foreign_key_check 로 찾아야 한다_

```sql
PRAGMA foreign_keys = ON;
```

`OK`

```sql
PRAGMA foreign_key_check;
```

| table | rowid | parent | fkid |
| --- | ---: | --- | ---: |
| review | 900 | member | 1 |

(1 row)

_고아 행을 정리하고 다시 확인 (위반 0건)_

```sql
DELETE FROM review WHERE review_id = 900;
```

`OK (1 rows affected)`

```sql
PRAGMA foreign_key_check;
```

| table | rowid | parent | fkid |
| --- | --- | --- | --- |

(0 rows)

### B14 · 해결: 부모(회원)를 먼저 만들고 자식(리뷰)을 넣는다 — 한 트랜잭션으로 묶어서

`보너스: 정합성` · 원본: [`sql/05_bonus_integrity.sql`](../sql/05_bonus_integrity.sql)

```sql
BEGIN TRANSACTION;
```

`OK`

```sql
INSERT INTO member (member_id, email, nickname, birth_year, joined_at)
VALUES (16, 'latecomer@example.com', '늦깎이', 1994, '2024-10-01');
```

`OK (1 rows affected)`

```sql
INSERT INTO review (member_id, movie_id, rating, content, created_at)
VALUES (16, 1, 5, '부모 행이 먼저 있으니 성공', '2024-10-02 20:00:00');
```

`OK (1 rows affected)`

```sql
COMMIT;
```

`OK`

```sql
SELECT mb.nickname, mv.title, r.rating, r.content
FROM review AS r
JOIN member AS mb ON mb.member_id = r.member_id
JOIN movie  AS mv ON mv.movie_id  = r.movie_id
WHERE r.member_id = 16;
```

| nickname | title | rating | content |
| --- | --- | ---: | --- |
| 늦깎이 | 기생충 | 5 | 부모 행이 먼저 있으니 성공 |

(1 row)

### R01 · 지표 1. 월별 리뷰 활동 추이

`보너스: 미니 리포트` · 원본: [`sql/06_bonus_mini_report.sql`](../sql/06_bonus_mini_report.sql)

_호평률 = 별점 4점 이상 리뷰 비율(%). [SQLite 전용] strftime_

```sql
SELECT strftime('%Y-%m', created_at)                                     AS month,
       COUNT(*)                                                          AS reviews,
       COUNT(DISTINCT member_id)                                         AS active_reviewers,
       ROUND(AVG(rating), 2)                                             AS avg_rating,
       ROUND(100.0 * SUM(CASE WHEN rating >= 4 THEN 1 ELSE 0 END) / COUNT(*), 1) AS positive_pct
FROM review
GROUP BY month
ORDER BY month;
```

| month | reviews | active_reviewers | avg_rating | positive_pct |
| --- | ---: | ---: | ---: | ---: |
| 2024-01 | 12 | 11 | 4.25 | 91.7 |
| 2024-02 | 9 | 9 | 4.22 | 88.9 |
| 2024-03 | 7 | 7 | 4.29 | 85.7 |
| 2024-04 | 12 | 12 | 3.83 | 66.7 |
| 2024-05 | 9 | 7 | 3.67 | 55.6 |
| 2024-06 | 9 | 9 | 4.44 | 100 |
| 2024-07 | 6 | 5 | 4.33 | 83.3 |
| 2024-08 | 7 | 7 | 4 | 85.7 |
| 2024-09 | 7 | 7 | 4.71 | 100 |

(9 rows)

### R02 · 지표 2. 인기 영화 TOP 10 — 베이지안 가중 평점

`보너스: 미니 리포트` · 원본: [`sql/06_bonus_mini_report.sql`](../sql/06_bonus_mini_report.sql)

_가중 평점 = (v × R + m × C) / (v + m) v = 영화의 리뷰 수, R = 영화의 평균 별점, C = 전체 평균 별점, m = 최소 신뢰 리뷰 수(3) 리뷰가 적은 영화는 전체 평균(C) 쪽으로 끌어당겨, 리뷰 2개짜리 5.0 이 리뷰 7개짜리 4.7 을 이기는 왜곡을 막는다._

```sql
WITH overall AS (
    SELECT AVG(rating) AS c, 3 AS m FROM review
),
per_movie AS (
    SELECT movie_id, COUNT(*) AS v, AVG(rating) AS r
    FROM review
    GROUP BY movie_id
)
SELECT mv.title,
       pm.v                                            AS review_count,
       ROUND(pm.r, 2)                                  AS avg_rating,
       ROUND((pm.v * pm.r + o.m * o.c) / (pm.v + o.m), 3) AS weighted_score
FROM per_movie AS pm
INNER JOIN movie AS mv ON mv.movie_id = pm.movie_id
CROSS JOIN overall AS o
ORDER BY weighted_score DESC, review_count DESC, mv.title
LIMIT 10;
```

| title | review_count | avg_rating | weighted_score |
| --- | ---: | ---: | ---: |
| 기생충 | 7 | 4.71 | 4.55 |
| 인터스텔라 | 6 | 4.67 | 4.5 |
| 서울의 봄 | 4 | 4.75 | 4.5 |
| 듄: 파트 2 | 3 | 4.67 | 4.417 |
| 너의 이름은. | 4 | 4.5 | 4.357 |
| 비긴 어게인 | 2 | 4.5 | 4.3 |
| 올드보이 | 2 | 4.5 | 4.3 |
| 인사이드 아웃 2 | 2 | 4.5 | 4.3 |
| 겟 아웃 | 3 | 4.33 | 4.25 |
| 엘리멘탈 | 3 | 4.33 | 4.25 |

(10 rows)

### R03 · 지표 3. 장르별 만족도 — 호평률(4점 이상) · 혹평률(2점 이하)

`보너스: 미니 리포트` · 원본: [`sql/06_bonus_mini_report.sql`](../sql/06_bonus_mini_report.sql)

```sql
SELECT g.name                                                                         AS genre,
       COUNT(r.review_id)                                                             AS reviews,
       ROUND(AVG(r.rating), 2)                                                        AS avg_rating,
       ROUND(100.0 * SUM(CASE WHEN r.rating >= 4 THEN 1 ELSE 0 END) / COUNT(r.review_id), 1) AS positive_pct,
       ROUND(100.0 * SUM(CASE WHEN r.rating <= 2 THEN 1 ELSE 0 END) / COUNT(r.review_id), 1) AS negative_pct
FROM genre AS g
INNER JOIN movie  AS m ON m.genre_id = g.genre_id
INNER JOIN review AS r ON r.movie_id = m.movie_id
GROUP BY g.genre_id, g.name
ORDER BY positive_pct DESC, reviews DESC;
```

| genre | reviews | avg_rating | positive_pct | negative_pct |
| --- | ---: | ---: | ---: | ---: |
| 드라마 | 11 | 4.73 | 100 | 0 |
| 애니메이션 | 9 | 4.44 | 100 | 0 |
| SF | 9 | 4.67 | 100 | 0 |
| 스릴러 | 8 | 4.25 | 87.5 | 0 |
| 로맨스 | 7 | 4.29 | 85.7 | 0 |
| 액션 | 18 | 4.06 | 83.3 | 0 |
| 코미디 | 4 | 4 | 75 | 0 |
| 판타지 | 3 | 3.67 | 66.7 | 0 |
| 공포 | 9 | 3 | 33.3 | 33.3 |

(9 rows)
