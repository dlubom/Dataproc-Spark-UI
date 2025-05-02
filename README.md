# Local Spark History Server for Dataproc Serverless

This project provides a Docker image to run a local Spark History Server that can read Spark event logs downloaded from Google Cloud Storage (GCS). While GCP provides its own interface for viewing Spark job details, it often lacks the depth and features of the original Spark UI accessible through the History Server.

Dataproc Serverless jobs store their event logs in GCS. This local History Server allows you to view the detailed Spark UI for completed jobs by downloading these logs and pointing the server to them.

## Prerequisites

*   Docker installed.
*   Google Cloud SDK (`gcloud`) installed and configured (for using `gsutil`). Run `gcloud auth login` and `gcloud config set project <YOUR_PROJECT_ID>` if needed.

## Building the Docker Image

Build the image using the following command. You can adjust `SPARK_VERSION` and `HADOOP_VERSION` if needed.

```bash
docker build --no-cache --network=host \
    --build-arg SPARK_VERSION="3.5.1" \
    --build-arg HADOOP_VERSION="3" \
    -t local-spark-history-server .
```

## Running the Container

1.  **Find the Spark Event Log Directory in GCS:**
    *   Go to your Dataproc Serverless job details page in the Google Cloud Console.
    *   Navigate to the "ENVIRONMENT" tab in the Spark UI provided by GCP.
    *   Find the value for the `spark.eventLog.dir` or a similar property indicating the GCS path. It will look something like `gs://dataproc-temp-europe-west1-xxxxxxxxxxxx-xxxxxx/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/spark-job-history`.

2.  **Download the Event Logs:**
    Create a local directory to store the logs (e.g., `spark-logs`) and use `gsutil` to download the log files *from* the `spark-job-history` subdirectory in GCS *into* your local `spark-logs` directory. Replace `<YOUR_GCS_LOG_DIRECTORY_PATH>` with the path you found in step 1 (the path *containing* `spark-job-history`).

    ```bash
    mkdir -p ./spark-logs
    # Note: We copy the contents of spark-job-history/* directly into ./spark-logs/
    gsutil -m cp -r "<YOUR_GCS_LOG_DIRECTORY_PATH>/spark-job-history/*" ./spark-logs/
    ```
    *   `-m`: Performs a parallel copy.
    *   `-r`: Copies recursively.
    *   Make sure the destination directory (`./spark-logs/`) exists.
    *   **Important:** Spark History Server typically ignores files ending with `.inprogress`. Ensure your jobs have finished and the log files in GCS (and thus the downloaded copies) do not have the `.inprogress` suffix.

3.  **Run the Docker container:**
    Mount your local log directory into the container and point the History Server to it.

    ```bash
    docker run --rm --name spark-history \
      -p 18080:18080 \
      -v "$(pwd)/spark-logs:/opt/spark/logs:ro" \
      -e SPARK_HISTORY_FS_LOGDIRECTORY="/opt/spark/logs" \
      local-spark-history-server
    ```

    *   `-v "$(pwd)/spark-logs:/opt/spark/logs:ro"`: Mounts your local `spark-logs` directory to `/opt/spark/logs` inside the container in read-only mode (`:ro`). **Adjust the host path (`$(pwd)/spark-logs`) if your logs are elsewhere.**
    *   `-e SPARK_HISTORY_FS_LOGDIRECTORY="/opt/spark/logs"`: Sets the path *inside the container* where the Spark History Server should look for event logs. This matches the container path used in the volume mount.

4.  **Access the Spark UI:**
    Open your web browser and navigate to `http://localhost:18080`.