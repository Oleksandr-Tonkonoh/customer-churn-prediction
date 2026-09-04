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
AmazonS3_node1787746732692 = glueContext.create_dynamic_frame.from_catalog(database="my_crawler_db", table_name="orders_csv", transformation_ctx="AmazonS3_node1787746732692")

# Script generated for node Drop Duplicates
DropDuplicates_node1787746774596 =  DynamicFrame.fromDF(AmazonS3_node1787746732692.toDF().dropDuplicates(["order_id"]), glueContext, "DropDuplicates_node1787746774596")

# Script generated for node Change Schema
ChangeSchema_node1787746789149 = ApplyMapping.apply(frame=DropDuplicates_node1787746774596, mappings=[("order_id", "long", "order_id", "int"), ("customer_id", "long", "customer_id", "int"), ("order_date", "string", "order_date", "date"), ("order_value", "double", "order_value", "decimal"), ("product_category", "string", "product_category", "string"), ("payment_method", "string", "payment_method", "string"), ("status", "string", "status", "string")], transformation_ctx="ChangeSchema_node1787746789149")

# Script generated for node Filter
Filter_node1787746826830 = Filter.apply(frame=ChangeSchema_node1787746789149, f=lambda row: (row["order_value"] > 0), transformation_ctx="Filter_node1787746826830")

# Script generated for node Amazon S3
EvaluateDataQuality().process_rows(frame=Filter_node1787746826830, ruleset=DEFAULT_DATA_QUALITY_RULESET, publishing_options={"dataQualityEvaluationContext": "EvaluateDataQuality_node1787746717321", "enableDataQualityResultsPublishing": True}, additional_options={"dataQualityResultsPublishing.strategy": "BEST_EFFORT", "observations.scope": "ALL"})
AmazonS3_node1787746893471 = glueContext.write_dynamic_frame.from_options(frame=Filter_node1787746826830, connection_type="s3", format="glueparquet", connection_options={"path": "s3://customer-churn-bucket12345/processed/orders/", "partitionKeys": []}, format_options={"compression": "snappy"}, transformation_ctx="AmazonS3_node1787746893471")

job.commit()