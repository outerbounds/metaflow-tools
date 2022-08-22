import functools
import subprocess
import json
import click
import logging
import os

from functools import wraps
import time


LOGGER_NAME = "BUCKET_SYNC"
logging.basicConfig(format="%(asctime)s %(message)s", datefmt="%m/%d/%Y %I:%M:%S %p")


@click.group()
def cli():
    pass


def _call_subprocess(cmd, check_output):
    if isinstance(cmd, list):
        try:
            if check_output:
                opx = subprocess.check_output(
                    cmd, stderr=subprocess.PIPE, env=os.environ
                )
            else:
                subprocess.call(cmd, stderr=subprocess.PIPE, env=os.environ)
                opx = ""
            return opx
        except subprocess.CalledProcessError as e:
            raise Exception(
                "An Exception Occurred with command : %s \n\n %s"
                % (
                    ", ".join(cmd),
                    "Not STDERR!" if e.stderr is None else e.stderr.decode(),
                )
            )
    return cmd


def bash_command(*args, **kwargs):
    check_output = True

    def inner(func, check_out=True):
        def wrapper(*args, **kwargs):
            cmd = func(*args, **kwargs)
            return _call_subprocess(cmd, check_out)

        return wrapper

    if len(args) == 1 and len(kwargs) == 0 and callable(args[0]):
        # called as @decorator
        return inner(args[0], check_output)
    else:
        # called as @decorator(*args, **kwargs)
        if "check_output" in kwargs and kwargs["check_output"]:
            check_output = True
        else:
            check_output = False
        return functools.partial(inner,check_out=check_output)


def as_json(func):
    def wrapper(*args, **kwargs):
        output = func(*args, **kwargs)
        return json.loads(output)

    return wrapper


@bash_command
def _sync_bucket(localp, s3p):
    return ["aws", "s3", "sync", s3p, localp]


@bash_command
def _s3_ls(s3p):
    return ["aws", "s3", "ls", s3p]


@bash_command(check_output=False)
def _sync_blobs(localp, s3p):
    return ["azcopy", "sync", localp, s3p, "--recursive"]


@bash_command(check_output=False)
def az_login():
    if not os.environ.get("AZURE_CLIENT_ID", False):
        raise Exception("No environment variable for `AZURE_CLIENT_ID` found")
    if not os.environ.get("AZURE_TENANT_ID", False):
        raise Exception("No environment variable for `AZURE_TENANT_ID` found")
    if not os.environ.get("AZURE_CLIENT_SECRET", False):
        raise Exception("No environment variable for `AZURE_CLIENT_SECRET` found")

    os.environ["AZCOPY_SPA_CLIENT_SECRET"] = os.environ.get("AZURE_CLIENT_SECRET")

    return [
        "azcopy",
        "login",
        "--service-principal",
        "--application-id",
        os.environ.get("AZURE_CLIENT_ID"),
        "--tenant-id",
        os.environ.get("AZURE_TENANT_ID"),
    ]


@cli.command()
@click.argument("s3-path")
@click.argument("local-path")
@click.option("--frequency", default=60, type=int, help="Frequency in seconds to sync")
@click.option(
    "--only-once",
    is_flag=True,
    default=False,
    type=int,
    help="Run the process only once",
)
def sync_bucket(local_path, s3_path, frequency=100, only_once=False):
    logger = logging.getLogger(LOGGER_NAME)
    logger.setLevel(logging.INFO)
    while True:
        logger.info("Syncing Bucket %s" % s3_path)
        logger.info(_s3_ls(s3_path))
        _sync_bucket(local_path, s3_path)
        logger.info(
            "Files synced: \n\t %s"
            % "\n\t".join([str(f) for f in os.listdir(local_path)])
        )
        logger.info(
            "Bucket Synced to path %s. Sleeping for %d seconds"
            % (local_path, frequency)
        )
        if only_once:
            break
        time.sleep(frequency)


@cli.command()
@click.argument("container-path")
@click.argument("local-path")
@click.option("--frequency", default=60, type=int, help="Frequency in seconds to sync")
@click.option(
    "--only-once",
    is_flag=True,
    default=False,
    type=int,
    help="Run the process only once",
)
def sync_azure_blobs(local_path, container_path, frequency=100, only_once=False):
    logger = logging.getLogger(LOGGER_NAME)
    logger.setLevel(logging.INFO)
    az_login()
    while True:
        logger.info("Syncing Azure Blob Store %s" % container_path)
        # logger.info(_s3_ls(s3_path))
        _sync_blobs(local_path, container_path)
        logger.info(
            "Files synced: \n\t %s"
            % "\n\t".join([str(f) for f in os.listdir(local_path)])
        )
        logger.info(
            "Azure Blobs Synced to path %s. Sleeping for %d seconds"
            % (local_path, frequency)
        )
        if only_once:
            break
        time.sleep(frequency)


if __name__ == "__main__":
    cli()
