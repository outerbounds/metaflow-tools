FROM python:3.7
RUN pip install boto3 awscli click azure-identity azure-storage-blob
RUN mkdir '/.aws' && echo '[default]\ncredential_source = Environment' > /.aws/config && chmod -R 777 /.aws
COPY s3_deploy.py s3_deploy.py
ENTRYPOINT ["python","s3_deploy.py"]
