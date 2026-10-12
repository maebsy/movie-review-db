-- =============================================================================
-- 05_bonus_integrity.sql — [보너스] 데이터 정합성 일부러 깨뜨려 보기
--
--   각 시도는 실패해야 정상이다. "-- @expect-error" 가 붙은 문장이 성공하면 scripts/run_all.py 가 실패한다.
--   마지막 B14 에서 올바른 순서(부모 → 자식)로 다시 넣어 해결한다.
--   02_seed.sql 직후의 새 DB 에서 실행한다.
-- =============================================================================

PRAGMA foreign_keys = ON;  -- [SQLite 전용]


-- @B07 | 보너스: 정합성 | FK 위반 ① 존재하지 않는 회원(999)의 리뷰를 INSERT
-- @expect-error
INSERT INTO review (member_id, movie_id, rating, content, created_at)
VALUES (999, 1, 5, '없는 회원이 쓴 리뷰', '2024-10-01 10:00:00');


-- @B08 | 보너스: 정합성 | FK 위반 ② 존재하지 않는 장르(99)로 영화를 INSERT
-- @expect-error
INSERT INTO movie (genre_id, title, release_date, running_time, country, director)
VALUES (99, '장르가 없는 영화', '2024-10-01', 100, '한국', '미상');


-- @B09 | 보너스: 정합성 | FK 위반 ③ 영화가 남아 있는 장르(액션)를 DELETE → ON DELETE RESTRICT
-- @expect-error
DELETE FROM genre WHERE name = '액션';

-- 참조하는 영화가 없는 장르(뮤지컬)는 지울 수 있다 → RESTRICT 는 "쓰이는 부모"만 보호한다
DELETE FROM genre WHERE name = '뮤지컬';


-- @B10 | 보너스: 정합성 | CHECK 위반: 별점 6점, 존재하지 않는 날짜, 허용되지 않는 회원 상태
-- @expect-error
INSERT INTO review (member_id, movie_id, rating, content, created_at)
VALUES (12, 1, 6, '별점 6점?', '2024-10-01 10:00:00');

-- @expect-error
INSERT INTO movie (genre_id, title, release_date, running_time, country, director)
VALUES (2, '날짜 오류 영화', '2024-02-30', 100, '한국', '미상');

-- CHECK 를 date(x) = x 로 만들었다면 이 행은 통과했다 (date('2024-13-01') 이 NULL → CHECK 가 NULL 을 통과시킴).
-- IS 로 비교하도록 고쳐서 막힌다. '2024-02-30' 은 '+0 days' 수식어로 버전과 상관없이 막는다. 01_schema.sql 주석 참고
-- @expect-error
INSERT INTO movie (genre_id, title, release_date, running_time, country, director)
VALUES (2, '13월 영화', '2024-13-01', 100, '한국', '미상');

-- @expect-error
UPDATE member SET status = 'BANNED' WHERE member_id = 1;


-- @B11 | 보너스: 정합성 | UNIQUE 위반: 같은 회원이 같은 영화에 두 번째 리뷰, 이미 쓰는 이메일로 가입
-- @expect-error
INSERT INTO review (member_id, movie_id, rating, content, created_at)
VALUES (1, 1, 3, '두 번째 리뷰', '2024-10-01 10:00:00');

-- @expect-error
INSERT INTO member (email, nickname, birth_year, joined_at)
VALUES ('popcorn@example.com', '팝콘요정2', 1995, '2024-10-01');


-- @B12 | 보너스: 정합성 | NOT NULL 위반: 제목 없는 영화
-- @expect-error
INSERT INTO movie (genre_id, title, release_date, running_time, country, director)
VALUES (2, NULL, '2024-10-01', 100, '한국', '미상');


-- @B13 | 보너스: 정합성 | FK 검사를 끄면? PRAGMA foreign_keys = OFF 상태에서는 고아 리뷰가 들어간다 [SQLite 전용]
PRAGMA foreign_keys = OFF;

INSERT INTO review (review_id, member_id, movie_id, rating, content, created_at)
VALUES (900, 999, 1, 5, 'FK 검사가 꺼져서 들어간 고아 리뷰', '2024-10-01 10:00:00');

-- 다시 켜도 이미 들어간 데이터는 자동으로 검사되지 않는다 → foreign_key_check 로 찾아야 한다
PRAGMA foreign_keys = ON;

PRAGMA foreign_key_check;

-- 고아 행을 정리하고 다시 확인 (위반 0건)
DELETE FROM review WHERE review_id = 900;

PRAGMA foreign_key_check;


-- @B14 | 보너스: 정합성 | 해결: 부모(회원)를 먼저 만들고 자식(리뷰)을 넣는다 — 한 트랜잭션으로 묶어서
BEGIN TRANSACTION;

INSERT INTO member (member_id, email, nickname, birth_year, joined_at)
VALUES (16, 'latecomer@example.com', '늦깎이', 1994, '2024-10-01');

INSERT INTO review (member_id, movie_id, rating, content, created_at)
VALUES (16, 1, 5, '부모 행이 먼저 있으니 성공', '2024-10-02 20:00:00');

COMMIT;

SELECT mb.nickname, mv.title, r.rating, r.content
FROM review AS r
JOIN member AS mb ON mb.member_id = r.member_id
JOIN movie  AS mv ON mv.movie_id  = r.movie_id
WHERE r.member_id = 16;
