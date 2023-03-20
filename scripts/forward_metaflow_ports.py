#!/usr/bin/env python3
import argparse
from contextlib import closing
from datetime import datetime
import logging
import os
import socket
import subprocess
import time

logger = logging.getLogger("connection-management")
logger.setLevel(logging.INFO)
sh = logging.StreamHandler()
formatter = logging.Formatter("%(asctime)s - %(message)s")
sh.setFormatter(formatter)
logger.addHandler(sh)

DEFAULT_PORT_FW_CONFIGS = {
    "service": {
        "deployment": "metadata-service",
        "port": 8080,
        "is_ui": False,
    },
    "ui": {
        "deployment": "metaflow-ui-backend-service",
        "port": 8083,
        "is_ui": False,
    },
    "ui-static": {
        "deployment": "metaflow-ui-static-service",
        "port": 3000,
        "is_ui": True,
    },
}


class PortForwarder(object):
    def __init__(
        self,
        key,
        deployment,
        port,
        is_ui,
        namespace=None,
        scheme="http",
        output_port=None,
        config_location=f"{os.getcwd()}/kubeconfig",
    ):
        self.key = key
        self.deployment = deployment
        self.port = port
        self.output_port = port
        if output_port is not None:
            self.output_port = output_port
        self.namespace = namespace
        self.port_fwd_proc = None
        self.is_ui = is_ui
        self.scheme = scheme
        self.config_location = config_location

    def port_fwd_is_running(self):
        return self.port_fwd_proc is not None and self.port_fwd_proc.returncode is None

    def get_browser_hint(self):
        return f"Open {self.deployment} at {self.scheme}://localhost:{self.output_port}"

    def start_new_port_fwd_proc(self):
        deployment_name = self.deployment
        cmd = ["kubectl", "port-forward", f"deployment/{deployment_name}"]
        if self.namespace:
            cmd.extend(["-n", self.namespace])
        cmd.append(f"{self.output_port}:{self.port}")
        logger.debug(f"Excuting {cmd}")
        self.port_fwd_proc = subprocess.Popen(
            cmd,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            # ensure we use the correct
            env={
                "KUBECONFIG": self.config_location,
            },
        )
        logger.info(f"Started port forward for {self.deployment}")
        if self.is_ui:
            logger.info(self.get_browser_hint())

    def stop_port_fwd_proc(self):
        self.port_fwd_proc.terminate()

    def run_keep_alive(self):
        with closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as sock:
            if sock.connect_ex(("localhost", self.port)) == 0:
                logger.info(f"Kept port forward alive for {self.deployment}")
                return True
            else:
                logger.info(f"Port forward failed for {self.deployment}")
                return False

    def step(self):
        if self.port_fwd_is_running():
            if not self.run_keep_alive():
                if self.port_fwd_is_running():
                    self.stop_port_fwd_proc()
                self.start_new_port_fwd_proc()
        else:
            self.start_new_port_fwd_proc()


def run(include_argo, include_airflow):
    port_forwarders = [
        PortForwarder(
            key,
            config["deployment"],
            config["port"],
            config["is_ui"],
            namespace=config.get("namespace", None),
        )
        for key, config in DEFAULT_PORT_FW_CONFIGS.items()
    ]
    if include_argo:
        port_forwarders.append(
            PortForwarder(
                "argo", "argo-server", 2746, True, namespace="argo", scheme="https"
            )
        )
    if include_airflow:
        port_forwarders.append(
            PortForwarder(
                "airflow",
                "airflow-deployment-webserver",
                8080,
                True,
                namespace="airflow",
                scheme="https",
                output_port=9090,
            )
        )
    try:
        while True:
            for port_forwarder in port_forwarders:
                port_forwarder.step()
            time.sleep(30)

    except KeyboardInterrupt:
        logger.info("Aborted!")
        return 0
    finally:
        for port_forwarder in port_forwarders:
            port_forwarder.stop_port_fwd_proc()
            logger.info(f"Terminated port forward to {port_forwarder.key}")


def main():
    parser = argparse.ArgumentParser(
        description="Maintain port forwards to Kubernetes Metaflow stack"
    )
    parser.add_argument(
        "--config-file",
        default=f"{os.getcwd()}/kubeconfig",
        help="Location of kubeconfig file for the cluster",
    )
    parser.add_argument(
        "--include-argo",
        action="store_true",
        help="Do port forward for argo server (needed for Argo UI)",
    )
    parser.add_argument(
        "--include-airflow",
        action="store_true",
        help="Do port forward for airflow server (needed for Airflow UI)",
    )
    parser.add_argument("--debug", action="store_true", help="Debug logging")
    parser.add_argument(
        "--use-gke-auth",
        action="store_true",
        help="Enable GKE auth plugin for GCP environments",
    )

    args = parser.parse_args()
    if args.debug:
        logger.setLevel(logging.DEBUG)
    if args.use_gke_auth:
        os.environ["USE_GKE_GCLOUD_AUTH_PLUGIN"] = "True"

    try:
        subprocess.check_output(["which", "kubectl"])
    except Exception:
        print("kubectl must be installed!")
        return 1

    return run(args.include_argo, args.include_airflow)


if __name__ == "__main__":
    exit(main())
