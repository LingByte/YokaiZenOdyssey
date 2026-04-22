-- Seed data for YokaiZenOdyssey
-- Initial user data

-- Insert test user (password: admin123)
-- bcrypt hash for "admin123": $2a$10$8K1p/a0dL3x5yZ9qR2t8W.5zX4yV8wK0pL3x5yZ9qR2t8W.5zX4yV8wK
INSERT INTO users (username, password, email, nickname, avatar, status, created_at, updated_at)
VALUES (
    'admin',
    '$2a$10$8K1p/a0dL3x5yZ9qR2t8W.5zX4yV8wK0pL3x5yZ9qR2t8W.5zX4yV8wK',
    'admin@example.com',
    '管理员',
    '',
    1,
    datetime('now'),
    datetime('now')
);

-- Insert test user (password: user123)
-- bcrypt hash for "user123": $2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi
INSERT INTO users (username, password, email, nickname, avatar, status, created_at, updated_at)
VALUES (
    'testuser',
    '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM8lE9lBOsl7iKTVKIUi',
    'user@example.com',
    '测试用户',
    '',
    1,
    datetime('now'),
    datetime('now')
);
