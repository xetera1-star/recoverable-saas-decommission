
-- Recoverable SaaS Decommission
-- Synthetic MySQL restore-verification fixture
-- All records are fictional.
-- Compatible with MySQL 8.0.

CREATE TABLE organisations (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    name VARCHAR(150) NOT NULL,
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NULL,
    PRIMARY KEY (id)
) ENGINE=InnoDB;

CREATE TABLE users (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    organisation_id BIGINT UNSIGNED NOT NULL,
    display_name VARCHAR(150) NOT NULL,
    status VARCHAR(20) NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_users_organisation
        FOREIGN KEY (organisation_id)
        REFERENCES organisations(id)
) ENGINE=InnoDB;

CREATE TABLE activity_logs (
    id BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id BIGINT UNSIGNED NOT NULL,
    event_type VARCHAR(100) NOT NULL,
    created_at TIMESTAMP NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_activity_user
        FOREIGN KEY (user_id)
        REFERENCES users(id)
) ENGINE=InnoDB;

INSERT INTO organisations
    (id, name, status, created_at)
VALUES
    (1, 'Example Academy', 'active', '2026-01-10 09:00:00'),
    (2, 'Sample Learning Centre', 'active', '2026-02-15 10:30:00'),
    (3, 'Demo Training Group', 'inactive', '2026-03-20 14:00:00');

INSERT INTO users
    (id, organisation_id, display_name, status)
VALUES
    (1, 1, 'Sample User One', 'active'),
    (2, 1, 'Sample User Two', 'active'),
    (3, 2, 'Sample User Three', 'active'),
    (4, 2, 'Sample User Four', 'inactive'),
    (5, 3, 'Sample User Five', 'active');

INSERT INTO activity_logs
    (id, user_id, event_type, created_at)
VALUES
    (1, 1, 'login', '2026-04-01 08:00:00'),
    (2, 1, 'profile_updated', '2026-04-01 08:15:00'),
    (3, 2, 'login', '2026-04-02 09:00:00'),
    (4, 3, 'login', '2026-04-03 10:00:00'),
    (5, 4, 'account_deactivated', '2026-04-04 11:00:00'),
    (6, 5, 'login', '2026-04-05 12:00:00');
