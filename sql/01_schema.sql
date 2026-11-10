-- =============================================================================
-- 01_schema.sql — 영화 평점 서비스 스키마 v1.0 (SQLite 3.25+) · 실행 순서 1/3: 01_schema → 02_seed → 03_queries
--
--   genre (1) ──< movie (1) ──< review >── (1) member
--
--   1:N 관계 3개
--     genre.genre_id   → movie.genre_id    한 장르에 여러 영화
--     member.member_id → review.member_id  한 회원이 여러 리뷰
--     movie.movie_id   → review.movie_id   한 영화에 여러 리뷰
--
--   생성 순서: genre, member(부모) → movie(자식) → review(손자) — 자식의 FK 가 가리킬 부모를 먼저 만든다 (MySQL·PostgreSQL 은 필수, SQLite 는 CREATE 때 검사하지 않지만 같은 순서를 지킨다)
--   DROP 순서는 그 반대 — 자식 행이 남아 있는 부모를 먼저 DROP 하면 FOREIGN KEY constraint failed 로 막힌다
-- =============================================================================

-- [SQLite 전용] SQLite 는 FK 검사가 기본으로 꺼져 있다. 연결(세션)마다 켜야 한다.
PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS review;
DROP TABLE IF EXISTS movie;
DROP TABLE IF EXISTS member;
DROP TABLE IF EXISTS genre;

-- 날짜 CHECK 에서 '=' 대신 'IS' 를 쓰는 이유
--   date('2024-13-01') 처럼 해석할 수 없는 값은 NULL 이 되고, NULL = '2024-13-01' 의 결과도 NULL 이다.
--   CHECK 는 결과가 거짓(0)일 때만 막고 NULL 은 통과시키므로 '=' 로는 잘못된 날짜가 들어간다.
--   IS 는 NULL 을 하나의 값처럼 비교해 NULL IS '2024-13-01' → 거짓 → 거부된다.
--   ('2024-02-30' 은 date() 가 '2024-03-01' 로 바꿔 버리므로 '=' 로도 거부되지만, 월 13 은 아니다)
--
-- date(x, '+0 days') 처럼 '아무것도 안 바꾸는 수식어'를 붙이는 이유
--   수식어가 없으면 일부 SQLite 버전은 입력한 연·월·일을 검증 없이 그대로 출력한다.
--   CI 의 Windows + Python 3.10 (SQLite 3.40.1) 에서 date('2024-02-30') 이 '2024-02-30' 을 돌려줘
--   존재하지 않는 날짜가 통과했다 (SQLite 3.45 에서는 '2024-03-01').
--   수식어를 붙이면 날짜를 율리우스일로 계산한 뒤 다시 날짜로 바꾸므로 버전과 상관없이 '2024-03-01' 이 되어 거부된다.

-- -----------------------------------------------------------------------------
-- genre: 장르 (부모 테이블)
-- -----------------------------------------------------------------------------
CREATE TABLE genre (
    genre_id     INTEGER PRIMARY KEY,                 -- [SQLite] INTEGER PRIMARY KEY = rowid 별칭, 값 생략 시 자동 증가
    name         TEXT    NOT NULL UNIQUE,             -- 같은 장르명이 두 번 생기지 않도록
    description  TEXT
);

-- -----------------------------------------------------------------------------
-- member: 회원 (부모 테이블)
-- -----------------------------------------------------------------------------
CREATE TABLE member (
    member_id    INTEGER PRIMARY KEY,
    email        TEXT    NOT NULL UNIQUE,             -- 로그인 식별자: 중복 불가
    nickname     TEXT    NOT NULL UNIQUE,             -- 리뷰에 표시되는 이름: 중복 불가
    birth_year   INTEGER CHECK (birth_year BETWEEN 1900 AND 2026),
    joined_at    TEXT    NOT NULL                     -- 날짜: ISO-8601 'YYYY-MM-DD' (SQLite 에는 DATE 타입이 없다)
                 CHECK (date(joined_at, '+0 days') IS joined_at),  -- [SQLite 전용] 실제 존재하는 날짜인지 검사 (위 주의 참고)
    status       TEXT    NOT NULL DEFAULT 'ACTIVE'
                 CHECK (status IN ('ACTIVE', 'DORMANT', 'WITHDRAWN'))
);

-- -----------------------------------------------------------------------------
-- movie: 영화 (genre 의 자식)
-- -----------------------------------------------------------------------------
CREATE TABLE movie (
    movie_id      INTEGER PRIMARY KEY,
    genre_id      INTEGER NOT NULL
                  REFERENCES genre (genre_id)         -- FK movie → genre: NULL 불가, 삭제 RESTRICT · 수정 CASCADE
                  ON UPDATE CASCADE                   -- 장르 id 가 바뀌면 영화의 genre_id 도 따라 바뀐다
                  ON DELETE RESTRICT,                 -- 영화가 남아 있는 장르는 지울 수 없다
    title         TEXT    NOT NULL,
    release_date  TEXT    NOT NULL CHECK (date(release_date, '+0 days') IS release_date), -- [SQLite 전용] date()
    running_time  INTEGER NOT NULL CHECK (running_time > 0),                   -- 분 단위
    country       TEXT    NOT NULL,
    director      TEXT    NOT NULL,
    UNIQUE (title, release_date)                      -- 같은 제목이라도 개봉일이 다르면 다른 영화(리메이크)
);

-- -----------------------------------------------------------------------------
-- review: 리뷰 (member, movie 의 자식). 회원과 영화의 N:M 관계를 연결하는 테이블이기도 하다.
-- -----------------------------------------------------------------------------
CREATE TABLE review (
    review_id   INTEGER PRIMARY KEY,
    member_id   INTEGER NOT NULL
                REFERENCES member (member_id)         -- FK review → member: NULL 불가, 삭제 CASCADE (ON UPDATE 미지정 = NO ACTION)
                ON DELETE CASCADE,                    -- 회원 탈퇴(삭제) 시 그 회원의 리뷰도 함께 삭제
    movie_id    INTEGER NOT NULL
                REFERENCES movie (movie_id)           -- FK review → movie: NULL 불가, 삭제 CASCADE (ON UPDATE 미지정 = NO ACTION)
                ON DELETE CASCADE,                    -- 영화가 삭제되면 리뷰도 의미가 없으므로 함께 삭제
    rating      INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),   -- 별점 1~5 정수
    content     TEXT,                                 -- 별점만 남기고 글은 비워도 된다 (NULL 허용)
    created_at  TEXT    NOT NULL
                CHECK (datetime(created_at, '+0 days') IS created_at),  -- [SQLite 전용] 'YYYY-MM-DD HH:MM:SS'
    UNIQUE (member_id, movie_id)                      -- 한 회원은 한 영화에 리뷰 1개만
);

-- 인덱스는 03_queries.sql 의 Q17 에서 "만들기 전/후 실행 계획"을 비교하며 생성한다.
