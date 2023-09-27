#!/bin/bash
set -e

# Handle CACHE_MEM_SIZE deprecation
if [[ ! -z "${CACHE_MEM_SIZE}" ]]; then
    CACHE_INDEX_SIZE=${CACHE_MEM_SIZE}
fi

# Preprocess UPSTREAM_DNS to allow for multiple resolvers using the same syntax as lancache-dns
UPSTREAM_DNS="$(echo -n "${UPSTREAM_DNS}" | sed 's/[;]/ /g')"

echo "worker_processes ${NGINX_WORKER_PROCESSES};" > /etc/nginx/workers.conf
sed -i "s/^user .*/user ${WEBUSER};/" /etc/nginx/nginx.conf
sed -i "s/CACHE_INDEX_SIZE/${CACHE_INDEX_SIZE}/"  /etc/nginx/conf.d/20_proxy_cache_path.conf
sed -i "s/CACHE_DISK_SIZE/${CACHE_DISK_SIZE}/" /etc/nginx/conf.d/20_proxy_cache_path.conf
sed -i "s/CACHE_MAX_AGE/${CACHE_MAX_AGE}/" /etc/nginx/conf.d/20_proxy_cache_path.conf
sed -i "s/CACHE_MAX_AGE/${CACHE_MAX_AGE}/"    /etc/nginx/sites-available/cache.conf.d/root/20_cache.conf
sed -i "s/slice 1m;/slice ${CACHE_SLICE_SIZE};/" /etc/nginx/sites-available/cache.conf.d/root/20_cache.conf
sed -i "s/UPSTREAM_DNS/${UPSTREAM_DNS}/"    /etc/nginx/sites-available/cache.conf.d/10_root.conf
sed -i "s/UPSTREAM_DNS/${UPSTREAM_DNS}/"    /etc/nginx/sites-available/upstream.conf.d/10_resolver.conf
sed -i "s/UPSTREAM_DNS/${UPSTREAM_DNS}/"    /etc/nginx/stream-available/10_sni.conf
sed -i "s/LOG_FORMAT/${NGINX_LOG_FORMAT}/"  /etc/nginx/sites-available/10_cache.conf
sed -i "s/LOG_FORMAT/${NGINX_LOG_FORMAT}/"  /etc/nginx/sites-available/20_upstream.conf

if [[ ! -z "${CACHE_FORCE_UPSTREAM}" ]]; then
    sed -i 's%proxy_pass http://$host%proxy_pass http://'"${CACHE_FORCE_UPSTREAM}%" /etc/nginx/sites-available/cache.conf.d/20_lol.conf
    sed -i 's%proxy_pass http://$host%proxy_pass http://'"${CACHE_FORCE_UPSTREAM}%" /etc/nginx/sites-available/cache.conf.d/21_arenanet_manifest.conf
    sed -i 's%proxy_pass http://$host%proxy_pass http://'"${CACHE_FORCE_UPSTREAM}%" /etc/nginx/sites-available/cache.conf.d/22_wsus_cabs.conf
    sed -i 's%proxy_pass http://$host%proxy_pass http://'"${CACHE_FORCE_UPSTREAM}%" /etc/nginx/sites-available/upstream.conf.d/30_primary_proxy.conf

    sed -i 's%#CACHE_FORCE_UPSTREAM_HEADER%proxy_set_header Host $host;%' /etc/nginx/sites-available/cache.conf.d/20_lol.conf
    sed -i 's%#CACHE_FORCE_UPSTREAM_HEADER%proxy_set_header Host $host;%' /etc/nginx/sites-available/cache.conf.d/21_arenanet_manifest.conf
    sed -i 's%#CACHE_FORCE_UPSTREAM_HEADER%proxy_set_header Host $host;%' /etc/nginx/sites-available/cache.conf.d/22_wsus_cabs.conf
    sed -i 's%#CACHE_FORCE_UPSTREAM_HEADER%proxy_set_header Host $host;%' /etc/nginx/sites-available/upstream.conf.d/30_primary_proxy.conf
fi

