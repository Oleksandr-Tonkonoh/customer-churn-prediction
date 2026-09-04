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
AmazonS3_node1787748319390 = glueContext.create_dynamic_frame.from_catalog(database="my_crawler_db", table_name="sessions_csv", transformation_ctx="AmazonS3_node1787748319390")

# Script generated for node Drop Duplicates
DropDuplicates_node1787748364087 =  DynamicFrame.fromDF(AmazonS3_node1787748319390.toDF().dropDuplicates(["session_id"]), glueContext, "DropDuplicates_node1787748364087")

# Script generated for node Change Schema
ChangeSchema_node1787748567070 = ApplyMapping.apply(frame=DropDuplicates_node1787748364087, mappings=[("session_id", "long", "session_id", "int"), ("customer_id", "long", "customer_id", "int"), ("session_date", "string", "session_date", "date"), ("duration_minutes", "double", "duration_minutes", "decimal"), ("pages_viewed", "long", "pages_viewed", "int"), ("device", "string", "device", "string"), ("traffic_source", "string", "traffic_source", "string"), ("converted", "long", "converted", "binary")], transformation_ctx="ChangeSchema_node1787748567070")

# Script generated for node Filter
Filter_node1787749080646 = Filter.apply(frame=ChangeSchema_node1787748567070, f=lambda row: (row["duration_minutes"] > 0), transformation_ctx="Filter_node1787749080646")

# Script generated for node Amazon S3
EvaluateDataQuality().process_rows(frame=Filter_node1787749080646, ruleset=DEFAULT_DATA_QUALITY_RULESET, publishing_options={"dataQualityEvaluationContext": "EvaluateDataQuality_node1787748207562", "enableDataQualityResultsPublishing": True}, additional_options={"dataQualityResultsPublishing.strategy": "BEST_EFFORT", "observations.scope": "ALL"})
AmazonS3_node1787749150320 = glueContext.write_dynamic_frame.from_options(frame=Filter_node1787749080646, connection_type="s3", format="glueparquet", connection_options={"path": "s3://customer-churn-bucket12345/processed/sessions/", "partitionKeys": []}, format_options={"compression": "snappy"}, transformation_ctx="AmazonS3_node1787749150320")

job.commit()