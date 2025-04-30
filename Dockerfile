# ────────────────────────────────────────────────────────────────────────────────
# Spark History Server • Java 11 • Hadoop 3
# ────────────────────────────────────────────────────────────────────────────────
FROM openjdk:11-jre-slim

# ── Build-time arguments ───────────────────────────────────────────────────────
ARG SPARK_VERSION="3.5.1"
ARG HADOOP_VERSION="3"

ENV SPARK_HOME=/opt/spark \
    PATH=$PATH:/opt/spark/bin:/opt/spark/sbin \
    # Default log directory inside the container
    SPARK_LOG_DIR=/opt/spark/logs

# ── Install tools & prepare APT (IPv4 + HTTPS) ─────────────────────────────────
RUN echo 'Acquire::ForceIPv4 "true";' > /etc/apt/apt.conf.d/99force-ipv4 && \
    sed -i 's|http://deb.debian.org|https://deb.debian.org|g' /etc/apt/sources.list && \
    apt-get update -qq && \
    apt-get install -y --no-install-recommends \
        curl tini procps gnupg && \
    rm -rf /var/lib/apt/lists/*

# ── Spark ──────────────────────────────────────────────────────────────────────
RUN curl -fsSL "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz" \
    | tar -xz -C /opt && \
    mv "/opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}" "${SPARK_HOME}"

# ── Configuration & Log dir ───────────────────────────────────────────────────
RUN mkdir -p "${SPARK_HOME}/conf" "${SPARK_LOG_DIR}"

# ── Entrypoint ─────────────────────────────────────────────────────────────────
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 18080

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/entrypoint.sh"]