DROP TABLE IF EXISTS PROMOTION_STAT CASCADE;
DROP TABLE IF EXISTS REPORT_VENUE CASCADE;
DROP TABLE IF EXISTS REPORT_COMMENT CASCADE;
DROP TABLE IF EXISTS REPORT_REVIEW CASCADE;
DROP TABLE IF EXISTS REPORT CASCADE;
DROP TABLE IF EXISTS PHOTO_REVIEW CASCADE;
DROP TABLE IF EXISTS PHOTO_VENUE CASCADE;
DROP TABLE IF EXISTS PHOTO CASCADE;
DROP TABLE IF EXISTS REVIEW_COMMENT CASCADE;
DROP TABLE IF EXISTS PROMOTION CASCADE;
DROP TABLE IF EXISTS VENUE_STAFF CASCADE;
DROP TABLE IF EXISTS VENUE_CLAIM CASCADE;
DROP TABLE IF EXISTS REVIEW CASCADE;
DROP TABLE IF EXISTS MODERATION_ACTION CASCADE;
DROP TABLE IF EXISTS MENU_ITEM CASCADE;
DROP TABLE IF EXISTS WORKING_HOURS CASCADE;
DROP TABLE IF EXISTS USER_FAVORITE CASCADE;
DROP TABLE IF EXISTS VENUE_FEATURE CASCADE;
DROP TABLE IF EXISTS VENUE_TYPE_ASSIGNMENT CASCADE;
DROP TABLE IF EXISTS VENUE CASCADE;
DROP TABLE IF EXISTS FEATURE CASCADE;
DROP TABLE IF EXISTS VENUE_TYPE CASCADE;
DROP TABLE IF EXISTS CITY CASCADE;
DROP TABLE IF EXISTS USER_DELETION CASCADE;
DROP TABLE IF EXISTS USERS CASCADE;
DROP FUNCTION IF EXISTS check_photo_target();
DROP FUNCTION IF EXISTS check_report_target();

DROP TYPE IF EXISTS report_status;
DROP TYPE IF EXISTS promotion_status;
DROP TYPE IF EXISTS promotion_type;
DROP TYPE IF EXISTS venue_staff_role;
DROP TYPE IF EXISTS venue_claim_status;
DROP TYPE IF EXISTS review_status;
DROP TYPE IF EXISTS moderation_action_action;
DROP TYPE IF EXISTS venue_status;
DROP TYPE IF EXISTS user_status;
DROP TYPE IF EXISTS user_role;

CREATE TYPE user_role AS ENUM ('user', 'moderator', 'admin');
CREATE TYPE venue_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE moderation_action_action AS ENUM ('approve', 'reject', 'request_changes');
CREATE TYPE review_status AS ENUM ('visible', 'hidden');
CREATE TYPE venue_claim_status AS ENUM ('pending', 'approved', 'rejected');
CREATE TYPE venue_staff_role AS ENUM ('owner', 'manager');
CREATE TYPE promotion_type AS ENUM ('featured', 'offer');
CREATE TYPE promotion_status AS ENUM (
    'draft',
    'pending',
    'active',
    'ended',
    'rejected'
);
CREATE TYPE report_status AS ENUM ('open', 'resolved', 'dismissed');

CREATE TABLE USERS (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR(254) UNIQUE NOT NULL,
    pass_hash TEXT NOT NULL,
    display_name VARCHAR(50) NOT NULL,
    avatar_url TEXT NULL,
    role user_role NOT NULL DEFAULT 'user',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE USER_DELETION (
    user_id INT PRIMARY KEY,
    deleted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_user_deletion_user
        FOREIGN KEY (user_id) REFERENCES USERS(user_id)
        ON DELETE CASCADE
);

CREATE TABLE CITY (
    city_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    region VARCHAR(255) NOT NULL
);

CREATE TABLE VENUE_TYPE (
    venue_type_id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE FEATURE (
    feature_id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL
);

CREATE TABLE VENUE (
    venue_id SERIAL PRIMARY KEY,
    city_id INT NOT NULL,
    created_by INT NULL,
    status venue_status NOT NULL DEFAULT 'pending',
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    address TEXT NOT NULL,
    latitude DOUBLE PRECISION NOT NULL CHECK (latitude BETWEEN -90 AND 90),
    longitude DOUBLE PRECISION NOT NULL CHECK (longitude BETWEEN -180 AND 180),
    phone_number VARCHAR(20) NOT NULL,
    website TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_venue_city FOREIGN KEY (city_id) REFERENCES CITY(city_id),
    CONSTRAINT fk_venue_created_by FOREIGN KEY (created_by) REFERENCES USERS(user_id)
        ON DELETE SET NULL
);

CREATE TABLE VENUE_TYPE_ASSIGNMENT (
    venue_id INT NOT NULL,
    venue_type_id INT NOT NULL,
    PRIMARY KEY (venue_id, venue_type_id),
    CONSTRAINT fk_vta_venue FOREIGN KEY (venue_id) REFERENCES VENUE(venue_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_vta_type FOREIGN KEY (venue_type_id) REFERENCES VENUE_TYPE(venue_type_id)
        ON DELETE CASCADE
);

CREATE TABLE VENUE_FEATURE (
    venue_id INT NOT NULL,
    feature_id INT NOT NULL,
    PRIMARY KEY (venue_id, feature_id),
    CONSTRAINT fk_venue_feature_venue FOREIGN KEY (venue_id) REFERENCES VENUE(venue_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_venue_feature_feature FOREIGN KEY (feature_id) REFERENCES FEATURE(feature_id)
        ON DELETE CASCADE
);

CREATE TABLE USER_FAVORITE (
    user_id INT NOT NULL,
    venue_id INT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (user_id, venue_id),
    CONSTRAINT fk_user_favorite_user FOREIGN KEY (user_id) REFERENCES USERS(user_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_user_favorite_venue FOREIGN KEY (venue_id) REFERENCES VENUE(venue_id)
        ON DELETE CASCADE
);

CREATE TABLE WORKING_HOURS (
    working_hours_id SERIAL PRIMARY KEY,
    venue_id INT NOT NULL,
    weekday SMALLINT NOT NULL CHECK (weekday BETWEEN 1 AND 7),
    opens_at TIME NOT NULL,
    closes_at TIME NOT NULL,
    CONSTRAINT uq_working_hours_venue_weekday UNIQUE (venue_id, weekday),
    CONSTRAINT fk_working_hours_venue FOREIGN KEY (venue_id) REFERENCES VENUE(venue_id)
        ON DELETE CASCADE
);

CREATE TABLE MENU_ITEM (
    menu_item_id SERIAL PRIMARY KEY,
    venue_id INT NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    price DECIMAL(10, 2) NOT NULL CHECK (price >= 0),
    is_available BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_menu_item_venue FOREIGN KEY (venue_id) REFERENCES VENUE(venue_id)
        ON DELETE CASCADE
);

CREATE TABLE MODERATION_ACTION (
    moderation_action_id SERIAL PRIMARY KEY,
    venue_id INT NOT NULL,
    moderator_id INT NOT NULL,
    action moderation_action_action NOT NULL,
    note TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_moderation_action_venue FOREIGN KEY (venue_id) REFERENCES VENUE(venue_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_moderation_action_moderator FOREIGN KEY (moderator_id) REFERENCES USERS(user_id)
        ON DELETE RESTRICT
);

CREATE TABLE REVIEW (
    review_id SERIAL PRIMARY KEY,
    venue_id INT NOT NULL,
    user_id INT NULL,
    rating SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 10),
    text TEXT NOT NULL,
    visited_on DATE NOT NULL,
    status review_status NOT NULL DEFAULT 'visible',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_review_venue_user UNIQUE (venue_id, user_id),
    CONSTRAINT fk_review_venue FOREIGN KEY (venue_id) REFERENCES VENUE(venue_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_review_user FOREIGN KEY (user_id) REFERENCES USERS(user_id)
        ON DELETE SET NULL
);

CREATE TABLE VENUE_CLAIM (
    venue_claim_id SERIAL PRIMARY KEY,
    venue_id INT NOT NULL,
    claimant_id INT NOT NULL,
    contact_info TEXT NOT NULL,
    evidence TEXT NOT NULL,
    status venue_claim_status NOT NULL DEFAULT 'pending',
    reviewed_by INT NULL,
    reviewed_at TIMESTAMPTZ NULL,
    review_note TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_venue_claim_venue FOREIGN KEY (venue_id) REFERENCES VENUE(venue_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_venue_claim_claimant FOREIGN KEY (claimant_id) REFERENCES USERS(user_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_venue_claim_reviewed_by FOREIGN KEY (reviewed_by) REFERENCES USERS(user_id)
        ON DELETE SET NULL
);

CREATE TABLE VENUE_STAFF (
    venue_id INT NOT NULL,
    user_id INT NOT NULL,
    role venue_staff_role NOT NULL,
    added_by INT NULL,
    added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (venue_id, user_id),
    CONSTRAINT fk_venue_staff_venue FOREIGN KEY (venue_id) REFERENCES VENUE(venue_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_venue_staff_user FOREIGN KEY (user_id) REFERENCES USERS(user_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_venue_staff_added_by FOREIGN KEY (added_by) REFERENCES USERS(user_id)
        ON DELETE SET NULL
);

CREATE TABLE PROMOTION (
    promotion_id SERIAL PRIMARY KEY,
    venue_id INT NOT NULL,
    created_by INT NULL,
    type promotion_type NOT NULL DEFAULT 'featured',
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    image_url TEXT NOT NULL,
    starts_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ends_at TIMESTAMPTZ NOT NULL,
    status promotion_status NOT NULL DEFAULT 'draft',
    reviewed_by INT NULL,
    reviewed_at TIMESTAMPTZ NULL,
    review_note TEXT NULL,
    CONSTRAINT chk_promotion_dates CHECK (ends_at >= starts_at),
    CONSTRAINT fk_promotion_venue FOREIGN KEY (venue_id) REFERENCES VENUE(venue_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_promotion_created_by FOREIGN KEY (created_by) REFERENCES USERS(user_id)
        ON DELETE SET NULL,
    CONSTRAINT fk_promotion_reviewed_by FOREIGN KEY (reviewed_by) REFERENCES USERS(user_id)
        ON DELETE SET NULL
);

CREATE TABLE REVIEW_COMMENT (
    review_comment_id SERIAL PRIMARY KEY,
    review_id INT NOT NULL,
    user_id INT NULL,
    parent_comment_id INT NULL,
    text TEXT NOT NULL,
    is_official BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_review_comment_review FOREIGN KEY (review_id) REFERENCES REVIEW(review_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_review_comment_user FOREIGN KEY (user_id) REFERENCES USERS(user_id)
        ON DELETE SET NULL,
    CONSTRAINT fk_review_comment_parent FOREIGN KEY (parent_comment_id)
        REFERENCES REVIEW_COMMENT(review_comment_id) ON DELETE CASCADE
);

CREATE TABLE PHOTO (
    photo_id SERIAL PRIMARY KEY,
    uploaded_by INT NULL,
    url TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_photo_uploaded_by FOREIGN KEY (uploaded_by) REFERENCES USERS(user_id)
        ON DELETE SET NULL
);

CREATE TABLE PHOTO_VENUE (
    photo_id INT PRIMARY KEY,
    venue_id INT NOT NULL,
    CONSTRAINT fk_photo_venue_photo FOREIGN KEY (photo_id) REFERENCES PHOTO(photo_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_photo_venue FOREIGN KEY (venue_id) REFERENCES VENUE(venue_id)
        ON DELETE CASCADE
);

CREATE TABLE PHOTO_REVIEW (
    photo_id INT PRIMARY KEY,
    review_id INT NOT NULL,
    CONSTRAINT fk_photo_review_photo FOREIGN KEY (photo_id) REFERENCES PHOTO(photo_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_photo_review FOREIGN KEY (review_id) REFERENCES REVIEW(review_id)
        ON DELETE CASCADE
);

CREATE TABLE REPORT (
    report_id SERIAL PRIMARY KEY,
    reporter_id INT NULL,
    reason TEXT NOT NULL,
    status report_status NOT NULL DEFAULT 'open',
    handled_by INT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT fk_report_reporter FOREIGN KEY (reporter_id) REFERENCES USERS(user_id)
        ON DELETE SET NULL,
    CONSTRAINT fk_report_handled_by FOREIGN KEY (handled_by) REFERENCES USERS(user_id)
        ON DELETE SET NULL
);

CREATE TABLE REPORT_REVIEW (
    report_id INT PRIMARY KEY,
    review_id INT NOT NULL,
    CONSTRAINT fk_report_review_report FOREIGN KEY (report_id) REFERENCES REPORT(report_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_report_review FOREIGN KEY (review_id) REFERENCES REVIEW(review_id)
        ON DELETE CASCADE
);

CREATE TABLE REPORT_COMMENT (
    report_id INT PRIMARY KEY,
    comment_id INT NOT NULL,
    CONSTRAINT fk_report_comment_report FOREIGN KEY (report_id) REFERENCES REPORT(report_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_report_comment FOREIGN KEY (comment_id)
        REFERENCES REVIEW_COMMENT(review_comment_id) ON DELETE CASCADE
);

CREATE TABLE REPORT_VENUE (
    report_id INT PRIMARY KEY,
    venue_id INT NOT NULL,
    CONSTRAINT fk_report_venue_report FOREIGN KEY (report_id) REFERENCES REPORT(report_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_report_venue FOREIGN KEY (venue_id) REFERENCES VENUE(venue_id)
        ON DELETE CASCADE
);

CREATE TABLE PROMOTION_STAT (
    promotion_stat_id SERIAL PRIMARY KEY,
    promotion_id INT NOT NULL,
    stat_date DATE NOT NULL,
    impressions INT NOT NULL DEFAULT 0 CHECK (impressions >= 0),
    clicks INT NOT NULL DEFAULT 0 CHECK (clicks >= 0),
    CONSTRAINT uq_promotion_stat_promotion_date UNIQUE (promotion_id, stat_date),
    CONSTRAINT chk_promotion_stat_clicks CHECK (clicks <= impressions),
    CONSTRAINT fk_promotion_stat_promotion FOREIGN KEY (promotion_id)
        REFERENCES PROMOTION(promotion_id) ON DELETE CASCADE
);

CREATE FUNCTION check_photo_target() RETURNS TRIGGER AS $$
DECLARE
    target_photo_id INT;
BEGIN
    IF TG_OP = 'DELETE' THEN
        target_photo_id := OLD.photo_id;
    ELSE
        target_photo_id := NEW.photo_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM PHOTO WHERE photo_id = target_photo_id) THEN
        RETURN NULL;
    END IF;

    IF (
        (SELECT COUNT(*) FROM PHOTO_VENUE WHERE photo_id = target_photo_id)
        + (SELECT COUNT(*) FROM PHOTO_REVIEW WHERE photo_id = target_photo_id)
    ) <> 1 THEN
        RAISE EXCEPTION 'PHOTO % must have exactly one target', target_photo_id;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trg_photo_target_parent
AFTER INSERT OR UPDATE ON PHOTO
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_photo_target();

CREATE CONSTRAINT TRIGGER trg_photo_target_venue
AFTER INSERT OR UPDATE OR DELETE ON PHOTO_VENUE
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_photo_target();

CREATE CONSTRAINT TRIGGER trg_photo_target_review
AFTER INSERT OR UPDATE OR DELETE ON PHOTO_REVIEW
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_photo_target();

CREATE FUNCTION check_report_target() RETURNS TRIGGER AS $$
DECLARE
    target_report_id INT;
BEGIN
    IF TG_OP = 'DELETE' THEN
        target_report_id := OLD.report_id;
    ELSE
        target_report_id := NEW.report_id;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM REPORT WHERE report_id = target_report_id) THEN
        RETURN NULL;
    END IF;

    IF (
        (SELECT COUNT(*) FROM REPORT_REVIEW WHERE report_id = target_report_id)
        + (SELECT COUNT(*) FROM REPORT_COMMENT WHERE report_id = target_report_id)
        + (SELECT COUNT(*) FROM REPORT_VENUE WHERE report_id = target_report_id)
    ) <> 1 THEN
        RAISE EXCEPTION 'REPORT % must have exactly one target', target_report_id;
    END IF;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE CONSTRAINT TRIGGER trg_report_target_parent
AFTER INSERT OR UPDATE ON REPORT
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_report_target();

CREATE CONSTRAINT TRIGGER trg_report_target_review
AFTER INSERT OR UPDATE OR DELETE ON REPORT_REVIEW
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_report_target();

CREATE CONSTRAINT TRIGGER trg_report_target_comment
AFTER INSERT OR UPDATE OR DELETE ON REPORT_COMMENT
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_report_target();

CREATE CONSTRAINT TRIGGER trg_report_target_venue
AFTER INSERT OR UPDATE OR DELETE ON REPORT_VENUE
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE FUNCTION check_report_target();
