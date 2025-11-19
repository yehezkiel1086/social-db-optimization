FROM postgres:17-alpine

WORKDIR /docker-entrypoint-initdb.d

ENV POSTGRES_USER=${DB_USER}
ENV POSTGRES_PASSWORD=${DB_PASSWORD}
ENV POSTGRES_DB=${DB_NAME}

EXPOSE ${DB_PORT}

COPY normalized_social_tables_create.sql .
COPY normalized_social_tables_indexing.sql .
COPY social_tables_seeder.sql .
COPY complex_queries_feed_generation.sql .

RUN chmod 755 ./normalized_social_tables_create.sql
RUN chmod 755 ./normalized_social_tables_indexing.sql
RUN chmod 755 ./social_tables_seeder.sql

# ENTRYPOINT ["/usr/local/bin/psql", "-U", ${DB_USER}, "-b", ${DB_NAME}]
# CMD ["-f", "/docker-entrypoint-initdb.d/complex_queries_feed_generation.sql"]
