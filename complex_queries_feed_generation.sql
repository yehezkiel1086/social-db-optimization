-- 1. Cursor-based feed (latest-first) — include followees' posts: This query fetches the feed for a user ('alice' in this case). It uses cursor-based pagination to efficiently load more posts. For the first page, we use `now()` as the cursor timestamp.
WITH followees AS (
  SELECT followee_id FROM user_follows WHERE follower_id = (SELECT id FROM users WHERE username = 'alice')
), base_posts AS (
  SELECT p.*
  FROM posts p
  WHERE
    -- Fetch posts from users 'alice' follows
    p.author_id IN (SELECT followee_id FROM followees)
    -- Cursor logic for pagination. For the first page, we use a future timestamp: For subsequent pages, you would use the `created_at` and `id` of the last post from the previous page.
    AND (p.created_at, p.id) < (now(), 'ffffffff-ffff-ffff-ffff-ffffffffffff'::uuid)
  ORDER BY p.created_at DESC, p.id DESC
  LIMIT 10 -- page size
)
SELECT
  bp.id,
  bp.author_id,
  bp.content,
  bp.created_at,
  u.username,
  COALESCE(pc.comment_count, 0) AS comment_count,
  COALESCE(pr.reaction_count, 0) AS reaction_count,
  -- Check if the viewing user ('alice') has reacted to the post
  EXISTS(SELECT 1 FROM reactions r WHERE r.user_id = (SELECT id FROM users WHERE username = 'alice') AND r.target_type='post' AND r.target_id = bp.id) AS viewer_reacted
FROM base_posts bp
JOIN users u ON u.id = bp.author_id

-- Efficiently count comments for all posts in the result set
LEFT JOIN (
  SELECT post_id, count(*) AS comment_count
  FROM comments
  WHERE post_id IN (SELECT id FROM base_posts)
  GROUP BY post_id
) pc ON pc.post_id = bp.id

-- Efficiently count reactions for all posts in the result set
LEFT JOIN (
  SELECT target_id AS post_id, count(*) AS reaction_count
  FROM reactions
  WHERE target_type='post' AND target_id IN (SELECT id FROM base_posts)
  GROUP BY target_id
) pr ON pr.post_id = bp.id
ORDER BY bp.created_at DESC, bp.id DESC;

-- 2. Combined feed with algorithmic ranking (score = recency * weight + interactions): This query ranks posts based on a scoring algorithm to show more relevant content first. The score considers reactions, comments, and the age of the post.
WITH followees AS (
  SELECT followee_id FROM user_follows WHERE follower_id = (SELECT id FROM users WHERE username = 'alice')
), candidates AS (
  -- Consider posts from the last 30 days for ranking
  SELECT p.* FROM posts p
  WHERE p.author_id IN (SELECT followee_id FROM followees) AND p.created_at > now() - INTERVAL '30 days'
), stats AS (
  SELECT
    c.id,
    c.author_id,
    c.content,
    c.created_at,
    -- Using LEFT JOIN and COUNT is more performant than correlated subqueries
    COUNT(DISTINCT r.id) AS reaction_count,
    COUNT(DISTINCT cm.id) AS comment_count
  FROM candidates c
  LEFT JOIN reactions r ON r.target_type = 'post' AND r.target_id = c.id
  LEFT JOIN comments cm ON cm.post_id = c.id
  GROUP BY c.id, c.author_id, c.content, c.created_at
)
SELECT *,
  -- Scoring algorithm: more weight to reactions, some to comments, and a penalty for age.
  (LN(1 + reaction_count) * 2 + LN(1 + comment_count) * 1.5 - (EXTRACT(EPOCH FROM (now() - created_at)) / 3600) * 0.01) AS score
FROM stats
ORDER BY score DESC
LIMIT 10; -- page size

-- 3. Notifications query (unseen recent): Fetches the 50 most recent, unseen notifications for a user ('charlie' in this case).
SELECT id, type, payload, created_at
FROM notifications
WHERE user_id = (SELECT id FROM users WHERE username = 'charlie') AND seen = FALSE
ORDER BY created_at DESC
LIMIT 50; -- page size

-- 4) Conversation messages (pagination): Fetches a page of messages from a specific conversation using cursor pagination. This example fetches messages from the private chat between 'alice' and 'bob'.
SELECT m.*
FROM messages m
JOIN conversation_participants cp_a ON m.conversation_id = cp_a.conversation_id
JOIN conversation_participants cp_b ON m.conversation_id = cp_b.conversation_id
WHERE
  -- Find the private conversation between 'alice' and 'bob'
  cp_a.user_id = (SELECT id FROM users WHERE username = 'alice')
  AND cp_b.user_id = (SELECT id FROM users WHERE username = 'bob')
  -- Cursor logic for pagination. For the first page, we use a future timestamp.
  AND (m.created_at, m.id) < (now(), 'ffffffff-ffff-ffff-ffff-ffffffffffff'::uuid)
ORDER BY m.created_at DESC, m.id DESC
LIMIT 20; -- page size
