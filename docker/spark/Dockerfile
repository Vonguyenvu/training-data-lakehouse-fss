FROM apache/spark:3.5.9-python3

ENV PYTHONPATH=/opt/spark/src:/opt/spark

# Jar Iceberg / Nessie / S3A nằm sẵn trong image (thay spark.jars.packages): executor không phải chép
# ~319MB jar mỗi lần khởi động vào work dir, và Thrift Server thấy catalog trên classpath hệ thống.
ARG MAVEN=https://repo1.maven.org/maven2
ADD --chown=spark:spark ${MAVEN}/org/apache/iceberg/iceberg-spark-runtime-3.5_2.12/1.6.1/iceberg-spark-runtime-3.5_2.12-1.6.1.jar /opt/spark/jars/
ADD --chown=spark:spark ${MAVEN}/org/projectnessie/nessie-integrations/nessie-spark-extensions-3.5_2.12/0.76.6/nessie-spark-extensions-3.5_2.12-0.76.6.jar /opt/spark/jars/
ADD --chown=spark:spark ${MAVEN}/org/apache/hadoop/hadoop-aws/3.3.4/hadoop-aws-3.3.4.jar /opt/spark/jars/
ADD --chown=spark:spark ${MAVEN}/com/amazonaws/aws-java-sdk-bundle/1.12.262/aws-java-sdk-bundle-1.12.262.jar /opt/spark/jars/

USER spark
