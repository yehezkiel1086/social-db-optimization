# Social Media Platform - Database Schema Design

## Caching Strategy

Goals: support low-latency feeds, reduce DB load, and make reads scalable.

1. Redis — primary caching layer
2. Per-user home timeline (precomputed): maintain a Redis list per user (e.g. timeline:{user_id} ) that stores serialized post pointers (post_id + score/order). On write (new post), fan-out to followers' timelines (push to list). For users with millions of followers, use hybrid: push to only some followers and rely on pull-on-demand for others (fan-out-on-write for typical users; fan-out-on-read for megastars).
3. Per-post metadata cache: store aggregated counts (comments, reactions) in Redis hashes for quick
display. Use eventual consistency with DB as source of truth.
4. Conversations: cache recent message pages ( conversation:{id}:messages ) for faster reads;
update on new messages.
5. Notifications queue: store recent notifications in Redis sorted set ( notifications:{user_id} )
for efficient retrieval.
6. CDN and Object Storage for Media
7. Store images/videos in S3 (or compatible) and serve via CDN. Use signed URLs for private media.
8. Materialized Views / Read Replica DBs
9. Use materialized views or denormalized tables (e.g., post_feed_items ) refreshed periodically or
incrementally to serve heavy queries with less join work.
10. Use read replicas for read-heavy endpoints (feeds, profile views). Ensure replication lag handling in
application logic.
11. Cache Invalidation & Consistency
12. When reactions/comments change: update Redis counters atomically and asynchronously persist to
DB (queue worker).
13. For critical operations (e.g., editing/deleting a post), invalidate cached timeline entries and
materialized views immediately.
14. Bulk operations
15. For a user with large followership (celeb): avoid pushing to millions of timelines. Instead, mark their
posts as "push-to-pull": store post in a global hot-post store and let followers' feeds pull from it.

## Performance & Scalability Considerations 

- Partitioning / Sharding: shard posts , comments , reactions  by author_id  or by range of id (or use key-based hashing) when tables grow to billions of rows. Use consistent hashing for Redis clusters.
- Hot keys: watch for hot keys (e.g. celebrity timeline) in Redis. Use strategies like request-rate limiting, batching, and separate storage for celebrity fanout.
- Async processing: use background workers (Kafka/RabbitMQ) for fan-out, counters aggregation, notifications generation, search indexing.
- Search & analytics: move full-text and analytics workloads to dedicated services (ElasticSearch,
ClickHouse).
- Soft deletes / audit: prefer soft deletes with deleted_at  for data recovery and auditing.
- Monitoring: collect metrics for queue lengths, replication lag, query latencies, cache hit rates.
