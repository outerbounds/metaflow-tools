FROM python:3.7
RUN pip install boto3 awscli click
RUN mkdir '/.aws' && echo '[default]\ncredential_source = Environment' > /.aws/config && chmod -R 777 /.aws
RUN mkdir /tmp/azcopy && \
    wget -O /tmp/azcopy/downloadazcopy-v10-linux https://aka.ms/downloadazcopy-v10-linux &&  \
    tar -xvf /tmp/azcopy/downloadazcopy-v10-linux -C /tmp/azcopy &&  \
    cp /tmp/azcopy/azcopy_linux_amd64_*/azcopy /usr/bin/ && \
    chmod 755 /usr/bin/azcopy 
# todo if chmod 755 can work 
RUN rm -rf /tmp/azcopy

COPY s3_deploy.py s3_deploy.py
RUN mkdir /.azcopy && mkdir /.azcopy/plans

ENV AZCOPY_PLAN_FILE_LOCATION=/.azcopy/plans
ENV AZCOPY_LOG_LOCATION=/.azcopy

ENTRYPOINT ["python","s3_deploy.py"]
