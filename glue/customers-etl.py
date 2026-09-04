import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsgluedq.transforms import EvaluateDataQuality
from awsglue.dynamicframe import DynamicFrame
from pyspark.sql import functions as SqlFuncs
import re

args = getResolvedOptions(sys.argv, ['JOB_NAME'])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Default ruleset used by all target nodes with data quality enabled
DEFAULT_DATA_QUALITY_RULESET = """
    Rules = [
        ColumnCount > 0
    ]
"""

# Script generated for node Amazon S3
AmazonS3_node1787747225195 = glueContext.create_dynamic_frame.from_catalog(database="my_crawler_db", table_name="customers_csv", transformation_ctx="AmazonS3_node1787747225195")

# Script generated for node Drop Duplicates
DropDuplicates_node1787747339118 =  DynamicFrame.fromDF(AmazonS3_node1787747225195.toDF().dropDuplicates(["customer_id"]), glueContext, "DropDuplicates_node1787747339118")

# Script generated for node Change Schema
ChangeSchema_node1787747437625 = ApplyMapping.apply(frame=DropDuplicates_node1787747339118, mappings=[("customer_id", "long", "customer_id", "int"), ("age", "long", "age", "int"), ("country", "string", "country", "string"), ("device", "string", "device", "string"), ("premium_user", "long", "premium_user", "binary"), ("signup_date", "string", "signup_date", "date")], transformation_ctx="ChangeSchema_node1787747437625")

# Script generated for node Filter
Filter_node1787747875816 = Filter.apply(frame=ChangeSchema_node1787747437625, f=lambda row: (row["age"] > 0), transformation_ctx="Filter_node1787747875816")

# Script generated for node Amazon S3
EvaluateDataQuality().process_rows(frame=Filter_node1787747875816, ruleset=DEFAULT_DATA_QUALITY_RULESET, publishing_options={"dataQualityEvaluationContext": "EvaluateDataQuality_node1787747205790", "enableDataQualityResultsPublishing": True}, additional_options={"dataQualityResultsPublishing.strategy": "BEST_EFFORT", "observations.scope": "ALL"})
AmazonS3_node1787747978283 = glueContext.write_dynamic_frame.from_options(frame=Filter_node1787747875816, connection_type="s3", format="glueparquet", connection_options={"path": "s3://customer-churn-bucket12345/processed/customers/", "partitionKeys": []}, format_options={"compression": "snappy"}, transformation_ctx="AmazonS3_node1787747978283")

job.commit()