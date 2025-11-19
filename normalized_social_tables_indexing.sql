-- Users
CREATE INDEX idx_users_username ON users(username);

-- Follows: find who a user follows and who follows a user
CREATE INDEX idx_user_follows_follower ON user_follows(follower_id);
CREATE INDEX idx_user_follows_followee ON user_follows(followee_id);

-- Posts: recent posts by author, for feed generation
CREATE INDEX idx_posts_author_created ON posts(author_id, created_at DESC);
CREATE INDEX idx_posts_created ON posts(created_at DESC);
CREATE INDEX idx_posts_is_private ON posts(is_private);

-- Post media lookup
CREATE INDEX idx_post_media_post ON post_media(post_id);

-- Comments and counts
CREATE INDEX idx_comments_post_created ON comments(post_id, created_at DESC);

-- Reactions count / lookup
CREATE INDEX idx_reactions_target ON reactions(target_type, target_id);
CREATE INDEX idx_reactions_user ON reactions(user_id);

-- Messages: conversation ordering
CREATE INDEX idx_messages_conv_created ON messages(conversation_id, created_at
DESC);

-- Notifications: unread/created
CREATE INDEX idx_notifications_user_seen_created ON notifications(user_id,
seen, created_at DESC);

-- Activities for feeds
CREATE INDEX idx_activities_user_created ON activities(user_id, created_at
DESC);

-- Full-text search (posts.content)
ALTER TABLE posts ADD COLUMN tsv tsvector;
UPDATE posts SET tsv = to_tsvector('english', coalesce(content, ''));
CREATE INDEX idx_posts_tsv ON posts USING GIN(tsv);
