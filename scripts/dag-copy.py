import sys
import argparse
import subprocess
from datetime import datetime
import os
import json

def as_json(func):
    def wrapper(*args, **kwargs):
        output = func(*args, **kwargs)
        return json.loads(output)

    return wrapper

def bash_command(func):
    def wrapper(*args, **kwargs):
        cmd = func(*args, **kwargs)
        if isinstance(cmd, list):
            try:
                opx = subprocess.check_output(
                    cmd, stderr=subprocess.PIPE, env=os.environ
                )
            except subprocess.CalledProcessError as e:
                print(e.stderr)
                raise e
            return opx
        return cmd

    return wrapper

@as_json
@bash_command
def get_pods(namespace):
    return [
        "kubectl",
        "get",
        "pods",
        "-n",
        namespace,
        "-o",
        "json",
    ]

@bash_command
def copy_file( source_file, dest_file,  pod_name, container_name, namespace,):
    return [
        "kubectl",
        "cp",
        source_file,
        "%s/%s:%s" % (namespace, pod_name,dest_file),
        "-c",
        container_name
    ]


def _get_scheduler_pod_name(namespace):
    pod_list = get_pods(namespace)
    pod_container_name = None
    for item in pod_list["items"]:
        if "component" not in item["metadata"]["labels"]:
            continue
        if item["metadata"]["labels"]["component"] == "scheduler":
            pod_container_name = item["metadata"]["name"]
            break
    if pod_container_name is None:
        raise Exception(
            "Namespace %s doesn't have an Airflow scheduler running."
            % pod_container_name
        )
    return pod_container_name


def log(s):
    dt = datetime.now().strftime("%d-%m-%Y %H:%M:%S")
    print("%s - %s" % (dt, s))

def sync_dags(source_path, destination_path, namespace):
    pod_name = _get_scheduler_pod_name(namespace)
    copy_file(source_path, destination_path, pod_name, "scheduler", namespace)
    log("File `%s` copied to `%s` path in the Airflow scheduler pod `%s` in `%s` namespace" % (source_path, destination_path, pod_name, namespace))


def main():
    parser = argparse.ArgumentParser(description="Copy dag files from local machine to the Airflow scheduler deployed in the Kubernetes Cluster.")
    parser.add_argument('source_path', type=str, help="Source path of the Airflow DAG file")
    parser.add_argument('destination_path', type=str, help="Destination path of the Airflow DAG file")
    parser.add_argument('--airflow-namespace','--ns', default='airflow', type=str, help="Namespace of the airflow deployment")
    args = parser.parse_args()
    sync_dags(args.source_path, args.destination_path, args.airflow_namespace)


if __name__ == '__main__':
    sys.exit(main())
