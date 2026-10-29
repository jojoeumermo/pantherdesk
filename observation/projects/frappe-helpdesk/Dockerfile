# Frappe Helpdesk. Everything that needs the internet (bench init, app downloads,
# asset builds) happens at build time, because the runtime network has no egress.
FROM frappe/bench:v5.31.1

ARG HELPDESK_VERSION=v1.31.0

USER frappe
WORKDIR /home/frappe
RUN bench init --skip-redis-config-generation --version version-15 frappe-bench \
    && cd frappe-bench \
    && bench get-app telephony \
    && bench get-app helpdesk --branch ${HELPDESK_VERSION} \
    && sed -i '/redis/d;/watch/d' Procfile

COPY --chown=frappe:frappe start.sh /home/frappe/start.sh
WORKDIR /home/frappe/frappe-bench
ENV TZ=UTC
CMD ["bash", "/home/frappe/start.sh"]
