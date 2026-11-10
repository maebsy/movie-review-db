-- =============================================================================
-- 03_queries.sql — 쿼리 17개 = 과제 필수 15개 + 추가 2개 (Q12, Q14) · 실행 순서 3/3
--
--   분류            필수  추가  쿼리
--   기본 조회        4     -    Q01 ~ Q04         (WHERE · ORDER BY · LIMIT · LIKE)
--   조인            4     -    Q05 ~ Q08         (INNER JOIN 2 · LEFT JOIN 2)
--   집계            3     1    Q09 ~ Q11 + Q12   (COUNT · SUM · AVG · GROUP BY · HAVING)
--   서브쿼리         1     1    Q13 + Q14         (스칼라 서브쿼리 / 상관 서브쿼리 + CTE)
--   수정 / 삭제      2     -    Q15 ~ Q16         (UPDATE · DELETE + CASCADE)
--   인덱스          1     -    Q17               (CREATE INDEX + 실행 계획 비교)
--   합계            15    2
--
--   추가 2개를 둔 이유: Q12 는 시간 축(월별) 집계와 SQLite 전용 strftime 의 대응 문법 예시,
--   Q14 는 "그룹별 최댓값을 가진 행 전체" 를 CTE + 상관 서브쿼리로 푸는 연습(회고 4-1)이다.
--   두 쿼리는 마커의 분류에 "추가" 를 붙여 필수 15개와 구분한다 (test_required_fifteen_match_categories 가 검사).
--
--   쿼리별 요구 유형: Q01~Q04 조회 · Q05 Q06 조인(INNER) · Q07 Q08 조인(LEFT) · Q09~Q11 집계 · Q12 집계(추가)
--                    · Q13 서브쿼리 · Q14 서브쿼리(추가) · Q15 수정 · Q16 삭제 · Q17 인덱스
--   실행 순서와 의존성: Q01~Q14 는 읽기 전용이라 순서와 무관 → Q15 UPDATE(회원 상태 변경) → Q16 DELETE(회원 1명 ·
--                    리뷰 2건 삭제, 이후 리뷰 76행) → Q17 인덱스 생성(결과 행은 그대로, 실행 계획만 바뀜).
--                    Q15·Q16 이 데이터를 바꾸므로 처음부터 다시 실행하려면 01_schema → 02_seed 부터.
--
--   02_seed.sql 직후의 데이터 기준이며, Q15·Q16 은 데이터를 바꾸므로 순서대로 실행한다.
--   각 쿼리 위의 "-- @Qnn | 분류 | 설명" 줄은 scripts/run_all.py 가 결과 파일 이름과 제목으로 사용한다.
-- =============================================================================

PRAGMA foreign_keys = ON;  -- [SQLite 전용]


-- @Q01 | 기본 조회 | 2020년 이후 개봉한 영화를 최신 개봉순으로 보기
SELECT title, release_date, running_time, country
FROM movie
WHERE release_date >= '2020-01-01'          -- ISO-8601 문자열은 사전순 = 날짜순이라 문자열 비교로 기간 검색이 된다
ORDER BY release_date DESC;


-- @Q02 | 기본 조회 | 별점 5점 리뷰 중 가장 최근 5개
SELECT review_id, movie_id, member_id, content, created_at
FROM review
WHERE rating = 5
ORDER BY created_at DESC
LIMIT 5;


-- @Q03 | 기본 조회 | 러닝타임 150분 이상인 긴 영화 (긴 순서, 같으면 제목순)
SELECT title, running_time, director
FROM movie
WHERE running_time >= 150
ORDER BY running_time DESC, title;


-- @Q04 | 기본 조회 | 제목 검색: '의' 가 들어간 영화 (LIKE 부분 일치)
SELECT movie_id, title, release_date
FROM movie
WHERE title LIKE '%의%'
ORDER BY release_date;


-- @Q05 | 조인 (INNER) | 최근 리뷰 10개를 회원 닉네임·영화 제목과 함께 보기 (3개 테이블 조인)
SELECT r.created_at,
       mb.nickname,
       mv.title,
       r.rating,
       COALESCE(r.content, '(별점만 남김)') AS content
FROM review AS r
-- INNER JOIN 은 ON 조건에 짝이 있는 행만 남긴다: 리뷰가 없는 회원 3명(12~14)과 영화 2편(18, 22)은 짝이 없어
-- 이 조인 결과(78행)에서 빠진다. 짝이 없는 쪽을 NULL 로 채워 남기는 LEFT JOIN(Q07 · Q08)과 반대.
INNER JOIN member AS mb ON mb.member_id = r.member_id     -- review.member_id (FK) → member.member_id (PK)
INNER JOIN movie  AS mv ON mv.movie_id  = r.movie_id      -- review.movie_id  (FK) → movie.movie_id  (PK)
ORDER BY r.created_at DESC
LIMIT 10;


-- @Q06 | 조인 (INNER) | 장르 이름과 함께 영화 목록 보기 (장르 → 개봉일 순)
SELECT g.name AS genre, m.title, m.release_date, m.director
FROM movie AS m
INNER JOIN genre AS g ON g.genre_id = m.genre_id   -- 짝이 있는 행만: 영화가 없는 장르 '뮤지컬' 은 빠져 10개 중 9개 장르만 나온다
ORDER BY g.genre_id, m.release_date;


-- @Q07 | 조인 (LEFT) | 리뷰를 한 번도 작성하지 않은 회원 찾기
SELECT mb.member_id, mb.nickname, mb.joined_at, mb.status
FROM member AS mb
LEFT JOIN review AS r ON r.member_id = mb.member_id   -- 리뷰가 없는 회원도 남기고, 리뷰 쪽 컬럼은 NULL
WHERE r.review_id IS NULL                             -- 짝이 없었던(NULL) 행만 고른다
ORDER BY mb.member_id;


-- @Q08 | 조인 (LEFT) | 영화별 리뷰 수 — 리뷰가 없는 영화도 0으로 표시
SELECT m.title,
       COUNT(r.review_id) AS review_count            -- COUNT(*) 를 쓰면 리뷰 없는 영화도 1로 세진다
FROM movie AS m
LEFT JOIN review AS r ON r.movie_id = m.movie_id
GROUP BY m.movie_id, m.title
ORDER BY review_count DESC, m.title;


-- @Q09 | 집계 (랭킹) | 평균 별점 TOP 5 영화 (리뷰 3개 이상만, 동점이면 리뷰 많은 순)
SELECT m.title,
       ROUND(AVG(r.rating), 2) AS avg_rating,
       COUNT(*)                AS review_count
FROM movie AS m
INNER JOIN review AS r ON r.movie_id = m.movie_id
GROUP BY m.movie_id, m.title
HAVING COUNT(*) >= 3                                 -- 그룹을 만든 뒤 거르는 조건은 WHERE 가 아니라 HAVING
ORDER BY avg_rating DESC, review_count DESC, m.title
LIMIT 5;


-- @Q10 | 집계 | 장르별 영화 수 · 리뷰 수 · 평균 별점 (영화가 없는 장르도 포함)
SELECT g.name                              AS genre,
       COUNT(DISTINCT m.movie_id)          AS movie_count,   -- 리뷰 조인으로 영화 행이 복제되므로 DISTINCT
       COUNT(r.review_id)                  AS review_count,
       ROUND(AVG(r.rating), 2)             AS avg_rating     -- 리뷰가 없으면 AVG 는 NULL
-- NULL 처리: COUNT(r.review_id) · AVG(r.rating) 는 NULL 을 건너뛰므로 리뷰 없는 '뮤지컬' 은 0 · NULL 이 된다.
--            COUNT(*) 는 행 자체를 세서 1 이 됐을 것이다. 같은 원리로 전체 리뷰는 COUNT(*) 78, COUNT(content) 74 (내용 NULL 4건 제외)
FROM genre AS g
LEFT JOIN movie  AS m ON m.genre_id = g.genre_id
LEFT JOIN review AS r ON r.movie_id = m.movie_id
GROUP BY g.genre_id, g.name
ORDER BY review_count DESC, g.genre_id;


-- @Q11 | 집계 | 회원별 리뷰 수 · 평균 준 별점 · 총 관람 시간(분) — 활동량 순
SELECT mb.nickname,
       COUNT(*)                  AS review_count,
       ROUND(AVG(r.rating), 2)   AS avg_given,
       SUM(mv.running_time)      AS total_minutes
FROM review AS r
INNER JOIN member AS mb ON mb.member_id = r.member_id
INNER JOIN movie  AS mv ON mv.movie_id  = r.movie_id
GROUP BY mb.member_id, mb.nickname
ORDER BY review_count DESC, avg_given DESC;


-- @Q12 | 집계 (추가) | 월별 리뷰 수와 평균 별점 추이
-- [SQLite 전용] strftime('%Y-%m', …). MySQL: DATE_FORMAT(created_at, '%Y-%m'), PostgreSQL: to_char(created_at, 'YYYY-MM')
SELECT strftime('%Y-%m', created_at) AS month,
       COUNT(*)                      AS review_count,
       ROUND(AVG(rating), 2)         AS avg_rating
FROM review
GROUP BY month
ORDER BY month;


-- @Q13 | 서브쿼리 | 전체 리뷰 평균 별점보다 평균이 높은 영화
SELECT m.title,
       ROUND(AVG(r.rating), 2) AS avg_rating,
       (SELECT ROUND(AVG(rating), 2) FROM review) AS overall_avg      -- 스칼라 서브쿼리: 값 1개를 돌려준다
FROM movie AS m
INNER JOIN review AS r ON r.movie_id = m.movie_id
GROUP BY m.movie_id, m.title
HAVING AVG(r.rating) > (SELECT AVG(rating) FROM review)
ORDER BY avg_rating DESC, m.title;


-- @Q14 | 서브쿼리 (상관·추가) | 장르마다 평균 별점이 가장 높은 영화 (동점이면 모두 표시)
-- 중간 결과 확인: 드라마(genre_id 2)의 1단계 행(movie_avg)과 2단계 상관 서브쿼리 값(genre_max), 남는지 여부(kept)
WITH movie_avg AS (
    SELECT m.movie_id, m.genre_id, m.title, AVG(r.rating) AS avg_rating, COUNT(*) AS review_count
    FROM movie AS m
    INNER JOIN review AS r ON r.movie_id = m.movie_id
    GROUP BY m.movie_id, m.genre_id, m.title
)
SELECT ma.movie_id, ma.title, ROUND(ma.avg_rating, 3) AS avg_rating, ma.review_count,
       ROUND((SELECT MAX(x.avg_rating) FROM movie_avg AS x WHERE x.genre_id = ma.genre_id), 3) AS genre_max,
       ma.avg_rating = (SELECT MAX(x.avg_rating) FROM movie_avg AS x WHERE x.genre_id = ma.genre_id) AS kept
FROM movie_avg AS ma
WHERE ma.genre_id = 2
ORDER BY ma.avg_rating DESC;

-- 최종: 모든 장르에 같은 규칙 적용
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


-- @Q15 | 수정 (UPDATE) | 2024-06-01 이후 리뷰가 없는 ACTIVE 회원을 휴면(DORMANT)으로 전환
-- 변경 전: 대상 회원 확인
SELECT mb.member_id, mb.nickname, mb.status,
       (SELECT MAX(created_at) FROM review WHERE member_id = mb.member_id) AS last_review_at
FROM member AS mb
WHERE mb.status = 'ACTIVE'
  AND NOT EXISTS (SELECT 1 FROM review AS r
                  WHERE r.member_id = mb.member_id AND r.created_at >= '2024-06-01')
ORDER BY mb.member_id;

UPDATE member
SET status = 'DORMANT'
WHERE status = 'ACTIVE'
  AND NOT EXISTS (SELECT 1 FROM review AS r
                  WHERE r.member_id = member.member_id AND r.created_at >= '2024-06-01');

-- 변경 후: 상태별 회원 수
SELECT status, COUNT(*) AS member_count
FROM member
GROUP BY status
ORDER BY status;


-- @Q16 | 삭제 (DELETE) | 탈퇴(WITHDRAWN) 회원 삭제 → 그 회원의 리뷰는 ON DELETE CASCADE 로 함께 삭제
-- 삭제 전
SELECT mb.nickname, mb.status, COUNT(r.review_id) AS review_count
FROM member AS mb
LEFT JOIN review AS r ON r.member_id = mb.member_id
WHERE mb.status = 'WITHDRAWN'
GROUP BY mb.member_id, mb.nickname, mb.status;

DELETE FROM member
WHERE status = 'WITHDRAWN';

-- 삭제 후: 회원 수와 리뷰 수 (리뷰 78 → 76, 고아 리뷰 0건)
SELECT (SELECT COUNT(*) FROM member) AS member_count,
       (SELECT COUNT(*) FROM review) AS review_count,
       (SELECT COUNT(*) FROM review AS r
        WHERE NOT EXISTS (SELECT 1 FROM member AS mb WHERE mb.member_id = r.member_id)) AS orphan_reviews;


-- @Q17 | 인덱스 | review.movie_id 인덱스 생성 전/후 실행 계획 비교
-- 적용 이유: review.movie_id 는 영화별 리뷰 조회·JOIN·GROUP BY(Q08~Q14)에 가장 자주 쓰이는 컬럼인데,
--           SQLite 는 FK 컬럼에 인덱스를 자동으로 만들지 않고, UNIQUE(member_id, movie_id) 인덱스는
--           member_id 가 앞이라 movie_id 만으로는 사용할 수 없다.
-- [SQLite 전용] EXPLAIN QUERY PLAN. MySQL/PostgreSQL: EXPLAIN
-- 생성 전: 리뷰 테이블 전체를 훑는다 (SCAN) — 78행을 모두 읽은 뒤 movie_id = 1 인 7행만 남긴다
EXPLAIN QUERY PLAN
SELECT rating, content FROM review WHERE movie_id = 1;

-- 생성 전 JOIN: 리뷰를 전부 훑고(SCAN r) 영화는 PK 로 찾은 뒤, 영화별로 묶으려고 임시 B-tree 로 다시 정렬한다
EXPLAIN QUERY PLAN
SELECT m.title, AVG(r.rating)
FROM movie AS m
INNER JOIN review AS r ON r.movie_id = m.movie_id
GROUP BY m.movie_id;

CREATE INDEX idx_review_movie_id ON review (movie_id);

-- 생성 후: 인덱스로 movie_id = 1 인 행만 찾아간다 (SEARCH … USING INDEX) — B-tree 에서 1 의 위치로 바로 가서 7행만 읽는다
EXPLAIN QUERY PLAN
SELECT rating, content FROM review WHERE movie_id = 1;

-- 생성 후 JOIN: 영화를 PK 순서로 훑으며(SCAN m) 리뷰를 인덱스로 찾는다(SEARCH r USING INDEX) → 이미 영화 순서라 임시 B-tree 정렬이 사라진다
EXPLAIN QUERY PLAN
SELECT m.title, AVG(r.rating)
FROM movie AS m
INNER JOIN review AS r ON r.movie_id = m.movie_id
GROUP BY m.movie_id;
