-- social_tables_seeder.sql
-- This script populates the social media database with sample data.
-- It uses CTEs (Common Table Expressions) to insert data and retrieve generated IDs
-- for use in subsequent inserts, ensuring relational integrity.

-- Clear existing data to ensure a clean slate
-- Use TRUNCATE ... RESTART IDENTITY CASCADE to reset auto-incrementing keys and handle foreign key constraints
TRUNCATE users, user_follows, posts, post_media, comments, reactions, conversations, conversation_participants, messages, notifications, activities RESTART IDENTITY;

-- 1. Create Users
-- Insert 5 sample users and capture their generated UUIDs.
WITH new_users AS (
  INSERT INTO users (username, email, display_name, bio) VALUES
  ('alice', 'alice@example.com', 'Alice', 'Art enthusiast and painter.'),
  ('bob', 'bob@example.com', 'Bob', 'Software developer and tech blogger.'),
  ('charlie', 'charlie@example.com', 'Charlie', 'Musician and coffee lover.'),
  ('diana', 'diana@example.com', 'Diana', 'Photographer and world traveler.'),
  ('edward', 'edward@example.com', 'Edward', 'Chef and food critic.')
  RETURNING id, username
),

-- 2. Create Follow Relationships
-- Use the user IDs captured above to create a social graph.
user_ids AS (
  SELECT id, username FROM new_users
),
follows AS (
  INSERT INTO user_follows (follower_id, followee_id)
  SELECT
    (SELECT id FROM user_ids WHERE username = 'alice'),
    (SELECT id FROM user_ids WHERE username = 'bob')
  UNION ALL
  SELECT
    (SELECT id FROM user_ids WHERE username = 'alice'),
    (SELECT id FROM user_ids WHERE username = 'charlie')
  UNION ALL
  SELECT
    (SELECT id FROM user_ids WHERE username = 'bob'),
    (SELECT id FROM user_ids WHERE username = 'alice')
  UNION ALL
  SELECT
    (SELECT id FROM user_ids WHERE username = 'charlie'),
    (SELECT id FROM user_ids WHERE username = 'diana')
)

-- 3. Create Posts
-- Users create posts. We capture the post IDs for comments, reactions, etc.
, new_posts AS (
  INSERT INTO posts (author_id, content)
  SELECT
    (SELECT id FROM user_ids WHERE username = 'alice'),
    'Just finished a new painting! What do you all think? #art #painting'
  UNION ALL
  SELECT
    (SELECT id FROM user_ids WHERE username = 'bob'),
    'Excited to announce my new open-source project. Check it out on my profile!'
  UNION ALL
  SELECT
    (SELECT id FROM user_ids WHERE username = 'diana'),
    'Sunrise from the top of the mountain was breathtaking.'
  RETURNING id, content
),

-- Create a reply post
reply_post AS (
  INSERT INTO posts (author_id, content, reply_to_post_id)
  SELECT
    (SELECT id FROM user_ids WHERE username = 'charlie'),
    'This is amazing! Your best work yet.',
    (SELECT id FROM new_posts WHERE content LIKE 'Just finished a new painting%')
),

-- 4. Add Media to a Post
post_media_insert AS (
  INSERT INTO post_media (post_id, media_url, media_type)
  SELECT
    (SELECT id FROM new_posts WHERE content LIKE 'Sunrise from the top%'),
    'https://example.com/images/sunrise.jpg',
    'image'
),

-- 5. Create Comments
-- Users comment on posts. We capture comment IDs to allow for threaded replies.
new_comments AS (
  INSERT INTO comments (post_id, author_id, content)
  SELECT
    (SELECT id FROM new_posts WHERE content LIKE 'Just finished a new painting%'),
    (SELECT id FROM user_ids WHERE username = 'bob'),
    'Wow, Alice, this is incredible!'
  UNION ALL
  SELECT
    (SELECT id FROM new_posts WHERE content LIKE 'Excited to announce%'),
    (SELECT id FROM user_ids WHERE username = 'alice'),
    'Congrats, Bob! Can''t wait to see it.'
  RETURNING id, content
),

-- Create a reply to a comment
reply_comment AS (
  INSERT INTO comments (post_id, author_id, content, reply_to_comment_id)
  SELECT
    (SELECT id FROM new_posts WHERE content LIKE 'Just finished a new painting%'),
    (SELECT id FROM user_ids WHERE username = 'alice'),
    'Thanks, Bob! I appreciate it.',
    (SELECT id FROM new_comments WHERE content LIKE 'Wow, Alice%')
),

-- 6. Create Reactions
-- Users react to posts and comments.
reactions AS (
  INSERT INTO reactions (user_id, target_type, target_id, reaction_type)
  -- Diana likes Alice's painting post
  SELECT
    (SELECT id FROM user_ids WHERE username = 'diana'),
    'post',
    (SELECT id FROM new_posts WHERE content LIKE 'Just finished a new painting%'),
    'love'
  UNION ALL
  -- Charlie likes Bob's project post
  SELECT
    (SELECT id FROM user_ids WHERE username = 'charlie'),
    'post',
    (SELECT id FROM new_posts WHERE content LIKE 'Excited to announce%'),
    'like'
  UNION ALL
  -- Edward likes Bob's comment on Alice's post
  SELECT
    (SELECT id FROM user_ids WHERE username = 'edward'),
    'comment',
    (SELECT id FROM new_comments WHERE content LIKE 'Wow, Alice%'),
    'haha'
),

-- 7. Create Conversations and Participants
-- A private chat between Alice and Bob
private_convo AS (
  INSERT INTO conversations (kind) VALUES ('private') RETURNING id
),
private_participants AS (
  INSERT INTO conversation_participants (conversation_id, user_id)
  SELECT id, (SELECT id FROM user_ids WHERE username = 'alice') FROM private_convo
  UNION ALL
  SELECT id, (SELECT id FROM user_ids WHERE username = 'bob') FROM private_convo
),

-- 8. Create Messages
-- Messages within the private conversation
messages AS (
  INSERT INTO messages (conversation_id, sender_id, content)
  SELECT (SELECT id FROM private_convo), (SELECT id FROM user_ids WHERE username = 'alice'), 'Hey Bob, did you see Charlie''s reply to my post?'
  UNION ALL
  SELECT (SELECT id FROM private_convo), (SELECT id FROM user_ids WHERE username = 'bob'), 'Hey! Yes, I did. So nice of him!'
)

-- Final SELECT to confirm the script ran. This is optional.
SELECT 'Database seeding complete.' AS status;