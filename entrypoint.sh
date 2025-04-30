#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

echo "--- Starting entrypoint script ---"

# Check if SPARK_LOG_DIR is set, otherwise use default from Dockerfile
echo "Checking environment variable SPARK_HISTORY_FS_LOGDIRECTORY..."
if [ -z "${SPARK_HISTORY_FS_LOGDIRECTORY}" ]; then
  echo "Info: SPARK_HISTORY_FS_LOGDIRECTORY not set, using default: ${SPARK_LOG_DIR}"
  # Use the default log directory defined in the Dockerfile
  export SPARK_HISTORY_FS_LOGDIRECTORY=${SPARK_LOG_DIR}
else
  echo "Info: Using SPARK_HISTORY_FS_LOGDIRECTORY from environment: ${SPARK_HISTORY_FS_LOGDIRECTORY}"
fi

echo "Final log directory set to: ${SPARK_HISTORY_FS_LOGDIRECTORY}"

# Check if the log directory exists and list its contents
echo "Checking if log directory [${SPARK_HISTORY_FS_LOGDIRECTORY}] exists..."
if [ ! -d "${SPARK_HISTORY_FS_LOGDIRECTORY}" ]; then
  echo "Error: Log directory ${SPARK_HISTORY_FS_LOGDIRECTORY} does not exist inside the container." >&2
  echo "Please ensure the volume is mounted correctly and points to this path." >&2
  exit 1
fi
echo "Log directory found. Listing contents:"
ls -la "${SPARK_HISTORY_FS_LOGDIRECTORY}"
echo "-------------------------------------"

# Create Spark configuration file dynamically
echo "Creating ${SPARK_HOME}/conf/spark-defaults.conf file..."

cat <<EOF > ${SPARK_HOME}/conf/spark-defaults.conf
# === Spark History Server Configuration ===
spark.history.provider                 org.apache.spark.deploy.history.FsHistoryProvider
# Point to the local directory inside the container
spark.history.fs.logDirectory          file://${SPARK_HISTORY_FS_LOGDIRECTORY}
spark.history.fs.update.interval       10s
spark.history.ui.port                  18080
EOF

echo "Configuration saved."
echo "--- spark-defaults.conf content ---"
cat ${SPARK_HOME}/conf/spark-defaults.conf # Display configuration for diagnostic purposes
echo "--- End spark-defaults.conf content ---"

# Launch Spark History Server
echo "Starting Spark History Server using command:"
echo "exec ${SPARK_HOME}/bin/spark-class org.apache.spark.deploy.history.HistoryServer"
echo "-------------------------------------"
echo "Spark History Server UI available at: http://localhost:18080 or http://127.0.0.1:18080"
echo "-------------------------------------"
exec ${SPARK_HOME}/bin/spark-class org.apache.spark.deploy.history.HistoryServer