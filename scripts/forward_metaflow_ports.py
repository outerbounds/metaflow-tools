import argparse
import subprocess
import sys
from datetime import datetime
import time

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
        'deployment': "metaflow-ui-static-service",
        "port": 3000,
        "is_ui": True
    }
}


class PortForwarder(object):
    def __init__(self, key,deployment, port, is_ui, namespace=None, scheme='http', output_port=None):
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

    def port_fwd_is_running(self):
        return self.port_fwd_proc is not None and self.port_fwd_proc.returncode is None

    def get_browser_hint(self):
        return "Open %s at %s://localhost:%d" % (self.deployment, self.scheme, self.output_port,)

    def start_new_port_fwd_proc(self):
        deployment_name = self.deployment
        cmd = ["kubectl", "port-forward", "deployment/%s" % deployment_name]
        if self.namespace:
            cmd.extend(["-n", self.namespace])
        cmd.append("{output_port}:{port}".format(port=self.port, output_port=self.output_port))
        self.port_fwd_proc = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        log("Started port forward for %s" % self.deployment)

    def stop_port_fwd_proc(self):
        self.port_fwd_proc.terminate()

    def run_keep_alive(self):
        cmd = ["nc", "-vz", "127.0.0.1", str(self.port)]
        try:
            subprocess.check_output(cmd, stderr=subprocess.DEVNULL)
            log("Kept port forward alive for %s" % self.deployment)
            return True
        except subprocess.CalledProcessError:
            log("Port forward failed for %s" % self.deployment)
            return False

    def step(self):
        if self.port_fwd_is_running():
            if not self.run_keep_alive():
                if self.port_fwd_is_running():
                    self.stop_port_fwd_proc()
                self.start_new_port_fwd_proc()

        else:
            self.start_new_port_fwd_proc()
        if self.is_ui:
            log(self.get_browser_hint())


def log(s):
    dt = datetime.now().strftime("%d-%m-%Y %H:%M:%S")
    print("%s - %s" % (dt, s))


def run(include_argo, include_airflow):
    port_forwarders = []
    for key, config in DEFAULT_PORT_FW_CONFIGS.items():
        port_forwarders.append(PortForwarder(
            key,
            config["deployment"],
            config["port"],
            config["is_ui"],
            namespace=config.get("namespace", None)
        ))
    if include_argo:
        port_forwarders.append(
            PortForwarder(
                "argo",
                "argo-server",
                2746,
                True,
                namespace="argo",
                scheme='https'
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
                scheme='https',
                output_port=9090
            )
        )
    try:
        while True:
            for port_forwarder in port_forwarders:
                port_forwarder.step()
            time.sleep(30)

    except KeyboardInterrupt:
        log("Aborted!")
        return 0
    finally:
        for port_forwarder in port_forwarders:
            port_forwarder.stop_port_fwd_proc()
            log("Terminated port forward to %s" % port_forwarder.key)


def main():
    parser = argparse.ArgumentParser(description="Maintain port forwards to Kubernetes Metaflow stack")
    parser.add_argument('--include-argo', action='store_true',
                        help="Do port forward for argo server (needed for Argo UI)")
    parser.add_argument('--include-airflow', action='store_true',
                        help="Do port forward for argo server (needed for Argo UI)")

    args = parser.parse_args()

    try:
        subprocess.check_output(["which", "kubectl"])
    except Exception:
        print("kubectl must be installed!")
        return 1

    try:
        subprocess.check_output(["which", "nc"])
    except Exception:
        print("nc utility must be installed!")
        return 1

    return run(args.include_argo, args.include_airflow)


if __name__ == '__main__':
    sys.exit(main())
