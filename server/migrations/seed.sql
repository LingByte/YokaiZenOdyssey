-- Seed data for YokaiZenOdyssey (可选手工 SQL；日常启动请走 Go 程序化 seed)
--
-- 启动服务时会自动执行：
--   1. utils.SeedUsers          → admin / testuser（库空时）
--   2. utils.SeedItems          → 物品目录（upsert）
--   3. utils.SeedEmptySaveInventories → 给空背包的旧存档补开局礼包
-- 新建存档时 GrantStarterKit 会按角色发开局装备+道具。
--
-- 本文件不会在 main 中默认执行；若要用 SQL：
--   sqlite3 yok.db < migrations/seed.sql
-- 或在代码中调用 utils.SeedDatabase(db, "migrations")

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
