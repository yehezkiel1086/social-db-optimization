FROM postgres:17-alpine

WORKDIR /app

EXPOSE 5432

COPY create_social_tables.sql /docker-entrypoint-initdb.d/
COPY create_social_tables.sql /docker-entrypoint-initdb.d/

RUN chmod 755 /docker-entrypoint-initdb.d/create_social_db.sql
