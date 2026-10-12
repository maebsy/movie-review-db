-- =============================================================================
-- 06_bonus_mini_report.sql — [보너스] 미니 리포트: 이 DB 로 뽑을 수 있는 핵심 지표 3개 (최종본)
--
--   지표 1. 월별 리뷰 활동 추이        서비스가 살아 있는가?   (리뷰 수 · 활동 회원 수 · 평균 별점 · 호평률)
--   지표 2. 인기 영화 TOP 10           무엇을 추천할까?        (베이지안 가중 평점으로 리뷰 수 편향 보정)
--   지표 3. 장르별 만족도              어떤 장르가 강한가?     (호평률 · 혹평률)
--
--   해석은 docs/mini-report.md 에 정리했다. 02_seed.sql 직후의 새 DB 에서 실행한다.
-- =============================================================================

PRAGMA foreign_keys = ON;  -- [SQLite 전용]


-- @R01 | 보너스: 미니 리포트 | 지표 1. 월별 리뷰 활동 추이
-- 호평률 = 별점 4점 이상 리뷰 비율(%). [SQLite 전용] strftime
SELECT strftime('%Y-%m', created_at)                                     AS month,
       COUNT(*)                                                          AS reviews,
       COUNT(DISTINCT member_id)                                         AS active_reviewers,
       ROUND(AVG(rating), 2)                                             AS avg_rating,
       ROUND(100.0 * SUM(CASE WHEN rating >= 4 THEN 1 ELSE 0 END) / COUNT(*), 1) AS positive_pct
FROM review
GROUP BY month
ORDER BY month;


-- @R02 | 보너스: 미니 리포트 | 지표 2. 인기 영화 TOP 10 — 베이지안 가중 평점
-- 가중 평점 = (v × R + m × C) / (v + m)
--   v = 영화의 리뷰 수, R = 영화의 평균 별점, C = 전체 평균 별점, m = 최소 신뢰 리뷰 수(3)
-- 리뷰가 적은 영화는 전체 평균(C) 쪽으로 끌어당겨, 리뷰 2개짜리 5.0 이 리뷰 7개짜리 4.7 을 이기는 왜곡을 막는다.
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


-- @R03 | 보너스: 미니 리포트 | 지표 3. 장르별 만족도 — 호평률(4점 이상) · 혹평률(2점 이하)
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
