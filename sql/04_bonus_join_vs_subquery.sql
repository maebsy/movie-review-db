-- =============================================================================
-- 04_bonus_join_vs_subquery.sql — [보너스] 같은 요구를 JOIN 과 서브쿼리로 풀고 비교하기
--
--   요구 A: "리뷰를 1개 이상 작성한 회원 목록"        → B01 ~ B05
--   요구 B: "영화별 리뷰 수 (리뷰 없는 영화는 0)"      → B06
--   02_seed.sql 직후의 새 DB 에서 실행한다.
-- =============================================================================

PRAGMA foreign_keys = ON;  -- [SQLite 전용]


-- @B01 | 보너스: JOIN vs 서브쿼리 | 요구 A ① INNER JOIN — 회원 × 리뷰 행이 늘어나므로 DISTINCT 로 중복 제거
SELECT DISTINCT mb.member_id, mb.nickname
FROM member AS mb
INNER JOIN review AS r ON r.member_id = mb.member_id
ORDER BY mb.member_id;


-- @B02 | 보너스: JOIN vs 서브쿼리 | 요구 A ② EXISTS — 회원마다 "리뷰가 하나라도 있나"만 확인 (찾으면 즉시 멈춤)
SELECT mb.member_id, mb.nickname
FROM member AS mb
WHERE EXISTS (SELECT 1 FROM review AS r WHERE r.member_id = mb.member_id)
ORDER BY mb.member_id;


-- @B03 | 보너스: JOIN vs 서브쿼리 | 요구 A ③ IN — 리뷰를 쓴 member_id 목록을 먼저 만들고 그 안에 있는지 확인
SELECT mb.member_id, mb.nickname
FROM member AS mb
WHERE mb.member_id IN (SELECT r.member_id FROM review AS r)
ORDER BY mb.member_id;


-- @B04 | 보너스: JOIN vs 서브쿼리 | 세 방식의 결과가 정확히 같은지 검증 (차집합이 모두 0행이어야 함)
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


-- @B05 | 보너스: JOIN vs 서브쿼리 | 실행 계획 비교 [SQLite 전용: EXPLAIN QUERY PLAN]
-- ① JOIN + DISTINCT: 결과 컬럼(member_id)이 회원 테이블의 유일 키라서, SQLite 옵티마이저가 임시 B-tree 없이
--    회원마다 리뷰 인덱스를 찾아보는 계획을 만든다 (조인된 78행을 만든 뒤 지우는 방식이 아님)
EXPLAIN QUERY PLAN
SELECT DISTINCT mb.member_id, mb.nickname
FROM member AS mb INNER JOIN review AS r ON r.member_id = mb.member_id;

-- ② EXISTS: 회원마다 UNIQUE(member_id, movie_id) 자동 인덱스로 한 건만 찾아본다 (상관 서브쿼리)
EXPLAIN QUERY PLAN
SELECT mb.member_id, mb.nickname
FROM member AS mb
WHERE EXISTS (SELECT 1 FROM review AS r WHERE r.member_id = mb.member_id);

-- ③ IN: 서브쿼리 결과를 한 번 만들어 두고(LIST SUBQUERY) 회원마다 그 목록에서 찾는다
EXPLAIN QUERY PLAN
SELECT mb.member_id, mb.nickname
FROM member AS mb
WHERE mb.member_id IN (SELECT r.member_id FROM review AS r);


-- @B06 | 보너스: JOIN vs 서브쿼리 | 요구 B — LEFT JOIN + GROUP BY 와 상관 스칼라 서브쿼리의 결과 비교
-- ① LEFT JOIN + GROUP BY: 한 번 조인한 뒤 묶어서 센다
SELECT m.movie_id, m.title, COUNT(r.review_id) AS review_count
FROM movie AS m
LEFT JOIN review AS r ON r.movie_id = m.movie_id
GROUP BY m.movie_id, m.title
ORDER BY m.movie_id;

-- ② SELECT 절 상관 서브쿼리: 영화 한 편마다 리뷰 수를 따로 센다
SELECT m.movie_id, m.title,
       (SELECT COUNT(*) FROM review AS r WHERE r.movie_id = m.movie_id) AS review_count
FROM movie AS m
ORDER BY m.movie_id;

-- 두 결과가 같은지 검증 (서로 다른 행 0개)
SELECT COUNT(*) AS mismatched_rows
FROM (
    SELECT m.movie_id, COUNT(r.review_id) AS c FROM movie m LEFT JOIN review r ON r.movie_id = m.movie_id GROUP BY m.movie_id
    EXCEPT
    SELECT m.movie_id, (SELECT COUNT(*) FROM review r WHERE r.movie_id = m.movie_id) FROM movie m
);
