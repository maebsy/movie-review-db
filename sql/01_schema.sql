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
--
--   테이블 개요 (4개 · 시드 기준 행 수)
--     테이블   PK                     FK                                     행    한 행의 의미
--     genre    genre_id  INTEGER       -                                      10    장르 하나
--     member   member_id INTEGER       -                                      15    회원 한 명
--     movie    movie_id  INTEGER       genre_id  → genre                      22    영화 한 편 (대표 장르 하나)
--     review   review_id INTEGER       member_id → member, movie_id → movie   78    회원 한 명이 영화 한 편에 남긴 평가 하나
--
--   PK 를 INTEGER 대체키로 고른 이유: email · nickname 같은 자연키는 바뀔 수 있고(UNIQUE 로만 보장),
--     movie 의 자연키 (title, release_date) 는 문자열 두 개라 FK 로 들고 다니기 무겁다.
--     INTEGER PRIMARY KEY 는 SQLite rowid 의 별칭이라 조회·조인이 가장 빠르고 값을 생략하면 자동으로 매겨진다.
--
--   FK 정책과 참조 도메인 (모든 FK 는 NOT NULL — "부모 없는 행" 을 NULL 로 우회할 수 없다)
--     movie.genre_id   → genre.genre_id   (1~10)  ON DELETE RESTRICT  쓰이는 장르는 못 지움 / ON UPDATE CASCADE 장르 id 변경 따라감
--     review.member_id → member.member_id (1~15)  ON DELETE CASCADE   탈퇴(삭제) 회원의 리뷰도 함께 삭제 / ON UPDATE 미지정(NO ACTION)
--     review.movie_id  → movie.movie_id   (1~22)  ON DELETE CASCADE   없어진 영화의 리뷰는 의미가 없음  / ON UPDATE 미지정(NO ACTION)
--     (FK 가 아닌 도메인 제약: review.rating 은 CHECK 1~5 정수, member.status 는 3가지 값)
--
--   왜 엑셀 한 시트가 아니라 DB 인가 (관계 표현 · 무결성)
--     엑셀은 시트 사이를 VLOOKUP 으로 이어도 원본 행을 지우면 #N/A 가 될 뿐 지우는 것을 막지 못하고,
--     별점 칸에 6 이나 "다섯" 을 넣는 것도 막지 못한다. 이 스키마에서는 없는 회원(999)의 리뷰 INSERT 가
--     FOREIGN KEY constraint failed, 별점 6 이 CHECK constraint failed, 같은 회원·영화의 두 번째 리뷰가
--     UNIQUE constraint failed 로 거부된다 (sqlite3 원문: docs/bonus.md · results/screenshots/ERR.png).
--     정보는 한 테이블에 한 번만 두고 키로 연결하므로, 회원 이메일을 바꿔도 member 1행만 고치면 된다.
--
--   컬럼 타입 요약 (자세한 근거: docs/design.md 4절)
--     *_id                 INTEGER   대체키 · FK. 시드 최대 78, 최대 2^63-1
--     rating               INTEGER   1~5 정수 단계값 + CHECK. 평균은 조회 때 AVG() 로 계산(REAL)
--     running_time         INTEGER   분 단위, 합계·비교가 필요해 숫자 (시드 94~181분)
--     birth_year           INTEGER   연도만 (개인정보 최소화), CHECK 1900~2026
--     *_date, joined_at    TEXT      SQLite 에 DATE 가 없어 ISO-8601 'YYYY-MM-DD' + 실제 날짜 CHECK (사전순 = 날짜순)
--     created_at           TEXT      'YYYY-MM-DD HH:MM:SS' (같은 날 여러 리뷰의 순서)
--     name, title, email…  TEXT      길이 제한 없는 문자열 (MySQL 이라면 VARCHAR(n))
--     status               TEXT      3가지 값만 CHECK (값이 늘면 별도 테이블로 분리)
-- =============================================================================

-- [SQLite 전용] SQLite 는 FK 검사가 기본으로 꺼져 있다. 연결(세션)마다 켜야 한다.
PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS review;
DROP TABLE IF EXISTS movie;
DROP TABLE IF EXISTS member;
DROP TABLE IF EXISTS genre;

-- 날짜 검증에서 겪은 난관 — 시도한 방법과 최종 선택 (작업 시간은 기록하지 않음, 커밋 시각만 남김)
--   ① CHECK (date(x) = x)            '2024-13-01' 이 통과 → 아래 'IS' 설명. 테스트를 쓰다 발견
--   ② CHECK (date(x) IS x)           3.45 에서는 해결, 그러나 CI 의 SQLite 3.40.1 에서 '2024-02-30' 이 통과 (커밋 cf86c1e, 10-12 14:41)
--   ③ CHECK (date(x, '+0 days') IS x) 버전과 상관없이 거부 → 최종 선택 (커밋 d5a1e43, 10-12 23:27 · 테스트로 고정)
--   검토만 하고 쓰지 않은 대안: 트리거로 검증(미션이 트리거 금지) · 앱에서 검증(DB 규칙이 아니게 되어 다른 도구로 넣으면 뚫림)
--                              · 연·월·일을 정수 컬럼 3개로 분리(날짜 함수·정렬이 불편해짐)
--
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
-- 정규화: 1NF 원자값 · 2NF 단일 PK · 3NF 장르 설명은 장르에만 종속 (영화마다 반복하지 않도록 movie 에서 분리)
-- -----------------------------------------------------------------------------
CREATE TABLE genre (
    genre_id     INTEGER PRIMARY KEY,                 -- [SQLite] INTEGER PRIMARY KEY = rowid 별칭, 값 생략 시 자동 증가
    name         TEXT    NOT NULL UNIQUE,             -- 같은 장르명이 두 번 생기지 않도록
    description  TEXT
);

-- -----------------------------------------------------------------------------
-- member: 회원 (부모 테이블)
-- 정규화: 1NF 원자값 · 2NF 단일 PK · 3NF 이메일·닉네임·상태가 회원에만 종속 (리뷰마다 반복하지 않도록 분리)
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
-- 정규화: 1NF 원자값 · 2NF 단일 PK · 3NF 장르명은 genre_id 로만 참조 (movie → genre_id → 장르명 이행 종속 제거)
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
-- 정규화: 1NF 원자값 · 2NF 별점·내용·작성일은 (회원, 영화) 한 쌍 전체에 종속 · 3NF 회원·영화 정보는 FK 로만 참조
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
